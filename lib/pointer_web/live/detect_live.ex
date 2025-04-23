defmodule PointerWeb.DetectLive do
  use PointerWeb, :live_view

  alias Membrane.WebRTC.Live.{Capture, Player}

  # Import Routes to use in callbacks
  import Phoenix.Component

  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        ingress_signaling = Membrane.WebRTC.Signaling.new()
        egress_signaling = Membrane.WebRTC.Signaling.new()

        Membrane.Pipeline.start_link(Pointer.Pipeline,
          ingress_signaling: ingress_signaling,
          egress_signaling: egress_signaling
        )

        socket
        |> Capture.attach(
          id: "mediaCapture",
          signaling: ingress_signaling,
          video?: true,
          audio?: false
        )
        |> Player.attach(
          id: "videoPlayer",
          signaling: egress_signaling
        )
      else
        socket
      end

    socket =
      socket
      |> assign(:box, [50, 50, 100, 100])

    {:ok, socket}
  end

  # Function to update the tracking box and push to the client
  def update_box(socket, box) do
    socket = assign(socket, :box, box)
    # Push the updated box to the client
    socket = push_event(socket, "update_box", %{box: box})
    socket
  end

  def render(assigns) do
    ~H"""
    <div class="hidden">
      <Capture.live_render socket={@socket} capture_id="mediaCapture" />
    </div>

    <div class="relative inline-block">
      <Player.live_render socket={@socket} player_id="videoPlayer" />
      <canvas
        id="trackingOverlay"
        phx-hook="TrackingOverlay"
        data-box={Jason.encode!(@box)}
        class="absolute top-0 left-0 w-full h-full z-10 pointer-events-none"
      >
      </canvas>
    </div>
    """
  end
end
