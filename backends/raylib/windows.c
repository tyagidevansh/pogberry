#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#ifndef NOMINMAX
#define NOMINMAX
#endif

#define CloseWindow WindowsCloseWindow
#define LoadImage WindowsLoadImage
#define DrawText WindowsDrawText
#define DrawTextEx WindowsDrawTextEx

#include <windows.h>

#undef CloseWindow
#undef LoadImage
#undef DrawText
#undef DrawTextEx

#define Rectangle RaylibRectangle
#define ShowCursor RaylibShowCursor

#include <raylib.h>

#undef Rectangle
#undef ShowCursor

__declspec(dllexport) void initWindow(int width, int height, const char *title) {
  SetTraceLogLevel(LOG_ERROR);
  InitWindow(width, height, title);
}

__declspec(dllexport) void closeWindow(void) { CloseWindow(); }

__declspec(dllexport) bool windowShouldClose(void) { return WindowShouldClose(); }

__declspec(dllexport) bool isWindowMinimized(void) { return IsWindowMinimized(); }

__declspec(dllexport) bool isWindowFocused(void) { return IsWindowFocused(); }
__declspec(dllexport) bool isWindowResized(void) { return IsWindowResized(); }
__declspec(dllexport) void toggleFullscreen(void) { ToggleFullscreen(); }

__declspec(dllexport) void toggleBorderlessWindowed(void) { ToggleBorderlessWindowed(); }

__declspec(dllexport) void setWindowTitle(const char *title) { SetWindowTitle(title); }

__declspec(dllexport) int getScreenWidth(void) { return GetScreenWidth(); }
__declspec(dllexport) int getScreenHeight(void) { return GetScreenHeight(); }
__declspec(dllexport) int getFPS(void) { return GetFPS(); }
__declspec(dllexport) float getFrameTime(void) { return GetFrameTime(); }

__declspec(dllexport) void clearBackground(int r, int g, int b) { ClearBackground((Color){r, g, b, 255}); }
__declspec(dllexport) void beginDrawing(void) { BeginDrawing(); }
__declspec(dllexport) void endDrawing(void) { EndDrawing(); }
__declspec(dllexport) void setTargetFPS(int fps) { SetTargetFPS(fps); }
__declspec(dllexport) void drawPixel(int posX, int posY, int r, int g, int b) {
  DrawPixel(posX, posY, (Color){r, g, b, 255});
}
__declspec(dllexport) void drawLine(int startPosX, int startPosY, int endPosX, int endPosY, int r, int g, int b) {
  DrawLine(startPosX, startPosY, endPosX, endPosY, (Color){r, g, b, 255});
}
__declspec(dllexport) void drawCircle(int centerX, int centerY, float radius, int r, int g, int b) {
  DrawCircle(centerX, centerY, radius, (Color){r, g, b, 255});
}
__declspec(dllexport) void drawCircleLines(int centerX, int centerY, float radius, int r, int g, int b) {
  DrawCircleLines(centerX, centerY, radius, (Color){r, g, b, 255});
}
__declspec(dllexport) void drawEllipse(int centerX, int centerY, float radiusH, float radiusV, int r, int g, int b) {
  DrawEllipse(centerX, centerY, radiusH, radiusV, (Color){r, g, b, 255});
}
__declspec(dllexport) void drawRectangle(int posX, int posY, int width, int height, int r, int g, int b) {
  DrawRectangle(posX, posY, width, height, (Color){r, g, b, 255});
}
__declspec(dllexport) void drawRectangleLines(int posX, int posY, int width, int height, int r, int g, int b) {
  DrawRectangleLines(posX, posY, width, height, (Color){r, g, b, 255});
}
__declspec(dllexport) void drawText(const char *text, int posX, int posY, int fontSize, int r, int g, int b) {
  DrawText(text, posX, posY, fontSize, (Color){r, g, b, 255});
}
__declspec(dllexport) int measureText(const char *text, int fontSize) { return MeasureText(text, fontSize); }

__declspec(dllexport) bool isKeyPressed(int key) { return IsKeyPressed(key); }
__declspec(dllexport) bool isKeyDown(int key) { return IsKeyDown(key); }
__declspec(dllexport) bool isKeyReleased(int key) { return IsKeyReleased(key); }
__declspec(dllexport) bool isKeyUp(int key) { return IsKeyUp(key); }
__declspec(dllexport) int getKeyPressed(void) { return GetKeyPressed(); }
__declspec(dllexport) int getCharPressed(void) { return GetCharPressed(); }
__declspec(dllexport) void setExitKey(int key) { SetExitKey(key); }

__declspec(dllexport) bool isMouseButtonPressed(int button) { return IsMouseButtonPressed(button); }
__declspec(dllexport) bool isMouseButtonDown(int button) { return IsMouseButtonDown(button); }
__declspec(dllexport) bool isMouseButtonReleased(int button) { return IsMouseButtonReleased(button); }
__declspec(dllexport) bool isMouseButtonUp(int button) { return IsMouseButtonUp(button); }
__declspec(dllexport) int getMouseX(void) { return GetMouseX(); }
__declspec(dllexport) int getMouseY(void) { return GetMouseY(); }
__declspec(dllexport) float getMouseWheelMove(void) { return GetMouseWheelMove(); }

__declspec(dllexport) void drawTriangle(float x1, float y1, float x2, float y2, float x3, float y3, int r, int g,
                                        int b) {
  DrawTriangle((Vector2){x1, y1}, (Vector2){x2, y2}, (Vector2){x3, y3}, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawTriangleLines(float x1, float y1, float x2, float y2, float x3, float y3, int r, int g,
                                             int b) {
  DrawTriangleLines((Vector2){x1, y1}, (Vector2){x2, y2}, (Vector2){x3, y3}, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawRectangleRounded(float x, float y, float width, float height, float roundness,
                                                int segments, int r, int g, int b) {
  DrawRectangleRounded((RaylibRectangle){x, y, width, height}, roundness, segments, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawRectangleRoundedLines(float x, float y, float width, float height, float roundness,
                                                     int segments, int r, int g, int b) {
  DrawRectangleRoundedLines((RaylibRectangle){x, y, width, height}, roundness, segments, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawPoly(float centerX, float centerY, int sides, float radius, float rotation, int r, int g,
                                    int b) {
  DrawPoly((Vector2){centerX, centerY}, sides, radius, rotation, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawPolyLines(float centerX, float centerY, int sides, float radius, float rotation, int r,
                                         int g, int b) {
  DrawPolyLines((Vector2){centerX, centerY}, sides, radius, rotation, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawRing(float centerX, float centerY, float innerRadius, float outerRadius,
                                    float startAngle, float endAngle, int segments, int r, int g, int b) {
  DrawRing((Vector2){centerX, centerY}, innerRadius, outerRadius, startAngle, endAngle, segments,
           (Color){r, g, b, 255});
}

__declspec(dllexport) void drawRingLines(float centerX, float centerY, float innerRadius, float outerRadius,
                                         float startAngle, float endAngle, int segments, int r, int g, int b) {
  DrawRingLines((Vector2){centerX, centerY}, innerRadius, outerRadius, startAngle, endAngle, segments,
                (Color){r, g, b, 255});
}

__declspec(dllexport) void drawCircleSector(float centerX, float centerY, float radius, float startAngle,
                                            float endAngle, int segments, int r, int g, int b) {
  DrawCircleSector((Vector2){centerX, centerY}, radius, startAngle, endAngle, segments, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawCircleSectorLines(float centerX, float centerY, float radius, float startAngle,
                                                 float endAngle, int segments, int r, int g, int b) {
  DrawCircleSectorLines((Vector2){centerX, centerY}, radius, startAngle, endAngle, segments, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawCircleGradient(int centerX, int centerY, float radius, int r1, int g1, int b1, int r2,
                                              int g2, int b2) {
  DrawCircleGradient(centerX, centerY, radius, (Color){r1, g1, b1, 255}, (Color){r2, g2, b2, 255});
}

__declspec(dllexport) void drawRectangleGradientV(int posX, int posY, int width, int height, int r1, int g1, int b1,
                                                  int r2, int g2, int b2) {
  DrawRectangleGradientV(posX, posY, width, height, (Color){r1, g1, b1, 255}, (Color){r2, g2, b2, 255});
}

__declspec(dllexport) void drawRectangleGradientH(int posX, int posY, int width, int height, int r1, int g1, int b1,
                                                  int r2, int g2, int b2) {
  DrawRectangleGradientH(posX, posY, width, height, (Color){r1, g1, b1, 255}, (Color){r2, g2, b2, 255});
}

__declspec(dllexport) void drawFPS(int posX, int posY) { DrawFPS(posX, posY); }

__declspec(dllexport) double getTime(void) { return GetTime(); }

__declspec(dllexport) void setWindowSize(int width, int height) { SetWindowSize(width, height); }

__declspec(dllexport) void setWindowPosition(int x, int y) { SetWindowPosition(x, y); }

__declspec(dllexport) bool isWindowFullscreen(void) { return IsWindowFullscreen(); }

__declspec(dllexport) bool checkCollisionRecs(float x1, float y1, float w1, float h1, float x2, float y2, float w2,
                                              float h2) {
  return CheckCollisionRecs((RaylibRectangle){x1, y1, w1, h1}, (RaylibRectangle){x2, y2, w2, h2});
}

__declspec(dllexport) bool checkCollisionCircles(float x1, float y1, float r1, float x2, float y2, float r2) {
  return CheckCollisionCircles((Vector2){x1, y1}, r1, (Vector2){x2, y2}, r2);
}

__declspec(dllexport) bool checkCollisionCircleRec(float cx, float cy, float radius, float rx, float ry, float rw,
                                                   float rh) {
  return CheckCollisionCircleRec((Vector2){cx, cy}, radius, (RaylibRectangle){rx, ry, rw, rh});
}

__declspec(dllexport) bool checkCollisionPointRec(float px, float py, float rx, float ry, float rw, float rh) {
  return CheckCollisionPointRec((Vector2){px, py}, (RaylibRectangle){rx, ry, rw, rh});
}

__declspec(dllexport) bool checkCollisionPointCircle(float px, float py, float cx, float cy, float radius) {
  return CheckCollisionPointCircle((Vector2){px, py}, (Vector2){cx, cy}, radius);
}

__declspec(dllexport) bool checkCollisionPointTriangle(float px, float py, float x1, float y1, float x2, float y2,
                                                       float x3, float y3) {
  return CheckCollisionPointTriangle((Vector2){px, py}, (Vector2){x1, y1}, (Vector2){x2, y2}, (Vector2){x3, y3});
}

__declspec(dllexport) int getCurrentMonitor(void) { return GetCurrentMonitor(); }

__declspec(dllexport) int getMonitorCount(void) { return GetMonitorCount(); }

__declspec(dllexport) int getMonitorWidth(int monitor) { return GetMonitorWidth(monitor); }

__declspec(dllexport) int getMonitorHeight(int monitor) { return GetMonitorHeight(monitor); }

__declspec(dllexport) bool isWindowMaximized(void) { return IsWindowMaximized(); }

__declspec(dllexport) void maximizeWindow(void) { MaximizeWindow(); }

__declspec(dllexport) void restoreWindow(void) { RestoreWindow(); }
