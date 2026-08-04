#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>
#include <math.h>

#ifdef _WIN32 // glorious
#include <windows.h>
#elif defined(__linux__)
#include <dlfcn.h>
#else
#error "Unsupported Platform"
#endif

#include "headers/common.h"
#include "headers/compiler.h"
#include "headers/debug.h"
#include "headers/object.h"
#include "headers/memory.h"
#include "headers/vm.h"
#include "headers/native.h"
#include "headers/pogberry.h"

// global declaration of VM (fuck it we ball)
VM vm;

// global defintion of all the function pointers for raylib
#ifdef _WIN32
HINSTANCE dllHandle = NULL;
#elif defined(__linux__)
void *handle = NULL;
#endif

InitWindowFunc initWindow = NULL;
WindowShouldCloseFunc windowShouldClose = NULL;
SetTargetFPSFunc setTargetFPS = NULL;
BeginDrawingFunc beginDrawing = NULL;
EndDrawingFunc endDrawing = NULL;
ClearBackgroundFunc clearBackground = NULL;
DrawTextFunc drawText = NULL;
DrawRectangleFunc drawRectangle = NULL;
DrawCircleFunc drawCircle = NULL;
IsKeyPressedFunc isKeyPressed = NULL;
IsKeyDownFunc isKeyDown = NULL;
IsMouseButtonPressedFunc isMouseButtonPressed = NULL;
IsMouseButtonDownFunc isMouseButtonDown = NULL;
GetMousePositionFunc getMousePosition = NULL;
DrawLineFunc drawLine = NULL;
IsKeyUpFunc isKeyUp = NULL;
IsKeyReleasedFunc isKeyReleased = NULL;
GetKeyPressedFunc getKeyPressed = NULL;
GetCharPressedFunc getCharPressed = NULL;
SetExitKeyFunc setExitKey = NULL;
IsMouseButtonUpFunc isMouseButtonUp = NULL;
IsMouseButtonReleasedFunc isMouseButtonReleased = NULL;
GetMouseXFunc getMouseX = NULL;
GetMouseYFunc getMouseY = NULL;
DrawPixelFunc drawPixel = NULL;
DrawEllipseFunc drawEllipse = NULL;
CloseWindowFunc closeWindow = NULL;
GetFPSFunc getFPS = NULL;
GetScreenHeightFunc getScreenHeight = NULL;
GetScreenWidthFunc getScreenWidth = NULL;
SwapScreenBufferFunc swapScreenBuffer = NULL;
ToggleBorderlessWindowedFunc toggleBorderlessWindowed = NULL;
IsWindowMinimizedFunc isWindowMinimized = NULL;

static void resetStack()
{
  vm.stackTop = vm.stack;
  vm.frameCount = 0;
}

void runtimeError(const char *format, ...)
{ // variadic function
  if (vm.hadRuntimeError)
    return;
  vm.hadRuntimeError = true;

  va_list args;
  va_start(args, format);
  vfprintf(stderr, format, args);
  va_end(args);
  fputs("\n", stderr);

  for (int i = vm.frameCount - 1; i >= 0; i--)
  {
    CallFrame *frame = &vm.frames[i];
    ObjFunction *function = frame->function;
    size_t instruction = frame->ip - function->chunk.code - 1;
    fprintf(stderr, "[line %d] in ",
            function->chunk.lines[instruction]);
    if (function->name == NULL)
    {
      fprintf(stderr, "script\n");
    }
    else
    {
      fprintf(stderr, "%s()\n", function->name->chars);
    }
  }
  resetStack();
}

void initVM()
{
  resetStack();
  vm.hadRuntimeError = false;
  vm.objects = NULL;
  vm.bytesAllocated = 0;
  vm.nextGC = 1024 * 1024;

  vm.grayCount = 0;
  vm.grayCapacity = 0;
  vm.grayStack = NULL;

  initTable(&vm.globals);
  initTable(&vm.strings);

  vm.initString = NULL; // GC reasons (again)
  vm.initString = copyString("init", 4);

  srand(time(NULL)); // for the native function
  defineNative("clock", clockNative);
  defineNative("rand", randNative);
  defineNative("floor", floorNative);
  defineNative("strInput", strInputNative);
  defineNative("sqrt", sqrtNative);
  defineNative("abs", absNative);
  defineNative("getTime", getTime);
}

POGBERRY_API void ext_initVM()
{
  resetStack();
  vm.hadRuntimeError = false;
  vm.objects = NULL;
  vm.bytesAllocated = 0;
  vm.nextGC = 1024 * 1024;

  vm.grayCount = 0;
  vm.grayCapacity = 0;
  vm.grayStack = NULL;

  initTable(&vm.globals);
  initTable(&vm.strings);

  vm.initString = NULL; // GC reasons (again)
  vm.initString = copyString("init", 4);

  srand(time(NULL)); // for the native function
  defineNative("clock", clockNative);
  defineNative("rand", randNative);
  defineNative("floor", floorNative);
  defineNative("strInput", strInputNative);
  defineNative("sqrt", sqrtNative);
  defineNative("abs", absNative);
  defineNative("getTime", getTime);
}

#ifdef _WIN32
#if defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wcast-function-type"
#endif
void initialiseRaylibWin()
{
  char exePath[MAX_PATH] = {0};
  GetModuleFileNameA(NULL, exePath, MAX_PATH);

  char *lastSlash = strrchr(exePath, '\\');
  if (lastSlash != NULL)
  {
    *lastSlash = '\0';
  }

  char dllPath[MAX_PATH] = {0};
  sprintf(dllPath, "%s\\lib\\pogberry_gui_windows.dll", exePath);

  dllHandle = LoadLibrary(dllPath);
  if (!dllHandle)
  {
    printf("Failed to load pogberry_gui.dll. Error code: %lu\n", GetLastError());
    return;
  }

  // Load function pointers
  initWindow = (InitWindowFunc)GetProcAddress(dllHandle, "initWindow");
  beginDrawing = (BeginDrawingFunc)GetProcAddress(dllHandle, "beginDrawing");
  clearBackground = (ClearBackgroundFunc)GetProcAddress(dllHandle, "clearBackground");
  drawText = (DrawTextFunc)GetProcAddress(dllHandle, "drawText");
  endDrawing = (EndDrawingFunc)GetProcAddress(dllHandle, "endDrawing");
  windowShouldClose = (WindowShouldCloseFunc)GetProcAddress(dllHandle, "windowShouldClose");
  drawRectangle = (DrawRectangleFunc)GetProcAddress(dllHandle, "drawRectangle");
  drawCircle = (DrawCircleFunc)GetProcAddress(dllHandle, "drawCircle");
  drawLine = (DrawLineFunc)GetProcAddress(dllHandle, "drawLine");
  // ! does not work for unknown reasons (always returns true)
  // isKeyDown = (IsKeyDownFunc)GetProcAddress(dllHandle, "isKeyDown");
  isKeyPressed = (IsKeyPressedFunc)GetProcAddress(dllHandle, "isKeyPressed");
  isMouseButtonDown = (IsMouseButtonDownFunc)GetProcAddress(dllHandle, "isMouseButtonDown");
  setTargetFPS = (SetTargetFPSFunc)GetProcAddress(dllHandle, "setTargetFPS");
  getFPS = (GetFPSFunc)GetProcAddress(dllHandle, "getFPS");
  closeWindow = (CloseWindowFunc)GetProcAddress(dllHandle, "closeWindow");
  isWindowMinimized = (IsWindowMinimizedFunc)GetProcAddress(dllHandle, "isWindowMinimized");
  toggleBorderlessWindowed = (ToggleBorderlessWindowedFunc)GetProcAddress(dllHandle, "toggleBorderlessWindowed");
  getScreenWidth = (GetScreenWidthFunc)GetProcAddress(dllHandle, "getScreenWidth");
  getScreenHeight = (GetScreenHeightFunc)GetProcAddress(dllHandle, "getScreenHeight");
  swapScreenBuffer = (SwapScreenBufferFunc)GetProcAddress(dllHandle, "swapScreenBuffer");
  getMouseX = (GetMouseXFunc)GetProcAddress(dllHandle, "getMouseX");
  getMouseY = (GetMouseYFunc)GetProcAddress(dllHandle, "getMouseY");
  isMouseButtonUp = (IsMouseButtonUpFunc)GetProcAddress(dllHandle, "isMouseButtonUp");
  isMouseButtonReleased = (IsMouseButtonReleasedFunc)GetProcAddress(dllHandle, "isMouseButtonReleased");
  isMouseButtonPressed = (IsMouseButtonPressedFunc)GetProcAddress(dllHandle, "isMouseButtonPressed");
  setExitKey = (SetExitKeyFunc)GetProcAddress(dllHandle, "setExitKey");
  getKeyPressed = (GetKeyPressedFunc)GetProcAddress(dllHandle, "getKeyPressed");
  getCharPressed = (GetCharPressedFunc)GetProcAddress(dllHandle, "getCharPressed");
  isKeyUp = (IsKeyUpFunc)GetProcAddress(dllHandle, "isKeyUp");
  isKeyReleased = (IsKeyReleasedFunc)GetProcAddress(dllHandle, "isKeyReleased");
  drawPixel = (DrawPixelFunc)GetProcAddress(dllHandle, "drawPixel");
  drawEllipse = (DrawEllipseFunc)GetProcAddress(dllHandle, "drawEllipse");

  defineNative("initWindow", initWindowNative);
  defineNative("beginDrawing", beginDrawingNative);
  defineNative("clearBackground", clearBackgroundNative);
  defineNative("drawText", drawTextNative);
  defineNative("endDrawing", endDrawingNative);
  defineNative("windowShouldClose", windowShouldCloseNative);
  defineNative("drawRectangle", drawRectangleNative);
  defineNative("drawCircle", drawCircleNative);
  defineNative("drawLine", drawLineNative);
  defineNative("setTargetFPS", setTargetFPSNative);
  // defineNative("isKeyDown", isKeyDownNative);
  defineNative("isKeyPressed", isKeyPressedNative);
  defineNative("closeWindow", closeWindowNative);
  defineNative("isWindowMinimized", isWindowMinimizedNative);
  defineNative("toggleBorderlessWindowed", toggleBorderlessWindowedNative);
  defineNative("getScreenWidth", getScreenWidthNative);
  defineNative("getScreenHeight", getScreenHeightNative);
  defineNative("getFPS", getFPSNative);
  defineNative("getMouseX", getMouseXNative);
  defineNative("getMouseY", getMouseYNative);
  defineNative("isMouseButtonUp", isMouseButtonUpNative);
  defineNative("isMouseButtonReleased", isMouseButtonReleasedNative);
  defineNative("isMouseButtonPressed", isMouseButtonPressedNative);
  defineNative("isMouseButtonDown", isMouseButtonDownNative);
  defineNative("setExitKey", setExitKeyNative);
  defineNative("getKeyPressed", getKeyPressedNative);
  defineNative("getCharPressed", getCharPressedNative);
  defineNative("isKeyUp", isKeyUpNative);
  defineNative("isKeyReleased", isKeyReleasedNative);
  defineNative("drawPixel", drawPixelNative);
  defineNative("drawEllipse", drawEllipseNative);
  defineNative("swapScreenBuffer", swapScreenBufferNative);
}
#if defined(__GNUC__)
#pragma GCC diagnostic pop
#endif

#elif defined(__linux__)
void initialiseRaylibLinux()
{
  handle = dlopen("lib/pogberry_gui_linux.so", RTLD_LAZY);
  if (!handle)
  {
    fprintf(stderr, "Failed to load shared library: %s\n", dlerror());
    return;
  }

  dlerror();

  initWindow = (InitWindowFunc)dlsym(handle, "initWindow");
  beginDrawing = (BeginDrawingFunc)dlsym(handle, "beginDrawing");
  clearBackground = (ClearBackgroundFunc)dlsym(handle, "clearBackground");
  drawText = (DrawTextFunc)dlsym(handle, "drawText");
  endDrawing = (EndDrawingFunc)dlsym(handle, "endDrawing");
  windowShouldClose = (WindowShouldCloseFunc)dlsym(handle, "windowShouldClose");
  drawRectangle = (DrawRectangleFunc)dlsym(handle, "drawRectangle");
  drawCircle = (DrawCircleFunc)dlsym(handle, "drawCircle");
  drawLine = (DrawLineFunc)dlsym(handle, "drawLine");
  // isKeyDown = (IsKeyDownFunc)dlsym(handle, "isKeyDown");
  isKeyPressed = (IsKeyPressedFunc)dlsym(handle, "isKeyPressed");
  isMouseButtonDown = (IsMouseButtonDownFunc)dlsym(handle, "isMouseButtonDown");
  isMouseButtonPressed = (IsMouseButtonPressedFunc)dlsym(handle, "IsMouseButtonPressed");
  setTargetFPS = (SetTargetFPSFunc)dlsym(handle, "setTargetFPS");
  getFPS = (GetFPSFunc)dlsym(handle, "getFPS");
  swapScreenBuffer = (SwapScreenBufferFunc)dlsym(handle, "swapScreenBuffer");
  closeWindow = (CloseWindowFunc)dlsym(handle, "closeWindow");
  isWindowMinimized = (IsWindowMinimizedFunc)dlsym(handle, "isWindowMinimized");
  toggleBorderlessWindowed = (ToggleBorderlessWindowedFunc)dlsym(handle, "toggleBorderlessWindowed");
  getScreenWidth = (GetScreenWidthFunc)dlsym(handle, "getScreenWidth");
  getScreenHeight = (GetScreenHeightFunc)dlsym(handle, "getScreenHeight");
  getMouseX = (GetMouseXFunc)dlsym(handle, "getMouseX");
  getMouseY = (GetMouseYFunc)dlsym(handle, "getMouseY");
  isMouseButtonUp = (IsMouseButtonUpFunc)dlsym(handle, "isMouseButtonUp");
  isMouseButtonReleased = (IsMouseButtonReleasedFunc)dlsym(handle, "isMouseButtonReleased");
  setExitKey = (SetExitKeyFunc)dlsym(handle, "setExitKey");
  getKeyPressed = (GetKeyPressedFunc)dlsym(handle, "getKeyPressed");
  getCharPressed = (GetCharPressedFunc)dlsym(handle, "getCharPressed");
  isKeyUp = (IsKeyUpFunc)dlsym(handle, "isKeyUp");
  isKeyReleased = (IsKeyReleasedFunc)dlsym(handle, "isKeyReleased");
  drawPixel = (DrawPixelFunc)dlsym(handle, "drawPixel");
  drawEllipse = (DrawEllipseFunc)dlsym(handle, "drawEllipse");

  defineNative("initWindow", initWindowNative);
  defineNative("beginDrawing", beginDrawingNative);
  defineNative("clearBackground", clearBackgroundNative);
  defineNative("drawText", drawTextNative);
  defineNative("endDrawing", endDrawingNative);
  defineNative("windowShouldClose", windowShouldCloseNative);
  defineNative("drawRectangle", drawRectangleNative);
  defineNative("drawCircle", drawCircleNative);
  defineNative("drawLine", drawLineNative);
  defineNative("setTargetFPS", setTargetFPSNative);
  // defineNative("isKeyDown", isKeyDownNative);
  defineNative("isKeyPressed", isKeyPressedNative);
  defineNative("getFPS", getFPSNative);
  defineNative("getMouseX", getMouseXNative);
  defineNative("getMouseY", getMouseYNative);
  defineNative("isMouseButtonUp", isMouseButtonUpNative);
  defineNative("isMouseButtonReleased", isMouseButtonReleasedNative);
  defineNative("isMouseButtonPressed", isMouseButtonPressedNative);
  defineNative("isMouseButtonDown", isMouseButtonDownNative);
  defineNative("closeWindow", closeWindowNative);
  defineNative("isWindowMinimized", isWindowMinimizedNative);
  defineNative("getScreenHeight", getScreenHeightNative);
  defineNative("getScreenWidth", getScreenWidthNative);
  defineNative("toggleBorderlessWindowed", toggleBorderlessWindowedNative);
  defineNative("setExitKey", setExitKeyNative);
  defineNative("getKeyPressed", getKeyPressedNative);
  defineNative("getCharPressed", getCharPressedNative);
  defineNative("isKeyUp", isKeyUpNative);
  defineNative("isKeyReleased", isKeyReleasedNative);
  defineNative("drawPixel", drawPixelNative);
  defineNative("drawEllipse", drawEllipseNative);
  defineNative("swapScreenBuffer", swapScreenBufferNative);
}
#endif

void freeVM()
{
  freeTable(&vm.globals);
  freeTable(&vm.strings);
  vm.initString = NULL;
  freeObjects();
#ifdef _WIN32
  FreeLibrary(dllHandle);
#endif
}

void push(Value value)
{
  *vm.stackTop = value; // put the new value in the empty spot
  vm.stackTop++;        // increase stackTop to point to the next empty spot
}

Value pop()
{
  vm.stackTop--;
  return *vm.stackTop;
}

static Value peek(int distance)
{
  return vm.stackTop[-1 - distance];
}

bool call(ObjFunction *function, int argCount)
{
  if (argCount != function->arity)
  {
    runtimeError("Expected %d arguments but got %d.", function->arity, argCount);
    return false;
  }

  if (vm.frameCount == FRAMES_MAX)
  {
    runtimeError("Stack overflow.");
    return false;
  }

  CallFrame *frame = &vm.frames[vm.frameCount++];
  frame->function = function;
  frame->ip = function->chunk.code;

  frame->slots = vm.stackTop - argCount - 1;

  return true;
}

static bool callValue(Value callee, int argCount)
{
  if (IS_OBJ(callee))
  {
    switch (OBJ_TYPE(callee))
    {
    case OBJ_FUNCTION:
      return call(AS_FUNCTION(callee), argCount);
    case OBJ_NATIVE:
    {
      NativeFn native = AS_NATIVE(callee);
      Value result = native(argCount, vm.stackTop - argCount);

      if (vm.hadRuntimeError)
        return false;

      vm.stackTop -= argCount + 1;
      push(result);
      return true;
    }
    case OBJ_CLASS:
    {
      ObjClass *klass = AS_CLASS(callee);
      vm.stackTop[-argCount - 1] = OBJ_VAL(newInstance(klass));
      Value initializer;
      if (tableGet(&klass->methods, vm.initString, &initializer))
      {
        return call(AS_FUNCTION(initializer), argCount);
      }
      else if (argCount != 0)
      {
        runtimeError("Expected 0 arguments but got %d.", argCount);
        return false;
      }
      return true;
    }
    case OBJ_BOUND_METHOD:
    {
      printf("inside obj bound");
      ObjBoundMethod *bound = AS_BOUND_METHOD(callee);
      vm.stackTop[-argCount - 1] = bound->receiver;
      return call(bound->method, argCount);
    }
    default:
      break; // Non-callable object type.
    }
  }
  runtimeError("Can only call functions and classes.");
  return false;
}

static bool invokeFromClass(ObjClass *klass, ObjString *name, int argCount)
{
  Value method;
  if (!tableGet(&klass->methods, name, &method))
  {
    runtimeError("Undefined property '%s'.", name->chars);
    return false;
  }
  return call(AS_FUNCTION(method), argCount);
}

static bool invokeListMethod(ObjString *name, int argCount)
{
  NativeFn method = NULL;

  if (strcmp(name->chars, "push") == 0)
  {
    method = listPushNative;
  }
  else if (strcmp(name->chars, "extend") == 0)
  {
    method = listExtendNative;
  }
  else if (strcmp(name->chars, "pop") == 0)
  {
    method = listPopNative;
  }
  else if (strcmp(name->chars, "insert") == 0)
  {
    method = listInsertNative;
  }
  else if (strcmp(name->chars, "remove") == 0)
  {
    method = listRemoveNative;
  }
  else if (strcmp(name->chars, "removeAt") == 0)
  {
    method = listRemoveAtNative;
  }
  else if (strcmp(name->chars, "clear") == 0)
  {
    method = listClearNative;
  }
  else if (strcmp(name->chars, "copy") == 0)
  {
    method = listCopyNative;
  }
  else if (strcmp(name->chars, "index") == 0)
  {
    method = listIndexNative;
  }
  else if (strcmp(name->chars, "count") == 0)
  {
    method = listCountNative;
  }
  else if (strcmp(name->chars, "reverse") == 0)
  {
    method = listReverseNative;
  }
  else if (strcmp(name->chars, "sort") == 0)
  {
    method = listSortNative;
  }
  else
  {
    runtimeError("Lists do not have a method named '%s'.", name->chars);
    return false;
  }

  Value result = method(argCount + 1, vm.stackTop - argCount - 1);

  if (vm.hadRuntimeError)
    return false;

  vm.stackTop -= argCount + 1;
  push(result);
  return true;
}

static bool invoke(ObjString *name, int argCount)
{
  Value receiver = peek(argCount);

  if (IS_LIST(receiver))
  {
    return invokeListMethod(name, argCount);
  }

  if (!IS_INSTANCE(receiver))
  {
    runtimeError("Only instances have methods.");
    return false;
  }

  ObjInstance *instance = AS_INSTANCE(receiver);

  Value value;
  if (tableGet(&instance->fields, name, &value))
  {
    vm.stackTop[-argCount - 1] = value;
    return callValue(value, argCount);
  }

  return invokeFromClass(instance->klass, name, argCount);
}

static bool bindMethod(ObjClass *klass, ObjString *name)
{
  Value method;
  if (!tableGet(&klass->methods, name, &method))
  {
    runtimeError("Undefined property '%s'.", name->chars);
    return false;
  }

  ObjBoundMethod *bound = newBoundMethod(peek(0), AS_FUNCTION(method));
  pop();
  push(OBJ_VAL(bound));
  return true;
}

// only nil and false are falsey
static bool isFalsey(Value value)
{
  return IS_NIL(value) || (IS_BOOL(value) && !AS_BOOL(value));
}

static char *formatNumber(Value value)
{
  if (!IS_NUMBER(value))
    return "NaN";
  char *buffer = ALLOCATE(char, 32);
  snprintf(buffer, 32, "%g", AS_NUMBER(value));
  return buffer;
}

static void concatenate()
{
  Value b = peek(0);
  Value a = peek(1);

  ObjString *strA = IS_STRING(a) ? AS_STRING(a) : copyString(formatNumber(a), strlen(formatNumber(a)));
  ObjString *strB = IS_STRING(b) ? AS_STRING(b) : copyString(formatNumber(b), strlen(formatNumber(b)));

  push(OBJ_VAL(strA));
  push(OBJ_VAL(strB));

  int length = strA->length + strB->length;
  char *chars = ALLOCATE(char, length + 1);
  memcpy(chars, strA->chars, strA->length);
  memcpy(chars + strA->length, strB->chars, strB->length);
  chars[length] = '\0';

  // the gc makes you do weird shit man
  pop();
  pop();
  pop();
  pop();

  ObjString *result = takeString(chars, length);
  push(OBJ_VAL(result));
}

static void defineMethod(ObjString *name)
{
  Value method = peek(0);
  ObjClass *klass = AS_CLASS(peek(1));
  tableSet(&klass->methods, name, method);
  pop();
}

static bool normalizeListIndex(Value indexValue, int listCount, int *outIndex)
{
  if (!IS_NUMBER(indexValue))
  {
    runtimeError("List index must be a number.");
    return false;
  }

  double index = AS_NUMBER(indexValue);
  if (!isfinite(index) || floor(index) != index)
  {
    runtimeError("List index must be a finite integer.");
    return false;
  }

  if (index < 0)
  {
    index += listCount;
  }

  if (index < 0 || index >= listCount)
  {
    runtimeError("List index out of bounds.");
    return false;
  }

  *outIndex = (int)index;
  return true;
}

static InterpretResult run()
{
  CallFrame *frame = &vm.frames[vm.frameCount - 1];

#define READ_BYTE() (*frame->ip++)

#define READ_SHORT() \
  (frame->ip += 2,   \
   (uint16_t)((frame->ip[-2] << 8) | frame->ip[-1]))

#define READ_CONSTANT() \
  (frame->function->chunk.constants.values[READ_BYTE()])

#define READ_STRING() AS_STRING(READ_CONSTANT())
// awkward do-while and then while(false) just to run it once so that this preprocessor can be defined at all. this faux loop is a workaround allowing preprocessor to take multiple statements
// really pushing macros to the limit here
#define BINARY_OP(valueType, op)                    \
  do                                                \
  {                                                 \
    if (!IS_NUMBER(peek(0)) || !IS_NUMBER(peek(1))) \
    {                                               \
      runtimeError("Operands must be numbers.");    \
      return INTERPRET_RUNTIME_ERROR;               \
    }                                               \
    double b = AS_NUMBER(pop());                    \
    double a = AS_NUMBER(pop());                    \
    push(valueType(a op b));                        \
  } while (false)

  for (;;)
  {
#ifdef DEBUG_TRACE_EXECUTION
    printf("        ");
    for (Value *slot = vm.stack; slot < vm.stackTop; slot++)
    {
      printf("[ ");
      printValue(*slot);
      printf(" ]");
    }
    printf("\n");
    disassembleInstruction(&frame->function->chunk,
                           (int)(frame->ip - frame->function->chunk.code));
#endif
    uint8_t instruction;
    switch (instruction = READ_BYTE())
    {
    case OP_CONSTANT:
    {
      Value constant = READ_CONSTANT();
      push(constant); // load a value (push it onto the stack)
      break;
    }
    case OP_NIL:
      push(NIL_VAL);
      break;
    case OP_TRUE:
      push(BOOL_VAL(true));
      break;
    case OP_FALSE:
      push(BOOL_VAL(false));
      break;
    case OP_POP:
      pop();
      break;
    case OP_GET_LOCAL:
    {
      uint8_t slot = READ_BYTE();
      push(frame->slots[slot]);
      break;
    }
    case OP_SET_LOCAL:
    {
      uint8_t slot = READ_BYTE();
      frame->slots[slot] = peek(0);
      break;
    }
    case OP_GET_GLOBAL:
    {
      ObjString *name = READ_STRING();
      Value value;
      if (!tableGet(&vm.globals, name, &value))
      {
        runtimeError("Undefined variable '%s'.", name->chars);
        return INTERPRET_RUNTIME_ERROR;
      }
      push(value);
      break;
    }
    case OP_DEFINE_GLOBAL:
    {
      ObjString *name = READ_STRING();
      tableSet(&vm.globals, name, peek(0));
      pop();
      break;
    }
    case OP_SET_GLOBAL:
    {
      ObjString *name = READ_STRING();
      if (tableSet(&vm.globals, name, peek(0)))
      {
        tableDelete(&vm.globals, name);
        runtimeError("Undefined variable '%s'.", name->chars);
        return INTERPRET_RUNTIME_ERROR;
      }
      break;
    }
    case OP_GET_PROPERTY:
    {
      if (!IS_INSTANCE(peek(0)))
      {
        runtimeError("Only instances have properties.");
        return INTERPRET_RUNTIME_ERROR;
      }

      ObjInstance *instance = AS_INSTANCE(peek(0));
      ObjString *name = READ_STRING();

      Value value;
      if (tableGet(&instance->fields, name, &value))
      {
        pop();
        push(value);
        break;
      }

      if (!bindMethod(instance->klass, name))
      {
        return INTERPRET_RUNTIME_ERROR;
      }
      break;
      // need to define a way to check if a field exists, also delete
      // push(NIL_VAL); // if the property doesnt exist dont crash the vm just return nil
    }
    case OP_SET_PROPERTY:
    {
      if (!IS_INSTANCE(peek(1)))
      {
        runtimeError("Only instances have fields.");
        return INTERPRET_RUNTIME_ERROR;
      }

      ObjInstance *instance = AS_INSTANCE(peek(1));
      tableSet(&instance->fields, READ_STRING(), peek(0));
      Value value = pop();
      pop();
      push(value);
      break;
    }
    case OP_INVOKE:
    {
      ObjString *method = READ_STRING();
      int argCount = READ_BYTE();
      if (!invoke(method, argCount))
      {
        return INTERPRET_RUNTIME_ERROR;
      }
      frame = &vm.frames[vm.frameCount - 1];
      break;
    }
    case OP_SUPER_INVOKE:
    {
      ObjString *method = READ_STRING();
      int argCount = READ_BYTE();
      ObjClass *superclass = AS_CLASS(pop());
      if (!invokeFromClass(superclass, method, argCount))
      {
        return INTERPRET_RUNTIME_ERROR;
      }
      frame = &vm.frames[vm.frameCount - 1];
      break;
    }
    case OP_GET_SUPER:
    {
      ObjString *name = READ_STRING();
      ObjClass *superclass = AS_CLASS(pop());

      if (!bindMethod(superclass, name))
      {
        return INTERPRET_RUNTIME_ERROR;
      }
      break;
    }
    case OP_EQUAL:
    {
      Value a = pop();
      Value b = pop();
      push(BOOL_VAL(valuesEqual(a, b)));
      break;
    }
    case OP_GREATER:
      BINARY_OP(BOOL_VAL, >);
      break;
    case OP_LESS:
      BINARY_OP(BOOL_VAL, <);
      break;
    case OP_ADD:
    {
      if (IS_STRING(peek(0)) || IS_STRING(peek(1)))
      {
        concatenate();
      }
      else if (IS_NUMBER(peek(0)) && IS_NUMBER(peek(1)))
      {
        double b = AS_NUMBER(pop());
        double a = AS_NUMBER(pop());
        push(NUMBER_VAL(a + b));
      }
      else
      {
        runtimeError("Operands must be two numbers or two strings.");
        return INTERPRET_RUNTIME_ERROR;
      }
      break;
    }
    case OP_SUBTRACT:
      BINARY_OP(NUMBER_VAL, -);
      break;
    case OP_MULTIPLY:
      BINARY_OP(NUMBER_VAL, *);
      break;
    case OP_DIVIDE:
      BINARY_OP(NUMBER_VAL, /);
      break;
    case OP_MODULO:
      if (!IS_NUMBER(peek(0)) || !IS_NUMBER(peek(1)))
      {
        runtimeError("Operands must be numbers.");
        return INTERPRET_RUNTIME_ERROR;
      }

      double b = AS_NUMBER(pop());
      double a = AS_NUMBER(pop());

      if (floor(b) != b || floor(a) != a)
      { // integer check
        runtimeError("Modulo only accepts integer operands.");
        return INTERPRET_RUNTIME_ERROR;
      }

      int intA = (int)a;
      int intB = (int)b;

      push(NUMBER_VAL(intA % intB));
      break;
    case OP_NOT:
      push(BOOL_VAL(isFalsey(pop())));
      break;
    case OP_NEGATE:
      if (!IS_NUMBER(peek(0)))
      {
        runtimeError("Operand must be a number.");
        return INTERPRET_RUNTIME_ERROR;
      }
      push(NUMBER_VAL(-AS_NUMBER(pop())));
      break;
    case OP_PRINT:
      printValue(peek(0));
      pop();
      printf("\n");
      break;
    case OP_PRINT_NO_NEWLINE:
      printValue(peek(0));
      pop();
      break;
    case OP_JUMP:
    {
      uint16_t offset = READ_SHORT();
      frame->ip += offset;
      break;
    }
    case OP_JUMP_IF_FALSE:
    {
      uint16_t offset = READ_SHORT();
      if (isFalsey(peek(0)))
        frame->ip += offset;
      break;
    }
    case OP_LOOP:
    {
      uint16_t offset = READ_SHORT();
      frame->ip -= offset;
      break;
    }
    case OP_CALL:
    {
      int argCount = READ_BYTE();
      if (!callValue(peek(argCount), argCount))
      {
        printf("rintime errpr inside call");
        return INTERPRET_RUNTIME_ERROR;
      }
      frame = &vm.frames[vm.frameCount - 1];
      break;
    }
    case OP_GET_INDEX:
    {
      Value index = peek(0);
      Value container = peek(1);

      if (IS_LIST(container))
      {
        ObjList *list = AS_LIST(container);
        int listIndex;

        if (!normalizeListIndex(index, list->items.count, &listIndex))
        {
          return INTERPRET_RUNTIME_ERROR;
        }

        Value result = list->items.values[listIndex];
        pop();
        pop();
        push(result);
      }
      else if (IS_STRING(container))
      {
        if (!IS_NUMBER(index))
        {
          runtimeError("String index must be a number.");
          return INTERPRET_RUNTIME_ERROR;
        }

        double stringIndex = AS_NUMBER(index);
        if (!isfinite(stringIndex) || floor(stringIndex) != stringIndex)
        {
          runtimeError("String index must be a finite integer.");
          return INTERPRET_RUNTIME_ERROR;
        }

        ObjString *string = AS_STRING(container);
        char chars[2] = {string->chars[(int)stringIndex], '\0'};

        ObjString *result = copyString(chars, 1);

        pop();
        pop();
        push(OBJ_VAL(result));
      }
      else if (IS_HASHMAP(container))
      {
        if (!IS_STRING(index) && !IS_NUMBER(index))
        {
          runtimeError("Hashmap key must be a string or a number.");
          return INTERPRET_RUNTIME_ERROR;
        }

        ObjString *key;

        if (IS_STRING(index))
        {
          key = AS_STRING(index);
        }
        else
        {
          char keyBuffer[32];
          snprintf(keyBuffer, sizeof(keyBuffer), "%g", AS_NUMBER(index));
          key = copyString(keyBuffer, strlen(keyBuffer));
        }

        Value result = NIL_VAL;
        tableGet(&AS_HASHMAP(container)->items, key, &result);

        pop();
        pop();
        push(result);
      }
      else
      {
        runtimeError("Can only index into lists, strings, and hashmaps.");
        return INTERPRET_RUNTIME_ERROR;
      }

      break;
    }

    case OP_SET_INDEX:
    {
      Value value = peek(0);
      Value key = peek(1);
      Value container = peek(2);

      if (IS_LIST(container))
      {
        ObjList *list = AS_LIST(container);
        int index;

        if (!normalizeListIndex(key, list->items.count, &index))
        {
          return INTERPRET_RUNTIME_ERROR;
        }

        list->items.values[index] = value;

        pop();
        pop();
        pop();
        push(value);
      }
      else if (IS_HASHMAP(container))
      {
        if (!IS_STRING(key) && !IS_NUMBER(key))
        {
          runtimeError("Hashmap key must be a string or a number.");
          return INTERPRET_RUNTIME_ERROR;
        }

        ObjString *mapKey;
        if (IS_STRING(key))
        {
          mapKey = AS_STRING(key);
        }
        else
        {
          char keyBuffer[32];
          snprintf(keyBuffer, sizeof(keyBuffer), "%g", AS_NUMBER(key));
          mapKey = copyString(keyBuffer, strlen(keyBuffer));
        }

        tableSet(&AS_HASHMAP(container)->items, mapKey, value);

        pop();
        pop();
        pop();
        push(value);
      }
      else
      {
        runtimeError("Can only assign through a list or hashmap index.");
        return INTERPRET_RUNTIME_ERROR;
      }

      break;
    }

    case OP_NEW_LIST:
    {
      push(OBJ_VAL(newList()));
      break;
    }
    case OP_LIST_LITERAL_APPEND:
    {
      Value item = pop();
      Value listVal = pop();

      if (!IS_LIST(listVal))
      {
        runtimeError("Can only append to a list.");
        return INTERPRET_RUNTIME_ERROR;
      }

      ObjList *list = AS_LIST(listVal);
      push(OBJ_VAL(list));
      writeValueArray(&list->items, item);
      pop();
      push(OBJ_VAL(list));
      break;
    }
    case OP_NEW_HASHMAP:
    {
      push(OBJ_VAL(newHashmap()));
      break;
    }
    case OP_HASHMAP_LITERAL_INSERT:
    {
      Value value = peek(0);
      Value keyVal = peek(1);
      Value hashmapVal = peek(2);

      if (!IS_HASHMAP(hashmapVal))
      {
        runtimeError("Expect a hashmap.");
        return INTERPRET_RUNTIME_ERROR;
      }

      ObjHashmap *hashmap = AS_HASHMAP(hashmapVal);

      if (!IS_STRING(keyVal) && !IS_NUMBER(keyVal))
      {
        runtimeError("Hashmap key must be a string or a number.");
        return INTERPRET_RUNTIME_ERROR;
      }

      if (IS_STRING(keyVal))
      {
        ObjString *key = AS_STRING(keyVal);
        tableSet(&hashmap->items, key, value);
      }
      else if (IS_NUMBER(keyVal))
      {
        char keyStr[32];
        snprintf(keyStr, sizeof(keyStr), "%g", AS_NUMBER(keyVal));
        ObjString *key = copyString(keyStr, strlen(keyStr));
        tableSet(&hashmap->items, key, value);
      }

      pop();
      pop();
      pop();
      push(OBJ_VAL(hashmap));
      break;
    }
    case OP_RETURN:
    {
      Value result = pop();
      vm.frameCount--;
      if (vm.frameCount == 0)
      {
        pop();
        return INTERPRET_OK;
      }

      vm.stackTop = frame->slots;
      push(result);
      frame = &vm.frames[vm.frameCount - 1];
      break;
    }
    case OP_CLASS:
    {
      push(OBJ_VAL(newClass(READ_STRING())));
      break;
    }
    case OP_INHERIT:
    {
      Value superclass = peek(1);
      if (!IS_CLASS(superclass))
      {
        runtimeError("Superclass must be a class.");
        return INTERPRET_RUNTIME_ERROR;
      }
      ObjClass *subclass = AS_CLASS(peek(0));
      tableAddAll(&AS_CLASS(superclass)->methods, &subclass->methods);
      pop();
      break;
    }
    case OP_METHOD:
    {
      defineMethod(READ_STRING());
      break;
    }
    case OP_USE:
    {
      Value name = pop();
      if (!IS_STRING(name))
      {
        runtimeError("Expected a string for 'use' statement.");
        return INTERPRET_RUNTIME_ERROR;
      }
      ObjString *namestr = AS_STRING(name);
      if (strcmp(namestr->chars, "pogberry_gui") == 0)
      {
#ifdef _WIN32
        initialiseRaylibWin();
#elif defined(__linux__)
        initialiseRaylibLinux();
#endif
      }
      break;
    }
    }
  }
#undef BINARY_OP
#undef READ_CONSTANT
#undef READ_STRING
#undef READ_SHORT
#undef READ_BYTE
}

InterpretResult interpret(const char *source)
{
  vm.hadRuntimeError = false;

  ObjFunction *function = compile(source);
  if (function == NULL)
    return INTERPRET_COMPILE_ERROR;

  push(OBJ_VAL(function));
  if (!call(function, 0))
  {
    return INTERPRET_RUNTIME_ERROR;
  }

  return run();
}

POGBERRY_API InterpretResult ext_interpret(const char *source)
{
  vm.hadRuntimeError = false;

  ObjFunction *function = compile(source);
  if (function == NULL)
    return INTERPRET_COMPILE_ERROR;

  push(OBJ_VAL(function));
  if (!call(function, 0))
  {
    return INTERPRET_RUNTIME_ERROR;
  }

  return run();
}
