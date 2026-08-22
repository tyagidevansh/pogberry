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
