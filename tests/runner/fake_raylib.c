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

RAYLIB_EXPORT void drawTriangle(float x1, float y1, float x2, float y2, float x3, float y3, int r, int g, int b) {
  (void)x1;
  (void)y1;
  (void)x2;
  (void)y2;
  (void)x3;
  (void)y3;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawTriangleLines(float x1, float y1, float x2, float y2, float x3, float y3, int r, int g, int b) {
  (void)x1;
  (void)y1;
  (void)x2;
  (void)y2;
  (void)x3;
  (void)y3;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawRectangleRounded(float x, float y, float width, float height, float roundness, int segments,
                                        int r, int g, int b) {
  (void)x;
  (void)y;
  (void)width;
  (void)height;
  (void)roundness;
  (void)segments;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawRectangleRoundedLines(float x, float y, float width, float height, float roundness, int segments,
                                             int r, int g, int b) {
  (void)x;
  (void)y;
  (void)width;
  (void)height;
  (void)roundness;
  (void)segments;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawPoly(float centerX, float centerY, int sides, float radius, float rotation, int r, int g,
                            int b) {
  (void)centerX;
  (void)centerY;
  (void)sides;
  (void)radius;
  (void)rotation;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawPolyLines(float centerX, float centerY, int sides, float radius, float rotation, int r, int g,
                                 int b) {
  (void)centerX;
  (void)centerY;
  (void)sides;
  (void)radius;
  (void)rotation;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawRing(float centerX, float centerY, float innerRadius, float outerRadius, float startAngle,
                            float endAngle, int segments, int r, int g, int b) {
  (void)centerX;
  (void)centerY;
  (void)innerRadius;
  (void)outerRadius;
  (void)startAngle;
  (void)endAngle;
  (void)segments;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawRingLines(float centerX, float centerY, float innerRadius, float outerRadius, float startAngle,
                                 float endAngle, int segments, int r, int g, int b) {
  (void)centerX;
  (void)centerY;
  (void)innerRadius;
  (void)outerRadius;
  (void)startAngle;
  (void)endAngle;
  (void)segments;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawCircleSector(float centerX, float centerY, float radius, float startAngle, float endAngle,
                                    int segments, int r, int g, int b) {
  (void)centerX;
  (void)centerY;
  (void)radius;
  (void)startAngle;
  (void)endAngle;
  (void)segments;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawCircleSectorLines(float centerX, float centerY, float radius, float startAngle, float endAngle,
                                         int segments, int r, int g, int b) {
  (void)centerX;
  (void)centerY;
  (void)radius;
  (void)startAngle;
  (void)endAngle;
  (void)segments;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawCircleGradient(int centerX, int centerY, float radius, int r1, int g1, int b1, int r2, int g2,
                                      int b2) {
  (void)centerX;
  (void)centerY;
  (void)radius;
  (void)r1;
  (void)g1;
  (void)b1;
  (void)r2;
  (void)g2;
  (void)b2;
}

RAYLIB_EXPORT void drawRectangleGradientV(int posX, int posY, int width, int height, int r1, int g1, int b1, int r2,
                                          int g2, int b2) {
  (void)posX;
  (void)posY;
  (void)width;
  (void)height;
  (void)r1;
  (void)g1;
  (void)b1;
  (void)r2;
  (void)g2;
  (void)b2;
}

RAYLIB_EXPORT void drawRectangleGradientH(int posX, int posY, int width, int height, int r1, int g1, int b1, int r2,
                                          int g2, int b2) {
  (void)posX;
  (void)posY;
  (void)width;
  (void)height;
  (void)r1;
  (void)g1;
  (void)b1;
  (void)r2;
  (void)g2;
  (void)b2;
}

RAYLIB_EXPORT void drawFPS(int posX, int posY) {
  (void)posX;
  (void)posY;
}

RAYLIB_EXPORT double getTime(void) { return 1.25; }

RAYLIB_EXPORT void setWindowSize(int width, int height) {
  (void)width;
  (void)height;
}

RAYLIB_EXPORT void setWindowPosition(int x, int y) {
  (void)x;
  (void)y;
}

RAYLIB_EXPORT bool isWindowFullscreen(void) { return true; }

RAYLIB_EXPORT bool checkCollisionRecs(float x1, float y1, float w1, float h1, float x2, float y2, float w2, float h2) {
  (void)x1;
  (void)y1;
  (void)w1;
  (void)h1;
  (void)x2;
  (void)y2;
  (void)w2;
  (void)h2;
  return true;
}

RAYLIB_EXPORT bool checkCollisionCircles(float x1, float y1, float r1, float x2, float y2, float r2) {
  (void)x1;
  (void)y1;
  (void)r1;
  (void)x2;
  (void)y2;
  (void)r2;
  return true;
}

RAYLIB_EXPORT bool checkCollisionCircleRec(float cx, float cy, float radius, float rx, float ry, float rw, float rh) {
  (void)cx;
  (void)cy;
  (void)radius;
  (void)rx;
  (void)ry;
  (void)rw;
  (void)rh;
  return true;
}

RAYLIB_EXPORT bool checkCollisionPointRec(float px, float py, float rx, float ry, float rw, float rh) {
  (void)px;
  (void)py;
  (void)rx;
  (void)ry;
  (void)rw;
  (void)rh;
  return true;
}

RAYLIB_EXPORT bool checkCollisionPointCircle(float px, float py, float cx, float cy, float radius) {
  (void)px;
  (void)py;
  (void)cx;
  (void)cy;
  (void)radius;
  return true;
}

RAYLIB_EXPORT bool checkCollisionPointTriangle(float px, float py, float x1, float y1, float x2, float y2, float x3,
                                               float y3) {
  (void)px;
  (void)py;
  (void)x1;
  (void)y1;
  (void)x2;
  (void)y2;
  (void)x3;
  (void)y3;
  return true;
}

RAYLIB_EXPORT int getCurrentMonitor(void) { return 0; }

RAYLIB_EXPORT int getMonitorCount(void) { return 1; }

RAYLIB_EXPORT int getMonitorWidth(int monitor) {
  (void)monitor;
  return 1920;
}

RAYLIB_EXPORT int getMonitorHeight(int monitor) {
  (void)monitor;
  return 1080;
}

RAYLIB_EXPORT bool isWindowMaximized(void) { return false; }

RAYLIB_EXPORT void maximizeWindow(void) {}

RAYLIB_EXPORT void restoreWindow(void) {}
