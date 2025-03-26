#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN  // exclude rarely used Windows APIs
#endif

#ifndef NOMINMAX
#define NOMINMAX             // prevent Windows.h from defining min/max macros
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

// undo the temporary renames so that raylib can be used normally
#undef Rectangle
#undef CloseWindow
#undef ShowCursor
#undef LoadImage
#undef DrawText
#undef DrawTextEx

__declspec(dllexport) void initWindow(int width, int height, const char* title) {
    InitWindow(width, height, title);
}

__declspec(dllexport) void beginDrawing() {
    BeginDrawing();
}

__declspec(dllexport) void clearBackground(int r, int g, int b) {
    ClearBackground((Color){r, g, b, 255});
}

__declspec(dllexport) void drawText(const char* text, int x, int y, int fontSize, int r, int g, int b) {
    DrawText(text, x, y, fontSize, (Color){r, g, b, 255});
}

__declspec(dllexport) void endDrawing() {
    EndDrawing();
}

__declspec(dllexport) int windowShouldClose() {
  return WindowShouldClose();
}


//gcc -shared -o pogberry_gui.dll pogberry_gui.c -DWIN32_LEAN_AND_MEAN -DNOMINMAX -lraylib -lopengl32 -lgdi32 -lwinmm
