// Tracking overlay hook for drawing a rectangle on top of video
const TrackingOverlayHook = {
  mounted() {
    this.canvas = this.el;
    this.ctx = this.canvas.getContext('2d');
    this.box = this.el.dataset.box ? JSON.parse(this.el.dataset.box) : null;
    
    // Find the video element more robustly
    // Try several methods to find the video element
    
    // Method 1: Direct ID
    this.videoElement = document.getElementById('videoPlayer');
    
    if (this.videoElement) {
      console.log('Found video by ID');
    } else {
      // Method 2: Look for LiveView wrapper with ID videoPlayer-lv
      const lvWrapper = document.getElementById('videoPlayer-lv');
      if (lvWrapper) {
        this.videoElement = lvWrapper.querySelector('video');
        console.log('Found video inside LiveView wrapper:', !!this.videoElement);
      }
    }
    
    // Method 3: If still not found, look in the same container
    if (!this.videoElement) {
      const parentElement = this.el.parentElement;
      if (parentElement) {
        this.videoElement = parentElement.querySelector('video');
        console.log('Found video element by query:', !!this.videoElement);
      }
    }
    
    // Set initial canvas size if we found a video element
    if (this.videoElement) {
      console.warn('TrackingOverlay hook: found video element');
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
      console.log('Received updated box coordinates:', box);
      
      // Make sure we're getting an array with 4 values
      if (Array.isArray(box) && box.length === 4) {
        // Validate that all values are numbers and reasonable
        const [x, y, w, h] = box;
        if (typeof x === 'number' && typeof y === 'number' && 
            typeof w === 'number' && typeof h === 'number') {
          
          // Ensure the dimensions are reasonable based on canvas size
          const maxWidth = this.canvas.width || 640;
          const maxHeight = this.canvas.height || 480;
          
          // Log if the dimensions seem suspicious
          if (w > maxWidth || h > maxHeight) {
            console.warn('Box dimensions may be too large for canvas:', { w, h, maxWidth, maxHeight });
          }
          
          this.box = box;
        } else {
          console.error('Box coordinates contain non-numeric values:', box);
        }
      } else {
        console.error('Invalid box format received:', box);
      }
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
      
      console.log('Drawing box with dimensions:', { 
        x, y, w, h, 
        canvasWidth: this.canvas.width, 
        canvasHeight: this.canvas.height,
        box: JSON.stringify(this.box)
      });
      
      // Rather than drawing a huge rectangle that might go off canvas,
      // let's constrain it to visible area for safety
      const safeW = Math.min(w, this.canvas.width - x);
      const safeH = Math.min(h, this.canvas.height - y);
      
      this.ctx.strokeStyle = 'red';
      this.ctx.lineWidth = 1;
      this.ctx.beginPath();
      // Draw the rectangle - use x,y as top-left corner, and w,h as dimensions
      this.ctx.rect(x, y, safeW, safeH);
      this.ctx.stroke();
      
      // Draw a small marker at the starting point for reference
      this.ctx.fillStyle = 'green';
      this.ctx.beginPath();
      this.ctx.arc(x, y, 4, 0, Math.PI * 2);
      this.ctx.fill();
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
