#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN  // Exclude rarely used Windows APIs
#endif

#ifndef NOMINMAX
#define NOMINMAX             // Prevent Windows.h from defining min/max macros
#endif

#include <windows.h>

// Temporary rename to prevent conflicts between Raylib and Windows API
#define Rectangle RaylibRectangle
#define CloseWindow RaylibCloseWindow
#define ShowCursor RaylibShowCursor
#define LoadImage RaylibLoadImage
#define DrawText RaylibDrawText
#define DrawTextEx RaylibDrawTextEx

#include <raylib.h>

// Undo the temporary renames so that Raylib can be used normally
#undef Rectangle
#undef CloseWindow
#undef ShowCursor
#undef LoadImage
#undef DrawText
#undef DrawTextEx

// Window functions
__declspec(dllexport) void initWindow(int width, int height, const char* title) {
    SetTraceLogLevel(LOG_ERROR); // Only write to the console in case of an error
    InitWindow(width, height, title);
}

__declspec(dllexport) int windowShouldClose() {
    return WindowShouldClose();
}

__declspec(dllexport) void setTargetFPS(int fps) {
    SetTargetFPS(fps);
}

// Rendering functions
__declspec(dllexport) void beginDrawing() {
    BeginDrawing();
}

__declspec(dllexport) void endDrawing() {
    EndDrawing();
}

__declspec(dllexport) void clearBackground(int r, int g, int b) {
    ClearBackground((Color){r, g, b, 255});
}

// Text drawing functions
__declspec(dllexport) void drawText(const char* text, int x, int y, int fontSize, int r, int g, int b) {
    DrawText(text, x, y, fontSize, (Color){r, g, b, 255});
}

// Shape drawing functions
__declspec(dllexport) void drawRectangle(int x, int y, int width, int height, int r, int g, int b) {
    DrawRectangle(x, y, width, height, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawCircle(int x, int y, float radius, int r, int g, int b) {
    DrawCircle(x, y, radius, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawLine(int startx, int starty, int endx, int endy, int r, int g, int b) {
    DrawLine(startx, starty, endx, endy, (Color){r, g, b, 255});
}

// Input functions
__declspec(dllexport) int isKeyPressed(int key) {
    return IsKeyPressed(key);
}

__declspec(dllexport) int isKeyDown(int key) {
    return IsKeyDown(key);
}

__declspec(dllexport) int isMouseButtonPressed(int button) {
    return IsMouseButtonPressed(button);
}

__declspec(dllexport) int isMouseButtonDown(int button) {
    return IsMouseButtonDown(button);
}

__declspec(dllexport) void getMousePosition(float* x, float* y) {
    Vector2 pos = GetMousePosition();
    *x = pos.x;
    *y = pos.y;
}

//gcc -shared -o pogberry_gui.dll pogberry_gui.c -DWIN32_LEAN_AND_MEAN -DNOMINMAX -lraylib -lopengl32 -lgdi32 -lwinmm
