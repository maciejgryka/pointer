defmodule Pointer.FrameExtractor do
  use Membrane.Filter

  def_input_pad(:input, accepted_format: %Membrane.RawVideo{pixel_format: :RGB})
  def_output_pad(:output, accepted_format: %Membrane.RawVideo{pixel_format: :RGB})

  def_options(
    detector_pid: [
      spec: pid(),
      description: "PID of the DetectLive process to send frames to"
    ]
  )

  @impl true
  def handle_init(_ctx, %{detector_pid: detector_pid}) do
    state = %{
      detector_pid: detector_pid
    }

    {[], state}
  end

  @impl true
  def handle_stream_format(:input, stream_format, _ctx, state) do
    {[stream_format: {:output, stream_format}], state}
  end

  @impl true
  def handle_buffer(:input, buffer, ctx, %{detector_pid: detector_pid} = state) do
    # Extract raw RGB frame data
    frame_data = buffer.payload

    # Get dimensions from stream format
    %{width: width, height: height} = ctx.pads.input.stream_format

    # Process the RGB frame data - using just base64 for simplicity
    # in a production environment, we'd use JPEG compression here
    try do
      # Convert frame to base64 and send to detector
      # Include dimensions which are needed for proper reconstruction in Python
      frame_info = %{
        width: width,
        height: height,
        format: :RGB,
        size: byte_size(frame_data)
      }

      # Send the raw RGB frame data encoded as base64
      base64_frame = Base.encode64(frame_data)
      send(detector_pid, {:frame, base64_frame, frame_info})
    rescue
      e ->
        IO.puts("Error processing frame: #{inspect(e)}")
    end

    # Forward the buffer to the output pad unchanged
    {[buffer: {:output, buffer}], state}
  end

  @impl true
  def handle_end_of_stream(:input, _ctx, state) do
    {[end_of_stream: :output], state}
  end
end
