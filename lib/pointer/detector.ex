defmodule Pointer.Detector do
  def detect(_frame) do
    {result, _globals} =
      Pythonx.eval(
        """
        import random
        from ultralytics import YOLO
        import cv2

        model = YOLO("data/2025-04-16-best.pt")
        input = cv2.imread("data/train_logo_0001.jpg")

        def get_coords():
          results = model.predict(source=input, conf=0.75, verbose=False)
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
                        return [x0, y0, x1, y1]

        get_coords()
        """,
        %{}
      )

    [x, y, w, h] = Pythonx.decode(result)
    [x, y, w, h]
  end
end
