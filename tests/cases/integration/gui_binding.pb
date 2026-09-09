use "pb_gui" as gui;

gui.initWindow(800, 600, "headless test");
gui.setTargetFPS(60);
gui.setExitKey(256);
gui.setWindowTitle("headless test updated");
gui.toggleFullscreen();
gui.toggleBorderlessWindowed();

gui.beginDrawing();
gui.clearBackground(10, 20, 30);
gui.drawPixel(1, 2, 255, 255, 255);
gui.drawLine(1, 2, 3, 4, 255, 0, 0);
gui.drawCircle(10, 20, 5, 0, 255, 0);
gui.drawCircleLines(10, 20, 5, 0, 255, 0);
gui.drawEllipse(10, 20, 5, 8, 0, 0, 255);
gui.drawRectangle(10, 20, 30, 40, 100, 110, 120);
gui.drawRectangleLines(10, 20, 30, 40, 100, 110, 120);
gui.drawTriangle(0, 0, 10, 0, 5, 10, 255, 0, 0);
gui.drawTriangleLines(0, 0, 10, 0, 5, 10, 255, 0, 0);
gui.drawRectangleRounded(10, 20, 30, 40, 0.5, 4, 100, 110, 120);
gui.drawRectangleRoundedLines(10, 20, 30, 40, 0.5, 4, 100, 110, 120);
gui.drawPoly(50, 50, 5, 15, 0, 255, 255, 0);
gui.drawPolyLines(50, 50, 5, 15, 0, 255, 255, 0);
gui.drawRing(50, 50, 10, 20, 0, 180, 8, 0, 255, 255);
gui.drawRingLines(50, 50, 10, 20, 0, 180, 8, 0, 255, 255);
gui.drawCircleSector(50, 50, 20, 0, 90, 8, 255, 0, 255);
gui.drawCircleSectorLines(50, 50, 20, 0, 90, 8, 255, 0, 255);
gui.drawCircleGradient(50, 50, 20, 255, 0, 0, 0, 0, 255);
gui.drawRectangleGradientV(0, 0, 100, 100, 255, 0, 0, 0, 255, 0);
gui.drawRectangleGradientH(0, 0, 100, 100, 255, 0, 0, 0, 0, 255);
gui.drawFPS(10, 10);
gui.drawText("Pogberry", 10, 20, 24, 255, 255, 255);
gui.endDrawing();

gui.setWindowSize(1024, 768);
gui.setWindowPosition(100, 100);

print(gui.windowShouldClose());
print(gui.isWindowMinimized());
print(gui.isWindowFocused());
print(gui.isWindowResized());
print(gui.getScreenWidth());
print(gui.getScreenHeight());
print(gui.getFPS());
print(gui.getFrameTime());
print(gui.getTime());
print(gui.isWindowFullscreen());
print(gui.measureText("PB", 10));
print(gui.isKeyPressed("KEY_UP"));
print(gui.isKeyPressed("KEY_ZERO"));
print(gui.isKeyDown("KEY_W"));
print(gui.isKeyReleased("KEY_LEFT"));
print(gui.isKeyUp("KEY_SPACE"));
print(gui.getKeyPressed());
print(gui.getCharPressed());
print(gui.isMouseButtonPressed("LEFT"));
print(gui.isMouseButtonDown("RIGHT"));
print(gui.isMouseButtonDown("SIDE"));
print(gui.isMouseButtonReleased("MIDDLE"));
print(gui.isMouseButtonUp("LEFT"));
print(gui.getMouseX());
print(gui.getMouseY());
print(gui.getMouseWheelMove());
print(gui.checkCollisionRecs(0, 0, 10, 10, 5, 5, 10, 10));
print(gui.checkCollisionCircles(0, 0, 10, 5, 5, 10));
print(gui.checkCollisionCircleRec(0, 0, 10, 5, 5, 10, 10));
print(gui.checkCollisionPointRec(5, 5, 0, 0, 10, 10));
print(gui.checkCollisionPointCircle(5, 5, 0, 0, 10));
print(gui.checkCollisionPointTriangle(5, 5, 0, 0, 10, 0, 5, 10));
print(gui.getCurrentMonitor());
print(gui.getMonitorCount());
print(gui.getMonitorWidth(0));
print(gui.getMonitorHeight(0));
print(gui.isWindowMaximized());
gui.maximizeWindow();
gui.restoreWindow();
gui.closeWindow();
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|true
//|false
//|true
//|true
//|800
//|600
//|60
//|0.016
//|1.25
//|true
//|20
//|true
//|true
//|true
//|true
//|true
//|265
//|65
//|true
//|true
//|true
//|true
//|true
//|123
//|456
//|2.5
//|true
//|true
//|true
//|true
//|true
//|true
//|0
//|1
//|1920
//|1080
//|false
// END EXPECTED OUTPUT
