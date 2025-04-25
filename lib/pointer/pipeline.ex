defmodule Pointer.Pipeline do
  use Membrane.Pipeline

  @impl true
  def handle_init(_ctx, opts) do
    spec =
      child(:webrtc_source, %Membrane.WebRTC.Source{
        allowed_video_codecs: :vp8,
        signaling: opts[:ingress_signaling]
      })
      |> via_out(:output, options: [kind: :video])
      |> child(%Membrane.Transcoder{output_stream_format: Membrane.RawVideo})
      |> child(%Membrane.FFmpeg.SWScale.Converter{format: :RGB})
      |> child(:frame_extractor, %Pointer.FrameExtractor{detector_pid: opts[:detector_pid]})
      |> child(%Membrane.FFmpeg.SWScale.Converter{format: :I420})
      |> child(%Membrane.Transcoder{
        output_stream_format: %Membrane.VP8{width: 640, height: 480}
      })
      |> via_in(:input, options: [kind: :video])
      |> child(:webrtc_sink, %Membrane.WebRTC.Sink{
        video_codec: :vp8,
        signaling: opts[:egress_signaling]
      })

    {[spec: spec], %{}}
  end
end
