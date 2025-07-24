#ifndef clox_vm_h
#define clox_vm_h

#include "object.h"
#include "table.h"
#include "value.h"

#define FRAMES_MAX 64
#define STACK_MAX (FRAMES_MAX * UINT8_COUNT)

typedef enum
{
  KEY_NULL = 0, // Key: NULL, used for no key pressed
  // Alphanumeric keys
  KEY_A = 65, // Key: A | a
  KEY_D = 68, // Key: D | d
  KEY_S = 83, // Key: S | s
  KEY_W = 87, // Key: W | w
  // Function keys
  KEY_SPACE = 32,   // Key: Space
  KEY_ESCAPE = 256, // Key: Esc
  KEY_ENTER = 257,  // Key: Enter
  KEY_RIGHT = 262,  // Key: Cursor right
  KEY_LEFT = 263,   // Key: Cursor left
  KEY_DOWN = 264,   // Key: Cursor down
  KEY_UP = 265,     // Key: Cursor up
} KeyboardKey;

// function pointer types for Raylib bindings
typedef void (*InitWindowFunc)(int, int, const char*);
typedef int (*WindowShouldCloseFunc)();
typedef void (*SetTargetFPSFunc)(int);
typedef void (*BeginDrawingFunc)();
typedef void (*EndDrawingFunc)();
typedef void (*ClearBackgroundFunc)(int, int, int);
typedef void (*DrawTextFunc)(const char *, int, int, int, int, int, int);
typedef void (*DrawRectangleFunc)(int, int, int, int, int, int, int);
typedef void (*DrawCircleFunc)(int, int, float, int, int, int);
typedef void (*DrawLineFunc)(int, int, int, int, int, int, int);
typedef int (*IsKeyPressedFunc)(int);
typedef int (*IsKeyDownFunc)(int);
typedef int (*IsMouseButtonPressedFunc)(int);
typedef int (*IsMouseButtonDownFunc)(int);
typedef void (*GetMousePositionFunc)(float *, float *);

// Window control function pointer types
typedef void (*CloseWindowFunc)();
typedef bool (*IsWindowMinimizedFunc)();
typedef void (*ToggleBorderlessWindowedFunc)();
typedef int (*GetScreenWidthFunc)();
typedef int (*GetScreenHeightFunc)();
typedef int (*GetFPSFunc)();

// global function pointers
extern InitWindowFunc initWindow;
extern WindowShouldCloseFunc windowShouldClose;
extern SetTargetFPSFunc setTargetFPS;
extern BeginDrawingFunc beginDrawing;
extern EndDrawingFunc endDrawing;
extern ClearBackgroundFunc clearBackground;
extern DrawTextFunc drawText;
extern DrawRectangleFunc drawRectangle;
extern DrawCircleFunc drawCircle;
extern DrawLineFunc drawLine;
extern IsKeyPressedFunc isKeyPressed;
extern IsKeyDownFunc isKeyDown;
extern IsMouseButtonPressedFunc isMouseButtonPressed;
extern IsMouseButtonDownFunc isMouseButtonDown;
extern GetMousePositionFunc getMousePosition;

// new window control pointers
extern CloseWindowFunc closeWindow;
extern IsWindowMinimizedFunc isWindowMinimized;
extern ToggleBorderlessWindowedFunc toggleBorderlessWindowed;
extern GetScreenWidthFunc getScreenWidth;
extern GetScreenHeightFunc getScreenHeight;
extern GetFPSFunc getFPS;

typedef struct
{
  ObjFunction *function;
  uint8_t *ip;
  Value *slots;
} CallFrame;

typedef struct
{
  CallFrame frames[FRAMES_MAX];
  int frameCount;

  Value stack[STACK_MAX]; // time for implementing a stack in the virtual machine babyyyy also this is the pointer to the first element of the array by default (if we dont do any pointer arithmetic)
  Value *stackTop;        // pointer to the element (pointer faster than indexing) just after the last stack, so pointing to 0 index means stack empty
  Table globals;
  Table strings; // for interning strings, each unique string will only be stored once in memory, so "=" operation can be carried out fast -> just compare the memory address rather than comparing the string character by character
  ObjString *initString;

  size_t bytesAllocated;
  size_t nextGC;
  Obj *objects;
  int grayCount;
  int grayCapacity;
  Obj **grayStack;
} VM;

typedef enum
{
  INTERPRET_OK,
  INTERPRET_COMPILE_ERROR,
  INTERPRET_RUNTIME_ERROR,
} InterpretResult;

extern VM vm;

void initVM();
void freeVM();
InterpretResult interpret(const char *source); // run the chunk and respond with a value from enum declared above
void push(Value value);
Value pop();

#endif