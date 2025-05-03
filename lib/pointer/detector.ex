defmodule Pointer.Detector do
  @doc """
  Detects objects in the given base64-encoded frame using a YOLO model.
  This delegates to DetectorServer which maintains a persistent Python process
  with the model loaded.
  """
  def detect(base64_frame, frame_info)
      when is_binary(base64_frame) and byte_size(base64_frame) > 0 and is_map(frame_info) do
    Pointer.DetectorServer.detect(base64_frame, frame_info)
  end

  def detect(_frame, _format), do: {[0, 0, 0, 0], 640, 480}
end
