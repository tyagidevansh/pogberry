use "pb_gui";

initWindow(800, 600, "headless test");
setTargetFPS(60);
setExitKey(256);
toggleBorderlessWindowed();

beginDrawing();
clearBackground(10, 20, 30);
drawPixel(1, 2, 255, 255, 255);
drawLine(1, 2, 3, 4, 255, 0, 0);
drawCircle(10, 20, 5, 0, 255, 0);
drawEllipse(10, 20, 5, 8, 0, 0, 255);
drawRectangle(10, 20, 30, 40, 100, 110, 120);
drawText("Pogberry", 10, 20, 24, 255, 255, 255);
endDrawing();
swapScreenBuffer();

print(windowShouldClose());
print(isWindowMinimized());
print(getScreenWidth());
print(getScreenHeight());
print(getFPS());
print(isKeyPressed("KEY_UP"));
print(isKeyReleased("KEY_LEFT"));
print(isKeyUp("KEY_SPACE"));
print(getKeyPressed());
print(getCharPressed());
print(isMouseButtonPressed("LEFT"));
print(isMouseButtonDown("RIGHT"));
print(isMouseButtonReleased("MIDDLE"));
print(isMouseButtonUp("LEFT"));
print(getMouseX());
print(getMouseY());
closeWindow();
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
