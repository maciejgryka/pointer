defmodule Pointer.DetectorServer do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {_result, globals} =
      Pythonx.eval(
        """
        import io
        import base64
        import numpy as np
        from ultralytics import YOLO
        import cv2

        # Load the model once at initialization
        model = YOLO("data/2025-04-16-best.pt")
        print("YOLO model loaded successfully")

        def decode_raw_rgb_frame(base64_frame, width, height):
            try:
                image_bytes = base64.b64decode(base64_frame)
                expected_size = width * height * 3
                actual_size = len(image_bytes)

                if abs(expected_size - actual_size) > 100:  # Allow small differences
                    print(f"Warning: Frame size mismatch. Expected {expected_size}, got {actual_size}")

                try:
                    img_array = np.frombuffer(image_bytes, dtype=np.uint8)
                    img = img_array[:width*height*3].reshape((height, width, 3))
                    return img
                except Exception as reshape_error:
                    print(f"Error reshaping image data: {reshape_error}")

            except Exception as e:
                print(f"Error in RGB decode function: {e}")
                import traceback
                traceback.print_exc()

        def get_coords(base64_frame, width, height):
            frame = decode_raw_rgb_frame(base64_frame, width, height)

            try:
                results = model.predict(source=frame, conf=0.75, verbose=False)

                if results and len(results) > 0:
                    res = results[0]
                    if res.boxes is not None and len(res.boxes) > 0:
                        boxes = res.boxes
                        confidences = boxes.conf
                        if len(confidences) > 0:
                            max_conf_idx = confidences.argmax()
                            best_box = boxes[max_conf_idx]

                            xyxy = best_box.xyxy[0].cpu().numpy().astype(int)
                            # conf = best_box.conf[0].cpu().numpy()
                            x0 = int(min(xyxy[0], xyxy[2]))
                            y0 = int(min(xyxy[1], xyxy[3]))
                            x1 = int(max(xyxy[0], xyxy[2]))
                            y1 = int(max(xyxy[1], xyxy[3]))

                            # print(f"Detection found at: [{x0}, {y0}, {x1}, {y1}]")
                            return [x0, y0, x1, y1]

                else:
                    print("No results returned from model")
            except Exception as e:
                print(f"Error during detection: {e}")

            # Default result if no detection or error
            return [0, 0, 0, 0]
        """,
        %{}
      )

    Logger.info("Python process and YOLO model initialization complete")
    {:ok, [globals]}
  end

  def detect(base64_frame, frame_info) do
    GenServer.call(__MODULE__, {:detect, base64_frame, frame_info}, 30000)
  end

  def handle_call({:detect, base64_frame, frame_info}, _from, [globals]) do
    width = Map.get(frame_info, :width, 640)
    height = Map.get(frame_info, :height, 480)

    globals =
      Map.merge(globals, %{
        "base64_frame" => base64_frame,
        "width" => width,
        "height" => height
      })

    {result, globals} =
      Pythonx.eval(
        """
        get_coords(base64_frame, width, height)
        """,
        globals
      )

    coords = Pythonx.decode(result) || [0, 0, 0, 0]
    {:reply, {coords, width, height}, [globals]}
  end
end
