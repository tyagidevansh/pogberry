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

#include "host/modules/gui.h"

typedef void (*InitWindowFn)(int, int, const char *);
typedef void (*CloseWindowFn)(void);
typedef bool (*WindowShouldCloseFn)(void);
typedef bool (*IsWindowMinimizedFn)(void);
typedef void (*ToggleBorderlessWindowedFn)(void);
typedef int (*GetScreenWidthFn)(void);
typedef int (*GetScreenHeightFn)(void);
typedef int (*GetFPSFn)(void);
typedef void (*SetTargetFPSFn)(int);
typedef void (*ClearBackgroundFn)(int, int, int);
typedef void (*BeginDrawingFn)(void);
typedef void (*EndDrawingFn)(void);
typedef void (*SwapScreenBufferFn)(void);
typedef void (*DrawPixelFn)(int, int, int, int, int);
typedef void (*DrawLineFn)(int, int, int, int, int, int, int);
typedef void (*DrawCircleFn)(int, int, float, int, int, int);
typedef void (*DrawEllipseFn)(int, int, float, float, int, int, int);
typedef void (*DrawRectangleFn)(int, int, int, int, int, int, int);
typedef void (*DrawTextFn)(const char *, int, int, int, int, int, int);
typedef bool (*IsKeyPressedFn)(int);
typedef bool (*IsKeyReleasedFn)(int);
typedef bool (*IsKeyUpFn)(int);
typedef int (*GetKeyPressedFn)(void);
typedef int (*GetCharPressedFn)(void);
typedef void (*SetExitKeyFn)(int);
typedef bool (*IsMouseButtonPressedFn)(int);
typedef bool (*IsMouseButtonDownFn)(int);
typedef bool (*IsMouseButtonReleasedFn)(int);
typedef bool (*IsMouseButtonUpFn)(int);
typedef int (*GetMouseXFn)(void);
typedef int (*GetMouseYFn)(void);

#define GUI_FUNCTIONS(X) \
  X(initWindow, InitWindowFn, "initWindow", guiInitWindow) \
  X(closeWindow, CloseWindowFn, "closeWindow", guiCloseWindow) \
  X(windowShouldClose, WindowShouldCloseFn, "windowShouldClose", guiWindowShouldClose) \
  X(isWindowMinimized, IsWindowMinimizedFn, "isWindowMinimized", guiIsWindowMinimized) \
  X(toggleBorderlessWindowed, ToggleBorderlessWindowedFn, "toggleBorderlessWindowed", guiToggleBorderlessWindowed) \
  X(getScreenWidth, GetScreenWidthFn, "getScreenWidth", guiGetScreenWidth) \
  X(getScreenHeight, GetScreenHeightFn, "getScreenHeight", guiGetScreenHeight) \
  X(getFPS, GetFPSFn, "getFPS", guiGetFPS) \
  X(setTargetFPS, SetTargetFPSFn, "setTargetFPS", guiSetTargetFPS) \
  X(clearBackground, ClearBackgroundFn, "clearBackground", guiClearBackground) \
  X(beginDrawing, BeginDrawingFn, "beginDrawing", guiBeginDrawing) \
  X(endDrawing, EndDrawingFn, "endDrawing", guiEndDrawing) \
  X(swapScreenBuffer, SwapScreenBufferFn, "swapScreenBuffer", guiSwapScreenBuffer) \
  X(drawPixel, DrawPixelFn, "drawPixel", guiDrawPixel) \
  X(drawLine, DrawLineFn, "drawLine", guiDrawLine) \
  X(drawCircle, DrawCircleFn, "drawCircle", guiDrawCircle) \
  X(drawEllipse, DrawEllipseFn, "drawEllipse", guiDrawEllipse) \
  X(drawRectangle, DrawRectangleFn, "drawRectangle", guiDrawRectangle) \
  X(drawText, DrawTextFn, "drawText", guiDrawText) \
  X(isKeyPressed, IsKeyPressedFn, "isKeyPressed", guiIsKeyPressed) \
  X(isKeyReleased, IsKeyReleasedFn, "isKeyReleased", guiIsKeyReleased) \
  X(isKeyUp, IsKeyUpFn, "isKeyUp", guiIsKeyUp) \
  X(getKeyPressed, GetKeyPressedFn, "getKeyPressed", guiGetKeyPressed) \
  X(getCharPressed, GetCharPressedFn, "getCharPressed", guiGetCharPressed) \
  X(setExitKey, SetExitKeyFn, "setExitKey", guiSetExitKey) \
  X(isMouseButtonPressed, IsMouseButtonPressedFn, "isMouseButtonPressed", guiIsMouseButtonPressed) \
  X(isMouseButtonDown, IsMouseButtonDownFn, "isMouseButtonDown", guiIsMouseButtonDown) \
  X(isMouseButtonReleased, IsMouseButtonReleasedFn, "isMouseButtonReleased", guiIsMouseButtonReleased) \
  X(isMouseButtonUp, IsMouseButtonUpFn, "isMouseButtonUp", guiIsMouseButtonUp) \
  X(getMouseX, GetMouseXFn, "getMouseX", guiGetMouseX) \
  X(getMouseY, GetMouseYFn, "getMouseY", guiGetMouseY)

#define GUI_FIELD(field, type, symbol, callback) type field;
typedef struct
{
  GUI_FUNCTIONS(GUI_FIELD)
} GuiApi;
#undef GUI_FIELD

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

static GuiApi gui;
static bool guiLoaded = false;
static size_t guiUsers = 0;

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
    {"KEY_RIGHT_ALT", 346}, {"KEY_RIGHT_SUPER", 347},
    {"KEY_KB_MENU", 348},
};

static PbValue guiError(PbVM *vm, const char *message)
{
  pbRuntimeError(vm, message);
  return pbNilValue();
}

static bool allNumbers(const PbValue *values, int count)
{
  for (int i = 0; i < count; i++)
  {
    if (values[i].type != PB_VALUE_NUMBER)
      return false;
  }
  return true;
}

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

static PbValue guiInitWindow(PbVM *vm, int argCount,
                             const PbValue *args, void *userData)
{
  (void)userData;
  if (argCount != 3 || !allNumbers(args, 2) ||
      args[2].type != PB_VALUE_STRING)
    return guiError(vm, "initWindow(width, height, title) expected.");
  gui.initWindow((int)args[0].as.number, (int)args[1].as.number,
                 args[2].as.string.chars);
  return pbNilValue();
}

static PbValue guiCloseWindow(PbVM *vm, int argCount,
                              const PbValue *args, void *userData)
{
  (void)args;
  (void)userData;
  if (argCount != 0)
    return guiError(vm, "closeWindow() takes no arguments.");
  gui.closeWindow();
  return pbNilValue();
}

static PbValue guiWindowShouldClose(PbVM *vm, int argCount,
                                    const PbValue *args, void *userData)
{
  (void)args;
  (void)userData;
  if (argCount != 0)
    return guiError(vm, "windowShouldClose() takes no arguments.");
  return pbBoolValue(gui.windowShouldClose());
}

static PbValue guiIsWindowMinimized(PbVM *vm, int argCount,
                                    const PbValue *args, void *userData)
{
  (void)args;
  (void)userData;
  if (argCount != 0)
    return guiError(vm, "isWindowMinimized() takes no arguments.");
  return pbBoolValue(gui.isWindowMinimized());
}

static PbValue guiToggleBorderlessWindowed(PbVM *vm, int argCount,
                                           const PbValue *args,
                                           void *userData)
{
  (void)args;
  (void)userData;
  if (argCount != 0)
    return guiError(vm,
                    "toggleBorderlessWindowed() takes no arguments.");
  gui.toggleBorderlessWindowed();
  return pbNilValue();
}

static PbValue guiGetScreenWidth(PbVM *vm, int argCount,
                                 const PbValue *args, void *userData)
{
  (void)args;
  (void)userData;
  if (argCount != 0)
    return guiError(vm, "getScreenWidth() takes no arguments.");
  return pbNumberValue(gui.getScreenWidth());
}

static PbValue guiGetScreenHeight(PbVM *vm, int argCount,
                                  const PbValue *args, void *userData)
{
  (void)args;
  (void)userData;
  if (argCount != 0)
    return guiError(vm, "getScreenHeight() takes no arguments.");
  return pbNumberValue(gui.getScreenHeight());
}

static PbValue guiGetFPS(PbVM *vm, int argCount,
                         const PbValue *args, void *userData)
{
  (void)args;
  (void)userData;
  if (argCount != 0)
    return guiError(vm, "getFPS() takes no arguments.");
  return pbNumberValue(gui.getFPS());
}

static PbValue guiSetTargetFPS(PbVM *vm, int argCount,
                               const PbValue *args, void *userData)
{
  (void)userData;
  if (argCount != 1 || !allNumbers(args, 1))
    return guiError(vm, "setTargetFPS(fps) expected.");
  gui.setTargetFPS((int)args[0].as.number);
  return pbNilValue();
}

static PbValue guiClearBackground(PbVM *vm, int argCount,
                                  const PbValue *args, void *userData)
{
  (void)userData;
  if (argCount != 3 || !allNumbers(args, 3))
    return guiError(vm, "clearBackground(r, g, b) expected.");
  gui.clearBackground((int)args[0].as.number, (int)args[1].as.number,
                      (int)args[2].as.number);
  return pbNilValue();
}

static PbValue guiBeginDrawing(PbVM *vm, int argCount,
                               const PbValue *args, void *userData)
{
  (void)args;
  (void)userData;
  if (argCount != 0)
    return guiError(vm, "beginDrawing() takes no arguments.");
  gui.beginDrawing();
  return pbNilValue();
}

static PbValue guiEndDrawing(PbVM *vm, int argCount,
                             const PbValue *args, void *userData)
{
  (void)args;
  (void)userData;
  if (argCount != 0)
    return guiError(vm, "endDrawing() takes no arguments.");
  gui.endDrawing();
  return pbNilValue();
}

static PbValue guiSwapScreenBuffer(PbVM *vm, int argCount,
                                   const PbValue *args, void *userData)
{
  (void)args;
  (void)userData;
  if (argCount != 0)
    return guiError(vm, "swapScreenBuffer() takes no arguments.");
  gui.swapScreenBuffer();
  return pbNilValue();
}

static PbValue guiDrawPixel(PbVM *vm, int argCount,
                            const PbValue *args, void *userData)
{
  (void)userData;
  if (argCount != 5 || !allNumbers(args, 5))
    return guiError(vm, "drawPixel(x, y, r, g, b) expected.");
  gui.drawPixel((int)args[0].as.number, (int)args[1].as.number,
                (int)args[2].as.number, (int)args[3].as.number,
                (int)args[4].as.number);
  return pbNilValue();
}

static PbValue guiDrawLine(PbVM *vm, int argCount,
                           const PbValue *args, void *userData)
{
  (void)userData;
  if (argCount != 7 || !allNumbers(args, 7))
    return guiError(vm, "drawLine(x1, y1, x2, y2, r, g, b) expected.");
  gui.drawLine((int)args[0].as.number, (int)args[1].as.number,
               (int)args[2].as.number, (int)args[3].as.number,
               (int)args[4].as.number, (int)args[5].as.number,
               (int)args[6].as.number);
  return pbNilValue();
}

static PbValue guiDrawCircle(PbVM *vm, int argCount,
                             const PbValue *args, void *userData)
{
  (void)userData;
  if (argCount != 6 || !allNumbers(args, 6))
    return guiError(vm, "drawCircle(x, y, radius, r, g, b) expected.");
  gui.drawCircle((int)args[0].as.number, (int)args[1].as.number,
                 (float)args[2].as.number, (int)args[3].as.number,
                 (int)args[4].as.number, (int)args[5].as.number);
  return pbNilValue();
}

static PbValue guiDrawEllipse(PbVM *vm, int argCount,
                              const PbValue *args, void *userData)
{
  (void)userData;
  if (argCount != 7 || !allNumbers(args, 7))
    return guiError(vm,
                    "drawEllipse(x, y, radiusH, radiusV, r, g, b) expected.");
  gui.drawEllipse((int)args[0].as.number, (int)args[1].as.number,
                  (float)args[2].as.number, (float)args[3].as.number,
                  (int)args[4].as.number, (int)args[5].as.number,
                  (int)args[6].as.number);
  return pbNilValue();
}

static PbValue guiDrawRectangle(PbVM *vm, int argCount,
                                const PbValue *args, void *userData)
{
  (void)userData;
  if (argCount != 7 || !allNumbers(args, 7))
    return guiError(
        vm, "drawRectangle(x, y, width, height, r, g, b) expected.");
  gui.drawRectangle((int)args[0].as.number, (int)args[1].as.number,
                    (int)args[2].as.number, (int)args[3].as.number,
                    (int)args[4].as.number, (int)args[5].as.number,
                    (int)args[6].as.number);
  return pbNilValue();
}

static PbValue guiDrawText(PbVM *vm, int argCount,
                           const PbValue *args, void *userData)
{
  (void)userData;
  if (argCount != 7 || args[0].type != PB_VALUE_STRING ||
      !allNumbers(args + 1, 6))
    return guiError(vm,
                    "drawText(text, x, y, fontSize, r, g, b) expected.");
  gui.drawText(args[0].as.string.chars, (int)args[1].as.number,
               (int)args[2].as.number, (int)args[3].as.number,
               (int)args[4].as.number, (int)args[5].as.number,
               (int)args[6].as.number);
  return pbNilValue();
}

static PbValue keyQuery(PbVM *vm, int argCount, const PbValue *args,
                        bool (*query)(int), const char *usage)
{
  if (argCount != 1 || args[0].type != PB_VALUE_STRING)
    return guiError(vm, usage);
  int key = getKeyCode(args[0].as.string.chars);
  if (key < 0)
  {
    char message[512];
    snprintf(message, sizeof(message), "Invalid key name: %s.",
             args[0].as.string.chars);
    return guiError(vm, message);
  }
  return pbBoolValue(query(key));
}

static PbValue guiIsKeyPressed(PbVM *vm, int argCount,
                               const PbValue *args, void *userData)
{
  (void)userData;
  return keyQuery(vm, argCount, args, gui.isKeyPressed,
                  "isKeyPressed(string keyName) expected.");
}

static PbValue guiIsKeyReleased(PbVM *vm, int argCount,
                                const PbValue *args, void *userData)
{
  (void)userData;
  return keyQuery(vm, argCount, args, gui.isKeyReleased,
                  "isKeyReleased(string keyName) expected.");
}

static PbValue guiIsKeyUp(PbVM *vm, int argCount,
                          const PbValue *args, void *userData)
{
  (void)userData;
  return keyQuery(vm, argCount, args, gui.isKeyUp,
                  "isKeyUp(string keyName) expected.");
}

static PbValue guiGetKeyPressed(PbVM *vm, int argCount,
                                const PbValue *args, void *userData)
{
  (void)args;
  (void)userData;
  if (argCount != 0)
    return guiError(vm, "getKeyPressed() takes no arguments.");
  return pbNumberValue(gui.getKeyPressed());
}

static PbValue guiGetCharPressed(PbVM *vm, int argCount,
                                 const PbValue *args, void *userData)
{
  (void)args;
  (void)userData;
  if (argCount != 0)
    return guiError(vm, "getCharPressed() takes no arguments.");
  return pbNumberValue(gui.getCharPressed());
}

static PbValue guiSetExitKey(PbVM *vm, int argCount,
                             const PbValue *args, void *userData)
{
  (void)userData;
  if (argCount != 1 || !allNumbers(args, 1))
    return guiError(vm, "setExitKey(key) expected.");
  gui.setExitKey((int)args[0].as.number);
  return pbNilValue();
}

static PbValue mouseQuery(PbVM *vm, int argCount, const PbValue *args,
                          bool (*query)(int), const char *usage)
{
  if (argCount != 1 || args[0].type != PB_VALUE_STRING)
    return guiError(vm, usage);
  int button = getMouseButtonCode(args[0].as.string.chars);
  if (button < 0)
  {
    char message[512];
    snprintf(message, sizeof(message), "Invalid mouse button name: %s.",
             args[0].as.string.chars);
    return guiError(vm, message);
  }
  return pbBoolValue(query(button));
}

static PbValue guiIsMouseButtonPressed(PbVM *vm, int argCount,
                                       const PbValue *args, void *userData)
{
  (void)userData;
  return mouseQuery(vm, argCount, args, gui.isMouseButtonPressed,
                    "isMouseButtonPressed(string buttonName) expected.");
}

static PbValue guiIsMouseButtonDown(PbVM *vm, int argCount,
                                    const PbValue *args, void *userData)
{
  (void)userData;
  return mouseQuery(vm, argCount, args, gui.isMouseButtonDown,
                    "isMouseButtonDown(string buttonName) expected.");
}

static PbValue guiIsMouseButtonReleased(PbVM *vm, int argCount,
                                        const PbValue *args, void *userData)
{
  (void)userData;
  return mouseQuery(vm, argCount, args, gui.isMouseButtonReleased,
                    "isMouseButtonReleased(string buttonName) expected.");
}

static PbValue guiIsMouseButtonUp(PbVM *vm, int argCount,
                                  const PbValue *args, void *userData)
{
  (void)userData;
  return mouseQuery(vm, argCount, args, gui.isMouseButtonUp,
                    "isMouseButtonUp(string buttonName) expected.");
}

static PbValue guiGetMouseX(PbVM *vm, int argCount,
                            const PbValue *args, void *userData)
{
  (void)args;
  (void)userData;
  if (argCount != 0)
    return guiError(vm, "getMouseX() takes no arguments.");
  return pbNumberValue(gui.getMouseX());
}

static PbValue guiGetMouseY(PbVM *vm, int argCount,
                            const PbValue *args, void *userData)
{
  (void)args;
  (void)userData;
  if (argCount != 0)
    return guiError(vm, "getMouseY() takes no arguments.");
  return pbNumberValue(gui.getMouseY());
}

static bool openGuiLibrary(void)
{
  const char *overridePath = getenv("PB_GUI_LIBRARY");
#ifdef _WIN32
  if (overridePath != NULL && overridePath[0] != '\0')
    guiLibrary = LoadLibraryA(overridePath);
  else
  {
    guiLibrary = LoadLibraryA("lib\\pb_gui_windows.dll");
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
          int written = snprintf(path, sizeof(path),
                                 "%s\\lib\\pb_gui_windows.dll", executable);
          if (written > 0 && (size_t)written < sizeof(path))
            guiLibrary = LoadLibraryA(path);
        }
      }
    }
  }
#else
  if (overridePath != NULL && overridePath[0] != '\0')
    guiLibrary = dlopen(overridePath, RTLD_NOW | RTLD_LOCAL);
  else
  {
    const char *paths[] = {
        "lib/pb_gui_linux.so",
        "$ORIGIN/../lib/pb_gui_linux.so",
        "$ORIGIN/../lib/pb/pb_gui_linux.so",
    };
    for (size_t i = 0;
         i < sizeof(paths) / sizeof(paths[0]) && guiLibrary == NULL; i++)
      guiLibrary = dlopen(paths[i], RTLD_NOW | RTLD_LOCAL);
  }
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

static bool loadGui(PbVM *vm)
{
  if (guiLoaded)
    return true;

  if (!openGuiLibrary())
  {
    char message[1024];
#ifdef _WIN32
    snprintf(message, sizeof(message),
             "Could not load PB GUI library (Windows error %lu).",
             (unsigned long)GetLastError());
#else
    const char *error = dlerror();
    snprintf(message, sizeof(message), "Could not load PB GUI library: %s.",
             error != NULL ? error : "unknown loader error");
#endif
    pbRuntimeError(vm, message);
    return false;
  }

#define LOAD_GUI_SYMBOL(field, type, symbol, callback)                      \
  do                                                                        \
  {                                                                         \
    GuiSymbol loadedSymbol = loadGuiSymbol(symbol);                          \
    if (loadedSymbol == NULL)                                                \
    {                                                                       \
      char message[256];                                                     \
      closeGuiLibrary();                                                     \
      memset(&gui, 0, sizeof(gui));                                          \
      snprintf(message, sizeof(message),                                     \
               "PB GUI library is missing symbol '%s'.", symbol);          \
      pbRuntimeError(vm, message);                                           \
      return false;                                                         \
    }                                                                       \
    _Static_assert(sizeof(gui.field) == sizeof(loadedSymbol),                \
                   "GUI function pointer size mismatch");                   \
    memcpy(&gui.field, &loadedSymbol, sizeof(gui.field));                    \
  } while (false);

  GUI_FUNCTIONS(LOAD_GUI_SYMBOL)
#undef LOAD_GUI_SYMBOL

  guiLoaded = true;
  return true;
}

#define GUI_NATIVE(field, type, symbol, callback) {symbol, callback, NULL},
static const PbNativeDefinition guiFunctions[] = {
    GUI_FUNCTIONS(GUI_NATIVE)
};
#undef GUI_NATIVE

bool registerGuiModule(PbVM *vm, const char *name)
{
  if (!loadGui(vm))
    return false;

  size_t count = sizeof(guiFunctions) / sizeof(guiFunctions[0]);
  if (!pbRegisterCapability(vm, name, guiFunctions, count))
  {
    if (guiUsers == 0)
    {
      closeGuiLibrary();
      memset(&gui, 0, sizeof(gui));
      guiLoaded = false;
    }
    return false;
  }
  guiUsers++;
  return true;
}

void releaseGuiModule(void)
{
  if (guiUsers == 0)
    return;
  guiUsers--;
  if (guiUsers != 0)
    return;
  closeGuiLibrary();
  memset(&gui, 0, sizeof(gui));
  guiLoaded = false;
}
