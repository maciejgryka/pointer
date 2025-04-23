// Tracking overlay hook for drawing a rectangle on top of video
const TrackingOverlayHook = {
  mounted() {
    this.canvas = this.el;
    this.ctx = this.canvas.getContext('2d');
    this.box = this.el.dataset.box ? JSON.parse(this.el.dataset.box) : null;
    this.canvas.width = 640;
    this.canvas.height = 480;
    this.draw();
    this.animationFrame = requestAnimationFrame(this.animationLoop.bind(this));
  },

  updated() {
    const newBoxData = this.el.dataset.box;
    if (newBoxData) {
      try {
        this.box = JSON.parse(newBoxData);
      } catch (e) {
        console.error('Error parsing updated box data:', e, newBoxData);
        this.box = null;
      }
    } else {
      this.box = null;
    }
    this.canvas.width = 640;
    this.canvas.height = 480;
  },
  
  draw() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    
    if (this.box && this.box.length === 4) {
      const [x, y, w, h] = this.box;
      
      const safeW = Math.min(w, this.canvas.width - x);
      const safeH = Math.min(h, this.canvas.height - y);
      
      this.ctx.strokeStyle = 'red';
      this.ctx.lineWidth = 1;
      this.ctx.beginPath();
      this.ctx.rect(x, y, safeW, safeH);
      this.ctx.stroke();
    }
  },
  
  animationLoop() {
    this.draw();
    this.animationFrame = requestAnimationFrame(this.animationLoop.bind(this));
  },
  
  destroyed() {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame);
    }
  }
};

export default TrackingOverlayHook;
