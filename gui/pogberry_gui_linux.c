#include <stdbool.h>
#include <raylib.h>

// Window functions
void initWindow(int width, int height, const char *title)
{
    SetTraceLogLevel(LOG_ERROR);
    InitWindow(width, height, title);
}

void closeWindow(void)
{
    CloseWindow();
}

bool windowShouldClose(void)
{
    return WindowShouldClose();
}

bool isWindowMinimized(void)
{
    return IsWindowMinimized();
}

void toggleBorderlessWindowed(void)
{
    ToggleBorderlessWindowed();
}

int getScreenWidth(void)
{
    return GetScreenWidth();
}

int getScreenHeight(void)
{
    return GetScreenHeight();
}

int getFPS(void)
{
    return GetFPS();
}

// Drawing control
void clearBackground(Color color)
{
    ClearBackground(color);
}

void beginDrawing(void)
{
    BeginDrawing();
}

void endDrawing(void)
{
    EndDrawing();
}

void setTargetFPS(int fps)
{
    SetTargetFPS(fps);
}

void swapScreenBuffer(void)
{
    EndDrawing();
}

// Shape drawing
void drawPixel(int posX, int posY, Color color)
{
    DrawPixel(posX, posY, color);
}

void drawLine(int startPosX, int startPosY, int endPosX, int endPosY, Color color)
{
    DrawLine(startPosX, startPosY, endPosX, endPosY, color);
}

void drawCircle(int centerX, int centerY, float radius, Color color)
{
    DrawCircle(centerX, centerY, radius, color);
}

void drawEllipse(int centerX, int centerY, float radiusH, float radiusV, Color color)
{
    DrawEllipse(centerX, centerY, radiusH, radiusV, color);
}

void drawRectangle(int posX, int posY, int width, int height, Color color)
{
    DrawRectangle(posX, posY, width, height, color);
}

void drawText(const char *text, int posX, int posY, int fontSize, Color color)
{
    DrawText(text, posX, posY, fontSize, color);
}

// Keyboard input
bool isKeyPressed(int key)
{
    return IsKeyPressed(key);
}

bool isKeyDown(int key)
{
    return IsKeyDown(key);
}

bool isKeyReleased(int key)
{
    return IsKeyReleased(key);
}

bool isKeyUp(int key)
{
    return IsKeyUp(key);
}

int getKeyPressed(void)
{
    return GetKeyPressed();
}

int getCharPressed(void)
{
    return GetCharPressed();
}

void setExitKey(int key)
{
    SetExitKey(key);
}

// Mouse input
bool isMouseButtonPressed(int button)
{
    return IsMouseButtonPressed(button);
}

bool isMouseButtonDown(int button)
{
    return IsMouseButtonDown(button);
}

bool isMouseButtonReleased(int button)
{
    return IsMouseButtonReleased(button);
}

bool isMouseButtonUp(int button)
{
    return IsMouseButtonUp(button);
}

int getMouseX(void)
{
    return GetMouseX();
}

int getMouseY(void)
{
    return GetMouseY();
}
