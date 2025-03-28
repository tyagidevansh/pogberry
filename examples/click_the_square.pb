use "pogberry_gui";

initWindow(800, 600, "Click the square");

var squareX = 400;
var squareY = 250;

setTargetFPS(60);

while (!windowShouldClose()) {
  beginDrawing();
  clearBackground(20, 20, 20);

  drawRectangle(squareX, squareY, 30, 30, 200, 20, 20);

  endDrawing();
}