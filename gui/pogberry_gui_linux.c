#include <raylib.h>

// Window functions
void initWindow(int width, int height, const char* title) {
    SetTraceLogLevel(LOG_ERROR); // Only write to the console in case of an error
    InitWindow(width, height, title);
}

int windowShouldClose() {
    return WindowShouldClose();
}

void setTargetFPS(int fps) {
    SetTargetFPS(fps);
}

// Rendering functions
void beginDrawing() {
    BeginDrawing();
}

void endDrawing() {
    EndDrawing();
}

void clearBackground(int r, int g, int b) {
    ClearBackground((Color){r, g, b, 255});
}

// Text drawing functions
void drawText(const char* text, int x, int y, int fontSize, int r, int g, int b) {
    DrawText(text, x, y, fontSize, (Color){r, g, b, 255});
}

// Shape drawing functions
void drawRectangle(int x, int y, int width, int height, int r, int g, int b) {
    DrawRectangle(x, y, width, height, (Color){r, g, b, 255});
}

void drawCircle(int x, int y, float radius, int r, int g, int b) {
    DrawCircle(x, y, radius, (Color){r, g, b, 255});
}

void drawLine(int startx, int starty, int endx, int endy, int r, int g, int b) {
    DrawLine(startx, starty, endx, endy, (Color){r, g, b, 255});
}

// Input functions
int isKeyPressed(int key) {
    return IsKeyPressed(key);
}

int isKeyDown(int key) {
    return IsKeyDown(key);
}

int isMouseButtonPressed(int button) {
    return IsMouseButtonPressed(button);
}

int isMouseButtonDown(int button) {
    return IsMouseButtonDown(button);
}

void getMousePosition(float* x, float* y) {
    Vector2 pos = GetMousePosition();
    *x = pos.x;
    *y = pos.y;
}

//gcc -shared -fPIC -o lib/pogberry_gui_linux.so gui/pogberry_gui_linux.c /usr/local/lib/libraylib.a -lGL -lm -lpthread -ldl -lrt -lX11
