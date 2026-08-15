use "pb_gui" as gui;

gui.initWindow(800, 600, "headless test");
gui.setTargetFPS(60);
gui.setExitKey(256);
gui.toggleBorderlessWindowed();

gui.beginDrawing();
gui.clearBackground(10, 20, 30);
gui.drawPixel(1, 2, 255, 255, 255);
gui.drawLine(1, 2, 3, 4, 255, 0, 0);
gui.drawCircle(10, 20, 5, 0, 255, 0);
gui.drawEllipse(10, 20, 5, 8, 0, 0, 255);
gui.drawRectangle(10, 20, 30, 40, 100, 110, 120);
gui.drawText("Pogberry", 10, 20, 24, 255, 255, 255);
gui.endDrawing();
gui.swapScreenBuffer();

print(gui.windowShouldClose());
print(gui.isWindowMinimized());
print(gui.getScreenWidth());
print(gui.getScreenHeight());
print(gui.getFPS());
print(gui.isKeyPressed("KEY_UP"));
print(gui.isKeyReleased("KEY_LEFT"));
print(gui.isKeyUp("KEY_SPACE"));
print(gui.getKeyPressed());
print(gui.getCharPressed());
print(gui.isMouseButtonPressed("LEFT"));
print(gui.isMouseButtonDown("RIGHT"));
print(gui.isMouseButtonReleased("MIDDLE"));
print(gui.isMouseButtonUp("LEFT"));
print(gui.getMouseX());
print(gui.getMouseY());
gui.closeWindow();
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|true
//|false
//|800
//|600
//|60
//|true
//|true
//|true
//|265
//|65
//|true
//|true
//|true
//|true
//|123
//|456
// END EXPECTED OUTPUT
