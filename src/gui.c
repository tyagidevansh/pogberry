#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#elif defined(__linux__)
#include <dlfcn.h>
#else
#error "Unsupported platform"
#endif

#include "headers/gui.h"
#include "headers/native.h"
#include "headers/object.h"
#include "headers/vm.h"

typedef void (*InitWindowFunc)(int, int, const char *);
typedef bool (*WindowShouldCloseFunc)(void);
typedef void (*SetTargetFPSFunc)(int);
typedef void (*BeginDrawingFunc)(void);
typedef void (*EndDrawingFunc)(void);
typedef void (*ClearBackgroundFunc)(int, int, int);
typedef void (*DrawTextFunc)(const char *, int, int, int, int, int, int);
typedef void (*DrawRectangleFunc)(int, int, int, int, int, int, int);
typedef void (*DrawCircleFunc)(int, int, float, int, int, int);
typedef void (*DrawLineFunc)(int, int, int, int, int, int, int);
typedef bool (*IsKeyPressedFunc)(int);
typedef bool (*IsMouseButtonPressedFunc)(int);
typedef bool (*IsMouseButtonDownFunc)(int);
typedef void (*SwapScreenBufferFunc)(void);
typedef void (*DrawPixelFunc)(int, int, int, int, int);
typedef void (*DrawEllipseFunc)(int, int, float, float, int, int, int);
typedef bool (*IsKeyReleasedFunc)(int);
typedef bool (*IsKeyUpFunc)(int);
typedef int (*GetKeyPressedFunc)(void);
typedef int (*GetCharPressedFunc)(void);
typedef void (*SetExitKeyFunc)(int);
typedef bool (*IsMouseButtonReleasedFunc)(int);
typedef bool (*IsMouseButtonUpFunc)(int);
typedef int (*GetMouseXFunc)(void);
typedef int (*GetMouseYFunc)(void);
typedef void (*CloseWindowFunc)(void);
typedef bool (*IsWindowMinimizedFunc)(void);
typedef void (*ToggleBorderlessWindowedFunc)(void);
typedef int (*GetScreenWidthFunc)(void);
typedef int (*GetScreenHeightFunc)(void);
typedef int (*GetFPSFunc)(void);

/*
 * This is the complete legacy GUI contract. The same list drives both symbol
 * loading and Pogberry-native registration, so Linux and Windows cannot drift.
 */
#define GUI_BINDINGS(X) \
  X(initWindow, InitWindowFunc, "initWindow", initWindowNative) \
  X(closeWindow, CloseWindowFunc, "closeWindow", closeWindowNative) \
  X(windowShouldClose, WindowShouldCloseFunc, "windowShouldClose", windowShouldCloseNative) \
  X(isWindowMinimized, IsWindowMinimizedFunc, "isWindowMinimized", isWindowMinimizedNative) \
  X(toggleBorderlessWindowed, ToggleBorderlessWindowedFunc, "toggleBorderlessWindowed", toggleBorderlessWindowedNative) \
  X(getScreenWidth, GetScreenWidthFunc, "getScreenWidth", getScreenWidthNative) \
  X(getScreenHeight, GetScreenHeightFunc, "getScreenHeight", getScreenHeightNative) \
  X(getFPS, GetFPSFunc, "getFPS", getFPSNative) \
  X(clearBackground, ClearBackgroundFunc, "clearBackground", clearBackgroundNative) \
  X(beginDrawing, BeginDrawingFunc, "beginDrawing", beginDrawingNative) \
  X(endDrawing, EndDrawingFunc, "endDrawing", endDrawingNative) \
  X(setTargetFPS, SetTargetFPSFunc, "setTargetFPS", setTargetFPSNative) \
  X(swapScreenBuffer, SwapScreenBufferFunc, "swapScreenBuffer", swapScreenBufferNative) \
  X(drawPixel, DrawPixelFunc, "drawPixel", drawPixelNative) \
  X(drawLine, DrawLineFunc, "drawLine", drawLineNative) \
  X(drawCircle, DrawCircleFunc, "drawCircle", drawCircleNative) \
  X(drawEllipse, DrawEllipseFunc, "drawEllipse", drawEllipseNative) \
  X(drawRectangle, DrawRectangleFunc, "drawRectangle", drawRectangleNative) \
  X(drawText, DrawTextFunc, "drawText", drawTextNative) \
  X(isKeyPressed, IsKeyPressedFunc, "isKeyPressed", isKeyPressedNative) \
  X(isKeyReleased, IsKeyReleasedFunc, "isKeyReleased", isKeyReleasedNative) \
  X(isKeyUp, IsKeyUpFunc, "isKeyUp", isKeyUpNative) \
  X(getKeyPressed, GetKeyPressedFunc, "getKeyPressed", getKeyPressedNative) \
  X(getCharPressed, GetCharPressedFunc, "getCharPressed", getCharPressedNative) \
  X(setExitKey, SetExitKeyFunc, "setExitKey", setExitKeyNative) \
  X(isMouseButtonPressed, IsMouseButtonPressedFunc, "isMouseButtonPressed", isMouseButtonPressedNative) \
  X(isMouseButtonDown, IsMouseButtonDownFunc, "isMouseButtonDown", isMouseButtonDownNative) \
  X(isMouseButtonReleased, IsMouseButtonReleasedFunc, "isMouseButtonReleased", isMouseButtonReleasedNative) \
  X(isMouseButtonUp, IsMouseButtonUpFunc, "isMouseButtonUp", isMouseButtonUpNative) \
  X(getMouseX, GetMouseXFunc, "getMouseX", getMouseXNative) \
  X(getMouseY, GetMouseYFunc, "getMouseY", getMouseYNative)

#define GUI_FIELD(field, type, symbol, native) type field;
typedef struct
{
  GUI_BINDINGS(GUI_FIELD)
} GuiApi;
#undef GUI_FIELD

static GuiApi gui;
static bool guiLoaded = false;
static size_t guiUsers = 0;

#ifdef _WIN32
static HMODULE guiLibrary = NULL;
typedef FARPROC GuiSymbol;
#else
static void *guiLibrary = NULL;
typedef void *GuiSymbol;
#endif

typedef struct
{
  const char *name;
  int code;
} NameCode;

static const NameCode keyCodes[] = {
    {"KEY_APOSTROPHE", 39}, {"KEY_COMMA", 44}, {"KEY_MINUS", 45},
    {"KEY_PERIOD", 46}, {"KEY_SLASH", 47}, {"KEY_SEMICOLON", 59},
    {"KEY_EQUAL", 61}, {"KEY_A", 65}, {"KEY_B", 66}, {"KEY_C", 67},
    {"KEY_D", 68}, {"KEY_E", 69}, {"KEY_F", 70}, {"KEY_G", 71},
    {"KEY_H", 72}, {"KEY_I", 73}, {"KEY_J", 74}, {"KEY_K", 75},
    {"KEY_L", 76}, {"KEY_M", 77}, {"KEY_N", 78}, {"KEY_O", 79},
    {"KEY_P", 80}, {"KEY_Q", 81}, {"KEY_R", 82}, {"KEY_S", 83},
    {"KEY_T", 84}, {"KEY_U", 85}, {"KEY_V", 86}, {"KEY_W", 87},
    {"KEY_X", 88}, {"KEY_Y", 89}, {"KEY_Z", 90}, {"KEY_SPACE", 32},
    {"KEY_ESCAPE", 256}, {"KEY_ENTER", 257}, {"KEY_TAB", 258},
    {"KEY_BACKSPACE", 259}, {"KEY_INSERT", 260}, {"KEY_DELETE", 261},
    {"KEY_RIGHT", 262}, {"KEY_LEFT", 263}, {"KEY_DOWN", 264},
    {"KEY_UP", 265}, {"KEY_PAGE_UP", 266}, {"KEY_PAGE_DOWN", 267},
    {"KEY_HOME", 268}, {"KEY_END", 269}, {"KEY_CAPS_LOCK", 280},
    {"KEY_SCROLL_LOCK", 281}, {"KEY_NUM_LOCK", 282},
    {"KEY_PRINT_SCREEN", 283}, {"KEY_PAUSE", 284}, {"KEY_F1", 290},
    {"KEY_F2", 291}, {"KEY_F3", 292}, {"KEY_F4", 293}, {"KEY_F5", 294},
    {"KEY_F6", 295}, {"KEY_F7", 296}, {"KEY_F8", 297}, {"KEY_F9", 298},
    {"KEY_F10", 299}, {"KEY_F11", 300}, {"KEY_F12", 301},
    {"KEY_LEFT_SHIFT", 340}, {"KEY_LEFT_CONTROL", 341},
    {"KEY_LEFT_ALT", 342}, {"KEY_LEFT_SUPER", 343},
    {"KEY_RIGHT_SHIFT", 344}, {"KEY_RIGHT_CONTROL", 345},
    {"KEY_RIGHT_ALT", 346}, {"KEY_RIGHT_SUPER", 347}, {"KEY_KB_MENU", 348},
};

static int findCode(const NameCode *codes, size_t count, const char *name)
{
  for (size_t i = 0; i < count; i++)
  {
    if (strcmp(codes[i].name, name) == 0)
      return codes[i].code;
  }
  return -1;
}

static int getKeyCode(const char *name)
{
  return findCode(keyCodes, sizeof(keyCodes) / sizeof(keyCodes[0]), name);
}

static int getMouseButtonCode(const char *name)
{
  static const NameCode mouseCodes[] = {
      {"LEFT", 0}, {"RIGHT", 1}, {"MIDDLE", 2}};
  return findCode(mouseCodes, sizeof(mouseCodes) / sizeof(mouseCodes[0]), name);
}

static Value argumentError(const char *message)
{
  runtimeError("%s", message);
  return NIL_VAL;
}

static Value initWindowNative(int argCount, Value *args)
{
  if (argCount != 3 || !IS_NUMBER(args[0]) || !IS_NUMBER(args[1]) || !IS_STRING(args[2]))
    return argumentError("initWindow(width, height, title) expected.");
  gui.initWindow((int)AS_NUMBER(args[0]), (int)AS_NUMBER(args[1]), AS_CSTRING(args[2]));
  return NIL_VAL;
}

static Value closeWindowNative(int argCount, Value *args)
{
  (void)args;
  if (argCount != 0)
    return argumentError("closeWindow() takes no arguments.");
  gui.closeWindow();
  return NIL_VAL;
}

static Value windowShouldCloseNative(int argCount, Value *args)
{
  (void)args;
  if (argCount != 0)
    return argumentError("windowShouldClose() takes no arguments.");
  return BOOL_VAL(gui.windowShouldClose());
}

static Value isWindowMinimizedNative(int argCount, Value *args)
{
  (void)args;
  if (argCount != 0)
    return argumentError("isWindowMinimized() takes no arguments.");
  return BOOL_VAL(gui.isWindowMinimized());
}

static Value toggleBorderlessWindowedNative(int argCount, Value *args)
{
  (void)args;
  if (argCount != 0)
    return argumentError("toggleBorderlessWindowed() takes no arguments.");
  gui.toggleBorderlessWindowed();
  return NIL_VAL;
}

static Value getScreenWidthNative(int argCount, Value *args)
{
  (void)args;
  if (argCount != 0)
    return argumentError("getScreenWidth() takes no arguments.");
  return NUMBER_VAL(gui.getScreenWidth());
}

static Value getScreenHeightNative(int argCount, Value *args)
{
  (void)args;
  if (argCount != 0)
    return argumentError("getScreenHeight() takes no arguments.");
  return NUMBER_VAL(gui.getScreenHeight());
}

static Value getFPSNative(int argCount, Value *args)
{
  (void)args;
  if (argCount != 0)
    return argumentError("getFPS() takes no arguments.");
  return NUMBER_VAL(gui.getFPS());
}

static Value clearBackgroundNative(int argCount, Value *args)
{
  if (argCount != 3 || !IS_NUMBER(args[0]) || !IS_NUMBER(args[1]) || !IS_NUMBER(args[2]))
    return argumentError("clearBackground(r, g, b) expected.");
  gui.clearBackground((int)AS_NUMBER(args[0]), (int)AS_NUMBER(args[1]),
                      (int)AS_NUMBER(args[2]));
  return NIL_VAL;
}

static Value beginDrawingNative(int argCount, Value *args)
{
  (void)args;
  if (argCount != 0)
    return argumentError("beginDrawing() takes no arguments.");
  gui.beginDrawing();
  return NIL_VAL;
}

static Value endDrawingNative(int argCount, Value *args)
{
  (void)args;
  if (argCount != 0)
    return argumentError("endDrawing() takes no arguments.");
  gui.endDrawing();
  return NIL_VAL;
}

static Value setTargetFPSNative(int argCount, Value *args)
{
  if (argCount != 1 || !IS_NUMBER(args[0]))
    return argumentError("setTargetFPS(fps) expected.");
  gui.setTargetFPS((int)AS_NUMBER(args[0]));
  return NIL_VAL;
}

static Value swapScreenBufferNative(int argCount, Value *args)
{
  (void)args;
  if (argCount != 0)
    return argumentError("swapScreenBuffer() takes no arguments.");
  gui.swapScreenBuffer();
  return NIL_VAL;
}

static Value drawPixelNative(int argCount, Value *args)
{
  if (argCount != 5 || !IS_NUMBER(args[0]) || !IS_NUMBER(args[1]) ||
      !IS_NUMBER(args[2]) || !IS_NUMBER(args[3]) || !IS_NUMBER(args[4]))
    return argumentError("drawPixel(x, y, r, g, b) expected.");
  gui.drawPixel((int)AS_NUMBER(args[0]), (int)AS_NUMBER(args[1]),
                (int)AS_NUMBER(args[2]), (int)AS_NUMBER(args[3]),
                (int)AS_NUMBER(args[4]));
  return NIL_VAL;
}

static Value drawLineNative(int argCount, Value *args)
{
  if (argCount != 7 || !IS_NUMBER(args[0]) || !IS_NUMBER(args[1]) ||
      !IS_NUMBER(args[2]) || !IS_NUMBER(args[3]) || !IS_NUMBER(args[4]) ||
      !IS_NUMBER(args[5]) || !IS_NUMBER(args[6]))
    return argumentError("drawLine(x1, y1, x2, y2, r, g, b) expected.");
  gui.drawLine((int)AS_NUMBER(args[0]), (int)AS_NUMBER(args[1]),
               (int)AS_NUMBER(args[2]), (int)AS_NUMBER(args[3]),
               (int)AS_NUMBER(args[4]), (int)AS_NUMBER(args[5]),
               (int)AS_NUMBER(args[6]));
  return NIL_VAL;
}

static Value drawCircleNative(int argCount, Value *args)
{
  if (argCount != 6 || !IS_NUMBER(args[0]) || !IS_NUMBER(args[1]) ||
      !IS_NUMBER(args[2]) || !IS_NUMBER(args[3]) || !IS_NUMBER(args[4]) ||
      !IS_NUMBER(args[5]))
    return argumentError("drawCircle(x, y, radius, r, g, b) expected.");
  gui.drawCircle((int)AS_NUMBER(args[0]), (int)AS_NUMBER(args[1]),
                 (float)AS_NUMBER(args[2]), (int)AS_NUMBER(args[3]),
                 (int)AS_NUMBER(args[4]), (int)AS_NUMBER(args[5]));
  return NIL_VAL;
}

static Value drawEllipseNative(int argCount, Value *args)
{
  if (argCount != 7 || !IS_NUMBER(args[0]) || !IS_NUMBER(args[1]) ||
      !IS_NUMBER(args[2]) || !IS_NUMBER(args[3]) || !IS_NUMBER(args[4]) ||
      !IS_NUMBER(args[5]) || !IS_NUMBER(args[6]))
    return argumentError("drawEllipse(x, y, radiusH, radiusV, r, g, b) expected.");
  gui.drawEllipse((int)AS_NUMBER(args[0]), (int)AS_NUMBER(args[1]),
                  (float)AS_NUMBER(args[2]), (float)AS_NUMBER(args[3]),
                  (int)AS_NUMBER(args[4]), (int)AS_NUMBER(args[5]),
                  (int)AS_NUMBER(args[6]));
  return NIL_VAL;
}

static Value drawRectangleNative(int argCount, Value *args)
{
  if (argCount != 7 || !IS_NUMBER(args[0]) || !IS_NUMBER(args[1]) ||
      !IS_NUMBER(args[2]) || !IS_NUMBER(args[3]) || !IS_NUMBER(args[4]) ||
      !IS_NUMBER(args[5]) || !IS_NUMBER(args[6]))
    return argumentError("drawRectangle(x, y, width, height, r, g, b) expected.");
  gui.drawRectangle((int)AS_NUMBER(args[0]), (int)AS_NUMBER(args[1]),
                    (int)AS_NUMBER(args[2]), (int)AS_NUMBER(args[3]),
                    (int)AS_NUMBER(args[4]), (int)AS_NUMBER(args[5]),
                    (int)AS_NUMBER(args[6]));
  return NIL_VAL;
}

static Value drawTextNative(int argCount, Value *args)
{
  if (argCount != 7 || !IS_STRING(args[0]) || !IS_NUMBER(args[1]) ||
      !IS_NUMBER(args[2]) || !IS_NUMBER(args[3]) || !IS_NUMBER(args[4]) ||
      !IS_NUMBER(args[5]) || !IS_NUMBER(args[6]))
    return argumentError("drawText(text, x, y, fontSize, r, g, b) expected.");
  gui.drawText(AS_CSTRING(args[0]), (int)AS_NUMBER(args[1]),
               (int)AS_NUMBER(args[2]), (int)AS_NUMBER(args[3]),
               (int)AS_NUMBER(args[4]), (int)AS_NUMBER(args[5]),
               (int)AS_NUMBER(args[6]));
  return NIL_VAL;
}

static Value keyQuery(int argCount, Value *args, bool (*query)(int), const char *usage)
{
  if (argCount != 1 || !IS_STRING(args[0]))
    return argumentError(usage);
  int key = getKeyCode(AS_CSTRING(args[0]));
  if (key < 0)
  {
    runtimeError("Invalid key name: %s.", AS_CSTRING(args[0]));
    return NIL_VAL;
  }
  return BOOL_VAL(query(key));
}

static Value isKeyPressedNative(int argCount, Value *args)
{
  return keyQuery(argCount, args, gui.isKeyPressed,
                  "isKeyPressed(string keyName) expected.");
}

static Value isKeyReleasedNative(int argCount, Value *args)
{
  return keyQuery(argCount, args, gui.isKeyReleased,
                  "isKeyReleased(string keyName) expected.");
}

static Value isKeyUpNative(int argCount, Value *args)
{
  return keyQuery(argCount, args, gui.isKeyUp,
                  "isKeyUp(string keyName) expected.");
}

static Value getKeyPressedNative(int argCount, Value *args)
{
  (void)args;
  if (argCount != 0)
    return argumentError("getKeyPressed() takes no arguments.");
  return NUMBER_VAL(gui.getKeyPressed());
}

static Value getCharPressedNative(int argCount, Value *args)
{
  (void)args;
  if (argCount != 0)
    return argumentError("getCharPressed() takes no arguments.");
  return NUMBER_VAL(gui.getCharPressed());
}

static Value setExitKeyNative(int argCount, Value *args)
{
  if (argCount != 1 || !IS_NUMBER(args[0]))
    return argumentError("setExitKey(key) expected.");
  gui.setExitKey((int)AS_NUMBER(args[0]));
  return NIL_VAL;
}

static Value mouseQuery(int argCount, Value *args, bool (*query)(int), const char *usage)
{
  if (argCount != 1 || !IS_STRING(args[0]))
    return argumentError(usage);
  int button = getMouseButtonCode(AS_CSTRING(args[0]));
  if (button < 0)
  {
    runtimeError("Invalid mouse button name: %s.", AS_CSTRING(args[0]));
    return NIL_VAL;
  }
  return BOOL_VAL(query(button));
}

static Value isMouseButtonPressedNative(int argCount, Value *args)
{
  return mouseQuery(argCount, args, gui.isMouseButtonPressed,
                    "isMouseButtonPressed(string buttonName) expected.");
}

static Value isMouseButtonDownNative(int argCount, Value *args)
{
  return mouseQuery(argCount, args, gui.isMouseButtonDown,
                    "isMouseButtonDown(string buttonName) expected.");
}

static Value isMouseButtonReleasedNative(int argCount, Value *args)
{
  return mouseQuery(argCount, args, gui.isMouseButtonReleased,
                    "isMouseButtonReleased(string buttonName) expected.");
}

static Value isMouseButtonUpNative(int argCount, Value *args)
{
  return mouseQuery(argCount, args, gui.isMouseButtonUp,
                    "isMouseButtonUp(string buttonName) expected.");
}

static Value getMouseXNative(int argCount, Value *args)
{
  (void)args;
  if (argCount != 0)
    return argumentError("getMouseX() takes no arguments.");
  return NUMBER_VAL(gui.getMouseX());
}

static Value getMouseYNative(int argCount, Value *args)
{
  (void)args;
  if (argCount != 0)
    return argumentError("getMouseY() takes no arguments.");
  return NUMBER_VAL(gui.getMouseY());
}

static bool openGuiLibrary(void)
{
  const char *overridePath = getenv("POGBERRY_GUI_LIBRARY");
#ifdef _WIN32
  if (overridePath != NULL && overridePath[0] != '\0')
    guiLibrary = LoadLibraryA(overridePath);
  else
  {
    guiLibrary = LoadLibraryA("lib\\pogberry_gui_windows.dll");
    if (guiLibrary == NULL)
    {
      char executable[MAX_PATH] = {0};
      DWORD length = GetModuleFileNameA(NULL, executable, MAX_PATH);
      if (length > 0 && length < MAX_PATH)
      {
        char *slash = strrchr(executable, '\\');
        if (slash != NULL)
        {
          *slash = '\0';
          char path[MAX_PATH] = {0};
          int written = snprintf(path, sizeof(path), "%s\\lib\\pogberry_gui_windows.dll",
                                 executable);
          if (written > 0 && (size_t)written < sizeof(path))
            guiLibrary = LoadLibraryA(path);
        }
      }
    }
  }
#else
  const char *path = overridePath != NULL && overridePath[0] != '\0'
                         ? overridePath
                         : "lib/pogberry_gui_linux.so";
  guiLibrary = dlopen(path, RTLD_NOW | RTLD_LOCAL);
#endif
  return guiLibrary != NULL;
}

static GuiSymbol loadGuiSymbol(const char *name)
{
#ifdef _WIN32
  return GetProcAddress(guiLibrary, name);
#else
  dlerror();
  return dlsym(guiLibrary, name);
#endif
}

static void closeGuiLibrary(void)
{
  if (guiLibrary == NULL)
    return;
#ifdef _WIN32
  FreeLibrary(guiLibrary);
#else
  dlclose(guiLibrary);
#endif
  guiLibrary = NULL;
}

bool initialiseGui(void)
{
  if (vm.legacyGuiLoaded)
    return true;

  if (!guiLoaded && !openGuiLibrary())
  {
#ifdef _WIN32
    runtimeError("Could not load Pogberry GUI library (Windows error %lu).",
                 (unsigned long)GetLastError());
#else
    const char *error = dlerror();
    runtimeError("Could not load Pogberry GUI library: %s.",
                 error != NULL ? error : "unknown loader error");
#endif
    return false;
  }

#define LOAD_GUI_SYMBOL(field, type, symbol, native)                         \
  do                                                                         \
  {                                                                          \
    GuiSymbol loadedSymbol = loadGuiSymbol(symbol);                           \
    if (loadedSymbol == NULL)                                                 \
    {                                                                        \
      closeGuiLibrary();                                                      \
      memset(&gui, 0, sizeof(gui));                                           \
      runtimeError("Pogberry GUI library is missing symbol '%s'.", symbol);  \
      return false;                                                          \
    }                                                                        \
    _Static_assert(sizeof(gui.field) == sizeof(loadedSymbol),                 \
                   "GUI function pointer size mismatch");                    \
    memcpy(&gui.field, &loadedSymbol, sizeof(gui.field));                     \
  } while (false);

  if (!guiLoaded)
  {
    GUI_BINDINGS(LOAD_GUI_SYMBOL)
  }
#undef LOAD_GUI_SYMBOL

#define REGISTER_GUI_NATIVE(field, type, symbol, native) defineNative(symbol, native);
  GUI_BINDINGS(REGISTER_GUI_NATIVE)
#undef REGISTER_GUI_NATIVE

  guiLoaded = true;
  vm.legacyGuiLoaded = true;
  guiUsers++;
  return true;
}

void freeGui(void)
{
  if (!vm.legacyGuiLoaded)
    return;
  vm.legacyGuiLoaded = false;
  if (guiUsers > 0)
    guiUsers--;
  if (guiUsers > 0)
    return;
  closeGuiLibrary();
  memset(&gui, 0, sizeof(gui));
  guiLoaded = false;
}
