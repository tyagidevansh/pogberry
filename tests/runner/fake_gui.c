#include <stdbool.h>

#ifdef _WIN32
#define GUI_EXPORT __declspec(dllexport)
#else
#define GUI_EXPORT __attribute__((visibility("default")))
#endif

GUI_EXPORT void initWindow(int width, int height, const char *title)
{
  (void)width;
  (void)height;
  (void)title;
}

GUI_EXPORT void closeWindow(void) {}
GUI_EXPORT bool windowShouldClose(void) { return true; }
GUI_EXPORT bool isWindowMinimized(void) { return false; }
GUI_EXPORT void toggleBorderlessWindowed(void) {}
GUI_EXPORT int getScreenWidth(void) { return 800; }
GUI_EXPORT int getScreenHeight(void) { return 600; }
GUI_EXPORT int getFPS(void) { return 60; }
GUI_EXPORT void clearBackground(int r, int g, int b)
{
  (void)r;
  (void)g;
  (void)b;
}
GUI_EXPORT void beginDrawing(void) {}
GUI_EXPORT void endDrawing(void) {}
GUI_EXPORT void setTargetFPS(int fps) { (void)fps; }
GUI_EXPORT void swapScreenBuffer(void) {}
GUI_EXPORT void drawPixel(int x, int y, int r, int g, int b)
{
  (void)x;
  (void)y;
  (void)r;
  (void)g;
  (void)b;
}
GUI_EXPORT void drawLine(int x1, int y1, int x2, int y2, int r, int g, int b)
{
  (void)x1;
  (void)y1;
  (void)x2;
  (void)y2;
  (void)r;
  (void)g;
  (void)b;
}
GUI_EXPORT void drawCircle(int x, int y, float radius, int r, int g, int b)
{
  (void)x;
  (void)y;
  (void)radius;
  (void)r;
  (void)g;
  (void)b;
}
GUI_EXPORT void drawEllipse(int x, int y, float radiusH, float radiusV,
                            int r, int g, int b)
{
  (void)x;
  (void)y;
  (void)radiusH;
  (void)radiusV;
  (void)r;
  (void)g;
  (void)b;
}
GUI_EXPORT void drawRectangle(int x, int y, int width, int height,
                              int r, int g, int b)
{
  (void)x;
  (void)y;
  (void)width;
  (void)height;
  (void)r;
  (void)g;
  (void)b;
}
GUI_EXPORT void drawText(const char *text, int x, int y, int fontSize,
                         int r, int g, int b)
{
  (void)text;
  (void)x;
  (void)y;
  (void)fontSize;
  (void)r;
  (void)g;
  (void)b;
}
GUI_EXPORT bool isKeyPressed(int key) { return key == 265; }
GUI_EXPORT bool isKeyReleased(int key) { return key == 263; }
GUI_EXPORT bool isKeyUp(int key) { return key == 32; }
GUI_EXPORT int getKeyPressed(void) { return 265; }
GUI_EXPORT int getCharPressed(void) { return 65; }
GUI_EXPORT void setExitKey(int key) { (void)key; }
GUI_EXPORT bool isMouseButtonPressed(int button) { return button == 0; }
GUI_EXPORT bool isMouseButtonDown(int button) { return button == 1; }
GUI_EXPORT bool isMouseButtonReleased(int button) { return button == 2; }
GUI_EXPORT bool isMouseButtonUp(int button) { return button == 0; }
GUI_EXPORT int getMouseX(void) { return 123; }
GUI_EXPORT int getMouseY(void) { return 456; }
