use "pb_gui" as gui;

gui.initWindow(800, 600, "Click the square");

var squareX = 400;
var squareY = 250;

gui.setTargetFPS(60);

while (!gui.windowShouldClose()) {
  gui.beginDrawing();
  gui.clearBackground(20, 20, 20);

  gui.drawRectangle(squareX, squareY, 30, 30, 200, 20, 20);

  gui.endDrawing();
}
