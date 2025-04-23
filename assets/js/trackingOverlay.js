// Tracking overlay hook for drawing a rectangle on top of video
const TrackingOverlayHook = {
  mounted() {
    this.canvas = this.el;
    this.ctx = this.canvas.getContext('2d');
    this.box = this.el.dataset.box ? JSON.parse(this.el.dataset.box) : [50, 50, 100, 100];
    
    // Find the video element more robustly
    // First try to find it by ID
    this.videoElement = document.getElementById('videoPlayer');
    
    // If not found by ID, try to find it as a sibling of the canvas
    if (!this.videoElement) {
      const parentElement = this.el.parentElement;
      if (parentElement) {
        // Look for video element within the same container
        this.videoElement = parentElement.querySelector('video');
        console.log('Found video element by query:', !!this.videoElement);
      }
    }
    
    // Set initial canvas size if we found a video element
    if (this.videoElement) {
      this.resizeCanvas();
      
      // Add resize observer to keep canvas size matching video
      this.resizeObserver = new ResizeObserver(() => {
        this.resizeCanvas();
      });
      this.resizeObserver.observe(this.videoElement);
    } else {
      console.warn('TrackingOverlay hook: Could not find video element');
      // Set a default size
      this.canvas.width = 640;
      this.canvas.height = 480;
    }
    
    // Listen for updates to the box coordinates
    this.handleEvent("update_box", ({box}) => {
      this.box = box;
    });
    
    // Draw initial content
    this.draw();
    
    // Set up animation loop
    this.animationFrame = requestAnimationFrame(this.animationLoop.bind(this));
  },
  
  resizeCanvas() {
    if (this.videoElement) {
      const rect = this.videoElement.getBoundingClientRect();
      if (rect.width > 0 && rect.height > 0) {
        this.canvas.width = rect.width;
        this.canvas.height = rect.height;
      } else {
        // Video might not have dimensions yet, set a default
        this.canvas.width = this.canvas.width || 640;
        this.canvas.height = this.canvas.height || 480;
      }
    }
  },
  
  draw() {
    // Clear the canvas
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    
    // Draw a rectangle using the box coordinates [x, y, w, h]
    if (this.box && this.box.length === 4) {
      const [x, y, w, h] = this.box;
      this.ctx.strokeStyle = 'red';
      this.ctx.lineWidth = 3;
      this.ctx.beginPath();
      this.ctx.rect(x, y, w, h);
      this.ctx.stroke();
    }
  },
  
  animationLoop() {
    this.draw();
    this.animationFrame = requestAnimationFrame(this.animationLoop.bind(this));
  },
  
  destroyed() {
    // Clean up
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    }
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame);
    }
  }
};

export default TrackingOverlayHook;
