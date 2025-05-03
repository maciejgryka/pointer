// Tracking overlay hook for drawing a rectangle on top of video
// const WIDTH = 640;
// const HEIGHT = 480;

const TrackingOverlayHook = {
  mounted() {
    this.canvas = this.el;
    this.ctx = this.canvas.getContext('2d');
    this.box = this.el.dataset.box ? JSON.parse(this.el.dataset.box) : null;
    this.width = this.el.dataset.width;
    this.height = this.el.dataset.height;
    this.canvas.width = this.width;
    this.canvas.height = this.height;
    this.draw();
    this.animationFrame = requestAnimationFrame(this.animationLoop.bind(this));
  },

  updated() {
    const newBoxData = this.el.dataset.box;
    if (newBoxData) {
      try {
        this.box = JSON.parse(newBoxData);
        this.width = this.el.dataset.width;
        this.height = this.el.dataset.height;
      } catch (e) {
        console.error('Error parsing updated box data:', e, newBoxData);
        this.box = null;
      }
    } else {
      this.box = null;
    }
    this.canvas.width = this.width;
    this.canvas.height = this.height;
  },
  
  draw() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    
    if (this.box && this.box.length === 4) {
      const [x0, y0, x1, y1] = this.box;
      // x0 = Math.max(0, Math.min(x0, WIDTH));
      // y0 = Math.max(0, Math.min(y0, HEIGHT));
      // x1 = Math.max(0, Math.min(x1, WIDTH));
      // y1 = Math.max(0, Math.min(y1, HEIGHT));
      
      const w = x1 - x0;
      const h = y1 - y0;
      
      this.ctx.strokeStyle = 'red';
      this.ctx.lineWidth = 1;
      this.ctx.beginPath();
      this.ctx.rect(x0, y0, w, h);
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
