# WebRTC LiveView Object Detection Demo

Real-time video processing with Phoenix LiveView and the Membrane Framework. Captures video from a webcam, does object detection on the server, and streams the coordinates back to the browser.

## How It Works

The application creates a WebRTC connection between your browser and the server. Your webcam feed is sent to the server, where it's processed by a Membrane pipeline that applies real-time object detection using a custom-trained YOLOv11 model running inside `Pythonx`. The coordinates of the detected objects are then streamed back to your browser and displayed using LiveView JS hook.

## Components

### LiveView

This component is the UI entry point of the application. It:

- Sets up bidirectional signaling channels for WebRTC communication
- Initializes the Membrane pipeline
- Attaches media capture components for sending webcam video to the server
- Attaches player components for displaying the processed video
- Renders the UI with video elements

### Membrane Pipeline

This is the core of the video processing system. It:

- Receives WebRTC video streams from the browser
- Transcodes the video to a raw format that can be processed
- Applies format conversion to prepare for contour detection
- Processes frames through the contour detection filter
- Converts the processed video back to a suitable format
- Streams the processed video back to the browser via WebRTC

### Detector

## Deployment

We can run it on the `lewton` server, but releases are not set up yet, only the dev server. `nginx` and `letsencrypt` are set up and `https://detect.gryka.net` points to port 4000, but first you need to:

```bash
ssh lewton
cd /home/mgryka/dev/pointer
MIX_ENV=prod mise exec elixir@1.18.3 -- mix release
sudo systemctl restart pointer.service
```

Then visit `https://detect.gryka.net`. You can also run `TERM=xterm htop` in a differnt terminal to monitor usage.
