#include <stdbool.h>
#include <string.h>

#if defined(_WIN32) || defined(__CYGWIN__)
#define RAYLIB_EXPORT __declspec(dllexport)
#elif defined(__GNUC__) && __GNUC__ >= 4
#define RAYLIB_EXPORT __attribute__((visibility("default")))
#else
#define RAYLIB_EXPORT
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
static int fakeVirtualWidth = 0;
static int fakeVirtualHeight = 0;

RAYLIB_EXPORT void setVirtualResolution(int width, int height) {
  fakeVirtualWidth = width;
  fakeVirtualHeight = height;
}

RAYLIB_EXPORT int getRenderWidth(void) { return 800; }
RAYLIB_EXPORT int getRenderHeight(void) { return 600; }
RAYLIB_EXPORT int getScreenWidth(void) { return fakeVirtualWidth > 0 ? fakeVirtualWidth : 800; }
RAYLIB_EXPORT int getScreenHeight(void) { return fakeVirtualHeight > 0 ? fakeVirtualHeight : 600; }
RAYLIB_EXPORT int getFPS(void) { return 60; }
RAYLIB_EXPORT float getFrameTime(void) { return 0.016f; }
RAYLIB_EXPORT void setTargetFPS(int fps) { (void)fps; }
RAYLIB_EXPORT void clearBackground(int r, int g, int b) {
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void beginDrawing(void) {}
RAYLIB_EXPORT void endDrawing(void) {}

RAYLIB_EXPORT void drawPixel(int posX, int posY, int r, int g, int b) {
  (void)posX;
  (void)posY;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawLine(int startPosX, int startPosY, int endPosX, int endPosY, int r, int g, int b) {
  (void)startPosX;
  (void)startPosY;
  (void)endPosX;
  (void)endPosY;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawCircle(int centerX, int centerY, float radius, int r, int g, int b) {
  (void)centerX;
  (void)centerY;
  (void)radius;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawCircleLines(int centerX, int centerY, float radius, int r, int g, int b) {
  (void)centerX;
  (void)centerY;
  (void)radius;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawCircleAlpha(int centerX, int centerY, float radius, int r, int g, int b, int a) {
  (void)centerX;
  (void)centerY;
  (void)radius;
  (void)r;
  (void)g;
  (void)b;
  (void)a;
}

RAYLIB_EXPORT void drawEllipse(int centerX, int centerY, float radiusH, float radiusV, int r, int g, int b) {
  (void)centerX;
  (void)centerY;
  (void)radiusH;
  (void)radiusV;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawRectangle(int posX, int posY, int width, int height, int r, int g, int b) {
  (void)posX;
  (void)posY;
  (void)width;
  (void)height;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawRectangleLines(int posX, int posY, int width, int height, int r, int g, int b) {
  (void)posX;
  (void)posY;
  (void)width;
  (void)height;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawRectangleAlpha(int posX, int posY, int width, int height, int r, int g, int b, int a) {
  (void)posX;
  (void)posY;
  (void)width;
  (void)height;
  (void)r;
  (void)g;
  (void)b;
  (void)a;
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

RAYLIB_EXPORT void drawText(const char *text, int x, int y, int fontSize, int r, int g, int b) {
  (void)text;
  (void)x;
  (void)y;
  (void)fontSize;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT int measureText(const char *text, int fontSize) {
  if (text == NULL) return 0;
  return (int)strlen(text) * fontSize;
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
RAYLIB_EXPORT bool isWindowMaximized(void) { return false; }
RAYLIB_EXPORT void maximizeWindow(void) {}
RAYLIB_EXPORT void restoreWindow(void) {}
RAYLIB_EXPORT void hideCursor(void) {}
RAYLIB_EXPORT void showCursor(void) {}

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

/* Sprites & Textures */
RAYLIB_EXPORT int loadTexture(const char *path) {
  (void)path;
  return 1;
}

RAYLIB_EXPORT void unloadTexture(int id) { (void)id; }

RAYLIB_EXPORT void drawTexture(int id, int posX, int posY) {
  (void)id;
  (void)posX;
  (void)posY;
}

RAYLIB_EXPORT void drawTextureTint(int id, int posX, int posY, int r, int g, int b) {
  (void)id;
  (void)posX;
  (void)posY;
  (void)r;
  (void)g;
  (void)b;
}

RAYLIB_EXPORT void drawTextureRec(int id, float sx, float sy, float sw, float sh, float dx, float dy) {
  (void)id;
  (void)sx;
  (void)sy;
  (void)sw;
  (void)sh;
  (void)dx;
  (void)dy;
}

RAYLIB_EXPORT void drawTexturePro(int id, float sx, float sy, float sw, float sh, float dx, float dy, float dw,
                                  float dh, float ox, float oy, float rot) {
  (void)id;
  (void)sx;
  (void)sy;
  (void)sw;
  (void)sh;
  (void)dx;
  (void)dy;
  (void)dw;
  (void)dh;
  (void)ox;
  (void)oy;
  (void)rot;
}

RAYLIB_EXPORT int getTextureWidth(int id) {
  (void)id;
  return 64;
}

RAYLIB_EXPORT int getTextureHeight(int id) {
  (void)id;
  return 64;
}

/* Sound Effects */
RAYLIB_EXPORT void initAudio(void) {}
RAYLIB_EXPORT void closeAudio(void) {}

RAYLIB_EXPORT int loadSound(const char *path) {
  (void)path;
  return 1;
}

RAYLIB_EXPORT void unloadSound(int id) { (void)id; }
RAYLIB_EXPORT void playSound(int id) { (void)id; }
RAYLIB_EXPORT void stopSound(int id) { (void)id; }
RAYLIB_EXPORT void setSoundVolume(int id, float volume) {
  (void)id;
  (void)volume;
}
RAYLIB_EXPORT void setSoundPitch(int id, float pitch) {
  (void)id;
  (void)pitch;
}
RAYLIB_EXPORT bool isSoundPlaying(int id) {
  (void)id;
  return false;
}
RAYLIB_EXPORT void setMasterVolume(float volume) { (void)volume; }

/* Music Streams */
RAYLIB_EXPORT int loadMusic(const char *path) {
  (void)path;
  return 1;
}

RAYLIB_EXPORT void unloadMusic(int id) { (void)id; }
RAYLIB_EXPORT void playMusic(int id) { (void)id; }
RAYLIB_EXPORT void pauseMusic(int id) { (void)id; }
RAYLIB_EXPORT void resumeMusic(int id) { (void)id; }
RAYLIB_EXPORT void stopMusic(int id) { (void)id; }
RAYLIB_EXPORT void updateMusic(int id) { (void)id; }
RAYLIB_EXPORT void setMusicVolume(int id, float volume) {
  (void)id;
  (void)volume;
}
RAYLIB_EXPORT bool isMusicStreamPlaying(int id) {
  (void)id;
  return true;
}
