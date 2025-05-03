defmodule PointerWeb.DetectLive do
  use PointerWeb, :live_view

  alias Membrane.WebRTC.Live.{Capture, Player}

  import Phoenix.Component

  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        ingress_signaling = Membrane.WebRTC.Signaling.new()
        egress_signaling = Membrane.WebRTC.Signaling.new()

        Membrane.Pipeline.start_link(Pointer.Pipeline,
          ingress_signaling: ingress_signaling,
          egress_signaling: egress_signaling,
          detector_pid: self()
        )

        socket
        |> Capture.attach(
          id: "mediaCapture",
          signaling: ingress_signaling,
          video?: true,
          audio?: false
        )
        |> Player.attach(id: "videoPlayer", signaling: egress_signaling)
      else
        socket
      end

    socket =
      socket
      |> assign(:box, nil)
      |> assign(:width, 640)
      |> assign(:height, 480)
      |> assign(:processing_frame?, false)

    {:ok, socket}
  end

  def handle_info({:frame, frame_data, format}, socket) do
    if socket.assigns.processing_frame? do
      {:noreply, socket}
    else
      send(self(), {:detect_this_frame, frame_data, format})
      {:noreply, assign(socket, :processing_frame?, true)}
    end
  end

  def handle_info({:detect_this_frame, frame_data, format}, socket) do
    {box, width, height} = Pointer.Detector.detect(frame_data, format)
    socket = socket |> update_box(box, width, height) |> assign(:processing_frame?, false)
    {:noreply, socket}
  end

  def update_box(socket, box, width, height) do
    socket
    |> assign(:box, box)
    |> assign(:width, width)
    |> assign(:height, height)
  end

  def render(assigns) do
    ~H"""
    <div class="hidden">
      <Capture.live_render socket={@socket} capture_id="mediaCapture" />
    </div>

    <div class="relative inline-block">
      <Player.live_render socket={@socket} player_id="videoPlayer" class="w-[640px] h-[480px]" />
      <canvas
        id="trackingOverlay"
        phx-hook="TrackingOverlay"
        data-box={Jason.encode!(@box)}
        data-width={@width}
        data-height={@height}
        class="absolute top-0 left-0 w-[640px] h-[480px] z-10 pointer-events-none border-red-500"
      >
      </canvas>
    </div>
    """
  end
end
