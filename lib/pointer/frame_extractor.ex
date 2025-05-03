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
    frame_data = buffer.payload
    %{width: width, height: height} = ctx.pads.input.stream_format

    frame_info = %{
      width: width,
      height: height,
      format: :RGB,
      size: byte_size(frame_data)
    }

    base64_frame = Base.encode64(frame_data)
    send(detector_pid, {:frame, base64_frame, frame_info})

    {[buffer: {:output, buffer}], state}
  end

  @impl true
  def handle_end_of_stream(:input, _ctx, state) do
    {[end_of_stream: :output], state}
  end
end
