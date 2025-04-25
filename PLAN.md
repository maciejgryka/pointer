# Plan for Server-Side Frame Extraction and Detection

This plan outlines the steps to modify the application to extract video frames directly from the Membrane pipeline on the server, send them to the `DetectLive` LiveView, handle potential back-pressure from the Python detector, and display the results.

## 1. Create `Pointer.FrameExtractor` Membrane Filter

*   **Goal:** Create a custom Membrane element to intercept video frames.
*   **Location:** `lib/pointer/frame_extractor.ex`
*   **Implementation:**
    *   Define a new module `Pointer.FrameExtractor` using `Membrane.Filter`.
    *   Define input and output pads for video buffers.
    *   Accept the target `DetectLive` process PID as an option (`:detector_pid`) in `handle_init/2`. Store this PID in the element's state.
    *   Implement `handle_process/4` for the input pad:
        *   Forward the received buffer unchanged to the output pad using `:buffer` action.
        *   Extract the raw frame data (payload) from the buffer.
        *   Send the frame data asynchronously to the stored `detector_pid` using `send(detector_pid, {:frame, frame_data})`.
    *   Ensure the filter handles necessary Membrane callbacks (e.g., `handle_eos`, `handle_stream_format`).

## 2. Modify `Pointer.Pipeline`

*   **Goal:** Integrate the `FrameExtractor` into the existing pipeline.
*   **Location:** `lib/pointer/pipeline.ex`
*   **Implementation:**
    *   Modify `handle_init/2` to accept the `:detector_pid` option.
    *   Update the pipeline `spec`:
        *   Insert `child(:frame_extractor, %Pointer.FrameExtractor{detector_pid: opts[:detector_pid]})` between the `webrtc_source` and `webrtc_sink`.
        *   Connect the `webrtc_source` output to the `frame_extractor` input.
        *   Connect the `frame_extractor` output to the `webrtc_sink` input.

## 3. Modify `PointerWeb.DetectLive`

*   **Goal:** Adapt the LiveView to receive frames, manage detection throttling, and update the UI.
*   **Location:** `lib/pointer_web/live/detect_live.ex`
*   **Implementation:**
    *   **`mount/3`:**
        *   Add `:processing_frame?` to the initial assigns, set to `false`.
        *   When starting the pipeline (`Membrane.Pipeline.start_link`), pass the LiveView's PID: `detector_pid: self()`.
        *   Remove the initial `Process.send_after(self(), :step, ...)` call and the corresponding `handle_info(:step, socket)`.
    *   **`handle_info({:frame, frame_data}, socket)`:**
        *   Check `socket.assigns.processing_frame?`.
        *   If `true`, return `{:noreply, socket}` (drop frame).
        *   If `false`:
            *   `assign(socket, :processing_frame?, true)`
            *   `send(self(), {:detect_this_frame, frame_data})`
            *   Return `{:noreply, socket}`.
    *   **`handle_info({:detect_this_frame, frame_data}, socket)`:**
        *   Call `box = Pointer.Detector.detect(frame_data)`.
        *   Update the UI state: `socket = update_box(socket, box)` (or integrate logic).
        *   Reset the flag: `socket = assign(socket, :processing_frame?, false)`.
        *   Return `{:noreply, socket}`.
    *   **`update_box/2`:** Ensure this function still correctly assigns the box and pushes the `update_box` event to the client hook.

## 4. Update `Pointer.Detector`

*   **Goal:** Modify the detector module to handle raw frame data.
*   **Location:** `lib/pointer/detector.ex`
*   **Implementation:**
    *   Adjust the `detect/1` function to accept the raw binary frame data (likely VP8 encoded based on the current pipeline) sent by `DetectLive`.
    *   Ensure the call to the Python function passes this binary data correctly.

## 5. Update Python Detection Code

*   **Goal:** Modify the Python code to decode the frame and perform detection.
*   **Location:** (Assumed to be within the Python code called by `Pointer.Detector`)
*   **Implementation:**
    *   Receive the raw binary frame data (e.g., VP8 bytes) from Elixir.
    *   Use a suitable Python library (e.g., `pyav`, `ffmpeg-python`, or specific OpenCV builds) to decode the VP8 frame into an image format (like NumPy array) that the detection model can process.
    *   Perform object detection on the decoded image.
    *   Return the detection results (bounding box coordinates) back to Elixir.
