# WebRTC LiveView Object Detection Demo

Real-time video processing with Phoenix LiveView and the Membrane Framework. Captures video from a webcam, does object detection on the server, and streams the coordinates back to the browser.

## Features
- Webcam video capture in the browser
- Server-side video processing with object detection
- WebRTC streaming

## How It Works
The application creates a WebRTC connection between your browser and the server. Your webcam feed is sent to the server, where it's processed by a Membrane pipeline that applies real-time object detection. The coordinates of the detected objects are then streamed back to your browser.

## Components
### LiveView Component (WebrtcLiveViewWeb.Live.EchoLive)
This component is the UI entry point of the application. It:

- Sets up bidirectional signaling channels for WebRTC communication
- Initializes the Membrane pipeline
- Attaches media capture components for sending webcam video to the server
- Attaches player components for displaying the processed video
- Renders the UI with video elements

### Membrane Pipeline (WebRTCLiveView.Pipeline)
This is the core of the video processing system. It:

- Receives WebRTC video streams from the browser
- Transcodes the video to a raw format that can be processed
- Applies format conversion to prepare for contour detection
- Processes frames through the contour detection filter
- Converts the processed video back to a suitable format
- Streams the processed video back to the browser via WebRTC

### Contours Drawer (WebRTCLiveView.CountoursDrawer)
This is a custom Membrane filter that processes each video frame. It:

- Converts RGB frames to grayscale
- Applies thresholding to create a binary image
- Finds contours in the binary image
- Filters contours by size
- Draws the detected contours on the original image
- Returns the processed frame to the pipeline
