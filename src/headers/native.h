#ifndef clox_native_h
#define clox_native_h

#include "value.h"
#include "object.h"

// ordinary C native function implementations
Value clockNative(int argCount, Value *args);
Value randNative(int argCount, Value *args);
Value floorNative(int argCount, Value *args);
Value strInputNative(int argCount, Value *args);
Value sqrtNative(int argCount, Value *args);
Value absNative(int argCount, Value *args);
Value sortNative(int argCount, Value *args);
Value listAdd(int argCount, Value *args);
Value listRemove(int argCount, Value *args);
Value getTime(int argCount, Value* args);

// raylib native functions (where do i put these???)
Value initWindowNative(int argCount, Value *args);
Value beginDrawingNative(int argCount, Value *args);
Value clearBackgroundNative(int argCount, Value *args);
Value drawTextNative(int argCount, Value *args);
Value endDrawingNative(int argCount, Value *args);
Value windowShouldCloseNative(int argCount, Value *args);
Value drawRectangleNative(int argCount, Value *args);
Value drawCircleNative(int argCount, Value *args);
Value drawLineNative(int argCount, Value *args);
Value setTargetFPSNative(int argCount, Value *args);
Value isKeyDownNative(int argCount, Value *args);
Value isMouseButtonDownNative(int argCount, Value *args);
Value closeWindowNative(int argCount, Value *args);
Value isWindowMinimizedNative(int argCount, Value *args);
Value toggleBorderlessWindowedNative(int argCount, Value *args);
Value getScreenWidthNative(int argCount, Value *args);
Value getScreenHeightNative(int argCount, Value *args);
Value getFPSNative(int argCount, Value *args);
Value drawPixelNative(int argCount, Value *args);
Value drawEllipseNative(int argCount, Value *args);
Value swapScreenBufferNative(int argCount, Value *args);
Value isKeyPressedNative(int argCount, Value *args);
Value isKeyReleasedNative(int argCount, Value *args);
Value isKeyUpNative(int argCount, Value *args);
Value getKeyPressedNative(int argCount, Value *args);
Value getCharPressedNative(int argCount, Value *args);
Value setExitKeyNative(int argCount, Value *args);
Value isMouseButtonPressedNative(int argCount, Value *args);
Value isMouseButtonReleasedNative(int argCount, Value *args);
Value isMouseButtonUpNative(int argCount, Value *args);
Value getMouseXNative(int argCount, Value *args);
Value getMouseYNative(int argCount, Value *args);

void defineNative(const char *name, NativeFn function);

// comparison functions for sorting
int Valuecomp(const void *elem1, const void *elem2);
int ValuecompReverse(const void *elem1, const void *elem2);
int Strcomp(const void *elem1, const void *elem2);
int StrcompReverse(const void *elem1, const void *elem2);

#endif
