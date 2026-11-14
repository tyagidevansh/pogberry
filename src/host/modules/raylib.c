#include <float.h>
#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#elif defined(__linux__) || defined(__APPLE__)
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
typedef int (*LoadShaderFn)(const char *, const char *);
typedef void (*UnloadShaderFn)(int);
typedef void (*BeginShaderModeFn)(int);
typedef void (*EndShaderModeFn)(void);
typedef void (*SetShaderFloatFn)(int, const char *, float);
typedef void (*SetShaderVec2Fn)(int, const char *, float, float);
typedef void (*SetTraceLogLevelFn)(int);
typedef int (*LoadRenderTextureFn)(int, int);
typedef void (*UnloadRenderTextureFn)(int);
typedef void (*BeginTextureModeFn)(int);
typedef void (*EndTextureModeFn)(void);
typedef void (*DrawRenderTextureFn)(int, int, int);
typedef void (*DrawRenderTextureRecFn)(int, float, float, float, float, float, float);
typedef int (*LoadFontFn)(const char *, int);
typedef void (*UnloadFontFn)(int);
typedef void (*DrawTextFontFn)(int, const char *, int, int, float, float, int, int, int);
typedef float (*MeasureTextFontFn)(int, const char *, float, float);
typedef int (*ReadCharFn)(void);
typedef void (*SetShaderVec3Fn)(int, const char *, float, float, float);
typedef void (*SetShaderVec4Fn)(int, const char *, float, float, float, float);
typedef void (*SetShaderColorFn)(int, const char *, float, float, float, float);
typedef void (*SetShaderTextureFn)(int, const char *, int);
typedef void (*Begin3DFn)(float, float, float, float, float, float, float);
typedef void (*Begin3DExFn)(float, float, float, float, float, float, float, float, float, float);
typedef void (*End3DFn)(void);
typedef void (*DrawCube3DFn)(float, float, float, float, float, float, int, int, int);
typedef void (*DrawPlane3DFn)(float, float, float, float, float, int, int, int);
typedef void (*DrawTriangle3DFn)(float, float, float, float, float, float, float, float, float, int, int, int);
typedef void (*DrawQuad3DFn)(float, float, float, float, float, float, float, float, float, float, float, float, int, int, int);
typedef void (*DrawSphere3DFn)(float, float, float, float, int, int, int);
typedef void (*DrawCylinder3DFn)(float, float, float, float, float, float, int, int, int, int);
typedef void (*DrawBillboardFn)(int, float, float, float, float, int, int, int);
typedef void (*DrawGridFn)(int, float);
typedef int (*LoadModelFn)(const char *);
typedef void (*UnloadModelFn)(int);
typedef void (*DrawModelFn)(int, float, float, float, float, int, int, int);
typedef void (*DrawModelExFn)(int, float, float, float, float, float, float, float, float, float, float, int, int, int);
typedef void (*SetModelTextureFn)(int, int, int);
typedef void (*TakeScreenshotFn)(const char *);

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
  X(getRenderHeight, GetRenderHeightFn, "getRenderHeight", guiGetRenderHeight) \
  X(loadShader, LoadShaderFn, "loadShader", guiLoadShader) \
  X(unloadShader, UnloadShaderFn, "unloadShader", guiUnloadShader) \
  X(beginShaderMode, BeginShaderModeFn, "beginShaderMode", guiBeginShaderMode) \
  X(endShaderMode, EndShaderModeFn, "endShaderMode", guiEndShaderMode) \
  X(setShaderFloat, SetShaderFloatFn, "setShaderFloat", guiSetShaderFloat) \
  X(setShaderVec2, SetShaderVec2Fn, "setShaderVec2", guiSetShaderVec2) \
  X(setTraceLogLevel, SetTraceLogLevelFn, "setTraceLogLevel", guiSetTraceLogLevel) \
  X(setDebugMode, SetTraceLogLevelFn, "setDebugMode", guiSetDebugMode) \
  X(loadRenderTexture, LoadRenderTextureFn, "loadRenderTexture", guiLoadRenderTexture) \
  X(unloadRenderTexture, UnloadRenderTextureFn, "unloadRenderTexture", guiUnloadRenderTexture) \
  X(beginTextureMode, BeginTextureModeFn, "beginTextureMode", guiBeginTextureMode) \
  X(endTextureMode, EndTextureModeFn, "endTextureMode", guiEndTextureMode) \
  X(drawRenderTexture, DrawRenderTextureFn, "drawRenderTexture", guiDrawRenderTexture) \
  X(drawRenderTextureRec, DrawRenderTextureRecFn, "drawRenderTextureRec", guiDrawRenderTextureRec) \
  X(loadFont, LoadFontFn, "loadFont", guiLoadFont) \
  X(unloadFont, UnloadFontFn, "unloadFont", guiUnloadFont) \
  X(drawTextFont, DrawTextFontFn, "drawTextFont", guiDrawTextFont) \
  X(measureTextFont, MeasureTextFontFn, "measureTextFont", guiMeasureTextFont) \
  X(readChar, ReadCharFn, "readChar", guiReadChar) \
  X(setShaderVec3, SetShaderVec3Fn, "setShaderVec3", guiSetShaderVec3) \
  X(setShaderVec4, SetShaderVec4Fn, "setShaderVec4", guiSetShaderVec4) \
  X(setShaderColor, SetShaderColorFn, "setShaderColor", guiSetShaderColor) \
  X(setShaderTexture, SetShaderTextureFn, "setShaderTexture", guiSetShaderTexture) \
  X(begin3D, Begin3DFn, "begin3D", guiBegin3D) \
  X(begin3DEx, Begin3DExFn, "begin3DEx", guiBegin3DEx) \
  X(end3D, End3DFn, "end3D", guiEnd3D) \
  X(drawCube3D, DrawCube3DFn, "drawCube3D", guiDrawCube3D) \
  X(drawCubeWires3D, DrawCube3DFn, "drawCubeWires3D", guiDrawCubeWires3D) \
  X(drawPlane3D, DrawPlane3DFn, "drawPlane3D", guiDrawPlane3D) \
  X(drawTriangle3D, DrawTriangle3DFn, "drawTriangle3D", guiDrawTriangle3D) \
  X(drawQuad3D, DrawQuad3DFn, "drawQuad3D", guiDrawQuad3D) \
  X(drawSphere3D, DrawSphere3DFn, "drawSphere3D", guiDrawSphere3D) \
  X(drawCylinder3D, DrawCylinder3DFn, "drawCylinder3D", guiDrawCylinder3D) \
  X(drawCylinderWires3D, DrawCylinder3DFn, "drawCylinderWires3D", guiDrawCylinderWires3D) \
  X(drawBillboard, DrawBillboardFn, "drawBillboard", guiDrawBillboard) \
  X(drawGrid, DrawGridFn, "drawGrid", guiDrawGrid) \
  X(loadModel, LoadModelFn, "loadModel", guiLoadModel) \
  X(unloadModel, UnloadModelFn, "unloadModel", guiUnloadModel) \
  X(drawModel, DrawModelFn, "drawModel", guiDrawModel) \
  X(drawModelEx, DrawModelExFn, "drawModelEx", guiDrawModelEx) \
  X(drawModelWires, DrawModelFn, "drawModelWires", guiDrawModelWires) \
  X(drawModelWiresEx, DrawModelExFn, "drawModelWiresEx", guiDrawModelWiresEx) \
  X(setModelTexture, SetModelTextureFn, "setModelTexture", guiSetModelTexture) \
  X(takeScreenshot, TakeScreenshotFn, "takeScreenshot", guiTakeScreenshot)

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

static const NameCode traceLogLevels[] = {
    {"ALL", 0}, {"TRACE", 1}, {"DEBUG", 2}, {"INFO", 3},
    {"WARNING", 4}, {"WARN", 4}, {"ERROR", 5}, {"FATAL", 6}, {"NONE", 7},
};


static int findCode(const NameCode *table, size_t count, const char *name) {
  for (size_t i = 0; i < count; i++) {
    if (strcmp(table[i].name, name) == 0) return table[i].code;
  }
  return -1;
}

static int getKeyCode(const char *name) {
  if (name == NULL || name[0] == '\0') return -1;
  int code = findCode(keyCodes, sizeof(keyCodes) / sizeof(keyCodes[0]), name);
  if (code >= 0) return code;

  const char *str = name;
  if ((str[0] == 'k' || str[0] == 'K') &&
      (str[1] == 'e' || str[1] == 'E') &&
      (str[2] == 'y' || str[2] == 'Y') &&
      str[3] == '_') {
    str += 4;
  }

  if (str[0] != '\0' && str[1] == '\0') {
    char c = str[0];
    if (c >= 'a' && c <= 'z') return c - 'a' + 65;
    if (c >= 'A' && c <= 'Z') return c;
    if (c >= '0' && c <= '9') return c - '0' + 48;
    if (c == ' ') return 32;
  }

  size_t count = sizeof(keyCodes) / sizeof(keyCodes[0]);
  for (size_t i = 0; i < count; i++) {
    const char *kName = keyCodes[i].name;
    if (strncmp(kName, "KEY_", 4) == 0) kName += 4;
    if (strcasecmp(kName, str) == 0) return keyCodes[i].code;
  }

  if (strcasecmp(str, "space") == 0) return 32;
  if (strcasecmp(str, "esc") == 0 || strcasecmp(str, "escape") == 0) return 256;
  if (strcasecmp(str, "enter") == 0 || strcasecmp(str, "return") == 0) return 257;
  if (strcasecmp(str, "tab") == 0) return 258;
  if (strcasecmp(str, "backspace") == 0) return 259;
  if (strcasecmp(str, "shift") == 0) return 340;
  if (strcasecmp(str, "ctrl") == 0 || strcasecmp(str, "control") == 0) return 341;
  if (strcasecmp(str, "alt") == 0) return 342;

  return -1;
}

static int getMouseButtonCode(const char *name) {
  if (name == NULL || name[0] == '\0') return -1;
  int code = findCode(mouseButtonCodes, sizeof(mouseButtonCodes) / sizeof(mouseButtonCodes[0]), name);
  if (code >= 0) return code;
  size_t count = sizeof(mouseButtonCodes) / sizeof(mouseButtonCodes[0]);
  for (size_t i = 0; i < count; i++) {
    if (strcasecmp(mouseButtonCodes[i].name, name) == 0) return mouseButtonCodes[i].code;
  }
  return -1;
}

static int getTraceLogLevelCode(const char *name) {
  if (name == NULL || name[0] == '\0') return -1;
  int code = findCode(traceLogLevels, sizeof(traceLogLevels) / sizeof(traceLogLevels[0]), name);
  if (code >= 0) return code;
  size_t count = sizeof(traceLogLevels) / sizeof(traceLogLevels[0]);
  for (size_t i = 0; i < count; i++) {
    if (strcasecmp(traceLogLevels[i].name, name) == 0) return traceLogLevels[i].code;
  }
  return -1;
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

static bool parseVec3(PbVM *vm, PbValue val, float out[3]) {
  double nums[3];
  int count = 0;
  if (!pbListGetNumbers(vm, val, nums, 3, &count) || count != 3) return false;
  for (int i = 0; i < 3; i++) {
    if (!fitsFloat(nums[i])) return false;
    out[i] = (float)nums[i];
  }
  return true;
}

static bool parseVec2(PbVM *vm, PbValue val, float out[2]) {
  double nums[2];
  int count = 0;
  if (!pbListGetNumbers(vm, val, nums, 2, &count) || count != 2) return false;
  for (int i = 0; i < 2; i++) {
    if (!fitsCoord(nums[i])) return false;
    out[i] = (float)nums[i];
  }
  return true;
}

static bool parseRect(PbVM *vm, PbValue val, float out[4]) {
  double nums[4];
  int count = 0;
  if (!pbListGetNumbers(vm, val, nums, 4, &count) || count != 4) return false;
  for (int i = 0; i < 4; i++) {
    if (!fitsFloat(nums[i])) return false;
    out[i] = (float)nums[i];
  }
  return true;
}

static bool parseColor(PbVM *vm, PbValue val, int out[4]) {
  out[0] = 0; out[1] = 0; out[2] = 0; out[3] = 255;
  if (val.type == PB_VALUE_NUMBER) {
    if (!isFiniteNumber(val.as.number) || val.as.number < 0) return false;
    double n = val.as.number;
    if (floor(n) != n) return false;
    if (n <= 0xFFFFFF) {
      uint32_t c = (uint32_t)n;
      out[0] = (c >> 16) & 0xFF;
      out[1] = (c >> 8) & 0xFF;
      out[2] = c & 0xFF;
      out[3] = 255;
      return true;
    } else if (n <= 0xFFFFFFFF) {
      uint32_t c = (uint32_t)n;
      out[0] = (c >> 24) & 0xFF;
      out[1] = (c >> 16) & 0xFF;
      out[2] = (c >> 8) & 0xFF;
      out[3] = c & 0xFF;
      return true;
    }
    return false;
  }
  if (pbIsList(val)) {
    double nums[4];
    int count = 0;
    if (!pbListGetNumbers(vm, val, nums, 4, &count)) return false;
    if (count != 3 && count != 4) return false;
    for (int i = 0; i < count; i++) {
      if (!isFiniteNumber(nums[i]) || nums[i] < 0 || nums[i] > 255) return false;
      out[i] = (int)nums[i];
    }
    if (count == 3) out[3] = 255;
    return true;
  }
  return false;
}

static bool parseSize3(PbVM *vm, PbValue val, float out[3]) {
  if (val.type == PB_VALUE_NUMBER) {
    if (!fitsFloat(val.as.number) || val.as.number < 0) return false;
    out[0] = (float)val.as.number;
    out[1] = (float)val.as.number;
    out[2] = (float)val.as.number;
    return true;
  }
  return parseVec3(vm, val, out);
}

static bool parseSize2(PbVM *vm, PbValue val, float out[2]) {
  if (val.type == PB_VALUE_NUMBER) {
    if (!fitsFloat(val.as.number) || val.as.number < 0) return false;
    out[0] = (float)val.as.number;
    out[1] = (float)val.as.number;
    return true;
  }
  return parseVec2(vm, val, out);
}

static bool parseScale3(PbVM *vm, PbValue val, float out[3]) {
  if (val.type == PB_VALUE_NUMBER) {
    if (!fitsFloat(val.as.number)) return false;
    out[0] = (float)val.as.number;
    out[1] = (float)val.as.number;
    out[2] = (float)val.as.number;
    return true;
  }
  return parseVec3(vm, val, out);
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

typedef enum {
  GUI_RESOURCE_SHADER = 1,
  GUI_RESOURCE_RENDER_TEXTURE = 2,
  GUI_RESOURCE_FONT = 3,
} GuiResourceKind;

static void unloadShaderFinalizer(int backendId, void *ctx) {
  (void)ctx;
  if (!raylibLoaded || raylib.unloadShader == NULL) return;
  raylib.unloadShader(backendId);
}

static void unloadRenderTextureFinalizer(int backendId, void *ctx) {
  (void)ctx;
  if (!raylibLoaded || raylib.unloadRenderTexture == NULL) return;
  raylib.unloadRenderTexture(backendId);
}

static void unloadFontFinalizer(int backendId, void *ctx) {
  (void)ctx;
  if (!raylibLoaded || raylib.unloadFont == NULL) return;
  raylib.unloadFont(backendId);
}

static bool shaderId(PbVM *vm, PbValue value, int *id, const char *usage) {
  int tag = 0;
  int backendId = 0;
  bool closed = false;
  if (!pbResourceInfo(value, NULL, &tag, &backendId, &closed) || tag != GUI_RESOURCE_SHADER) {
    guiError(vm, usage);
    return false;
  }
  if (closed) {
    guiError(vm, "shader has been unloaded.");
    return false;
  }
  *id = backendId;
  return true;
}

static bool renderTextureId(PbVM *vm, PbValue value, int *id, const char *usage) {
  int tag = 0;
  int backendId = 0;
  bool closed = false;
  if (!pbResourceInfo(value, NULL, &tag, &backendId, &closed) || tag != GUI_RESOURCE_RENDER_TEXTURE) {
    guiError(vm, usage);
    return false;
  }
  if (closed) {
    guiError(vm, "render texture has been unloaded.");
    return false;
  }
  *id = backendId;
  return true;
}

static bool fontId(PbVM *vm, PbValue value, int *id, const char *usage) {
  int tag = 0;
  int backendId = 0;
  bool closed = false;
  if (!pbResourceInfo(value, NULL, &tag, &backendId, &closed) || tag != GUI_RESOURCE_FONT) {
    guiError(vm, usage);
    return false;
  }
  if (closed) {
    guiError(vm, "font has been unloaded.");
    return false;
  }
  *id = backendId;
  return true;
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
  int color[4];
  if (argCount == 1) {
    if (!parseColor(vm, args[0], color)) return guiError(vm, "clearBackground(color) expected a color.");
    raylib.clearBackground(color[0], color[1], color[2]);
    return pbNilValue();
  }
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

static PbValue guiBegin3DEx(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float cam[3], target[3], up[3];
  float fovy;

  if (argCount == 4) {
    if (!parseVec3(vm, args[0], cam) || !parseVec3(vm, args[1], target) ||
        !parseVec3(vm, args[2], up) || !numberFitsFloat(args[3]) ||
        args[3].as.number <= 1.0 || args[3].as.number >= 179.0) {
      return guiError(vm, "begin3DEx(camPos, targetPos, upVec, fovy) expected.");
    }
    fovy = (float)args[3].as.number;
  } else if (argCount == 10) {
    if (!numbersFitFloat(args, 10) || args[9].as.number <= 1.0 || args[9].as.number >= 179.0)
      return guiError(vm, "begin3DEx(camX, camY, camZ, targetX, targetY, targetZ, upX, upY, upZ, fovy) expected.");
    cam[0] = (float)args[0].as.number; cam[1] = (float)args[1].as.number; cam[2] = (float)args[2].as.number;
    target[0] = (float)args[3].as.number; target[1] = (float)args[4].as.number; target[2] = (float)args[5].as.number;
    up[0] = (float)args[6].as.number; up[1] = (float)args[7].as.number; up[2] = (float)args[8].as.number;
    fovy = (float)args[9].as.number;
  } else {
    return guiError(vm, "begin3DEx expects 4 arguments (camPos, targetPos, upVec, fovy) or 10 arguments.");
  }

  if (raylib.begin3DEx != NULL) {
    raylib.begin3DEx(cam[0], cam[1], cam[2], target[0], target[1], target[2], up[0], up[1], up[2], fovy);
  } else if (raylib.begin3D != NULL) {
    raylib.begin3D(cam[0], cam[1], cam[2], target[0], target[1], target[2], fovy);
  } else {
    return missingRaylibFunction(vm, "begin3DEx");
  }
  return pbNilValue();
}

static PbValue guiBegin3D(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  if (argCount == 4 || argCount == 10) return guiBegin3DEx(vm, argCount, args, userData);
  (void)userData;
  float cam[3], target[3];
  float fovy;

  if (argCount == 3) {
    if (!parseVec3(vm, args[0], cam) || !parseVec3(vm, args[1], target) ||
        !numberFitsFloat(args[2]) || args[2].as.number <= 1.0 || args[2].as.number >= 179.0) {
      return guiError(vm, "begin3D(camPos, targetPos, fovy) expected.");
    }
    fovy = (float)args[2].as.number;
  } else if (argCount == 7) {
    if (!numbersFitFloat(args, 7) || args[6].as.number <= 1.0 || args[6].as.number >= 179.0)
      return guiError(vm, "begin3D(camX, camY, camZ, targetX, targetY, targetZ, fovy) expected.");
    cam[0] = (float)args[0].as.number; cam[1] = (float)args[1].as.number; cam[2] = (float)args[2].as.number;
    target[0] = (float)args[3].as.number; target[1] = (float)args[4].as.number; target[2] = (float)args[5].as.number;
    fovy = (float)args[6].as.number;
  } else {
    return guiError(vm, "begin3D expects 3 arguments (camPos, targetPos, fovy) or 7 arguments.");
  }

  if (raylib.begin3D == NULL) return missingRaylibFunction(vm, "begin3D");
  raylib.begin3D(cam[0], cam[1], cam[2], target[0], target[1], target[2], fovy);
  return pbNilValue();
}

static PbValue guiEnd3D(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "end3D() takes no arguments.");
  if (raylib.end3D == NULL) return missingRaylibFunction(vm, "end3D");
  raylib.end3D();
  return pbNilValue();
}

static PbValue guiDrawCube3D(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float pos[3], size[3];
  int color[4];

  if (argCount == 3) {
    if (!parseVec3(vm, args[0], pos) || !parseSize3(vm, args[1], size) ||
        size[0] < 0 || size[1] < 0 || size[2] < 0 || !parseColor(vm, args[2], color)) {
      return guiError(vm, "drawCube3D(pos, size, color) expected.");
    }
  } else if (argCount == 9) {
    if (!numbersFitFloat(args, 6) || args[3].as.number < 0 || args[4].as.number < 0 ||
        args[5].as.number < 0 || !validColor(args + 6))
      return guiError(vm, "drawCube3D(x, y, z, width, height, length, r, g, b) expected.");
    pos[0] = (float)args[0].as.number; pos[1] = (float)args[1].as.number; pos[2] = (float)args[2].as.number;
    size[0] = (float)args[3].as.number; size[1] = (float)args[4].as.number; size[2] = (float)args[5].as.number;
    color[0] = (int)args[6].as.number; color[1] = (int)args[7].as.number; color[2] = (int)args[8].as.number;
  } else {
    return guiError(vm, "drawCube3D expects 3 arguments (pos, size, color) or 9 arguments.");
  }

  if (raylib.drawCube3D == NULL) return missingRaylibFunction(vm, "drawCube3D");
  raylib.drawCube3D(pos[0], pos[1], pos[2], size[0], size[1], size[2], color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawCubeWires3D(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float pos[3], size[3];
  int color[4];

  if (argCount == 3) {
    if (!parseVec3(vm, args[0], pos) || !parseSize3(vm, args[1], size) ||
        size[0] < 0 || size[1] < 0 || size[2] < 0 || !parseColor(vm, args[2], color)) {
      return guiError(vm, "drawCubeWires3D(pos, size, color) expected.");
    }
  } else if (argCount == 9) {
    if (!numbersFitFloat(args, 6) || args[3].as.number < 0 || args[4].as.number < 0 ||
        args[5].as.number < 0 || !validColor(args + 6))
      return guiError(vm, "drawCubeWires3D(x, y, z, width, height, length, r, g, b) expected.");
    pos[0] = (float)args[0].as.number; pos[1] = (float)args[1].as.number; pos[2] = (float)args[2].as.number;
    size[0] = (float)args[3].as.number; size[1] = (float)args[4].as.number; size[2] = (float)args[5].as.number;
    color[0] = (int)args[6].as.number; color[1] = (int)args[7].as.number; color[2] = (int)args[8].as.number;
  } else {
    return guiError(vm, "drawCubeWires3D expects 3 arguments (pos, size, color) or 9 arguments.");
  }

  if (raylib.drawCubeWires3D == NULL) return missingRaylibFunction(vm, "drawCubeWires3D");
  raylib.drawCubeWires3D(pos[0], pos[1], pos[2], size[0], size[1], size[2], color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawPlane3D(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float pos[3], size[2];
  int color[4];

  if (argCount == 3) {
    if (!parseVec3(vm, args[0], pos) || !parseSize2(vm, args[1], size) ||
        size[0] < 0 || size[1] < 0 || !parseColor(vm, args[2], color)) {
      return guiError(vm, "drawPlane3D(pos, size, color) expected.");
    }
  } else if (argCount == 8) {
    if (!numbersFitFloat(args, 5) || args[3].as.number < 0 || args[4].as.number < 0 ||
        !validColor(args + 5))
      return guiError(vm, "drawPlane3D(x, y, z, width, length, r, g, b) expected.");
    pos[0] = (float)args[0].as.number; pos[1] = (float)args[1].as.number; pos[2] = (float)args[2].as.number;
    size[0] = (float)args[3].as.number; size[1] = (float)args[4].as.number;
    color[0] = (int)args[5].as.number; color[1] = (int)args[6].as.number; color[2] = (int)args[7].as.number;
  } else {
    return guiError(vm, "drawPlane3D expects 3 arguments (pos, size, color) or 8 arguments.");
  }

  if (raylib.drawPlane3D == NULL) return missingRaylibFunction(vm, "drawPlane3D");
  raylib.drawPlane3D(pos[0], pos[1], pos[2], size[0], size[1], color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawTriangle3D(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float p1[3], p2[3], p3[3];
  int color[4];

  if (argCount == 4) {
    if (!parseVec3(vm, args[0], p1) || !parseVec3(vm, args[1], p2) ||
        !parseVec3(vm, args[2], p3) || !parseColor(vm, args[3], color)) {
      return guiError(vm, "drawTriangle3D(p1, p2, p3, color) expected.");
    }
  } else if (argCount == 12) {
    if (!numbersFitFloat(args, 9) || !validColor(args + 9))
      return guiError(vm, "drawTriangle3D(x1, y1, z1, x2, y2, z2, x3, y3, z3, r, g, b) expected.");
    p1[0] = (float)args[0].as.number; p1[1] = (float)args[1].as.number; p1[2] = (float)args[2].as.number;
    p2[0] = (float)args[3].as.number; p2[1] = (float)args[4].as.number; p2[2] = (float)args[5].as.number;
    p3[0] = (float)args[6].as.number; p3[1] = (float)args[7].as.number; p3[2] = (float)args[8].as.number;
    color[0] = (int)args[9].as.number; color[1] = (int)args[10].as.number; color[2] = (int)args[11].as.number;
  } else {
    return guiError(vm, "drawTriangle3D expects 4 arguments (p1, p2, p3, color) or 12 arguments.");
  }

  if (raylib.drawTriangle3D == NULL) return missingRaylibFunction(vm, "drawTriangle3D");
  raylib.drawTriangle3D(p1[0], p1[1], p1[2], p2[0], p2[1], p2[2],
                        p3[0], p3[1], p3[2], color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawQuad3D(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float p1[3], p2[3], p3[3], p4[3];
  int color[4];

  if (argCount == 2) {
    if (!pbIsList(args[0]) || pbListLength(args[0]) != 4 || !parseColor(vm, args[1], color)) {
      return guiError(vm, "drawQuad3D([p1, p2, p3, p4], color) expected.");
    }
    PbValue pt1, pt2, pt3, pt4;
    if (!pbListGet(vm, args[0], 0, &pt1) || !pbListGet(vm, args[0], 1, &pt2) ||
        !pbListGet(vm, args[0], 2, &pt3) || !pbListGet(vm, args[0], 3, &pt4) ||
        !parseVec3(vm, pt1, p1) || !parseVec3(vm, pt2, p2) ||
        !parseVec3(vm, pt3, p3) || !parseVec3(vm, pt4, p4)) {
      return guiError(vm, "drawQuad3D([p1, p2, p3, p4], color) expected 4 3D points.");
    }
  } else if (argCount == 5) {
    if (!parseVec3(vm, args[0], p1) || !parseVec3(vm, args[1], p2) ||
        !parseVec3(vm, args[2], p3) || !parseVec3(vm, args[3], p4) ||
        !parseColor(vm, args[4], color)) {
      return guiError(vm, "drawQuad3D(p1, p2, p3, p4, color) expected.");
    }
  } else if (argCount == 15) {
    if (!numbersFitFloat(args, 12) || !validColor(args + 12))
      return guiError(vm, "drawQuad3D(x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, r, g, b) expected.");
    p1[0] = (float)args[0].as.number; p1[1] = (float)args[1].as.number; p1[2] = (float)args[2].as.number;
    p2[0] = (float)args[3].as.number; p2[1] = (float)args[4].as.number; p2[2] = (float)args[5].as.number;
    p3[0] = (float)args[6].as.number; p3[1] = (float)args[7].as.number; p3[2] = (float)args[8].as.number;
    p4[0] = (float)args[9].as.number; p4[1] = (float)args[10].as.number; p4[2] = (float)args[11].as.number;
    color[0] = (int)args[12].as.number; color[1] = (int)args[13].as.number; color[2] = (int)args[14].as.number;
  } else {
    return guiError(vm, "drawQuad3D expects 2, 5, or 15 arguments.");
  }

  if (raylib.drawQuad3D == NULL) return missingRaylibFunction(vm, "drawQuad3D");
  raylib.drawQuad3D(p1[0], p1[1], p1[2], p2[0], p2[1], p2[2],
                    p3[0], p3[1], p3[2], p4[0], p4[1], p4[2],
                    color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawSphere3D(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float pos[3];
  float radius;
  int color[4];

  if (argCount == 3) {
    if (!parseVec3(vm, args[0], pos) || !numberFitsFloat(args[1]) || args[1].as.number < 0 ||
        !parseColor(vm, args[2], color)) {
      return guiError(vm, "drawSphere3D(pos, radius, color) expected.");
    }
    radius = (float)args[1].as.number;
  } else if (argCount == 7) {
    if (!numbersFitFloat(args, 4) || args[3].as.number < 0 || !validColor(args + 4))
      return guiError(vm, "drawSphere3D(x, y, z, radius, r, g, b) expected.");
    pos[0] = (float)args[0].as.number; pos[1] = (float)args[1].as.number; pos[2] = (float)args[2].as.number;
    radius = (float)args[3].as.number;
    color[0] = (int)args[4].as.number; color[1] = (int)args[5].as.number; color[2] = (int)args[6].as.number;
  } else {
    return guiError(vm, "drawSphere3D expects 3 arguments (pos, radius, color) or 7 arguments.");
  }

  if (raylib.drawSphere3D == NULL) return missingRaylibFunction(vm, "drawSphere3D");
  raylib.drawSphere3D(pos[0], pos[1], pos[2], radius, color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawCylinder3D(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float pos[3];
  float radTop, radBottom, height;
  int slices = 16;
  int color[4];

  if (argCount == 4) {
    float dims[3];
    if (!parseVec3(vm, args[0], pos) || !parseVec3(vm, args[1], dims) ||
        !numbersFitInt(args + 2, 1) || args[2].as.number <= 0 || !parseColor(vm, args[3], color)) {
      return guiError(vm, "drawCylinder3D(pos, [radTop, radBottom, height], slices, color) expected.");
    }
    radTop = dims[0]; radBottom = dims[1]; height = dims[2];
    slices = (int)args[2].as.number;
  } else if (argCount == 5) {
    if (!parseVec3(vm, args[0], pos) || !numberFitsFloat(args[1]) || !numberFitsFloat(args[2]) ||
        !numberFitsFloat(args[3]) || !parseColor(vm, args[4], color)) {
      return guiError(vm, "drawCylinder3D(pos, radTop, radBottom, height, color) expected.");
    }
    radTop = (float)args[1].as.number; radBottom = (float)args[2].as.number; height = (float)args[3].as.number;
  } else if (argCount == 10) {
    if (!numbersFitFloat(args, 6) || !numbersFitInt(args + 6, 1) || !validColor(args + 7))
      return guiError(vm, "drawCylinder3D(x, y, z, radiusTop, radiusBottom, height, slices, r, g, b) expected.");
    pos[0] = (float)args[0].as.number; pos[1] = (float)args[1].as.number; pos[2] = (float)args[2].as.number;
    radTop = (float)args[3].as.number; radBottom = (float)args[4].as.number; height = (float)args[5].as.number;
    slices = (int)args[6].as.number;
    color[0] = (int)args[7].as.number; color[1] = (int)args[8].as.number; color[2] = (int)args[9].as.number;
  } else {
    return guiError(vm, "drawCylinder3D expects 4, 5, or 10 arguments.");
  }

  if (raylib.drawCylinder3D == NULL) return missingRaylibFunction(vm, "drawCylinder3D");
  raylib.drawCylinder3D(pos[0], pos[1], pos[2], radTop, radBottom, height, slices, color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawCylinderWires3D(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float pos[3];
  float radTop, radBottom, height;
  int slices = 16;
  int color[4];

  if (argCount == 4) {
    float dims[3];
    if (!parseVec3(vm, args[0], pos) || !parseVec3(vm, args[1], dims) ||
        !numbersFitInt(args + 2, 1) || args[2].as.number <= 0 || !parseColor(vm, args[3], color)) {
      return guiError(vm, "drawCylinderWires3D(pos, [radTop, radBottom, height], slices, color) expected.");
    }
    radTop = dims[0]; radBottom = dims[1]; height = dims[2];
    slices = (int)args[2].as.number;
  } else if (argCount == 5) {
    if (!parseVec3(vm, args[0], pos) || !numberFitsFloat(args[1]) || !numberFitsFloat(args[2]) ||
        !numberFitsFloat(args[3]) || !parseColor(vm, args[4], color)) {
      return guiError(vm, "drawCylinderWires3D(pos, radTop, radBottom, height, color) expected.");
    }
    radTop = (float)args[1].as.number; radBottom = (float)args[2].as.number; height = (float)args[3].as.number;
  } else if (argCount == 10) {
    if (!numbersFitFloat(args, 6) || !numbersFitInt(args + 6, 1) || !validColor(args + 7))
      return guiError(vm, "drawCylinderWires3D(x, y, z, radiusTop, radiusBottom, height, slices, r, g, b) expected.");
    pos[0] = (float)args[0].as.number; pos[1] = (float)args[1].as.number; pos[2] = (float)args[2].as.number;
    radTop = (float)args[3].as.number; radBottom = (float)args[4].as.number; height = (float)args[5].as.number;
    slices = (int)args[6].as.number;
    color[0] = (int)args[7].as.number; color[1] = (int)args[8].as.number; color[2] = (int)args[9].as.number;
  } else {
    return guiError(vm, "drawCylinderWires3D expects 4, 5, or 10 arguments.");
  }

  if (raylib.drawCylinderWires3D == NULL) return missingRaylibFunction(vm, "drawCylinderWires3D");
  raylib.drawCylinderWires3D(pos[0], pos[1], pos[2], radTop, radBottom, height, slices, color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawBillboard(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  int id;
  float pos[3];
  float size;
  int color[4];

  if (argCount == 4) {
    if (!numbersFitInt(args, 1) || !parseVec3(vm, args[1], pos) ||
        !numberFitsFloat(args[2]) || !parseColor(vm, args[3], color)) {
      return guiError(vm, "drawBillboard(textureId, pos, size, color) expected.");
    }
    id = (int)args[0].as.number;
    size = (float)args[2].as.number;
  } else if (argCount == 8) {
    if (!numbersFitInt(args, 1) || !numbersFitFloat(args + 1, 4) || !validColor(args + 5))
      return guiError(vm, "drawBillboard(textureId, x, y, z, size, r, g, b) expected.");
    id = (int)args[0].as.number;
    pos[0] = (float)args[1].as.number; pos[1] = (float)args[2].as.number; pos[2] = (float)args[3].as.number;
    size = (float)args[4].as.number;
    color[0] = (int)args[5].as.number; color[1] = (int)args[6].as.number; color[2] = (int)args[7].as.number;
  } else {
    return guiError(vm, "drawBillboard expects 4 arguments (textureId, pos, size, color) or 8 arguments.");
  }

  if (raylib.drawBillboard == NULL) return missingRaylibFunction(vm, "drawBillboard");
  raylib.drawBillboard(id, pos[0], pos[1], pos[2], size, color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawGrid(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || !numbersFitInt(args, 1) || !numberFitsFloat(args[1]))
    return guiError(vm, "drawGrid(slices, spacing) expected.");
  if (raylib.drawGrid == NULL) return missingRaylibFunction(vm, "drawGrid");
  raylib.drawGrid((int)args[0].as.number, (float)args[1].as.number);
  return pbNilValue();
}

static PbValue guiLoadModel(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_STRING) return guiError(vm, "loadModel(path) expected.");
  if (raylib.loadModel == NULL) return missingRaylibFunction(vm, "loadModel");
  return pbNumberValue(raylib.loadModel(args[0].as.string.chars));
}

static PbValue guiUnloadModel(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || !numbersFitInt(args, 1)) return guiError(vm, "unloadModel(id) expected.");
  if (raylib.unloadModel == NULL) return missingRaylibFunction(vm, "unloadModel");
  raylib.unloadModel((int)args[0].as.number);
  return pbNilValue();
}

static PbValue guiDrawModel(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  int id;
  float pos[3];
  float scale;
  int color[4];

  if (argCount == 4) {
    if (!numbersFitInt(args, 1) || !parseVec3(vm, args[1], pos) ||
        !numberFitsFloat(args[2]) || !parseColor(vm, args[3], color)) {
      return guiError(vm, "drawModel(id, pos, scale, tint) expected.");
    }
    id = (int)args[0].as.number;
    scale = (float)args[2].as.number;
  } else if (argCount == 8) {
    if (!numbersFitInt(args, 1) || !numbersFitFloat(args + 1, 4) || !validColor(args + 5))
      return guiError(vm, "drawModel(id, x, y, z, scale, r, g, b) expected.");
    id = (int)args[0].as.number;
    pos[0] = (float)args[1].as.number; pos[1] = (float)args[2].as.number; pos[2] = (float)args[3].as.number;
    scale = (float)args[4].as.number;
    color[0] = (int)args[5].as.number; color[1] = (int)args[6].as.number; color[2] = (int)args[7].as.number;
  } else {
    return guiError(vm, "drawModel expects 4 arguments (id, pos, scale, tint) or 8 arguments.");
  }

  if (raylib.drawModel == NULL) return missingRaylibFunction(vm, "drawModel");
  raylib.drawModel(id, pos[0], pos[1], pos[2], scale, color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawModelEx(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  int id;
  float pos[3];
  float rotAxis[3] = {0.0f, 1.0f, 0.0f};
  float rotAngle = 0.0f;
  float scale[3];
  int color[4];

  if (argCount == 5) {
    if (!numbersFitInt(args, 1) || !parseVec3(vm, args[1], pos) ||
        !parseScale3(vm, args[3], scale) || !parseColor(vm, args[4], color)) {
      return guiError(vm, "drawModelEx(id, pos, rot, scale, tint) expected.");
    }
    id = (int)args[0].as.number;
    if (numberFitsFloat(args[2])) {
      rotAngle = (float)args[2].as.number;
    } else if (pbIsList(args[2])) {
      double rnums[4];
      int rcount = 0;
      if (!pbListGetNumbers(vm, args[2], rnums, 4, &rcount) || rcount != 4) {
        return guiError(vm, "drawModelEx rot must be an angle number or [rx, ry, rz, angle].");
      }
      rotAxis[0] = (float)rnums[0]; rotAxis[1] = (float)rnums[1]; rotAxis[2] = (float)rnums[2];
      rotAngle = (float)rnums[3];
    } else {
      return guiError(vm, "drawModelEx rot must be an angle number or [rx, ry, rz, angle].");
    }
  } else if (argCount == 14) {
    if (!numbersFitInt(args, 1) || !numbersFitFloat(args + 1, 10) || !validColor(args + 11))
      return guiError(vm, "drawModelEx(id, x, y, z, rx, ry, rz, angle, sx, sy, sz, r, g, b) expected.");
    id = (int)args[0].as.number;
    pos[0] = (float)args[1].as.number; pos[1] = (float)args[2].as.number; pos[2] = (float)args[3].as.number;
    rotAxis[0] = (float)args[4].as.number; rotAxis[1] = (float)args[5].as.number; rotAxis[2] = (float)args[6].as.number;
    rotAngle = (float)args[7].as.number;
    scale[0] = (float)args[8].as.number; scale[1] = (float)args[9].as.number; scale[2] = (float)args[10].as.number;
    color[0] = (int)args[11].as.number; color[1] = (int)args[12].as.number; color[2] = (int)args[13].as.number;
  } else {
    return guiError(vm, "drawModelEx expects 5 arguments (id, pos, rot, scale, tint) or 14 arguments.");
  }

  if (raylib.drawModelEx == NULL) return missingRaylibFunction(vm, "drawModelEx");
  raylib.drawModelEx(id, pos[0], pos[1], pos[2], rotAxis[0], rotAxis[1], rotAxis[2], rotAngle,
                     scale[0], scale[1], scale[2], color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawModelRotY(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 5 || !numbersFitInt(args, 1) || !numberFitsFloat(args[2]))
    return guiError(vm, "drawModelRotY(id, pos, rotY, scale, tint) expected.");
  int id = (int)args[0].as.number;
  float pos[3], scale[3];
  int color[4];
  if (!parseVec3(vm, args[1], pos) || !parseScale3(vm, args[3], scale) || !parseColor(vm, args[4], color))
    return guiError(vm, "drawModelRotY(id, pos, rotY, scale, tint) expected.");
  float rotY = (float)args[2].as.number;
  if (raylib.drawModelEx == NULL) return missingRaylibFunction(vm, "drawModelEx");
  raylib.drawModelEx(id, pos[0], pos[1], pos[2], 0.0f, 1.0f, 0.0f, rotY,
                     scale[0], scale[1], scale[2], color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawModelWires(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  int id;
  float pos[3];
  float scale;
  int color[4];

  if (argCount == 4) {
    if (!numbersFitInt(args, 1) || !parseVec3(vm, args[1], pos) ||
        !numberFitsFloat(args[2]) || !parseColor(vm, args[3], color)) {
      return guiError(vm, "drawModelWires(id, pos, scale, tint) expected.");
    }
    id = (int)args[0].as.number;
    scale = (float)args[2].as.number;
  } else if (argCount == 8) {
    if (!numbersFitInt(args, 1) || !numbersFitFloat(args + 1, 4) || !validColor(args + 5))
      return guiError(vm, "drawModelWires(id, x, y, z, scale, r, g, b) expected.");
    id = (int)args[0].as.number;
    pos[0] = (float)args[1].as.number; pos[1] = (float)args[2].as.number; pos[2] = (float)args[3].as.number;
    scale = (float)args[4].as.number;
    color[0] = (int)args[5].as.number; color[1] = (int)args[6].as.number; color[2] = (int)args[7].as.number;
  } else {
    return guiError(vm, "drawModelWires expects 4 arguments (id, pos, scale, tint) or 8 arguments.");
  }

  if (raylib.drawModelWires == NULL) return missingRaylibFunction(vm, "drawModelWires");
  raylib.drawModelWires(id, pos[0], pos[1], pos[2], scale, color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawModelWiresEx(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  int id;
  float pos[3];
  float rotAxis[3] = {0.0f, 1.0f, 0.0f};
  float rotAngle = 0.0f;
  float scale[3];
  int color[4];

  if (argCount == 5) {
    if (!numbersFitInt(args, 1) || !parseVec3(vm, args[1], pos) ||
        !parseScale3(vm, args[3], scale) || !parseColor(vm, args[4], color)) {
      return guiError(vm, "drawModelWiresEx(id, pos, rot, scale, tint) expected.");
    }
    id = (int)args[0].as.number;
    if (numberFitsFloat(args[2])) {
      rotAngle = (float)args[2].as.number;
    } else if (pbIsList(args[2])) {
      double rnums[4];
      int rcount = 0;
      if (!pbListGetNumbers(vm, args[2], rnums, 4, &rcount) || rcount != 4) {
        return guiError(vm, "drawModelWiresEx rot must be an angle number or [rx, ry, rz, angle].");
      }
      rotAxis[0] = (float)rnums[0]; rotAxis[1] = (float)rnums[1]; rotAxis[2] = (float)rnums[2];
      rotAngle = (float)rnums[3];
    } else {
      return guiError(vm, "drawModelWiresEx rot must be an angle number or [rx, ry, rz, angle].");
    }
  } else if (argCount == 14) {
    if (!numbersFitInt(args, 1) || !numbersFitFloat(args + 1, 10) || !validColor(args + 11))
      return guiError(vm, "drawModelWiresEx(id, x, y, z, rx, ry, rz, angle, sx, sy, sz, r, g, b) expected.");
    id = (int)args[0].as.number;
    pos[0] = (float)args[1].as.number; pos[1] = (float)args[2].as.number; pos[2] = (float)args[3].as.number;
    rotAxis[0] = (float)args[4].as.number; rotAxis[1] = (float)args[5].as.number; rotAxis[2] = (float)args[6].as.number;
    rotAngle = (float)args[7].as.number;
    scale[0] = (float)args[8].as.number; scale[1] = (float)args[9].as.number; scale[2] = (float)args[10].as.number;
    color[0] = (int)args[11].as.number; color[1] = (int)args[12].as.number; color[2] = (int)args[13].as.number;
  } else {
    return guiError(vm, "drawModelWiresEx expects 5 arguments (id, pos, rot, scale, tint) or 14 arguments.");
  }

  if (raylib.drawModelWiresEx == NULL) return missingRaylibFunction(vm, "drawModelWiresEx");
  raylib.drawModelWiresEx(id, pos[0], pos[1], pos[2], rotAxis[0], rotAxis[1], rotAxis[2], rotAngle,
                          scale[0], scale[1], scale[2], color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawModelWiresRotY(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 5 || !numbersFitInt(args, 1) || !numberFitsFloat(args[2]))
    return guiError(vm, "drawModelWiresRotY(id, pos, rotY, scale, tint) expected.");
  int id = (int)args[0].as.number;
  float pos[3], scale[3];
  int color[4];
  if (!parseVec3(vm, args[1], pos) || !parseScale3(vm, args[3], scale) || !parseColor(vm, args[4], color))
    return guiError(vm, "drawModelWiresRotY(id, pos, rotY, scale, tint) expected.");
  float rotY = (float)args[2].as.number;
  if (raylib.drawModelWiresEx == NULL) return missingRaylibFunction(vm, "drawModelWiresEx");
  raylib.drawModelWiresEx(id, pos[0], pos[1], pos[2], 0.0f, 1.0f, 0.0f, rotY,
                          scale[0], scale[1], scale[2], color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawQuadStrip3D(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || !pbIsList(args[0]))
    return guiError(vm, "drawQuadStrip3D(quads, color) expected: a list of quads and a color.");
  int color[4];
  if (!parseColor(vm, args[1], color))
    return guiError(vm, "drawQuadStrip3D(quads, color): invalid color.");
  if (raylib.drawQuad3D == NULL) return missingRaylibFunction(vm, "drawQuad3D");
  int count = pbListLength(args[0]);
  for (int i = 0; i < count; i++) {
    PbValue quadVal;
    if (!pbListGet(vm, args[0], i, &quadVal) || !pbIsList(quadVal)) continue;
    if (pbListLength(quadVal) != 4) continue;
    PbValue pv1, pv2, pv3, pv4;
    pbListGet(vm, quadVal, 0, &pv1);
    pbListGet(vm, quadVal, 1, &pv2);
    pbListGet(vm, quadVal, 2, &pv3);
    pbListGet(vm, quadVal, 3, &pv4);
    float p1[3], p2[3], p3[3], p4[3];
    if (parseVec3(vm, pv1, p1) && parseVec3(vm, pv2, p2) &&
        parseVec3(vm, pv3, p3) && parseVec3(vm, pv4, p4)) {
      raylib.drawQuad3D(p1[0], p1[1], p1[2], p2[0], p2[1], p2[2],
                        p3[0], p3[1], p3[2], p4[0], p4[1], p4[2],
                        color[0], color[1], color[2]);
    }
  }
  return pbNilValue();
}

static PbValue guiSetModelTexture(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 3 || !numbersFitInt(args, 3))
    return guiError(vm, "setModelTexture(modelId, materialIndex, textureId) expected.");
  if (raylib.setModelTexture == NULL) return missingRaylibFunction(vm, "setModelTexture");
  raylib.setModelTexture((int)args[0].as.number, (int)args[1].as.number, (int)args[2].as.number);
  return pbNilValue();
}

static PbValue guiTakeScreenshot(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_STRING) return guiError(vm, "takeScreenshot(path) expected.");
  if (raylib.takeScreenshot == NULL) return missingRaylibFunction(vm, "takeScreenshot");
  raylib.takeScreenshot(args[0].as.string.chars);
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
  float p1[2], p2[2];
  int color[4];
  if (argCount == 3) {
    if (!parseVec2(vm, args[0], p1) || !parseVec2(vm, args[1], p2) || !parseColor(vm, args[2], color))
      return guiError(vm, "drawLine(p1, p2, color) expected.");
  } else if (argCount == 7) {
    if (!numbersFitCoord(args, 4) || !validColor(args + 4))
      return guiError(vm, "drawLine(x1, y1, x2, y2, r, g, b) expected.");
    p1[0] = (float)args[0].as.number; p1[1] = (float)args[1].as.number;
    p2[0] = (float)args[2].as.number; p2[1] = (float)args[3].as.number;
    color[0] = (int)args[4].as.number; color[1] = (int)args[5].as.number; color[2] = (int)args[6].as.number;
  } else {
    return guiError(vm, "drawLine expects 3 arguments (p1, p2, color) or 7 arguments.");
  }
  raylib.drawLine((int)p1[0], (int)p1[1], (int)p2[0], (int)p2[1], color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawCircle(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float pos[2];
  float radius;
  int color[4];
  if (argCount == 3) {
    if (!parseVec2(vm, args[0], pos) || !numberFitsFloat(args[1]) || args[1].as.number < 0 ||
        !parseColor(vm, args[2], color)) {
      return guiError(vm, "drawCircle(center, radius, color) expected.");
    }
    radius = (float)args[1].as.number;
  } else if (argCount == 6) {
    if (!numbersFitCoord(args, 2) || !numberFitsFloat(args[2]) || args[2].as.number < 0 || !validColor(args + 3))
      return guiError(vm, "drawCircle(x, y, radius, r, g, b) expected.");
    pos[0] = (float)args[0].as.number; pos[1] = (float)args[1].as.number;
    radius = (float)args[2].as.number;
    color[0] = (int)args[3].as.number; color[1] = (int)args[4].as.number; color[2] = (int)args[5].as.number;
  } else {
    return guiError(vm, "drawCircle expects 3 arguments (center, radius, color) or 6 arguments.");
  }
  raylib.drawCircle((int)pos[0], (int)pos[1], radius, color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawCircleLines(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float pos[2];
  float radius;
  int color[4];
  if (argCount == 3) {
    if (!parseVec2(vm, args[0], pos) || !numberFitsFloat(args[1]) || args[1].as.number < 0 ||
        !parseColor(vm, args[2], color)) {
      return guiError(vm, "drawCircleLines(center, radius, color) expected.");
    }
    radius = (float)args[1].as.number;
  } else if (argCount == 6) {
    if (!numbersFitCoord(args, 2) || !numberFitsFloat(args[2]) || args[2].as.number < 0 || !validColor(args + 3))
      return guiError(vm, "drawCircleLines(x, y, radius, r, g, b) expected.");
    pos[0] = (float)args[0].as.number; pos[1] = (float)args[1].as.number;
    radius = (float)args[2].as.number;
    color[0] = (int)args[3].as.number; color[1] = (int)args[4].as.number; color[2] = (int)args[5].as.number;
  } else {
    return guiError(vm, "drawCircleLines expects 3 arguments (center, radius, color) or 6 arguments.");
  }
  if (raylib.drawCircleLines == NULL) return missingRaylibFunction(vm, "drawCircleLines");
  raylib.drawCircleLines((int)pos[0], (int)pos[1], radius, color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawCircleAlpha(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float pos[2];
  float radius;
  int color[4];
  if (argCount == 3) {
    if (!parseVec2(vm, args[0], pos) || !numberFitsFloat(args[1]) || args[1].as.number < 0 ||
        !parseColor(vm, args[2], color)) {
      return guiError(vm, "drawCircleAlpha(center, radius, colorWithAlpha) expected.");
    }
    radius = (float)args[1].as.number;
  } else if (argCount == 4) {
    if (!parseVec2(vm, args[0], pos) || !numberFitsFloat(args[1]) || args[1].as.number < 0 ||
        !parseColor(vm, args[2], color) || !numberFitsFloat(args[3]) || args[3].as.number < 0 || args[3].as.number > 255) {
      return guiError(vm, "drawCircleAlpha(center, radius, color, alpha) expected.");
    }
    radius = (float)args[1].as.number;
    color[3] = (int)args[3].as.number;
  } else if (argCount == 7) {
    if (!numbersFitCoord(args, 2) || !numberFitsFloat(args[2]) || args[2].as.number < 0 || !validColorAlpha(args + 3))
      return guiError(vm, "drawCircleAlpha(x, y, radius, r, g, b, a) expected.");
    pos[0] = (float)args[0].as.number; pos[1] = (float)args[1].as.number;
    radius = (float)args[2].as.number;
    color[0] = (int)args[3].as.number; color[1] = (int)args[4].as.number; color[2] = (int)args[5].as.number;
    color[3] = (int)args[6].as.number;
  } else {
    return guiError(vm, "drawCircleAlpha expects 3, 4, or 7 arguments.");
  }
  if (raylib.drawCircleAlpha == NULL) return missingRaylibFunction(vm, "drawCircleAlpha");
  raylib.drawCircleAlpha((int)pos[0], (int)pos[1], radius, color[0], color[1], color[2], color[3]);
  return pbNilValue();
}

static PbValue guiDrawEllipse(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float pos[2];
  float radii[2];
  int color[4];
  if (argCount == 3) {
    if (!parseVec2(vm, args[0], pos) || !parseVec2(vm, args[1], radii) || radii[0] < 0 || radii[1] < 0 ||
        !parseColor(vm, args[2], color)) {
      return guiError(vm, "drawEllipse(center, [radiusH, radiusV], color) expected.");
    }
  } else if (argCount == 4) {
    if (!parseVec2(vm, args[0], pos) || !numberFitsFloat(args[1]) || !numberFitsFloat(args[2]) ||
        args[1].as.number < 0 || args[2].as.number < 0 || !parseColor(vm, args[3], color)) {
      return guiError(vm, "drawEllipse(center, radiusH, radiusV, color) expected.");
    }
    radii[0] = (float)args[1].as.number; radii[1] = (float)args[2].as.number;
  } else if (argCount == 7) {
    if (!numbersFitCoord(args, 2) || !numberFitsFloat(args[2]) || !numberFitsFloat(args[3]) ||
        args[2].as.number < 0 || args[3].as.number < 0 || !validColor(args + 4))
      return guiError(vm, "drawEllipse(x, y, radiusH, radiusV, r, g, b) expected.");
    pos[0] = (float)args[0].as.number; pos[1] = (float)args[1].as.number;
    radii[0] = (float)args[2].as.number; radii[1] = (float)args[3].as.number;
    color[0] = (int)args[4].as.number; color[1] = (int)args[5].as.number; color[2] = (int)args[6].as.number;
  } else {
    return guiError(vm, "drawEllipse expects 3, 4, or 7 arguments.");
  }
  raylib.drawEllipse((int)pos[0], (int)pos[1], radii[0], radii[1], color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawRectangle(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float rect[4];
  int color[4];
  if (argCount == 2) {
    if (!parseRect(vm, args[0], rect) || !parseColor(vm, args[1], color))
      return guiError(vm, "drawRectangle(rect, color) expected.");
  } else if (argCount == 5) {
    if (!numbersFitCoord(args, 4) || !parseColor(vm, args[4], color))
      return guiError(vm, "drawRectangle(x, y, width, height, color) expected.");
    rect[0] = (float)args[0].as.number; rect[1] = (float)args[1].as.number;
    rect[2] = (float)args[2].as.number; rect[3] = (float)args[3].as.number;
  } else if (argCount == 7) {
    if (!numbersFitCoord(args, 4) || !validColor(args + 4))
      return guiError(vm, "drawRectangle(x, y, width, height, r, g, b) expected.");
    rect[0] = (float)args[0].as.number; rect[1] = (float)args[1].as.number;
    rect[2] = (float)args[2].as.number; rect[3] = (float)args[3].as.number;
    color[0] = (int)args[4].as.number; color[1] = (int)args[5].as.number; color[2] = (int)args[6].as.number;
  } else {
    return guiError(vm, "drawRectangle expects 2, 5, or 7 arguments.");
  }
  raylib.drawRectangle((int)rect[0], (int)rect[1], (int)rect[2], (int)rect[3], color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawRectangleLines(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float rect[4];
  int color[4];
  if (argCount == 2) {
    if (!parseRect(vm, args[0], rect) || !parseColor(vm, args[1], color))
      return guiError(vm, "drawRectangleLines(rect, color) expected.");
  } else if (argCount == 5) {
    if (!numbersFitCoord(args, 4) || !parseColor(vm, args[4], color))
      return guiError(vm, "drawRectangleLines(x, y, width, height, color) expected.");
    rect[0] = (float)args[0].as.number; rect[1] = (float)args[1].as.number;
    rect[2] = (float)args[2].as.number; rect[3] = (float)args[3].as.number;
  } else if (argCount == 7) {
    if (!numbersFitCoord(args, 4) || !validColor(args + 4))
      return guiError(vm, "drawRectangleLines(x, y, width, height, r, g, b) expected.");
    rect[0] = (float)args[0].as.number; rect[1] = (float)args[1].as.number;
    rect[2] = (float)args[2].as.number; rect[3] = (float)args[3].as.number;
    color[0] = (int)args[4].as.number; color[1] = (int)args[5].as.number; color[2] = (int)args[6].as.number;
  } else {
    return guiError(vm, "drawRectangleLines expects 2, 5, or 7 arguments.");
  }
  if (raylib.drawRectangleLines == NULL) return missingRaylibFunction(vm, "drawRectangleLines");
  raylib.drawRectangleLines((int)rect[0], (int)rect[1], (int)rect[2], (int)rect[3], color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawRectangleAlpha(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float rect[4];
  int color[4];
  if (argCount == 2) {
    if (!parseRect(vm, args[0], rect) || !parseColor(vm, args[1], color))
      return guiError(vm, "drawRectangleAlpha(rect, colorWithAlpha) expected.");
  } else if (argCount == 3) {
    if (!parseRect(vm, args[0], rect) || !parseColor(vm, args[1], color) ||
        !numberFitsFloat(args[2]) || args[2].as.number < 0 || args[2].as.number > 255) {
      return guiError(vm, "drawRectangleAlpha(rect, color, alpha) expected.");
    }
    color[3] = (int)args[2].as.number;
  } else if (argCount == 6) {
    if (!numbersFitCoord(args, 4) || !parseColor(vm, args[4], color) ||
        !numberFitsFloat(args[5]) || args[5].as.number < 0 || args[5].as.number > 255) {
      return guiError(vm, "drawRectangleAlpha(x, y, width, height, color, alpha) expected.");
    }
    rect[0] = (float)args[0].as.number; rect[1] = (float)args[1].as.number;
    rect[2] = (float)args[2].as.number; rect[3] = (float)args[3].as.number;
    color[3] = (int)args[5].as.number;
  } else if (argCount == 8) {
    if (!numbersFitCoord(args, 4) || !validColorAlpha(args + 4))
      return guiError(vm, "drawRectangleAlpha(x, y, width, height, r, g, b, a) expected.");
    rect[0] = (float)args[0].as.number; rect[1] = (float)args[1].as.number;
    rect[2] = (float)args[2].as.number; rect[3] = (float)args[3].as.number;
    color[0] = (int)args[4].as.number; color[1] = (int)args[5].as.number; color[2] = (int)args[6].as.number;
    color[3] = (int)args[7].as.number;
  } else {
    return guiError(vm, "drawRectangleAlpha expects 2, 3, 6, or 8 arguments.");
  }
  if (raylib.drawRectangleAlpha == NULL) return missingRaylibFunction(vm, "drawRectangleAlpha");
  raylib.drawRectangleAlpha((int)rect[0], (int)rect[1], (int)rect[2], (int)rect[3],
                            color[0], color[1], color[2], color[3]);
  return pbNilValue();
}

static PbValue guiDrawRectangleRounded(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float rect[4];
  float roundness;
  int segments;
  int color[4];
  if (argCount == 4) {
    if (!parseRect(vm, args[0], rect) || !numberFitsFloat(args[1]) || args[1].as.number < 0.0 ||
        args[1].as.number > 1.0 || !numbersFitInt(args + 2, 1) || args[2].as.number <= 0 ||
        !parseColor(vm, args[3], color)) {
      return guiError(vm, "drawRectangleRounded(rect, roundness, segments, color) expected.");
    }
    roundness = (float)args[1].as.number;
    segments = (int)args[2].as.number;
  } else if (argCount == 9) {
    if (!numbersFitFloat(args, 5) || !numbersFitInt(args + 5, 1) || args[4].as.number < 0.0 ||
        args[4].as.number > 1.0 || args[5].as.number <= 0 || !validColor(args + 6)) {
      return guiError(vm, "drawRectangleRounded(x, y, width, height, roundness, segments, r, g, b) expected.");
    }
    rect[0] = (float)args[0].as.number; rect[1] = (float)args[1].as.number;
    rect[2] = (float)args[2].as.number; rect[3] = (float)args[3].as.number;
    roundness = (float)args[4].as.number;
    segments = (int)args[5].as.number;
    color[0] = (int)args[6].as.number; color[1] = (int)args[7].as.number; color[2] = (int)args[8].as.number;
  } else {
    return guiError(vm, "drawRectangleRounded expects 4 arguments (rect, roundness, segments, color) or 9 arguments.");
  }
  if (raylib.drawRectangleRounded == NULL) return missingRaylibFunction(vm, "drawRectangleRounded");
  raylib.drawRectangleRounded(rect[0], rect[1], rect[2], rect[3], roundness, segments, color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawText(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float pos[2];
  int fontSize;
  int color[4];
  if (argCount == 4) {
    if (args[0].type != PB_VALUE_STRING || !parseVec2(vm, args[1], pos) ||
        !numbersFitInt(args + 2, 1) || args[2].as.number <= 0 || !parseColor(vm, args[3], color)) {
      return guiError(vm, "drawText(text, pos, fontSize, color) expected.");
    }
    fontSize = (int)args[2].as.number;
  } else if (argCount == 5) {
    if (args[0].type != PB_VALUE_STRING || !numbersFitCoord(args + 1, 2) ||
        !numbersFitInt(args + 3, 1) || args[3].as.number <= 0 || !parseColor(vm, args[4], color)) {
      return guiError(vm, "drawText(text, x, y, fontSize, color) expected.");
    }
    pos[0] = (float)args[1].as.number; pos[1] = (float)args[2].as.number;
    fontSize = (int)args[3].as.number;
  } else if (argCount == 7) {
    if (args[0].type != PB_VALUE_STRING || !numbersFitCoord(args + 1, 2) ||
        !numbersFitInt(args + 3, 1) || args[3].as.number <= 0 || !validColor(args + 4)) {
      return guiError(vm, "drawText(text, x, y, fontSize, r, g, b) expected.");
    }
    pos[0] = (float)args[1].as.number; pos[1] = (float)args[2].as.number;
    fontSize = (int)args[3].as.number;
    color[0] = (int)args[4].as.number; color[1] = (int)args[5].as.number; color[2] = (int)args[6].as.number;
  } else {
    return guiError(vm, "drawText expects 4, 5, or 7 arguments.");
  }
  raylib.drawText(args[0].as.string.chars, (int)pos[0], (int)pos[1], fontSize, color[0], color[1], color[2]);
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
  if (argCount != 1) return guiError(vm, usage);
  int key = -1;
  if (args[0].type == PB_VALUE_NUMBER) {
    if (!fitsInt(args[0].as.number)) return guiError(vm, usage);
    key = (int)args[0].as.number;
  } else if (args[0].type == PB_VALUE_STRING) {
    key = getKeyCode(args[0].as.string.chars);
    if (key < 0) {
      char message[512];
      snprintf(message, sizeof(message), "Invalid key name: %s.", args[0].as.string.chars);
      return guiError(vm, message);
    }
  } else {
    return guiError(vm, usage);
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
  if (argCount != 1) return guiError(vm, usage);
  int button = -1;
  if (args[0].type == PB_VALUE_NUMBER) {
    if (!fitsInt(args[0].as.number)) return guiError(vm, usage);
    button = (int)args[0].as.number;
    if (button < 0 || button > 6) return guiError(vm, "Invalid mouse button code.");
  } else if (args[0].type == PB_VALUE_STRING) {
    button = getMouseButtonCode(args[0].as.string.chars);
    if (button < 0) {
      char message[512];
      snprintf(message, sizeof(message), "Invalid mouse button name: %s.", args[0].as.string.chars);
      return guiError(vm, message);
    }
  } else {
    return guiError(vm, usage);
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
  float r1[4], r2[4];
  if (argCount == 2) {
    if (!parseRect(vm, args[0], r1) || !parseRect(vm, args[1], r2))
      return guiError(vm, "checkCollisionRecs(rect1, rect2) expected two [x, y, w, h] lists.");
  } else if (argCount == 8) {
    if (!numbersFitFloat(args, 8))
      return guiError(vm, "checkCollisionRecs(x1, y1, w1, h1, x2, y2, w2, h2) expected.");
    r1[0] = (float)args[0].as.number; r1[1] = (float)args[1].as.number;
    r1[2] = (float)args[2].as.number; r1[3] = (float)args[3].as.number;
    r2[0] = (float)args[4].as.number; r2[1] = (float)args[5].as.number;
    r2[2] = (float)args[6].as.number; r2[3] = (float)args[7].as.number;
  } else {
    return guiError(vm, "checkCollisionRecs expects 2 arguments (rect1, rect2) or 8 arguments.");
  }
  if (raylib.checkCollisionRecs == NULL) return missingRaylibFunction(vm, "checkCollisionRecs");
  return pbBoolValue(raylib.checkCollisionRecs(r1[0], r1[1], r1[2], r1[3], r2[0], r2[1], r2[2], r2[3]));
}

static PbValue guiCheckCollisionCircles(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float c1[3], c2[3];
  if (argCount == 2) {
    if (!parseVec3(vm, args[0], c1) || !parseVec3(vm, args[1], c2) || c1[2] < 0 || c2[2] < 0)
      return guiError(vm, "checkCollisionCircles(circle1, circle2) expected two [x, y, radius] lists.");
  } else if (argCount == 4) {
    float p1[2], p2[2];
    if (!parseVec2(vm, args[0], p1) || !numberFitsFloat(args[1]) || args[1].as.number < 0 ||
        !parseVec2(vm, args[2], p2) || !numberFitsFloat(args[3]) || args[3].as.number < 0) {
      return guiError(vm, "checkCollisionCircles(p1, r1, p2, r2) expected.");
    }
    c1[0] = p1[0]; c1[1] = p1[1]; c1[2] = (float)args[1].as.number;
    c2[0] = p2[0]; c2[1] = p2[1]; c2[2] = (float)args[3].as.number;
  } else if (argCount == 6) {
    if (!numbersFitFloat(args, 6) || args[2].as.number < 0.0 || args[5].as.number < 0.0)
      return guiError(vm, "checkCollisionCircles(x1, y1, r1, x2, y2, r2) expected.");
    c1[0] = (float)args[0].as.number; c1[1] = (float)args[1].as.number; c1[2] = (float)args[2].as.number;
    c2[0] = (float)args[3].as.number; c2[1] = (float)args[4].as.number; c2[2] = (float)args[5].as.number;
  } else {
    return guiError(vm, "checkCollisionCircles expects 2, 4, or 6 arguments.");
  }
  if (raylib.checkCollisionCircles == NULL) return missingRaylibFunction(vm, "checkCollisionCircles");
  return pbBoolValue(raylib.checkCollisionCircles(c1[0], c1[1], c1[2], c2[0], c2[1], c2[2]));
}

static PbValue guiCheckCollisionCircleRec(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float c[3], r[4];
  if (argCount == 2) {
    if (!parseVec3(vm, args[0], c) || !parseRect(vm, args[1], r) || c[2] < 0)
      return guiError(vm, "checkCollisionCircleRec(circle, rect) expected [cx, cy, r] and [rx, ry, rw, rh].");
  } else if (argCount == 3) {
    float pos[2];
    if (!parseVec2(vm, args[0], pos) || !numberFitsFloat(args[1]) || args[1].as.number < 0 ||
        !parseRect(vm, args[2], r)) {
      return guiError(vm, "checkCollisionCircleRec(pos, radius, rect) expected.");
    }
    c[0] = pos[0]; c[1] = pos[1]; c[2] = (float)args[1].as.number;
  } else if (argCount == 7) {
    if (!numbersFitFloat(args, 7) || args[2].as.number < 0.0)
      return guiError(vm, "checkCollisionCircleRec(cx, cy, radius, rx, ry, rw, rh) expected.");
    c[0] = (float)args[0].as.number; c[1] = (float)args[1].as.number; c[2] = (float)args[2].as.number;
    r[0] = (float)args[3].as.number; r[1] = (float)args[4].as.number;
    r[2] = (float)args[5].as.number; r[3] = (float)args[6].as.number;
  } else {
    return guiError(vm, "checkCollisionCircleRec expects 2, 3, or 7 arguments.");
  }
  if (raylib.checkCollisionCircleRec == NULL) return missingRaylibFunction(vm, "checkCollisionCircleRec");
  return pbBoolValue(raylib.checkCollisionCircleRec(c[0], c[1], c[2], r[0], r[1], r[2], r[3]));
}

static PbValue guiCheckCollisionPointRec(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float p[2], r[4];
  if (argCount == 2) {
    if (!parseVec2(vm, args[0], p) || !parseRect(vm, args[1], r))
      return guiError(vm, "checkCollisionPointRec(point, rect) expected [px, py] and [rx, ry, rw, rh].");
  } else if (argCount == 6) {
    if (!numbersFitFloat(args, 6))
      return guiError(vm, "checkCollisionPointRec(px, py, rx, ry, rw, rh) expected.");
    p[0] = (float)args[0].as.number; p[1] = (float)args[1].as.number;
    r[0] = (float)args[2].as.number; r[1] = (float)args[3].as.number;
    r[2] = (float)args[4].as.number; r[3] = (float)args[5].as.number;
  } else {
    return guiError(vm, "checkCollisionPointRec expects 2 or 6 arguments.");
  }
  if (raylib.checkCollisionPointRec == NULL) return missingRaylibFunction(vm, "checkCollisionPointRec");
  return pbBoolValue(raylib.checkCollisionPointRec(p[0], p[1], r[0], r[1], r[2], r[3]));
}

static PbValue guiCheckCollisionPointCircle(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  float p[2], c[2];
  float radius;
  if (argCount == 2) {
    float circle[3];
    if (!parseVec2(vm, args[0], p) || !parseVec3(vm, args[1], circle) || circle[2] < 0)
      return guiError(vm, "checkCollisionPointCircle(point, circle) expected [px, py] and [cx, cy, r].");
    c[0] = circle[0]; c[1] = circle[1]; radius = circle[2];
  } else if (argCount == 3) {
    if (!parseVec2(vm, args[0], p) || !parseVec2(vm, args[1], c) ||
        !numberFitsFloat(args[2]) || args[2].as.number < 0) {
      return guiError(vm, "checkCollisionPointCircle(point, center, radius) expected.");
    }
    radius = (float)args[2].as.number;
  } else if (argCount == 5) {
    if (!numbersFitFloat(args, 5) || args[4].as.number < 0.0)
      return guiError(vm, "checkCollisionPointCircle(px, py, cx, cy, radius) expected.");
    p[0] = (float)args[0].as.number; p[1] = (float)args[1].as.number;
    c[0] = (float)args[2].as.number; c[1] = (float)args[3].as.number;
    radius = (float)args[4].as.number;
  } else {
    return guiError(vm, "checkCollisionPointCircle expects 2, 3, or 5 arguments.");
  }
  if (raylib.checkCollisionPointCircle == NULL) return missingRaylibFunction(vm, "checkCollisionPointCircle");
  return pbBoolValue(raylib.checkCollisionPointCircle(p[0], p[1], c[0], c[1], radius));
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
  int id;
  float pos[2];
  if (argCount == 2) {
    if (!numbersFitInt(args, 1) || !parseVec2(vm, args[1], pos))
      return guiError(vm, "drawTexture(id, pos) expected.");
    id = (int)args[0].as.number;
  } else if (argCount == 3) {
    if (!numbersFitInt(args, 1) || !numbersFitCoord(args + 1, 2))
      return guiError(vm, "drawTexture(id, x, y) expected.");
    id = (int)args[0].as.number;
    pos[0] = (float)args[1].as.number; pos[1] = (float)args[2].as.number;
  } else {
    return guiError(vm, "drawTexture expects 2 arguments (id, pos) or 3 arguments.");
  }
  if (raylib.drawTexture == NULL) return missingRaylibFunction(vm, "drawTexture");
  raylib.drawTexture(id, (int)pos[0], (int)pos[1]);
  return pbNilValue();
}

static PbValue guiDrawTextureTint(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  int id;
  float pos[2];
  int color[4];
  if (argCount == 3) {
    if (!numbersFitInt(args, 1) || !parseVec2(vm, args[1], pos) || !parseColor(vm, args[2], color))
      return guiError(vm, "drawTextureTint(id, pos, color) expected.");
    id = (int)args[0].as.number;
  } else if (argCount == 6) {
    if (!numbersFitInt(args, 1) || !numbersFitCoord(args + 1, 2) || !validColor(args + 3))
      return guiError(vm, "drawTextureTint(id, x, y, r, g, b) expected.");
    id = (int)args[0].as.number;
    pos[0] = (float)args[1].as.number; pos[1] = (float)args[2].as.number;
    color[0] = (int)args[3].as.number; color[1] = (int)args[4].as.number; color[2] = (int)args[5].as.number;
  } else {
    return guiError(vm, "drawTextureTint expects 3 arguments (id, pos, color) or 6 arguments.");
  }
  if (raylib.drawTextureTint == NULL) return missingRaylibFunction(vm, "drawTextureTint");
  raylib.drawTextureTint(id, (int)pos[0], (int)pos[1], color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiDrawTextureRec(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  int id;
  float src[4], dest[2];
  if (argCount == 3) {
    if (!numbersFitInt(args, 1) || !parseRect(vm, args[1], src) || !parseVec2(vm, args[2], dest))
      return guiError(vm, "drawTextureRec(id, srcRect, destPos) expected.");
    id = (int)args[0].as.number;
  } else if (argCount == 7) {
    if (!numbersFitInt(args, 1) || !numbersFitFloat(args + 1, 6))
      return guiError(vm, "drawTextureRec(id, sourceX, sourceY, sourceW, sourceH, destX, destY) expected.");
    id = (int)args[0].as.number;
    src[0] = (float)args[1].as.number; src[1] = (float)args[2].as.number;
    src[2] = (float)args[3].as.number; src[3] = (float)args[4].as.number;
    dest[0] = (float)args[5].as.number; dest[1] = (float)args[6].as.number;
  } else {
    return guiError(vm, "drawTextureRec expects 3 arguments (id, srcRect, destPos) or 7 arguments.");
  }
  if (raylib.drawTextureRec == NULL) return missingRaylibFunction(vm, "drawTextureRec");
  raylib.drawTextureRec(id, src[0], src[1], src[2], src[3], dest[0], dest[1]);
  return pbNilValue();
}

static PbValue guiDrawTexturePro(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  int id;
  float src[4], dest[4], origin[2];
  float rot;
  if (argCount == 5) {
    if (!numbersFitInt(args, 1) || !parseRect(vm, args[1], src) || !parseRect(vm, args[2], dest) ||
        !parseVec2(vm, args[3], origin) || !numberFitsFloat(args[4])) {
      return guiError(vm, "drawTexturePro(id, srcRect, destRect, origin, rot) expected.");
    }
    id = (int)args[0].as.number;
    rot = (float)args[4].as.number;
  } else if (argCount == 12) {
    if (!numbersFitInt(args, 1) || !numbersFitFloat(args + 1, 11))
      return guiError(vm, "drawTexturePro(id, sx, sy, sw, sh, dx, dy, dw, dh, ox, oy, rot) expected.");
    id = (int)args[0].as.number;
    src[0] = (float)args[1].as.number; src[1] = (float)args[2].as.number;
    src[2] = (float)args[3].as.number; src[3] = (float)args[4].as.number;
    dest[0] = (float)args[5].as.number; dest[1] = (float)args[6].as.number;
    dest[2] = (float)args[7].as.number; dest[3] = (float)args[8].as.number;
    origin[0] = (float)args[9].as.number; origin[1] = (float)args[10].as.number;
    rot = (float)args[11].as.number;
  } else {
    return guiError(vm, "drawTexturePro expects 5 arguments (id, srcRect, destRect, origin, rot) or 12 arguments.");
  }
  if (raylib.drawTexturePro == NULL) return missingRaylibFunction(vm, "drawTexturePro");
  raylib.drawTexturePro(id, src[0], src[1], src[2], src[3],
                        dest[0], dest[1], dest[2], dest[3],
                        origin[0], origin[1], rot);
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

static const char *shaderPathOrNull(const PbValue *value, bool *ok) {
  if (value->type == PB_VALUE_NIL) return NULL;
  if (value->type == PB_VALUE_STRING) {
    if (value->as.string.chars[0] == '\0') return NULL;
    return value->as.string.chars;
  }
  *ok = false;
  return NULL;
}

static PbValue guiLoadShader(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  const char *vs = NULL;
  const char *fs = NULL;
  if (argCount == 1) {
    if (args[0].type != PB_VALUE_STRING || args[0].as.string.chars[0] == '\0') {
      return guiError(vm, "loadShader(fsPath) or loadShader(vsPath, fsPath) expected.");
    }
    fs = args[0].as.string.chars;
  } else if (argCount == 2) {
    bool ok = true;
    vs = shaderPathOrNull(&args[0], &ok);
    fs = shaderPathOrNull(&args[1], &ok);
    if (!ok) return guiError(vm, "loadShader(vsPath, fsPath) expected (nil selects the default).");
  } else {
    return guiError(vm, "loadShader(vsPath, fsPath) expected (nil selects the default).");
  }
  if (raylib.loadShader == NULL) return missingRaylibFunction(vm, "loadShader");
  int id = raylib.loadShader(vs, fs);
  if (id <= 0) {
    char message[512];
    snprintf(message, sizeof(message),
             "loadShader() failed for vs=\"%s\" fs=\"%s\". Check the paths and GLSL, or call "
             "gui.setDebugMode(true) for Raylib shader logs.",
             vs != NULL ? vs : "(default)", fs != NULL ? fs : "(default)");
    return guiError(vm, message);
  }
  return pbNewResource(vm, "shader", GUI_RESOURCE_SHADER, id, unloadShaderFinalizer, NULL);
}

static PbValue guiUnloadShader(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1) return guiError(vm, "unloadShader(shader) expected a shader.");
  int tag = 0;
  int backendId = 0;
  if (!pbResourceInfo(args[0], NULL, &tag, &backendId, NULL) || tag != GUI_RESOURCE_SHADER)
    return guiError(vm, "unloadShader(shader) expected a shader.");
  if (raylib.unloadShader == NULL) return missingRaylibFunction(vm, "unloadShader");
  raylib.unloadShader(backendId);
  pbResourceClose(args[0]);
  return pbNilValue();
}

static PbValue guiBeginShaderMode(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1) return guiError(vm, "beginShaderMode(shader) expected a shader.");
  int id = 0;
  if (!shaderId(vm, args[0], &id, "beginShaderMode(shader) expected a shader.")) return pbNilValue();
  if (raylib.beginShaderMode == NULL) return missingRaylibFunction(vm, "beginShaderMode");
  raylib.beginShaderMode(id);
  return pbNilValue();
}

static PbValue guiEndShaderMode(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "endShaderMode() takes no arguments.");
  if (raylib.endShaderMode == NULL) return missingRaylibFunction(vm, "endShaderMode");
  raylib.endShaderMode();
  return pbNilValue();
}

static PbValue guiSetShaderFloat(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 3 || args[1].type != PB_VALUE_STRING || args[1].as.string.chars[0] == '\0' ||
      !numberFitsFloat(args[2]))
    return guiError(vm, "setShaderFloat(shader, uniformName, value) expected.");
  int id = 0;
  if (!shaderId(vm, args[0], &id, "setShaderFloat(shader, uniformName, value) expected.")) return pbNilValue();
  if (raylib.setShaderFloat == NULL) return missingRaylibFunction(vm, "setShaderFloat");
  raylib.setShaderFloat(id, args[1].as.string.chars, (float)args[2].as.number);
  return pbNilValue();
}

static PbValue guiSetShaderVec2(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 4 || args[1].type != PB_VALUE_STRING || args[1].as.string.chars[0] == '\0' ||
      !numberFitsFloat(args[2]) || !numberFitsFloat(args[3]))
    return guiError(vm, "setShaderVec2(shader, uniformName, x, y) expected.");
  int id = 0;
  if (!shaderId(vm, args[0], &id, "setShaderVec2(shader, uniformName, x, y) expected.")) return pbNilValue();
  if (raylib.setShaderVec2 == NULL) return missingRaylibFunction(vm, "setShaderVec2");
  raylib.setShaderVec2(id, args[1].as.string.chars, (float)args[2].as.number, (float)args[3].as.number);
  return pbNilValue();
}


static PbValue guiSetTraceLogLevel(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_STRING)
    return guiError(vm, "setTraceLogLevel(level) expected one of ALL, TRACE, DEBUG, INFO, WARNING, ERROR, FATAL, NONE.");
  int level = getTraceLogLevelCode(args[0].as.string.chars);
  if (level < 0)
    return guiError(vm, "setTraceLogLevel(level) expected one of ALL, TRACE, DEBUG, INFO, WARNING, ERROR, FATAL, NONE.");
  if (raylib.setTraceLogLevel == NULL) return missingRaylibFunction(vm, "setTraceLogLevel");
  raylib.setTraceLogLevel(level);
  return pbNilValue();
}

static PbValue guiSetDebugMode(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_BOOL)
    return guiError(vm, "setDebugMode(enabled) expected a boolean.");
  if (raylib.setDebugMode == NULL) return missingRaylibFunction(vm, "setDebugMode");
  raylib.setDebugMode(args[0].as.boolean ? 0 : 5);
  return pbNilValue();
}

static PbValue guiLoadRenderTexture(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || !numbersFitInt(args, 2) || args[0].as.number <= 0 || args[1].as.number <= 0)
    return guiError(vm, "loadRenderTexture(width, height) expected positive integers.");
  if (raylib.loadRenderTexture == NULL) return missingRaylibFunction(vm, "loadRenderTexture");
  int id = raylib.loadRenderTexture((int)args[0].as.number, (int)args[1].as.number);
  if (id <= 0) {
    char message[512];
    snprintf(message, sizeof(message),
             "loadRenderTexture(%d, %d) failed. Lower the size or call gui.setDebugMode(true) for Raylib logs.",
             (int)args[0].as.number, (int)args[1].as.number);
    return guiError(vm, message);
  }
  return pbNewResource(vm, "render texture", GUI_RESOURCE_RENDER_TEXTURE, id, unloadRenderTextureFinalizer, NULL);
}

static PbValue guiUnloadRenderTexture(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1) return guiError(vm, "unloadRenderTexture(target) expected a render texture.");
  int tag = 0;
  int backendId = 0;
  if (!pbResourceInfo(args[0], NULL, &tag, &backendId, NULL) || tag != GUI_RESOURCE_RENDER_TEXTURE)
    return guiError(vm, "unloadRenderTexture(target) expected a render texture.");
  if (raylib.unloadRenderTexture == NULL) return missingRaylibFunction(vm, "unloadRenderTexture");
  raylib.unloadRenderTexture(backendId);
  pbResourceClose(args[0]);
  return pbNilValue();
}

static PbValue guiBeginTextureMode(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1) return guiError(vm, "beginTextureMode(target) expected a render texture.");
  int id = 0;
  if (!renderTextureId(vm, args[0], &id, "beginTextureMode(target) expected a render texture.")) return pbNilValue();
  if (raylib.beginTextureMode == NULL) return missingRaylibFunction(vm, "beginTextureMode");
  raylib.beginTextureMode(id);
  return pbNilValue();
}

static PbValue guiEndTextureMode(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "endTextureMode() takes no arguments.");
  if (raylib.endTextureMode == NULL) return missingRaylibFunction(vm, "endTextureMode");
  raylib.endTextureMode();
  return pbNilValue();
}

static PbValue guiDrawRenderTexture(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  int id = 0;
  float pos[2];
  if (argCount == 2) {
    if (!renderTextureId(vm, args[0], &id, "drawRenderTexture(target, pos) expected.") ||
        !parseVec2(vm, args[1], pos)) {
      return guiError(vm, "drawRenderTexture(target, pos) expected.");
    }
  } else if (argCount == 3) {
    if (!renderTextureId(vm, args[0], &id, "drawRenderTexture(target, x, y) expected.") ||
        !numbersFitCoord(args + 1, 2)) {
      return guiError(vm, "drawRenderTexture(target, x, y) expected.");
    }
    pos[0] = (float)args[1].as.number; pos[1] = (float)args[2].as.number;
  } else {
    return guiError(vm, "drawRenderTexture expects 2 or 3 arguments.");
  }
  if (raylib.drawRenderTexture == NULL) return missingRaylibFunction(vm, "drawRenderTexture");
  raylib.drawRenderTexture(id, (int)pos[0], (int)pos[1]);
  return pbNilValue();
}

static PbValue guiDrawRenderTextureRec(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  int id = 0;
  float src[4], dest[2];
  if (argCount == 3) {
    if (!renderTextureId(vm, args[0], &id, "drawRenderTextureRec(target, srcRect, destPos) expected.") ||
        !parseRect(vm, args[1], src) || !parseVec2(vm, args[2], dest)) {
      return guiError(vm, "drawRenderTextureRec(target, srcRect, destPos) expected.");
    }
  } else if (argCount == 7) {
    if (!renderTextureId(vm, args[0], &id,
                         "drawRenderTextureRec(target, sourceX, sourceY, sourceW, sourceH, destX, destY) expected.") ||
        !numbersFitFloat(args + 1, 6)) {
      return guiError(vm, "drawRenderTextureRec(target, sourceX, sourceY, sourceW, sourceH, destX, destY) expected.");
    }
    src[0] = (float)args[1].as.number; src[1] = (float)args[2].as.number;
    src[2] = (float)args[3].as.number; src[3] = (float)args[4].as.number;
    dest[0] = (float)args[5].as.number; dest[1] = (float)args[6].as.number;
  } else {
    return guiError(vm, "drawRenderTextureRec expects 3 or 7 arguments.");
  }
  if (raylib.drawRenderTextureRec == NULL) return missingRaylibFunction(vm, "drawRenderTextureRec");
  raylib.drawRenderTextureRec(id, src[0], src[1], src[2], src[3], dest[0], dest[1]);
  return pbNilValue();
}

static PbValue guiLoadFont(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || args[0].type != PB_VALUE_STRING || args[0].as.string.chars[0] == '\0' ||
      !numbersFitInt(args + 1, 1) || args[1].as.number <= 0)
    return guiError(vm, "loadFont(path, size) expected a path and a positive size.");
  if (raylib.loadFont == NULL) return missingRaylibFunction(vm, "loadFont");
  int id = raylib.loadFont(args[0].as.string.chars, (int)args[1].as.number);
  if (id == 0) return pbNilValue();
  if (id < 0) {
    char message[512];
    snprintf(message, sizeof(message), "loadFont() failed for \"%s\". Check the file or call gui.setDebugMode(true).",
             args[0].as.string.chars);
    return guiError(vm, message);
  }
  return pbNewResource(vm, "font", GUI_RESOURCE_FONT, id, unloadFontFinalizer, NULL);
}

static PbValue guiUnloadFont(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1) return guiError(vm, "unloadFont(font) expected a font.");
  int tag = 0;
  int backendId = 0;
  if (!pbResourceInfo(args[0], NULL, &tag, &backendId, NULL) || tag != GUI_RESOURCE_FONT)
    return guiError(vm, "unloadFont(font) expected a font.");
  if (raylib.unloadFont == NULL) return missingRaylibFunction(vm, "unloadFont");
  raylib.unloadFont(backendId);
  pbResourceClose(args[0]);
  return pbNilValue();
}

static PbValue guiDrawTextFont(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  int id = 0;
  float pos[2];
  float size, spacing;
  int color[4];
  if (argCount == 6) {
    if (!fontId(vm, args[0], &id, "drawTextFont(font, text, pos, size, spacing, color) expected.") ||
        args[1].type != PB_VALUE_STRING || !parseVec2(vm, args[2], pos) ||
        !numberFitsFloat(args[3]) || args[3].as.number <= 0 ||
        !numberFitsFloat(args[4]) || !parseColor(vm, args[5], color)) {
      return guiError(vm, "drawTextFont(font, text, pos, size, spacing, color) expected.");
    }
    size = (float)args[3].as.number;
    spacing = (float)args[4].as.number;
  } else if (argCount == 9) {
    if (!fontId(vm, args[0], &id, "drawTextFont(font, text, x, y, size, spacing, r, g, b) expected.") ||
        args[1].type != PB_VALUE_STRING || !numbersFitCoord(args + 2, 2) ||
        !numberFitsFloat(args[4]) || args[4].as.number <= 0 || !numberFitsFloat(args[5]) || !validColor(args + 6)) {
      return guiError(vm, "drawTextFont(font, text, x, y, size, spacing, r, g, b) expected.");
    }
    pos[0] = (float)args[2].as.number; pos[1] = (float)args[3].as.number;
    size = (float)args[4].as.number;
    spacing = (float)args[5].as.number;
    color[0] = (int)args[6].as.number; color[1] = (int)args[7].as.number; color[2] = (int)args[8].as.number;
  } else {
    return guiError(vm, "drawTextFont expects 6 or 9 arguments.");
  }
  if (raylib.drawTextFont == NULL) return missingRaylibFunction(vm, "drawTextFont");
  raylib.drawTextFont(id, args[1].as.string.chars, (int)pos[0], (int)pos[1], size, spacing,
                      color[0], color[1], color[2]);
  return pbNilValue();
}

static PbValue guiMeasureTextFont(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 4 || args[1].type != PB_VALUE_STRING || !numberFitsFloat(args[2]) || args[2].as.number <= 0 ||
      !numberFitsFloat(args[3]))
    return guiError(vm, "measureTextFont(font, text, size, spacing) expected.");
  int id = 0;
  if (!fontId(vm, args[0], &id, "measureTextFont(font, text, size, spacing) expected.")) return pbNilValue();
  if (raylib.measureTextFont == NULL) return missingRaylibFunction(vm, "measureTextFont");
  return pbNumberValue(raylib.measureTextFont(id, args[1].as.string.chars, (float)args[2].as.number,
                                              (float)args[3].as.number));
}

static PbValue guiReadChar(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) return guiError(vm, "readChar() takes no arguments.");
  if (raylib.readChar == NULL) return missingRaylibFunction(vm, "readChar");
  int code = raylib.readChar();
  if (code <= 0) return pbStringCopyN(vm, "", 0);
  char text[5];
  int length = 0;
  if (code < 0x80) {
    text[0] = (char)code;
    length = 1;
  } else if (code < 0x800) {
    text[0] = (char)(0xC0 | (code >> 6));
    text[1] = (char)(0x80 | (code & 0x3F));
    length = 2;
  } else if (code < 0x10000) {
    text[0] = (char)(0xE0 | (code >> 12));
    text[1] = (char)(0x80 | ((code >> 6) & 0x3F));
    text[2] = (char)(0x80 | (code & 0x3F));
    length = 3;
  } else if (code <= 0x10FFFF) {
    text[0] = (char)(0xF0 | (code >> 18));
    text[1] = (char)(0x80 | ((code >> 12) & 0x3F));
    text[2] = (char)(0x80 | ((code >> 6) & 0x3F));
    text[3] = (char)(0x80 | (code & 0x3F));
    length = 4;
  } else {
    return pbStringCopyN(vm, "", 0);
  }
  text[length] = '\0';
  return pbStringCopyN(vm, text, (size_t)length);
}

static PbValue guiSetShaderVec3(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 5 || args[1].type != PB_VALUE_STRING || args[1].as.string.chars[0] == '\0' ||
      !numbersFitFloat(args + 2, 3))
    return guiError(vm, "setShaderVec3(shader, uniformName, x, y, z) expected.");
  int id = 0;
  if (!shaderId(vm, args[0], &id, "setShaderVec3(shader, uniformName, x, y, z) expected.")) return pbNilValue();
  if (raylib.setShaderVec3 == NULL) return missingRaylibFunction(vm, "setShaderVec3");
  raylib.setShaderVec3(id, args[1].as.string.chars, (float)args[2].as.number, (float)args[3].as.number,
                       (float)args[4].as.number);
  return pbNilValue();
}

static PbValue guiSetShaderVec4(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 6 || args[1].type != PB_VALUE_STRING || args[1].as.string.chars[0] == '\0' ||
      !numbersFitFloat(args + 2, 4))
    return guiError(vm, "setShaderVec4(shader, uniformName, x, y, z, w) expected.");
  int id = 0;
  if (!shaderId(vm, args[0], &id, "setShaderVec4(shader, uniformName, x, y, z, w) expected.")) return pbNilValue();
  if (raylib.setShaderVec4 == NULL) return missingRaylibFunction(vm, "setShaderVec4");
  raylib.setShaderVec4(id, args[1].as.string.chars, (float)args[2].as.number, (float)args[3].as.number,
                       (float)args[4].as.number, (float)args[5].as.number);
  return pbNilValue();
}

static PbValue guiSetShaderColor(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  int id = 0;
  int color[4];
  if (argCount == 3) {
    if (args[1].type != PB_VALUE_STRING || args[1].as.string.chars[0] == '\0' ||
        !parseColor(vm, args[2], color) ||
        !shaderId(vm, args[0], &id, "setShaderColor(shader, uniformName, color) expected.")) {
      return guiError(vm, "setShaderColor(shader, uniformName, color) expected.");
    }
  } else if (argCount == 6) {
    if (args[1].type != PB_VALUE_STRING || args[1].as.string.chars[0] == '\0' ||
        !validColorAlpha(args + 2) ||
        !shaderId(vm, args[0], &id, "setShaderColor(shader, uniformName, r, g, b, a) expected (0-255).")) {
      return guiError(vm, "setShaderColor(shader, uniformName, r, g, b, a) expected (0-255).");
    }
    color[0] = (int)args[2].as.number; color[1] = (int)args[3].as.number;
    color[2] = (int)args[4].as.number; color[3] = (int)args[5].as.number;
  } else {
    return guiError(vm, "setShaderColor expects 3 or 6 arguments.");
  }
  if (raylib.setShaderColor == NULL) return missingRaylibFunction(vm, "setShaderColor");
  raylib.setShaderColor(id, args[1].as.string.chars, (float)color[0], (float)color[1],
                        (float)color[2], (float)color[3]);
  return pbNilValue();
}

static PbValue guiSetShaderTexture(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 3 || args[1].type != PB_VALUE_STRING || args[1].as.string.chars[0] == '\0' ||
      !numbersFitInt(args + 2, 1))
    return guiError(vm, "setShaderTexture(shader, uniformName, textureId) expected.");
  int id = 0;
  if (!shaderId(vm, args[0], &id, "setShaderTexture(shader, uniformName, textureId) expected.")) return pbNilValue();
  if (raylib.setShaderTexture == NULL) return missingRaylibFunction(vm, "setShaderTexture");
  raylib.setShaderTexture(id, args[1].as.string.chars, (int)args[2].as.number);
  return pbNilValue();
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
    const char *paths[] = {
#ifdef __APPLE__
        "build/pb_raylib_darwin.dylib",
        "@executable_path/pb_raylib_darwin.dylib",
        "lib/pb_raylib_darwin.dylib",
        "@executable_path/../lib/pb_raylib_darwin.dylib",
        "@executable_path/../lib/pb/pb_raylib_darwin.dylib",
        "build/pb_raylib_darwin.so",
        "@executable_path/pb_raylib_darwin.so",
        "lib/pb_raylib_darwin.so",
        "@executable_path/../lib/pb_raylib_darwin.so",
        "@executable_path/../lib/pb/pb_raylib_darwin.so",
#endif
        "build/pb_raylib_linux.so",
        "$ORIGIN/pb_raylib_linux.so",
        "lib/pb_raylib_linux.so",
        "$ORIGIN/../lib/pb_raylib_linux.so",
        "$ORIGIN/../lib/pb/pb_raylib_linux.so"};
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
static const PbNativeDefinition raylibFunctions[] = {
  RAYLIB_FUNCTIONS(RAYLIB_NATIVE)
  {"drawModelRotY", guiDrawModelRotY, NULL},
  {"drawModelWiresRotY", guiDrawModelWiresRotY, NULL},
  {"drawQuadStrip3D", guiDrawQuadStrip3D, NULL},
};
#undef RAYLIB_NATIVE

bool registerRaylibModule(PbVM *vm, const char *name, const char *projectRoot) {
  (void)projectRoot;
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
