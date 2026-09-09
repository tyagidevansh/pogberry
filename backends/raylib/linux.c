#include <stdbool.h>
#include <raylib.h>

void initWindow(int width, int height, const char *title) {
  SetTraceLogLevel(LOG_ERROR);
  InitWindow(width, height, title);
}

void closeWindow(void) { CloseWindow(); }

bool windowShouldClose(void) { return WindowShouldClose(); }

bool isWindowMinimized(void) { return IsWindowMinimized(); }

bool isWindowFocused(void) { return IsWindowFocused(); }

bool isWindowResized(void) { return IsWindowResized(); }

void toggleFullscreen(void) { ToggleFullscreen(); }

void toggleBorderlessWindowed(void) { ToggleBorderlessWindowed(); }

void setWindowTitle(const char *title) { SetWindowTitle(title); }

int getScreenWidth(void) { return GetScreenWidth(); }

int getScreenHeight(void) { return GetScreenHeight(); }

int getFPS(void) { return GetFPS(); }

float getFrameTime(void) { return GetFrameTime(); }

void clearBackground(int r, int g, int b) { ClearBackground((Color){r, g, b, 255}); }

void beginDrawing(void) { BeginDrawing(); }

void endDrawing(void) { EndDrawing(); }

void setTargetFPS(int fps) { SetTargetFPS(fps); }

void drawPixel(int posX, int posY, int r, int g, int b) { DrawPixel(posX, posY, (Color){r, g, b, 255}); }

void drawLine(int startPosX, int startPosY, int endPosX, int endPosY, int r, int g, int b) {
  DrawLine(startPosX, startPosY, endPosX, endPosY, (Color){r, g, b, 255});
}

void drawCircle(int centerX, int centerY, float radius, int r, int g, int b) {
  DrawCircle(centerX, centerY, radius, (Color){r, g, b, 255});
}

void drawCircleLines(int centerX, int centerY, float radius, int r, int g, int b) {
  DrawCircleLines(centerX, centerY, radius, (Color){r, g, b, 255});
}

void drawEllipse(int centerX, int centerY, float radiusH, float radiusV, int r, int g, int b) {
  DrawEllipse(centerX, centerY, radiusH, radiusV, (Color){r, g, b, 255});
}

void drawRectangle(int posX, int posY, int width, int height, int r, int g, int b) {
  DrawRectangle(posX, posY, width, height, (Color){r, g, b, 255});
}

void drawRectangleLines(int posX, int posY, int width, int height, int r, int g, int b) {
  DrawRectangleLines(posX, posY, width, height, (Color){r, g, b, 255});
}

void drawText(const char *text, int posX, int posY, int fontSize, int r, int g, int b) {
  DrawText(text, posX, posY, fontSize, (Color){r, g, b, 255});
}

int measureText(const char *text, int fontSize) { return MeasureText(text, fontSize); }

bool isKeyPressed(int key) { return IsKeyPressed(key); }

bool isKeyDown(int key) { return IsKeyDown(key); }

bool isKeyReleased(int key) { return IsKeyReleased(key); }

bool isKeyUp(int key) { return IsKeyUp(key); }

int getKeyPressed(void) { return GetKeyPressed(); }

int getCharPressed(void) { return GetCharPressed(); }

void setExitKey(int key) { SetExitKey(key); }

bool isMouseButtonPressed(int button) { return IsMouseButtonPressed(button); }

bool isMouseButtonDown(int button) { return IsMouseButtonDown(button); }

bool isMouseButtonReleased(int button) { return IsMouseButtonReleased(button); }

bool isMouseButtonUp(int button) { return IsMouseButtonUp(button); }

int getMouseX(void) { return GetMouseX(); }

int getMouseY(void) { return GetMouseY(); }

float getMouseWheelMove(void) { return GetMouseWheelMove(); }

void drawTriangle(float x1, float y1, float x2, float y2, float x3, float y3, int r, int g, int b) {
  DrawTriangle((Vector2){x1, y1}, (Vector2){x2, y2}, (Vector2){x3, y3}, (Color){r, g, b, 255});
}

void drawTriangleLines(float x1, float y1, float x2, float y2, float x3, float y3, int r, int g, int b) {
  DrawTriangleLines((Vector2){x1, y1}, (Vector2){x2, y2}, (Vector2){x3, y3}, (Color){r, g, b, 255});
}

void drawRectangleRounded(float x, float y, float width, float height, float roundness, int segments, int r, int g,
                          int b) {
  DrawRectangleRounded((Rectangle){x, y, width, height}, roundness, segments, (Color){r, g, b, 255});
}

void drawRectangleRoundedLines(float x, float y, float width, float height, float roundness, int segments, int r, int g,
                               int b) {
  DrawRectangleRoundedLines((Rectangle){x, y, width, height}, roundness, segments, (Color){r, g, b, 255});
}

void drawPoly(float centerX, float centerY, int sides, float radius, float rotation, int r, int g, int b) {
  DrawPoly((Vector2){centerX, centerY}, sides, radius, rotation, (Color){r, g, b, 255});
}

void drawPolyLines(float centerX, float centerY, int sides, float radius, float rotation, int r, int g, int b) {
  DrawPolyLines((Vector2){centerX, centerY}, sides, radius, rotation, (Color){r, g, b, 255});
}

void drawRing(float centerX, float centerY, float innerRadius, float outerRadius, float startAngle, float endAngle,
              int segments, int r, int g, int b) {
  DrawRing((Vector2){centerX, centerY}, innerRadius, outerRadius, startAngle, endAngle, segments,
           (Color){r, g, b, 255});
}

void drawRingLines(float centerX, float centerY, float innerRadius, float outerRadius, float startAngle, float endAngle,
                   int segments, int r, int g, int b) {
  DrawRingLines((Vector2){centerX, centerY}, innerRadius, outerRadius, startAngle, endAngle, segments,
                (Color){r, g, b, 255});
}

void drawCircleSector(float centerX, float centerY, float radius, float startAngle, float endAngle, int segments, int r,
                      int g, int b) {
  DrawCircleSector((Vector2){centerX, centerY}, radius, startAngle, endAngle, segments, (Color){r, g, b, 255});
}

void drawCircleSectorLines(float centerX, float centerY, float radius, float startAngle, float endAngle, int segments,
                           int r, int g, int b) {
  DrawCircleSectorLines((Vector2){centerX, centerY}, radius, startAngle, endAngle, segments, (Color){r, g, b, 255});
}

void drawCircleGradient(int centerX, int centerY, float radius, int r1, int g1, int b1, int r2, int g2, int b2) {
  DrawCircleGradient(centerX, centerY, radius, (Color){r1, g1, b1, 255}, (Color){r2, g2, b2, 255});
}

void drawRectangleGradientV(int posX, int posY, int width, int height, int r1, int g1, int b1, int r2, int g2, int b2) {
  DrawRectangleGradientV(posX, posY, width, height, (Color){r1, g1, b1, 255}, (Color){r2, g2, b2, 255});
}

void drawRectangleGradientH(int posX, int posY, int width, int height, int r1, int g1, int b1, int r2, int g2, int b2) {
  DrawRectangleGradientH(posX, posY, width, height, (Color){r1, g1, b1, 255}, (Color){r2, g2, b2, 255});
}

void drawFPS(int posX, int posY) { DrawFPS(posX, posY); }

double getTime(void) { return GetTime(); }

void setWindowSize(int width, int height) { SetWindowSize(width, height); }

void setWindowPosition(int x, int y) { SetWindowPosition(x, y); }

bool isWindowFullscreen(void) { return IsWindowFullscreen(); }

bool checkCollisionRecs(float x1, float y1, float w1, float h1, float x2, float y2, float w2, float h2) {
  return CheckCollisionRecs((Rectangle){x1, y1, w1, h1}, (Rectangle){x2, y2, w2, h2});
}

bool checkCollisionCircles(float x1, float y1, float r1, float x2, float y2, float r2) {
  return CheckCollisionCircles((Vector2){x1, y1}, r1, (Vector2){x2, y2}, r2);
}

bool checkCollisionCircleRec(float cx, float cy, float radius, float rx, float ry, float rw, float rh) {
  return CheckCollisionCircleRec((Vector2){cx, cy}, radius, (Rectangle){rx, ry, rw, rh});
}

bool checkCollisionPointRec(float px, float py, float rx, float ry, float rw, float rh) {
  return CheckCollisionPointRec((Vector2){px, py}, (Rectangle){rx, ry, rw, rh});
}

bool checkCollisionPointCircle(float px, float py, float cx, float cy, float radius) {
  return CheckCollisionPointCircle((Vector2){px, py}, (Vector2){cx, cy}, radius);
}

bool checkCollisionPointTriangle(float px, float py, float x1, float y1, float x2, float y2, float x3, float y3) {
  return CheckCollisionPointTriangle((Vector2){px, py}, (Vector2){x1, y1}, (Vector2){x2, y2}, (Vector2){x3, y3});
}

int getCurrentMonitor(void) { return GetCurrentMonitor(); }

int getMonitorCount(void) { return GetMonitorCount(); }

int getMonitorWidth(int monitor) { return GetMonitorWidth(monitor); }

int getMonitorHeight(int monitor) { return GetMonitorHeight(monitor); }

bool isWindowMaximized(void) { return IsWindowMaximized(); }

void maximizeWindow(void) { MaximizeWindow(); }

void restoreWindow(void) { RestoreWindow(); }
