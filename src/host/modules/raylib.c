#include <float.h>
#include <limits.h>
#include <math.h>
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

#include "host/modules/raylib.h"

typedef void (*InitWindowFn)(int, int, const char *);
typedef void (*CloseWindowFn)(void);
typedef bool (*WindowShouldCloseFn)(void);
typedef bool (*IsWindowMinimizedFn)(void);
typedef bool (*IsWindowFocusedFn)(void);
typedef bool (*IsWindowResizedFn)(void);
typedef void (*ToggleFullscreenFn)(void);
typedef void (*ToggleBorderlessWindowedFn)(void);
typedef void (*SetWindowTitleFn)(const char *);
typedef int (*GetScreenWidthFn)(void);
typedef int (*GetScreenHeightFn)(void);
typedef int (*GetFPSFn)(void);
typedef float (*GetFrameTimeFn)(void);
typedef void (*SetTargetFPSFn)(int);
typedef void (*ClearBackgroundFn)(int, int, int);
typedef void (*BeginDrawingFn)(void);
typedef void (*EndDrawingFn)(void);
typedef void (*DrawPixelFn)(int, int, int, int, int);
typedef void (*DrawLineFn)(int, int, int, int, int, int, int);
typedef void (*DrawCircleFn)(int, int, float, int, int, int);
typedef void (*DrawCircleLinesFn)(int, int, float, int, int, int);
typedef void (*DrawCircleAlphaFn)(int, int, float, int, int, int, int);
typedef void (*DrawEllipseFn)(int, int, float, float, int, int, int);
typedef void (*DrawRectangleFn)(int, int, int, int, int, int, int);
typedef void (*DrawRectangleLinesFn)(int, int, int, int, int, int, int);
typedef void (*DrawRectangleAlphaFn)(int, int, int, int, int, int, int, int);
typedef void (*DrawRectangleRoundedFn)(float, float, float, float, float, int, int, int, int);
typedef void (*DrawTextFn)(const char *, int, int, int, int, int, int);
typedef int (*MeasureTextFn)(const char *, int);
typedef void (*DrawFPSFn)(int, int);
typedef double (*GetTimeFn)(void);
typedef void (*SetWindowSizeFn)(int, int);
typedef void (*SetWindowPositionFn)(int, int);
typedef bool (*IsWindowFullscreenFn)(void);
typedef bool (*IsWindowMaximizedFn)(void);
typedef void (*MaximizeWindowFn)(void);
typedef void (*RestoreWindowFn)(void);
typedef void (*HideCursorFn)(void);
typedef void (*ShowCursorFn)(void);
typedef bool (*IsKeyPressedFn)(int);
typedef bool (*IsKeyDownFn)(int);
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
typedef float (*GetMouseWheelMoveFn)(void);
typedef bool (*CheckCollisionRecsFn)(float, float, float, float, float, float, float, float);
typedef bool (*CheckCollisionCirclesFn)(float, float, float, float, float, float);
typedef bool (*CheckCollisionCircleRecFn)(float, float, float, float, float, float, float);
typedef bool (*CheckCollisionPointRecFn)(float, float, float, float, float, float);
typedef bool (*CheckCollisionPointCircleFn)(float, float, float, float, float);

/* Sprites & Textures */
typedef int (*LoadTextureFn)(const char *);
typedef void (*UnloadTextureFn)(int);
typedef void (*DrawTextureFn)(int, int, int);
typedef void (*DrawTextureTintFn)(int, int, int, int, int, int);
typedef void (*DrawTextureRecFn)(int, float, float, float, float, float, float);
typedef void (*DrawTextureProFn)(int, float, float, float, float, float, float, float, float, float, float, float);
typedef int (*GetTextureWidthFn)(int);
typedef int (*GetTextureHeightFn)(int);

/* Audio */
typedef void (*InitAudioFn)(void);
typedef void (*CloseAudioFn)(void);
typedef int (*LoadSoundFn)(const char *);
typedef void (*UnloadSoundFn)(int);
typedef void (*PlaySoundFn)(int);
typedef void (*StopSoundFn)(int);
typedef void (*SetSoundVolumeFn)(int, float);
typedef void (*SetSoundPitchFn)(int, float);
typedef bool (*IsSoundPlayingFn)(int);
typedef void (*SetMasterVolumeFn)(float);
typedef int (*LoadMusicFn)(const char *);
typedef void (*UnloadMusicFn)(int);
typedef void (*PlayMusicFn)(int);
typedef void (*PauseMusicFn)(int);
typedef void (*ResumeMusicFn)(int);
typedef void (*StopMusicFn)(int);
typedef void (*UpdateMusicFn)(int);
typedef void (*SetMusicVolumeFn)(int, float);
typedef bool (*IsMusicStreamPlayingFn)(int);
typedef void (*SetVirtualResolutionFn)(int, int);
typedef int (*GetRenderWidthFn)(void);
typedef int (*GetRenderHeightFn)(void);

#define RAYLIB_BASE_FUNCTIONS(X) \
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
  X(drawPixel, DrawPixelFn, "drawPixel", guiDrawPixel) \
  X(drawLine, DrawLineFn, "drawLine", guiDrawLine) \
  X(drawCircle, DrawCircleFn, "drawCircle", guiDrawCircle) \
  X(drawEllipse, DrawEllipseFn, "drawEllipse", guiDrawEllipse) \
  X(drawRectangle, DrawRectangleFn, "drawRectangle", guiDrawRectangle) \
  X(drawText, DrawTextFn, "drawText", guiDrawText) \
  X(isKeyPressed, IsKeyPressedFn, "isKeyPressed", guiIsKeyPressed) \
  X(isKeyDown, IsKeyDownFn, "isKeyDown", guiIsKeyDown) \
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

#define RAYLIB_EXTENDED_FUNCTIONS(X) \
  X(isWindowFocused, IsWindowFocusedFn, "isWindowFocused", guiIsWindowFocused) \
  X(isWindowResized, IsWindowResizedFn, "isWindowResized", guiIsWindowResized) \
  X(toggleFullscreen, ToggleFullscreenFn, "toggleFullscreen", guiToggleFullscreen) \
  X(setWindowTitle, SetWindowTitleFn, "setWindowTitle", guiSetWindowTitle) \
  X(getFrameTime, GetFrameTimeFn, "getFrameTime", guiGetFrameTime) \
  X(drawCircleLines, DrawCircleLinesFn, "drawCircleLines", guiDrawCircleLines) \
  X(drawCircleAlpha, DrawCircleAlphaFn, "drawCircleAlpha", guiDrawCircleAlpha) \
  X(drawRectangleLines, DrawRectangleLinesFn, "drawRectangleLines", guiDrawRectangleLines) \
  X(drawRectangleAlpha, DrawRectangleAlphaFn, "drawRectangleAlpha", guiDrawRectangleAlpha) \
  X(drawRectangleRounded, DrawRectangleRoundedFn, "drawRectangleRounded", guiDrawRectangleRounded) \
  X(measureText, MeasureTextFn, "measureText", guiMeasureText) \
  X(getMouseWheelMove, GetMouseWheelMoveFn, "getMouseWheelMove", guiGetMouseWheelMove) \
  X(drawFPS, DrawFPSFn, "drawFPS", guiDrawFPS) \
  X(getTime, GetTimeFn, "getTime", guiGetTime) \
  X(setWindowSize, SetWindowSizeFn, "setWindowSize", guiSetWindowSize) \
  X(setWindowPosition, SetWindowPositionFn, "setWindowPosition", guiSetWindowPosition) \
  X(isWindowFullscreen, IsWindowFullscreenFn, "isWindowFullscreen", guiIsWindowFullscreen) \
  X(isWindowMaximized, IsWindowMaximizedFn, "isWindowMaximized", guiIsWindowMaximized) \
  X(maximizeWindow, MaximizeWindowFn, "maximizeWindow", guiMaximizeWindow) \
  X(restoreWindow, RestoreWindowFn, "restoreWindow", guiRestoreWindow) \
  X(hideCursor, HideCursorFn, "hideCursor", guiHideCursor) \
  X(showCursor, ShowCursorFn, "showCursor", guiShowCursor) \
  X(checkCollisionRecs, CheckCollisionRecsFn, "checkCollisionRecs", guiCheckCollisionRecs) \
  X(checkCollisionCircles, CheckCollisionCirclesFn, "checkCollisionCircles", guiCheckCollisionCircles) \
  X(checkCollisionCircleRec, CheckCollisionCircleRecFn, "checkCollisionCircleRec", guiCheckCollisionCircleRec) \
  X(checkCollisionPointRec, CheckCollisionPointRecFn, "checkCollisionPointRec", guiCheckCollisionPointRec) \
  X(checkCollisionPointCircle, CheckCollisionPointCircleFn, "checkCollisionPointCircle", guiCheckCollisionPointCircle) \
  X(loadTexture, LoadTextureFn, "loadTexture", guiLoadTexture) \
  X(unloadTexture, UnloadTextureFn, "unloadTexture", guiUnloadTexture) \
  X(drawTexture, DrawTextureFn, "drawTexture", guiDrawTexture) \
  X(drawTextureTint, DrawTextureTintFn, "drawTextureTint", guiDrawTextureTint) \
  X(drawTextureRec, DrawTextureRecFn, "drawTextureRec", guiDrawTextureRec) \
  X(drawTexturePro, DrawTextureProFn, "drawTexturePro", guiDrawTexturePro) \
  X(getTextureWidth, GetTextureWidthFn, "getTextureWidth", guiGetTextureWidth) \
  X(getTextureHeight, GetTextureHeightFn, "getTextureHeight", guiGetTextureHeight) \
  X(initAudio, InitAudioFn, "initAudio", guiInitAudio) \
  X(closeAudio, CloseAudioFn, "closeAudio", guiCloseAudio) \
  X(loadSound, LoadSoundFn, "loadSound", guiLoadSound) \
  X(unloadSound, UnloadSoundFn, "unloadSound", guiUnloadSound) \
  X(playSound, PlaySoundFn, "playSound", guiPlaySound) \
  X(stopSound, StopSoundFn, "stopSound", guiStopSound) \
  X(setSoundVolume, SetSoundVolumeFn, "setSoundVolume", guiSetSoundVolume) \
  X(setSoundPitch, SetSoundPitchFn, "setSoundPitch", guiSetSoundPitch) \
  X(isSoundPlaying, IsSoundPlayingFn, "isSoundPlaying", guiIsSoundPlaying) \
  X(setMasterVolume, SetMasterVolumeFn, "setMasterVolume", guiSetMasterVolume) \
  X(loadMusic, LoadMusicFn, "loadMusic", guiLoadMusic) \
  X(unloadMusic, UnloadMusicFn, "unloadMusic", guiUnloadMusic) \
  X(playMusic, PlayMusicFn, "playMusic", guiPlayMusic) \
  X(pauseMusic, PauseMusicFn, "pauseMusic", guiPauseMusic) \
  X(resumeMusic, ResumeMusicFn, "resumeMusic", guiResumeMusic) \
  X(stopMusic, StopMusicFn, "stopMusic", guiStopMusic) \
  X(updateMusic, UpdateMusicFn, "updateMusic", guiUpdateMusic) \
  X(setMusicVolume, SetMusicVolumeFn, "setMusicVolume", guiSetMusicVolume) \
  X(isMusicStreamPlaying, IsMusicStreamPlayingFn, "isMusicStreamPlaying", guiIsMusicStreamPlaying) \
  X(setVirtualResolution, SetVirtualResolutionFn, "setVirtualResolution", guiSetVirtualResolution) \
  X(getRenderWidth, GetRenderWidthFn, "getRenderWidth", guiGetRenderWidth) \
  X(getRenderHeight, GetRenderHeightFn, "getRenderHeight", guiGetRenderHeight)

#define RAYLIB_FUNCTIONS(X) \
  RAYLIB_BASE_FUNCTIONS(X) \
  RAYLIB_EXTENDED_FUNCTIONS(X)

#define RAYLIB_FIELD(field, type, symbol, callback) type field;
typedef struct {
  RAYLIB_FUNCTIONS(RAYLIB_FIELD)
} RaylibApi;
#undef RAYLIB_FIELD

#ifdef _WIN32
static HMODULE raylibLibrary = NULL;
typedef FARPROC RaylibSymbol;
#else
static void *raylibLibrary = NULL;
typedef void *RaylibSymbol;
#endif

typedef struct {
  const char *name;
  int code;
} NameCode;

static RaylibApi raylib;
static bool raylibLoaded = false;
static size_t raylibUsers = 0;

static const NameCode keyCodes[] = {
    {"KEY_APOSTROPHE", 39},
    {"KEY_COMMA", 44},
    {"KEY_MINUS", 45},
    {"KEY_PERIOD", 46},
    {"KEY_SLASH", 47},
    {"KEY_SEMICOLON", 59},
    {"KEY_ZERO", 48},
    {"KEY_ONE", 49},
    {"KEY_TWO", 50},
    {"KEY_THREE", 51},
    {"KEY_FOUR", 52},
    {"KEY_FIVE", 53},
    {"KEY_SIX", 54},
    {"KEY_SEVEN", 55},
    {"KEY_EIGHT", 56},
    {"KEY_NINE", 57},
    {"KEY_EQUAL", 61},
    {"KEY_A", 65},
    {"KEY_B", 66},
    {"KEY_C", 67},
    {"KEY_D", 68},
    {"KEY_E", 69},
    {"KEY_F", 70},
    {"KEY_G", 71},
    {"KEY_H", 72},
    {"KEY_I", 73},
    {"KEY_J", 74},
    {"KEY_K", 75},
    {"KEY_L", 76},
    {"KEY_M", 77},
    {"KEY_N", 78},
    {"KEY_O", 79},
    {"KEY_P", 80},
    {"KEY_Q", 81},
    {"KEY_R", 82},
    {"KEY_S", 83},
    {"KEY_T", 84},
    {"KEY_U", 85},
    {"KEY_V", 86},
    {"KEY_W", 87},
    {"KEY_X", 88},
    {"KEY_Y", 89},
    {"KEY_Z", 90},
    {"KEY_LEFT_BRACKET", 91},
    {"KEY_BACKSLASH", 92},
    {"KEY_RIGHT_BRACKET", 93},
    {"KEY_GRAVE", 96},
    {"KEY_SPACE", 32},
    {"KEY_ESCAPE", 256},
    {"KEY_ENTER", 257},
    {"KEY_TAB", 258},
    {"KEY_BACKSPACE", 259},
    {"KEY_INSERT", 260},
    {"KEY_DELETE", 261},
    {"KEY_RIGHT", 262},
    {"KEY_LEFT", 263},
    {"KEY_DOWN", 264},
    {"KEY_UP", 265},
    {"KEY_PAGE_UP", 266},
    {"KEY_PAGE_DOWN", 267},
    {"KEY_HOME", 268},
    {"KEY_END", 269},
    {"KEY_CAPS_LOCK", 280},
    {"KEY_SCROLL_LOCK", 281},
    {"KEY_NUM_LOCK", 282},
    {"KEY_PRINT_SCREEN", 283},
    {"KEY_PAUSE", 284},
    {"KEY_F1", 290},
    {"KEY_F2", 291},
    {"KEY_F3", 292},
    {"KEY_F4", 293},
    {"KEY_F5", 294},
    {"KEY_F6", 295},
    {"KEY_F7", 296},
    {"KEY_F8", 297},
    {"KEY_F9", 298},
    {"KEY_F10", 299},
    {"KEY_F11", 300},
    {"KEY_F12", 301},
    {"KEY_LEFT_SHIFT", 340},
    {"KEY_LEFT_CONTROL", 341},
    {"KEY_LEFT_ALT", 342},
    {"KEY_LEFT_SUPER", 343},
    {"KEY_RIGHT_SHIFT", 344},
    {"KEY_RIGHT_CONTROL", 345},
    {"KEY_RIGHT_ALT", 346},
    {"KEY_RIGHT_SUPER", 347},
    {"KEY_KB_MENU", 348},
    {"KEY_KP_0", 320},
    {"KEY_KP_1", 321},
    {"KEY_KP_2", 322},
    {"KEY_KP_3", 323},
    {"KEY_KP_4", 324},
    {"KEY_KP_5", 325},
    {"KEY_KP_6", 326},
    {"KEY_KP_7", 327},
    {"KEY_KP_8", 328},
    {"KEY_KP_9", 329},
    {"KEY_KP_DECIMAL", 330},
    {"KEY_KP_DIVIDE", 331},
    {"KEY_KP_MULTIPLY", 332},
    {"KEY_KP_SUBTRACT", 333},
    {"KEY_KP_ADD", 334},
    {"KEY_KP_ENTER", 335},
    {"KEY_KP_EQUAL", 336},
};

static const NameCode mouseButtonCodes[] = {
    {"LEFT", 0}, {"RIGHT", 1}, {"MIDDLE", 2}, {"SIDE", 3}, {"EXTRA", 4}, {"FORWARD", 5}, {"BACK", 6},
};

static int findCode(const NameCode *table, size_t count, const char *name) {
  for (size_t i = 0; i < count; i++) {
    if (strcmp(table[i].name, name) == 0) return table[i].code;
  }
  return -1;
}

static int getKeyCode(const char *name) { return findCode(keyCodes, sizeof(keyCodes) / sizeof(keyCodes[0]), name); }

static int getMouseButtonCode(const char *name) {
  return findCode(mouseButtonCodes, sizeof(mouseButtonCodes) / sizeof(mouseButtonCodes[0]), name);
}

static bool isFiniteNumber(double value) { return !isnan(value) && !isinf(value); }

static bool fitsInt(double value) {
  return isFiniteNumber(value) && floor(value) == value && value >= INT_MIN && value <= INT_MAX;
}

static bool fitsFloat(double value) { return isFiniteNumber(value) && value >= -FLT_MAX && value <= FLT_MAX; }

static bool numbersFitInt(const PbValue *values, int count) {
  for (int i = 0; i < count; i++) {
    if (values[i].type != PB_VALUE_NUMBER || !fitsInt(values[i].as.number)) return false;
  }
  return true;
}

static bool numberFitsFloat(PbValue value) { return value.type == PB_VALUE_NUMBER && fitsFloat(value.as.number); }

static bool numbersFitFloat(const PbValue *values, int count) {
  for (int i = 0; i < count; i++) {
    if (!numberFitsFloat(values[i])) return false;
  }
  return true;
}

static bool fitsCoord(double value) { return isFiniteNumber(value) && value >= -1e8 && value <= 1e8; }

static bool numbersFitCoord(const PbValue *values, int count) {
  for (int i = 0; i < count; i++) {
    if (values[i].type != PB_VALUE_NUMBER || !fitsCoord(values[i].as.number)) return false;
  }
  return true;
}

static bool validColor(const PbValue *values) {
  for (int i = 0; i < 3; i++) {
    if (values[i].type != PB_VALUE_NUMBER || !isFiniteNumber(values[i].as.number) || values[i].as.number < 0 ||
        values[i].as.number > 255)
      return false;
  }
  return true;
}

static bool validColorAlpha(const PbValue *values) {
  for (int i = 0; i < 4; i++) {
    if (values[i].type != PB_VALUE_NUMBER || !isFiniteNumber(values[i].as.number) || values[i].as.number < 0 ||
        values[i].as.number > 255)
      return false;
  }
  return true;
}

static PbValue guiError(PbVM *vm, const char *message) {
  pbRuntimeError(vm, message);
  return pbNilValue();
}

static PbValue missingRaylibFunction(PbVM *vm, const char *name) {
  char message[256];
  snprintf(message, sizeof(message), "The installed Raylib backend does not provide %s().", name);
  return guiError(vm, message);
}

static PbValue guiInitWindow(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 3 || !numbersFitInt(args, 2) || args[0].as.number <= 0 || args[1].as.number <= 0 ||
      args[2].type != PB_VALUE_STRING)
    return guiError(vm, "initWindow(width, height, title) expected.");
  raylib.initWindow((int)args[0].as.number, (int)args[1].as.number, args[2].as.string.chars);
  return pbNilValue();
}

static PbValue guiCloseWindow(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "closeWindow() takes no arguments.");
  raylib.closeWindow();
  return pbNilValue();
}

static PbValue guiWindowShouldClose(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "windowShouldClose() takes no arguments.");
  return pbBoolValue(raylib.windowShouldClose());
}

static PbValue guiIsWindowMinimized(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "isWindowMinimized() takes no arguments.");
  return pbBoolValue(raylib.isWindowMinimized());
}

static PbValue guiIsWindowFocused(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "isWindowFocused() takes no arguments.");
  if (raylib.isWindowFocused == NULL) return missingRaylibFunction(vm, "isWindowFocused");
  return pbBoolValue(raylib.isWindowFocused());
}

static PbValue guiIsWindowResized(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "isWindowResized() takes no arguments.");
  if (raylib.isWindowResized == NULL) return missingRaylibFunction(vm, "isWindowResized");
  return pbBoolValue(raylib.isWindowResized());
}

static PbValue guiToggleFullscreen(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "toggleFullscreen() takes no arguments.");
  if (raylib.toggleFullscreen == NULL) return missingRaylibFunction(vm, "toggleFullscreen");
  raylib.toggleFullscreen();
  return pbNilValue();
}

static PbValue guiToggleBorderlessWindowed(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "toggleBorderlessWindowed() takes no arguments.");
  raylib.toggleBorderlessWindowed();
  return pbNilValue();
}

static PbValue guiSetWindowTitle(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_STRING) return guiError(vm, "setWindowTitle(title) expected.");
  if (raylib.setWindowTitle == NULL) return missingRaylibFunction(vm, "setWindowTitle");
  raylib.setWindowTitle(args[0].as.string.chars);
  return pbNilValue();
}

static PbValue guiGetScreenWidth(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "getScreenWidth() takes no arguments.");
  return pbNumberValue(raylib.getScreenWidth());
}

static PbValue guiGetScreenHeight(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "getScreenHeight() takes no arguments.");
  return pbNumberValue(raylib.getScreenHeight());
}

static PbValue guiGetFPS(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "getFPS() takes no arguments.");
  return pbNumberValue(raylib.getFPS());
}

static PbValue guiGetFrameTime(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "getFrameTime() takes no arguments.");
  if (raylib.getFrameTime == NULL) return missingRaylibFunction(vm, "getFrameTime");
  return pbNumberValue(raylib.getFrameTime());
}

static PbValue guiSetTargetFPS(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1) || args[0].as.number < 0)
    return guiError(vm, "setTargetFPS(fps) expected.");
  raylib.setTargetFPS((int)args[0].as.number);
  return pbNilValue();
}

static PbValue guiClearBackground(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 3 || !validColor(args)) return guiError(vm, "clearBackground(r, g, b) expected.");
  raylib.clearBackground((int)args[0].as.number, (int)args[1].as.number, (int)args[2].as.number);
  return pbNilValue();
}

static PbValue guiBeginDrawing(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "beginDrawing() takes no arguments.");
  raylib.beginDrawing();
  return pbNilValue();
}

static PbValue guiEndDrawing(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "endDrawing() takes no arguments.");
  raylib.endDrawing();
  return pbNilValue();
}

static PbValue guiDrawPixel(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 5 || !numbersFitCoord(args, 2) || !validColor(args + 2))
    return guiError(vm, "drawPixel(x, y, r, g, b) expected.");
  raylib.drawPixel((int)args[0].as.number, (int)args[1].as.number, (int)args[2].as.number, (int)args[3].as.number,
                   (int)args[4].as.number);
  return pbNilValue();
}

static PbValue guiDrawLine(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 7 || !numbersFitCoord(args, 4) || !validColor(args + 4))
    return guiError(vm, "drawLine(x1, y1, x2, y2, r, g, b) expected.");
  raylib.drawLine((int)args[0].as.number, (int)args[1].as.number, (int)args[2].as.number, (int)args[3].as.number,
                  (int)args[4].as.number, (int)args[5].as.number, (int)args[6].as.number);
  return pbNilValue();
}

static PbValue guiDrawCircle(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 6 || !numbersFitCoord(args, 2) || !numberFitsFloat(args[2]) || args[2].as.number < 0 ||
      !validColor(args + 3))
    return guiError(vm, "drawCircle(x, y, radius, r, g, b) expected.");
  raylib.drawCircle((int)args[0].as.number, (int)args[1].as.number, (float)args[2].as.number, (int)args[3].as.number,
                    (int)args[4].as.number, (int)args[5].as.number);
  return pbNilValue();
}

static PbValue guiDrawCircleLines(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 6 || !numbersFitCoord(args, 2) || !numberFitsFloat(args[2]) || args[2].as.number < 0 ||
      !validColor(args + 3))
    return guiError(vm, "drawCircleLines(x, y, radius, r, g, b) expected.");
  if (raylib.drawCircleLines == NULL) return missingRaylibFunction(vm, "drawCircleLines");
  raylib.drawCircleLines((int)args[0].as.number, (int)args[1].as.number, (float)args[2].as.number,
                         (int)args[3].as.number, (int)args[4].as.number, (int)args[5].as.number);
  return pbNilValue();
}

static PbValue guiDrawCircleAlpha(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 7 || !numbersFitCoord(args, 2) || !numberFitsFloat(args[2]) || args[2].as.number < 0 ||
      !validColorAlpha(args + 3))
    return guiError(vm, "drawCircleAlpha(x, y, radius, r, g, b, a) expected.");
  if (raylib.drawCircleAlpha == NULL) return missingRaylibFunction(vm, "drawCircleAlpha");
  raylib.drawCircleAlpha((int)args[0].as.number, (int)args[1].as.number, (float)args[2].as.number,
                         (int)args[3].as.number, (int)args[4].as.number, (int)args[5].as.number,
                         (int)args[6].as.number);
  return pbNilValue();
}

static PbValue guiDrawEllipse(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 7 || !numbersFitCoord(args, 2) || !numberFitsFloat(args[2]) || !numberFitsFloat(args[3]) ||
      args[2].as.number < 0 || args[3].as.number < 0 || !validColor(args + 4))
    return guiError(vm, "drawEllipse(x, y, radiusH, radiusV, r, g, b) expected.");
  raylib.drawEllipse((int)args[0].as.number, (int)args[1].as.number, (float)args[2].as.number, (float)args[3].as.number,
                     (int)args[4].as.number, (int)args[5].as.number, (int)args[6].as.number);
  return pbNilValue();
}

static PbValue guiDrawRectangle(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 7 || !numbersFitCoord(args, 4) || !validColor(args + 4))
    return guiError(vm, "drawRectangle(x, y, width, height, r, g, b) expected.");
  raylib.drawRectangle((int)args[0].as.number, (int)args[1].as.number, (int)args[2].as.number, (int)args[3].as.number,
                       (int)args[4].as.number, (int)args[5].as.number, (int)args[6].as.number);
  return pbNilValue();
}

static PbValue guiDrawRectangleLines(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 7 || !numbersFitCoord(args, 4) || !validColor(args + 4))
    return guiError(vm, "drawRectangleLines(x, y, width, height, r, g, b) expected.");
  if (raylib.drawRectangleLines == NULL) return missingRaylibFunction(vm, "drawRectangleLines");
  raylib.drawRectangleLines((int)args[0].as.number, (int)args[1].as.number, (int)args[2].as.number,
                            (int)args[3].as.number, (int)args[4].as.number, (int)args[5].as.number,
                            (int)args[6].as.number);
  return pbNilValue();
}

static PbValue guiDrawRectangleAlpha(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 8 || !numbersFitCoord(args, 4) || !validColorAlpha(args + 4))
    return guiError(vm, "drawRectangleAlpha(x, y, width, height, r, g, b, a) expected.");
  if (raylib.drawRectangleAlpha == NULL) return missingRaylibFunction(vm, "drawRectangleAlpha");
  raylib.drawRectangleAlpha((int)args[0].as.number, (int)args[1].as.number, (int)args[2].as.number,
                            (int)args[3].as.number, (int)args[4].as.number, (int)args[5].as.number,
                            (int)args[6].as.number, (int)args[7].as.number);
  return pbNilValue();
}

static PbValue guiDrawRectangleRounded(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 9 || !numbersFitFloat(args, 5) || !numbersFitInt(args + 5, 1) || args[4].as.number < 0.0 ||
      args[4].as.number > 1.0 || args[5].as.number <= 0 || !validColor(args + 6))
    return guiError(vm, "drawRectangleRounded(x, y, width, height, roundness, segments, r, g, b) expected.");
  if (raylib.drawRectangleRounded == NULL) return missingRaylibFunction(vm, "drawRectangleRounded");
  raylib.drawRectangleRounded((float)args[0].as.number, (float)args[1].as.number, (float)args[2].as.number,
                              (float)args[3].as.number, (float)args[4].as.number, (int)args[5].as.number,
                              (int)args[6].as.number, (int)args[7].as.number, (int)args[8].as.number);
  return pbNilValue();
}

static PbValue guiDrawText(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 7 || args[0].type != PB_VALUE_STRING || !numbersFitCoord(args + 1, 2) ||
      !numbersFitInt(args + 3, 1) || args[3].as.number <= 0 || !validColor(args + 4))
    return guiError(vm, "drawText(text, x, y, fontSize, r, g, b) expected.");
  raylib.drawText(args[0].as.string.chars, (int)args[1].as.number, (int)args[2].as.number, (int)args[3].as.number,
                  (int)args[4].as.number, (int)args[5].as.number, (int)args[6].as.number);
  return pbNilValue();
}

static PbValue guiMeasureText(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || args[0].type != PB_VALUE_STRING || !numbersFitInt(args + 1, 1) || args[1].as.number <= 0)
    return guiError(vm, "measureText(text, fontSize) expected.");
  if (raylib.measureText == NULL) return missingRaylibFunction(vm, "measureText");
  return pbNumberValue(raylib.measureText(args[0].as.string.chars, (int)args[1].as.number));
}

static PbValue guiDrawFPS(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || !numbersFitCoord(args, 2)) return guiError(vm, "drawFPS(x, y) expected.");
  if (raylib.drawFPS == NULL) return missingRaylibFunction(vm, "drawFPS");
  raylib.drawFPS((int)args[0].as.number, (int)args[1].as.number);
  return pbNilValue();
}

static PbValue guiGetTime(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "getTime() takes no arguments.");
  if (raylib.getTime == NULL) return missingRaylibFunction(vm, "getTime");
  return pbNumberValue(raylib.getTime());
}

static PbValue guiSetWindowSize(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || !numbersFitInt(args, 2) || args[0].as.number <= 0 || args[1].as.number <= 0)
    return guiError(vm, "setWindowSize(width, height) expected.");
  if (raylib.setWindowSize == NULL) return missingRaylibFunction(vm, "setWindowSize");
  raylib.setWindowSize((int)args[0].as.number, (int)args[1].as.number);
  return pbNilValue();
}

static PbValue guiSetWindowPosition(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || !numbersFitInt(args, 2)) return guiError(vm, "setWindowPosition(x, y) expected.");
  if (raylib.setWindowPosition == NULL) return missingRaylibFunction(vm, "setWindowPosition");
  raylib.setWindowPosition((int)args[0].as.number, (int)args[1].as.number);
  return pbNilValue();
}

static PbValue guiIsWindowFullscreen(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "isWindowFullscreen() takes no arguments.");
  if (raylib.isWindowFullscreen == NULL) return missingRaylibFunction(vm, "isWindowFullscreen");
  return pbBoolValue(raylib.isWindowFullscreen());
}

static PbValue guiIsWindowMaximized(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "isWindowMaximized() takes no arguments.");
  if (raylib.isWindowMaximized == NULL) return missingRaylibFunction(vm, "isWindowMaximized");
  return pbBoolValue(raylib.isWindowMaximized());
}

static PbValue guiMaximizeWindow(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "maximizeWindow() takes no arguments.");
  if (raylib.maximizeWindow == NULL) return missingRaylibFunction(vm, "maximizeWindow");
  raylib.maximizeWindow();
  return pbNilValue();
}

static PbValue guiRestoreWindow(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "restoreWindow() takes no arguments.");
  if (raylib.restoreWindow == NULL) return missingRaylibFunction(vm, "restoreWindow");
  raylib.restoreWindow();
  return pbNilValue();
}

static PbValue guiHideCursor(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "hideCursor() takes no arguments.");
  if (raylib.hideCursor == NULL) return missingRaylibFunction(vm, "hideCursor");
  raylib.hideCursor();
  return pbNilValue();
}

static PbValue guiShowCursor(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "showCursor() takes no arguments.");
  if (raylib.showCursor == NULL) return missingRaylibFunction(vm, "showCursor");
  raylib.showCursor();
  return pbNilValue();
}

static PbValue keyQuery(PbVM *vm, int argCount, const PbValue *args, bool (*query)(int), const char *usage) {
  if (argCount != 1 || args[0].type != PB_VALUE_STRING) return guiError(vm, usage);
  int key = getKeyCode(args[0].as.string.chars);
  if (key < 0) {
    char message[512];
    snprintf(message, sizeof(message), "Invalid key name: %s.", args[0].as.string.chars);
    return guiError(vm, message);
  }
  return pbBoolValue(query(key));
}

static PbValue guiIsKeyPressed(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  return keyQuery(vm, argCount, args, raylib.isKeyPressed, "isKeyPressed(string keyName) expected.");
}

static PbValue guiIsKeyDown(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  return keyQuery(vm, argCount, args, raylib.isKeyDown, "isKeyDown(string keyName) expected.");
}

static PbValue guiIsKeyReleased(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  return keyQuery(vm, argCount, args, raylib.isKeyReleased, "isKeyReleased(string keyName) expected.");
}

static PbValue guiIsKeyUp(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  return keyQuery(vm, argCount, args, raylib.isKeyUp, "isKeyUp(string keyName) expected.");
}

static PbValue guiGetKeyPressed(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "getKeyPressed() takes no arguments.");
  return pbNumberValue(raylib.getKeyPressed());
}

static PbValue guiGetCharPressed(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "getCharPressed() takes no arguments.");
  return pbNumberValue(raylib.getCharPressed());
}

static PbValue guiSetExitKey(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "setExitKey(key) expected.");
  raylib.setExitKey((int)args[0].as.number);
  return pbNilValue();
}

static PbValue mouseQuery(PbVM *vm, int argCount, const PbValue *args, bool (*query)(int), const char *usage) {
  if (argCount != 1 || args[0].type != PB_VALUE_STRING) return guiError(vm, usage);
  int button = getMouseButtonCode(args[0].as.string.chars);
  if (button < 0) {
    char message[512];
    snprintf(message, sizeof(message), "Invalid mouse button name: %s.", args[0].as.string.chars);
    return guiError(vm, message);
  }
  return pbBoolValue(query(button));
}

static PbValue guiIsMouseButtonPressed(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  return mouseQuery(vm, argCount, args, raylib.isMouseButtonPressed,
                    "isMouseButtonPressed(string buttonName) expected.");
}

static PbValue guiIsMouseButtonDown(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  return mouseQuery(vm, argCount, args, raylib.isMouseButtonDown, "isMouseButtonDown(string buttonName) expected.");
}

static PbValue guiIsMouseButtonReleased(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  return mouseQuery(vm, argCount, args, raylib.isMouseButtonReleased,
                    "isMouseButtonReleased(string buttonName) expected.");
}

static PbValue guiIsMouseButtonUp(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  return mouseQuery(vm, argCount, args, raylib.isMouseButtonUp, "isMouseButtonUp(string buttonName) expected.");
}

static PbValue guiGetMouseX(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "getMouseX() takes no arguments.");
  return pbNumberValue(raylib.getMouseX());
}

static PbValue guiGetMouseY(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "getMouseY() takes no arguments.");
  return pbNumberValue(raylib.getMouseY());
}

static PbValue guiGetMouseWheelMove(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "getMouseWheelMove() takes no arguments.");
  if (raylib.getMouseWheelMove == NULL) return missingRaylibFunction(vm, "getMouseWheelMove");
  return pbNumberValue(raylib.getMouseWheelMove());
}

static PbValue guiCheckCollisionRecs(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 8 || !numbersFitFloat(args, 8))
    return guiError(vm, "checkCollisionRecs(x1, y1, w1, h1, x2, y2, w2, h2) expected.");
  if (raylib.checkCollisionRecs == NULL) return missingRaylibFunction(vm, "checkCollisionRecs");
  return pbBoolValue(raylib.checkCollisionRecs(
      (float)args[0].as.number, (float)args[1].as.number, (float)args[2].as.number, (float)args[3].as.number,
      (float)args[4].as.number, (float)args[5].as.number, (float)args[6].as.number, (float)args[7].as.number));
}

static PbValue guiCheckCollisionCircles(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 6 || !numbersFitFloat(args, 6) || args[2].as.number < 0.0 || args[5].as.number < 0.0)
    return guiError(vm, "checkCollisionCircles(x1, y1, r1, x2, y2, r2) expected.");
  if (raylib.checkCollisionCircles == NULL) return missingRaylibFunction(vm, "checkCollisionCircles");
  return pbBoolValue(raylib.checkCollisionCircles((float)args[0].as.number, (float)args[1].as.number,
                                                  (float)args[2].as.number, (float)args[3].as.number,
                                                  (float)args[4].as.number, (float)args[5].as.number));
}

static PbValue guiCheckCollisionCircleRec(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 7 || !numbersFitFloat(args, 7) || args[2].as.number < 0.0)
    return guiError(vm, "checkCollisionCircleRec(cx, cy, radius, rx, ry, rw, rh) expected.");
  if (raylib.checkCollisionCircleRec == NULL) return missingRaylibFunction(vm, "checkCollisionCircleRec");
  return pbBoolValue(raylib.checkCollisionCircleRec(
      (float)args[0].as.number, (float)args[1].as.number, (float)args[2].as.number, (float)args[3].as.number,
      (float)args[4].as.number, (float)args[5].as.number, (float)args[6].as.number));
}

static PbValue guiCheckCollisionPointRec(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 6 || !numbersFitFloat(args, 6))
    return guiError(vm, "checkCollisionPointRec(px, py, rx, ry, rw, rh) expected.");
  if (raylib.checkCollisionPointRec == NULL) return missingRaylibFunction(vm, "checkCollisionPointRec");
  return pbBoolValue(raylib.checkCollisionPointRec((float)args[0].as.number, (float)args[1].as.number,
                                                   (float)args[2].as.number, (float)args[3].as.number,
                                                   (float)args[4].as.number, (float)args[5].as.number));
}

static PbValue guiCheckCollisionPointCircle(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 5 || !numbersFitFloat(args, 5) || args[4].as.number < 0.0)
    return guiError(vm, "checkCollisionPointCircle(px, py, cx, cy, radius) expected.");
  if (raylib.checkCollisionPointCircle == NULL) return missingRaylibFunction(vm, "checkCollisionPointCircle");
  return pbBoolValue(raylib.checkCollisionPointCircle((float)args[0].as.number, (float)args[1].as.number,
                                                      (float)args[2].as.number, (float)args[3].as.number,
                                                      (float)args[4].as.number));
}

/* Sprites & Textures */

static PbValue guiLoadTexture(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_STRING) return guiError(vm, "loadTexture(path) expected.");
  if (raylib.loadTexture == NULL) return missingRaylibFunction(vm, "loadTexture");
  return pbNumberValue(raylib.loadTexture(args[0].as.string.chars));
}

static PbValue guiUnloadTexture(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "unloadTexture(id) expected.");
  if (raylib.unloadTexture == NULL) return missingRaylibFunction(vm, "unloadTexture");
  raylib.unloadTexture((int)args[0].as.number);
  return pbNilValue();
}

static PbValue guiDrawTexture(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 3 || !numbersFitInt(args, 1) || !numbersFitCoord(args + 1, 2))
    return guiError(vm, "drawTexture(id, x, y) expected.");
  if (raylib.drawTexture == NULL) return missingRaylibFunction(vm, "drawTexture");
  raylib.drawTexture((int)args[0].as.number, (int)args[1].as.number, (int)args[2].as.number);
  return pbNilValue();
}

static PbValue guiDrawTextureTint(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 6 || !numbersFitInt(args, 1) || !numbersFitCoord(args + 1, 2) || !validColor(args + 3))
    return guiError(vm, "drawTextureTint(id, x, y, r, g, b) expected.");
  if (raylib.drawTextureTint == NULL) return missingRaylibFunction(vm, "drawTextureTint");
  raylib.drawTextureTint((int)args[0].as.number, (int)args[1].as.number, (int)args[2].as.number, (int)args[3].as.number,
                         (int)args[4].as.number, (int)args[5].as.number);
  return pbNilValue();
}

static PbValue guiDrawTextureRec(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 7 || !numbersFitInt(args, 1) || !numbersFitFloat(args + 1, 6))
    return guiError(vm, "drawTextureRec(id, sourceX, sourceY, sourceW, sourceH, destX, destY) expected.");
  if (raylib.drawTextureRec == NULL) return missingRaylibFunction(vm, "drawTextureRec");
  raylib.drawTextureRec((int)args[0].as.number, (float)args[1].as.number, (float)args[2].as.number,
                        (float)args[3].as.number, (float)args[4].as.number, (float)args[5].as.number,
                        (float)args[6].as.number);
  return pbNilValue();
}

static PbValue guiDrawTexturePro(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 12 || !numbersFitInt(args, 1) || !numbersFitFloat(args + 1, 11))
    return guiError(vm, "drawTexturePro(id, sx, sy, sw, sh, dx, dy, dw, dh, ox, oy, rot) expected.");
  if (raylib.drawTexturePro == NULL) return missingRaylibFunction(vm, "drawTexturePro");
  raylib.drawTexturePro((int)args[0].as.number, (float)args[1].as.number, (float)args[2].as.number,
                        (float)args[3].as.number, (float)args[4].as.number, (float)args[5].as.number,
                        (float)args[6].as.number, (float)args[7].as.number, (float)args[8].as.number,
                        (float)args[9].as.number, (float)args[10].as.number, (float)args[11].as.number);
  return pbNilValue();
}

static PbValue guiGetTextureWidth(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "getTextureWidth(id) expected.");
  if (raylib.getTextureWidth == NULL) return missingRaylibFunction(vm, "getTextureWidth");
  return pbNumberValue(raylib.getTextureWidth((int)args[0].as.number));
}

static PbValue guiGetTextureHeight(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "getTextureHeight(id) expected.");
  if (raylib.getTextureHeight == NULL) return missingRaylibFunction(vm, "getTextureHeight");
  return pbNumberValue(raylib.getTextureHeight((int)args[0].as.number));
}

/* Audio: Sound & Music */

static PbValue guiInitAudio(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "initAudio() takes no arguments.");
  if (raylib.initAudio == NULL) return missingRaylibFunction(vm, "initAudio");
  raylib.initAudio();
  return pbNilValue();
}

static PbValue guiCloseAudio(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "closeAudio() takes no arguments.");
  if (raylib.closeAudio == NULL) return missingRaylibFunction(vm, "closeAudio");
  raylib.closeAudio();
  return pbNilValue();
}

static PbValue guiLoadSound(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_STRING) return guiError(vm, "loadSound(path) expected.");
  if (raylib.loadSound == NULL) return missingRaylibFunction(vm, "loadSound");
  return pbNumberValue(raylib.loadSound(args[0].as.string.chars));
}

static PbValue guiUnloadSound(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "unloadSound(id) expected.");
  if (raylib.unloadSound == NULL) return missingRaylibFunction(vm, "unloadSound");
  raylib.unloadSound((int)args[0].as.number);
  return pbNilValue();
}

static PbValue guiPlaySound(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "playSound(id) expected.");
  if (raylib.playSound == NULL) return missingRaylibFunction(vm, "playSound");
  raylib.playSound((int)args[0].as.number);
  return pbNilValue();
}

static PbValue guiStopSound(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "stopSound(id) expected.");
  if (raylib.stopSound == NULL) return missingRaylibFunction(vm, "stopSound");
  raylib.stopSound((int)args[0].as.number);
  return pbNilValue();
}

static PbValue guiSetSoundVolume(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || !numbersFitInt(args, 1) || !numberFitsFloat(args[1]))
    return guiError(vm, "setSoundVolume(id, volume) expected.");
  if (raylib.setSoundVolume == NULL) return missingRaylibFunction(vm, "setSoundVolume");
  raylib.setSoundVolume((int)args[0].as.number, (float)args[1].as.number);
  return pbNilValue();
}

static PbValue guiSetSoundPitch(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || !numbersFitInt(args, 1) || !numberFitsFloat(args[1]))
    return guiError(vm, "setSoundPitch(id, pitch) expected.");
  if (raylib.setSoundPitch == NULL) return missingRaylibFunction(vm, "setSoundPitch");
  raylib.setSoundPitch((int)args[0].as.number, (float)args[1].as.number);
  return pbNilValue();
}

static PbValue guiIsSoundPlaying(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "isSoundPlaying(id) expected.");
  if (raylib.isSoundPlaying == NULL) return missingRaylibFunction(vm, "isSoundPlaying");
  return pbBoolValue(raylib.isSoundPlaying((int)args[0].as.number));
}

static PbValue guiSetMasterVolume(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numberFitsFloat(args[0])) return guiError(vm, "setMasterVolume(volume) expected.");
  if (raylib.setMasterVolume == NULL) return missingRaylibFunction(vm, "setMasterVolume");
  raylib.setMasterVolume((float)args[0].as.number);
  return pbNilValue();
}

static PbValue guiLoadMusic(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_STRING) return guiError(vm, "loadMusic(path) expected.");
  if (raylib.loadMusic == NULL) return missingRaylibFunction(vm, "loadMusic");
  return pbNumberValue(raylib.loadMusic(args[0].as.string.chars));
}

static PbValue guiUnloadMusic(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "unloadMusic(id) expected.");
  if (raylib.unloadMusic == NULL) return missingRaylibFunction(vm, "unloadMusic");
  raylib.unloadMusic((int)args[0].as.number);
  return pbNilValue();
}

static PbValue guiPlayMusic(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "playMusic(id) expected.");
  if (raylib.playMusic == NULL) return missingRaylibFunction(vm, "playMusic");
  raylib.playMusic((int)args[0].as.number);
  return pbNilValue();
}

static PbValue guiPauseMusic(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "pauseMusic(id) expected.");
  if (raylib.pauseMusic == NULL) return missingRaylibFunction(vm, "pauseMusic");
  raylib.pauseMusic((int)args[0].as.number);
  return pbNilValue();
}

static PbValue guiResumeMusic(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "resumeMusic(id) expected.");
  if (raylib.resumeMusic == NULL) return missingRaylibFunction(vm, "resumeMusic");
  raylib.resumeMusic((int)args[0].as.number);
  return pbNilValue();
}

static PbValue guiStopMusic(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "stopMusic(id) expected.");
  if (raylib.stopMusic == NULL) return missingRaylibFunction(vm, "stopMusic");
  raylib.stopMusic((int)args[0].as.number);
  return pbNilValue();
}

static PbValue guiUpdateMusic(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "updateMusic(id) expected.");
  if (raylib.updateMusic == NULL) return missingRaylibFunction(vm, "updateMusic");
  raylib.updateMusic((int)args[0].as.number);
  return pbNilValue();
}

static PbValue guiSetMusicVolume(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || !numbersFitInt(args, 1) || !numberFitsFloat(args[1]))
    return guiError(vm, "setMusicVolume(id, volume) expected.");
  if (raylib.setMusicVolume == NULL) return missingRaylibFunction(vm, "setMusicVolume");
  raylib.setMusicVolume((int)args[0].as.number, (float)args[1].as.number);
  return pbNilValue();
}

static PbValue guiIsMusicStreamPlaying(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "isMusicStreamPlaying(id) expected.");
  if (raylib.isMusicStreamPlaying == NULL) return missingRaylibFunction(vm, "isMusicStreamPlaying");
  return pbBoolValue(raylib.isMusicStreamPlaying((int)args[0].as.number));
}

static PbValue guiSetVirtualResolution(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || !numbersFitInt(args, 2) || args[0].as.number <= 0 || args[1].as.number <= 0)
    return guiError(vm, "setVirtualResolution(width, height) expected positive integers.");
  if (raylib.setVirtualResolution == NULL) return missingRaylibFunction(vm, "setVirtualResolution");
  raylib.setVirtualResolution((int)args[0].as.number, (int)args[1].as.number);
  return pbNilValue();
}

static PbValue guiGetRenderWidth(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "getRenderWidth() takes no arguments.");
  if (raylib.getRenderWidth == NULL) return missingRaylibFunction(vm, "getRenderWidth");
  return pbNumberValue(raylib.getRenderWidth());
}

static PbValue guiGetRenderHeight(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "getRenderHeight() takes no arguments.");
  if (raylib.getRenderHeight == NULL) return missingRaylibFunction(vm, "getRenderHeight");
  return pbNumberValue(raylib.getRenderHeight());
}

static bool openRaylibLibrary(void) {
  const char *overridePath = getenv("PB_RAYLIB_LIBRARY");
#ifdef _WIN32
  if (overridePath != NULL && overridePath[0] != '\0') {
    raylibLibrary = LoadLibraryA(overridePath);
  } else {
    raylibLibrary = LoadLibraryA("build\\pb_raylib_windows.dll");
    if (raylibLibrary == NULL) raylibLibrary = LoadLibraryA("lib\\pb_raylib_windows.dll");
    if (raylibLibrary == NULL) {
      char executable[MAX_PATH] = {0};
      DWORD length = GetModuleFileNameA(NULL, executable, MAX_PATH);
      if (length > 0 && length < MAX_PATH) {
        char *slash = strrchr(executable, '\\');
        if (slash != NULL) {
          *slash = '\0';
          char path[MAX_PATH] = {0};
          int written = snprintf(path, sizeof(path), "%s\\lib\\pb_raylib_windows.dll", executable);
          if (written > 0 && (size_t)written < sizeof(path)) raylibLibrary = LoadLibraryA(path);
        }
      }
    }
  }
#else
  if (overridePath != NULL && overridePath[0] != '\0') {
    raylibLibrary = dlopen(overridePath, RTLD_NOW | RTLD_LOCAL);
  } else {
    const char *paths[] = {"build/pb_raylib_linux.so", "$ORIGIN/pb_raylib_linux.so", "lib/pb_raylib_linux.so",
                           "$ORIGIN/../lib/pb_raylib_linux.so", "$ORIGIN/../lib/pb/pb_raylib_linux.so"};
    for (size_t i = 0; i < sizeof(paths) / sizeof(paths[0]) && raylibLibrary == NULL; i++)
      raylibLibrary = dlopen(paths[i], RTLD_NOW | RTLD_LOCAL);
  }
#endif
  return raylibLibrary != NULL;
}

static RaylibSymbol loadRaylibSymbol(const char *name) {
#ifdef _WIN32
  return GetProcAddress(raylibLibrary, name);
#else
  dlerror();
  return dlsym(raylibLibrary, name);
#endif
}

static void closeRaylibLibrary(void) {
  if (raylibLibrary == NULL) return;
#ifdef _WIN32
  FreeLibrary(raylibLibrary);
#else
  dlclose(raylibLibrary);
#endif
  raylibLibrary = NULL;
}

static bool loadRaylib(PbVM *vm) {
  if (raylibLoaded) return true;

  if (!openRaylibLibrary()) {
    char message[1024];
#ifdef _WIN32
    snprintf(message, sizeof(message), "Could not load PB Raylib backend (Windows error %lu).",
             (unsigned long)GetLastError());
#else
    const char *error = dlerror();
    snprintf(message, sizeof(message), "Could not load PB Raylib backend: %s.",
             error != NULL ? error : "unknown loader error");
#endif
    pbRuntimeError(vm, message);
    return false;
  }

#define LOAD_RAYLIB_SYMBOL(field, type, symbol, callback) \
  do { \
    RaylibSymbol loadedSymbol = loadRaylibSymbol(symbol); \
    if (loadedSymbol == NULL) { \
      char message[256]; \
      closeRaylibLibrary(); \
      memset(&raylib, 0, sizeof(raylib)); \
      snprintf(message, sizeof(message), "PB Raylib backend is missing symbol '%s'.", symbol); \
      pbRuntimeError(vm, message); \
      return false; \
    } \
    _Static_assert(sizeof(raylib.field) == sizeof(loadedSymbol), "Raylib function pointer size mismatch"); \
    memcpy(&raylib.field, &loadedSymbol, sizeof(raylib.field)); \
  } while (false);

  RAYLIB_BASE_FUNCTIONS(LOAD_RAYLIB_SYMBOL)
#undef LOAD_RAYLIB_SYMBOL

#define LOAD_OPTIONAL_RAYLIB_SYMBOL(field, type, symbol, callback) \
  do { \
    RaylibSymbol loadedSymbol = loadRaylibSymbol(symbol); \
    if (loadedSymbol != NULL) memcpy(&raylib.field, &loadedSymbol, sizeof(raylib.field)); \
  } while (false);

  RAYLIB_EXTENDED_FUNCTIONS(LOAD_OPTIONAL_RAYLIB_SYMBOL)
#undef LOAD_OPTIONAL_RAYLIB_SYMBOL

  raylibLoaded = true;
  return true;
}

#define RAYLIB_NATIVE(field, type, symbol, callback) {symbol, callback, NULL},
static const PbNativeDefinition raylibFunctions[] = {RAYLIB_FUNCTIONS(RAYLIB_NATIVE)};
#undef RAYLIB_NATIVE

bool registerRaylibModule(PbVM *vm, const char *name) {
  if (!loadRaylib(vm)) return false;

  size_t count = sizeof(raylibFunctions) / sizeof(raylibFunctions[0]);
  if (!pbRegisterCapability(vm, name, raylibFunctions, count)) {
    if (raylibUsers == 0) {
      closeRaylibLibrary();
      memset(&raylib, 0, sizeof(raylib));
      raylibLoaded = false;
    }
    return false;
  }
  raylibUsers++;
  return true;
}

void releaseRaylibModule(void) {
  if (raylibUsers == 0) return;
  raylibUsers--;
  if (raylibUsers != 0) return;
  closeRaylibLibrary();
  memset(&raylib, 0, sizeof(raylib));
  raylibLoaded = false;
}
