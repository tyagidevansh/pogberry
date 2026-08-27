use "pb_gui" as gui;

class Particle {
  init(i) {
    this.x = (i * 37) % 800;
    this.y = (i * 53) % 600;
    this.vx = ((i * 17) % 5) - 2;
    this.vy = ((i * 13) % 5) - 2;
    this.r = (i * 7) % 256;
    this.g = (i * 11) % 256;
    this.b = (i * 13) % 256;
  }

  update() {
    this.x = this.x + this.vx;
    this.y = this.y + this.vy;
    if (this.x > 800) this.x = this.x - 800;
    if (this.x < 0) this.x = this.x + 800;
    if (this.y > 600) this.y = this.y - 600;
    if (this.y < 0) this.y = this.y + 600;
  }

  draw() {
    gui.drawCircle(this.x, this.y, 3, this.r, this.g, this.b);
  }
}

gui.initWindow(800, 600, "Particle Simulation");
gui.setTargetFPS(0);

var particles = [];
for (var i = 0; i < 1000; i = i + 1) {
  particles.push(Particle(i));
}

var frame = 0;
while (frame < 500) {
  gui.beginDrawing();
  gui.clearBackground(0, 0, 0);

  for (var i = 0; i < 1000; i = i + 1) {
    particles[i].update();
    particles[i].draw();
  }

  gui.endDrawing();
  frame = frame + 1;
}

gui.closeWindow();
print(500);
