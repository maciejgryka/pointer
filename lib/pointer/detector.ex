defmodule Pointer.Detector do
  # DETECT/1 FUNCTIONS

  # Main detect/1 function for backward compatibility without format
  def detect(base64_frame) when is_binary(base64_frame) and byte_size(base64_frame) > 0 do
    # Use default dimensions when no frame info is provided
    frame_info = %{
      width: 640,
      height: 480,
      format: :RGB,
      size: byte_size(Base.decode64!(base64_frame))
    }

    detect(base64_frame, frame_info)
  end

  # Fallback for bare calls with no parameters
  def detect(_) do
    # Return an empty box
    [0, 0, 0, 0]
  end

  # DETECT/2 FUNCTIONS

  # Main detection function that accepts raw RGB frame information
  def detect(base64_frame, frame_info)
      when is_binary(base64_frame) and byte_size(base64_frame) > 0 and is_map(frame_info) do
    # Extract width and height from frame info
    # Default to 640 if not provided
    width = Map.get(frame_info, :width, 640)
    # Default to 480 if not provided
    height = Map.get(frame_info, :height, 480)

    # Forward the base64 encoded frame and dimensions to Python for processing
    {result, _globals} =
      Pythonx.eval(
        """
        import io
        import base64
        import numpy as np
        from ultralytics import YOLO
        import cv2

        model = YOLO("data/2025-04-16-best.pt")

        def decode_raw_rgb_frame(base64_frame, width, height):
            try:
                # Decode the base64 string to binary data
                # print(f"Received RGB frame of length {len(base64_frame)}: {base64_frame[:20]}...")
                image_bytes = base64.b64decode(base64_frame)

                # Check if the size matches what we'd expect for RGB data
                expected_size = width * height * 3  # 3 bytes per pixel for RGB
                actual_size = len(image_bytes)

                # print(f"Frame dimensions: {width}x{height}, expected size: {expected_size}, actual size: {actual_size}")

                if abs(expected_size - actual_size) > 100:  # Allow small differences
                    print(f"Warning: Frame size mismatch. Expected {expected_size}, got {actual_size}")

                # Convert binary data to numpy array and reshape to image dimensions
                try:
                    # Create a numpy array from the raw bytes
                    img_array = np.frombuffer(image_bytes, dtype=np.uint8)

                    # Reshape to image dimensions with 3 channels (RGB)
                    img = img_array[:width*height*3].reshape((height, width, 3))

                    # Convert from RGB to BGR for OpenCV
                    img = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)

                    # print(f"Successfully reconstructed RGB frame with shape {img.shape}")
                    return img
                except Exception as reshape_error:
                    print(f"Error reshaping image data: {reshape_error}")

                    # Try to save the raw data for debugging
                    with open('/tmp/rgb_frame.raw', 'wb') as f:
                        f.write(image_bytes)
                    print("Saved raw frame data to /tmp/rgb_frame.raw")

            except Exception as e:
                print(f"Error in RGB decode function: {e}")
                import traceback
                traceback.print_exc()

            # If decoding fails, use test image
            print("Using fallback test image")
            return cv2.imread("data/train_logo_0001.jpg")

        def get_coords(base64_frame, width, height):
            # Decode the base64 frame into a numpy array using dimensions
            frame = decode_raw_rgb_frame(base64_frame, width, height)

            try:
                # Run detection on the decoded frame
                # print("Running detection on frame")
                results = model.predict(source=frame, conf=0.75, verbose=False)

                if results and len(results) > 0:
                    res = results[0]  # Get the Results object for the first image/frame
                    if res.boxes is not None and len(res.boxes) > 0:
                        boxes = res.boxes
                        confidences = boxes.conf
                        if len(confidences) > 0:
                            # Find the index of the detection with the highest confidence
                            max_conf_idx = confidences.argmax()
                            best_box = boxes[max_conf_idx]

                            # Extract data for the best box
                            xyxy = best_box.xyxy[0].cpu().numpy().astype(int)
                            # conf = best_box.conf[0].cpu().numpy()
                            x0 = int(min(xyxy[0], xyxy[2]))
                            y0 = int(min(xyxy[1], xyxy[3]))
                            x1 = int(max(xyxy[0], xyxy[2]))
                            y1 = int(max(xyxy[1], xyxy[3]))
                            # print(f"Detection found at: [{x0}, {y0}, {x1}, {y1}]")
                            return [x0, y0, x1, y1]

                    # print("No boxes found in results")
                else:
                    print("No results returned from model")
            except Exception as e:
                print(f"Error during detection: {e}")

            # Default result if no detection or error
            return [0, 0, 0, 0]

        get_coords(base64_frame, width, height)
        """,
        %{
          "base64_frame" => base64_frame,
          "width" => width,
          "height" => height
        }
      )

    coords = Pythonx.decode(result)
    # Default empty box if Python returns nil
    coords || [0, 0, 0, 0]
  end

  # Method for backward compatibility with the format parameter
  def detect(base64_frame, format)
      when is_binary(base64_frame) and byte_size(base64_frame) > 0 and not is_map(format) do
    IO.puts("Detecting with legacy format: #{inspect(format)}")

    # Create a proper frame_info map
    frame_info = %{
      width: 640,
      height: 480,
      format: :RGB,
      size: byte_size(Base.decode64!(base64_frame))
    }

    detect(base64_frame, frame_info)
  end

  # Fallback for empty or non-binary frames
  def detect(_frame, _format) do
    # Return an empty box
    [0, 0, 0, 0]
  end
end
