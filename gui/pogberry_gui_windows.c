#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN // Exclude rarely used Windows APIs
#endif

#ifndef NOMINMAX
#define NOMINMAX // Prevent Windows.h from defining min/max macros
#endif

// Rename Windows API functions to avoid conflicts
#define CloseWindow WindowsCloseWindow
#define LoadImage WindowsLoadImage
#define DrawText WindowsDrawText
#define DrawTextEx WindowsDrawTextEx

#include <windows.h>

#undef CloseWindow
#undef LoadImage
#undef DrawText
#undef DrawTextEx

// Temporary rename to prevent conflicts between Raylib and Windows API
#define Rectangle RaylibRectangle
#define ShowCursor RaylibShowCursor

#include <raylib.h>

// Undo the temporary renames so that Raylib can be used normally
#undef Rectangle
#undef ShowCursor

// Window functions
__declspec(dllexport) void initWindow(int width, int height, const char *title)
{
    SetTraceLogLevel(LOG_ERROR);
    InitWindow(width, height, title);
}

__declspec(dllexport) void closeWindow(void)
{
    CloseWindow();
}

__declspec(dllexport) bool windowShouldClose(void)
{
    return WindowShouldClose();
}

__declspec(dllexport) bool isWindowMinimized(void)
{
    return IsWindowMinimized();
}

__declspec(dllexport) void toggleBorderlessWindowed(void)
{
    ToggleBorderlessWindowed();
}

__declspec(dllexport) int getScreenWidth(void) { return GetScreenWidth(); }
__declspec(dllexport) int getScreenHeight(void) { return GetScreenHeight(); }
__declspec(dllexport) int getFPS(void) { return GetFPS(); }

// Drawing control
__declspec(dllexport) void clearBackground(Color color) { ClearBackground(color); }
__declspec(dllexport) void beginDrawing(void) { BeginDrawing(); }
__declspec(dllexport) void endDrawing(void) { EndDrawing(); }
__declspec(dllexport) void setTargetFPS(int fps) { SetTargetFPS(fps); }
__declspec(dllexport) void swapScreenBuffer(void) { EndDrawing(); }

// Shape drawing
__declspec(dllexport) void drawPixel(int posX, int posY, Color color) { DrawPixel(posX, posY, color); }
__declspec(dllexport) void drawLine(int startPosX, int startPosY, int endPosX, int endPosY, Color color) { DrawLine(startPosX, startPosY, endPosX, endPosY, color); }
__declspec(dllexport) void drawCircle(int centerX, int centerY, float radius, Color color) { DrawCircle(centerX, centerY, radius, color); }
__declspec(dllexport) void drawEllipse(int centerX, int centerY, float radiusH, float radiusV, Color color) { DrawEllipse(centerX, centerY, radiusH, radiusV, color); }
__declspec(dllexport) void drawRectangle(int posX, int posY, int width, int height, Color color) { DrawRectangle(posX, posY, width, height, color); }
__declspec(dllexport) void drawText(const char *text, int posX, int posY, int fontSize, Color color) { DrawText(text, posX, posY, fontSize, color); }

// Keyboard input
__declspec(dllexport) bool isKeyPressed(int key) { return IsKeyPressed(key); }
__declspec(dllexport) bool isKeyDown(int key) { return IsKeyDown(key); }
__declspec(dllexport) bool isKeyReleased(int key) { return IsKeyReleased(key); }
__declspec(dllexport) bool isKeyUp(int key) { return IsKeyUp(key); }
__declspec(dllexport) int getKeyPressed(void) { return GetKeyPressed(); }
__declspec(dllexport) int getCharPressed(void) { return GetCharPressed(); }
__declspec(dllexport) void setExitKey(int key) { SetExitKey(key); }

// Mouse input
__declspec(dllexport) bool isMouseButtonPressed(int button) { return IsMouseButtonPressed(button); }
__declspec(dllexport) bool isMouseButtonDown(int button) { return IsMouseButtonDown(button); }
__declspec(dllexport) bool isMouseButtonReleased(int button) { return IsMouseButtonReleased(button); }
__declspec(dllexport) bool isMouseButtonUp(int button) { return IsMouseButtonUp(button); }
__declspec(dllexport) int getMouseX(void) { return GetMouseX(); }
__declspec(dllexport) int getMouseY(void) { return GetMouseY(); }

// gcc -shared -o lib/pogberry_gui_windows.dll pogberry_gui_windows.c -DWIN32_LEAN_AND_MEAN -DNOMINMAX -lraylib -lopengl32 -lgdi32 -lwinmm
