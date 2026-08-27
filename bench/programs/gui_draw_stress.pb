use "pb_gui" as gui;

gui.initWindow(800, 600, "Draw Stress Benchmark");
gui.setTargetFPS(0);

var frame = 0;

while (frame < 300) {
  gui.beginDrawing();
  gui.clearBackground(0, 0, 0);

  for (var i = 0; i < 2000; i = i + 1) {
    var x = (i * 37) % 800;
    var y = (i * 53) % 600;
    var c = i % 256;
    gui.drawRectangle(x, y, 10, 10, c, 100, 100);
  }

  for (var i = 0; i < 500; i = i + 1) {
    var x = (i * 41) % 800;
    var y = (i * 67) % 600;
    var c = i % 256;
    gui.drawCircle(x, y, 5, c, 100, 100);
  }

  for (var i = 0; i < 200; i = i + 1) {
    var x = (i * 59) % 780;
    var y = (i * 71) % 580;
    gui.drawText("Hi", x, y, 12, 255, 255, 255);
  }

  gui.endDrawing();
  frame = frame + 1;
}

gui.closeWindow();
print(300);
