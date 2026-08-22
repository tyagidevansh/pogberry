#include <stdbool.h>
#include <string.h>

#ifdef _WIN32
#define RAYLIB_EXPORT __declspec(dllexport)
#else
#define RAYLIB_EXPORT __attribute__((visibility("default")))
#endif

RAYLIB_EXPORT void initWindow(int width, int height, const char *title) {
  (void)width;
  (void)height;
  (void)title;
}

RAYLIB_EXPORT void closeWindow(void) {}
RAYLIB_EXPORT bool windowShouldClose(void) { return true; }
RAYLIB_EXPORT bool isWindowMinimized(void) { return false; }
RAYLIB_EXPORT bool isWindowFocused(void) { return true; }
RAYLIB_EXPORT bool isWindowResized(void) { return true; }
RAYLIB_EXPORT void toggleFullscreen(void) {}
RAYLIB_EXPORT void toggleBorderlessWindowed(void) {}
RAYLIB_EXPORT void setWindowTitle(const char *title) { (void)title; }
RAYLIB_EXPORT int getScreenWidth(void) { return 800; }
RAYLIB_EXPORT int getScreenHeight(void) { return 600; }
RAYLIB_EXPORT int getFPS(void) { return 60; }
RAYLIB_EXPORT float getFrameTime(void) { return 0.016f; }
RAYLIB_EXPORT void clearBackground(int r, int g, int b) {
  (void)r;
  (void)g;
  (void)b;
}
RAYLIB_EXPORT void beginDrawing(void) {}
RAYLIB_EXPORT void endDrawing(void) {}
RAYLIB_EXPORT void setTargetFPS(int fps) { (void)fps; }
RAYLIB_EXPORT void drawPixel(int x, int y, int r, int g, int b) {
  (void)x;
  (void)y;
  (void)r;
  (void)g;
  (void)b;
}
RAYLIB_EXPORT void drawLine(int x1, int y1, int x2, int y2, int r, int g, int b) {
  (void)x1;
  (void)y1;
  (void)x2;
  (void)y2;
  (void)r;
  (void)g;
  (void)b;
}
RAYLIB_EXPORT void drawCircle(int x, int y, float radius, int r, int g, int b) {
  (void)x;
  (void)y;
  (void)radius;
  (void)r;
  (void)g;
  (void)b;
}
RAYLIB_EXPORT void drawCircleLines(int x, int y, float radius, int r, int g, int b) {
  (void)x;
  (void)y;
  (void)radius;
  (void)r;
  (void)g;
  (void)b;
}
RAYLIB_EXPORT void drawEllipse(int x, int y, float radiusH, float radiusV, int r, int g, int b) {
  (void)x;
  (void)y;
  (void)radiusH;
  (void)radiusV;
  (void)r;
  (void)g;
  (void)b;
}
RAYLIB_EXPORT void drawRectangle(int x, int y, int width, int height, int r, int g, int b) {
  (void)x;
  (void)y;
  (void)width;
  (void)height;
  (void)r;
  (void)g;
  (void)b;
}
RAYLIB_EXPORT void drawRectangleLines(int x, int y, int width, int height, int r, int g, int b) {
  drawRectangle(x, y, width, height, r, g, b);
}
RAYLIB_EXPORT void drawText(const char *text, int x, int y, int fontSize, int r, int g, int b) {
  (void)text;
  (void)x;
  (void)y;
  (void)fontSize;
  (void)r;
  (void)g;
  (void)b;
}
RAYLIB_EXPORT int measureText(const char *text, int fontSize) { return (int)strlen(text) * fontSize; }
RAYLIB_EXPORT bool isKeyPressed(int key) { return key == 265 || key == 48; }
RAYLIB_EXPORT bool isKeyDown(int key) { return key == 87; }
RAYLIB_EXPORT bool isKeyReleased(int key) { return key == 263; }
RAYLIB_EXPORT bool isKeyUp(int key) { return key == 32; }
RAYLIB_EXPORT int getKeyPressed(void) { return 265; }
RAYLIB_EXPORT int getCharPressed(void) { return 65; }
RAYLIB_EXPORT void setExitKey(int key) { (void)key; }
RAYLIB_EXPORT bool isMouseButtonPressed(int button) { return button == 0; }
RAYLIB_EXPORT bool isMouseButtonDown(int button) { return button == 1 || button == 3; }
RAYLIB_EXPORT bool isMouseButtonReleased(int button) { return button == 2; }
RAYLIB_EXPORT bool isMouseButtonUp(int button) { return button == 0; }
RAYLIB_EXPORT int getMouseX(void) { return 123; }
RAYLIB_EXPORT int getMouseY(void) { return 456; }
RAYLIB_EXPORT float getMouseWheelMove(void) { return 2.5f; }
