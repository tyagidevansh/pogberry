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

// global declaration of VM (fuck it we ball)
VM vm;

// global defintion of all the function pointers for raylib
#ifdef _WIN32
HINSTANCE dllHandle = NULL;
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
// GetFps getFps = NULL;
#endif

static void resetStack()
{
  vm.stackTop = vm.stack;
  vm.frameCount = 0;
}

static void runtimeError(const char *format, ...)
{ // variadic function
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
  defineNative("add", listAdd);
  defineNative("remove", listRemove);
  defineNative("sort", sortNative);
}

#ifdef _WIN32
void initialiseRaylibWin()
{
  dllHandle = LoadLibrary("lib/pogberry_gui_windows.dll");
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
  isKeyDown = (IsKeyDownFunc)GetProcAddress(dllHandle, "isKeyDown");
  isMouseButtonDown = (IsMouseButtonDownFunc)GetProcAddress(dllHandle, "isMouseButtonDown");
  setTargetFPS = (SetTargetFPSFunc)GetProcAddress(dllHandle, "setTargetFPS");
  // getFPS = (GetFPSFunc)GetProcAddress(dllHandle, "getFPS");

  // Register native functions
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
  defineNative("isKeyDown", isKeyDownNative);
  // defineNative("getFPS", getFPSNative);
}
#elif defined(__linux__)
void initialiseRaylibLinux()
{
  // pass
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

static bool invoke(ObjString *name, int argCount)
{
  Value receiver = peek(argCount);

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
      if (IS_NUMBER(peek(0)) && IS_STRING(peek(1)))
      {
        Value key = peek(0); // do NOT change to pop, this is important for the gc
        Value container = peek(1);

        ObjString *string = AS_STRING(container);
        int i = (int)AS_NUMBER(key);
        if (i < 0 || i >= string->length)
        {
          runtimeError("String index out of bounds.");
          return INTERPRET_RUNTIME_ERROR;
        }

        pop();
        pop();

        char chars[2] = {string->chars[i], '\0'};
        push(OBJ_VAL(copyString(chars, 1)));
      }
      else if ((IS_STRING(peek(0)) || IS_NUMBER(peek(0))) && IS_HASHMAP(peek(1)))
      {
        Value key = peek(0);
        Value container = peek(1);

        ObjHashmap *hashmap = AS_HASHMAP(container);

        if (!IS_STRING(key) && !IS_NUMBER(key))
        {
          runtimeError("Hashmap key must be a string or a number");
          return INTERPRET_RUNTIME_ERROR;
        }

        ObjString *keyStr;
        if (IS_STRING(key))
        {
          keyStr = AS_STRING(key);
        }
        else
        {
          char keyBuffer[32];
          snprintf(keyBuffer, sizeof(keyBuffer), "%g", AS_NUMBER(key));
          keyStr = copyString(keyBuffer, strlen(keyBuffer));
        }

        pop();
        pop();

        Value value;
        if (tableGet(&hashmap->items, keyStr, &value))
        {
          push(value);
        }
        else
        {
          push(NIL_VAL);
        }
      }
      else if (IS_NUMBER(peek(0)))
      {
        int keyCount = 0;

        while (IS_NUMBER(peek(keyCount)))
        {
          keyCount++;
        }

        Value container = peek(keyCount);

        if (!IS_LIST(container))
        {
          if (keyCount == 1)
          {
            runtimeError("Can only index into lists, strings and hashmaps.");
            return INTERPRET_RUNTIME_ERROR;
          }
          else
          {
            runtimeError("Multi-level indexing is only supported in lists.");
            return INTERPRET_RUNTIME_ERROR;
          }
        }

        for (int i = keyCount - 1; i >= 0; i--)
        {
          if (!IS_LIST(container))
          {
            runtimeError("Cannot index non-list value.");
            return INTERPRET_RUNTIME_ERROR;
          }

          ObjList *objList = AS_LIST(container);
          int index = (int)AS_NUMBER(peek(i));

          if (index < 0 || index >= objList->items.count)
          {
            runtimeError("List index out of bounds.");
            return INTERPRET_RUNTIME_ERROR;
          }

          container = objList->items.values[index];
        }

        for (int i = 0; i <= keyCount; i++)
        {
          pop();
        }

        push(container);
        break;
      }
      else
      {
        runtimeError("Can only index into lists, strings and hashmaps.");
        return INTERPRET_RUNTIME_ERROR;
      }
      break;
    }

    case OP_SET_INDEX:
    {
      Value value = pop(); // think this is fine because it wont ever be a part of any other expression
      Value key = pop();
      Value container = pop();

      if (IS_LIST(container))
      {
        ObjList *objList = AS_LIST(container);
        if (!IS_NUMBER(key))
        {
          runtimeError("List index must be a number.");
          return INTERPRET_RUNTIME_ERROR;
        }

        int i = (int)AS_NUMBER(key);
        if (i < 0 || i >= objList->items.count)
        {
          runtimeError("List index out of bounds.");
          return INTERPRET_RUNTIME_ERROR;
        }

        objList->items.values[i] = value;
        push(value);
      }
      else if (IS_HASHMAP(container))
      {
        ObjHashmap *hashmap = AS_HASHMAP(container);
        if (!IS_STRING(key) && !IS_NUMBER(key))
        {
          runtimeError("Hashmap key must be a string or a number");
          return INTERPRET_RUNTIME_ERROR;
        }

        ObjString *keyStr;
        if (IS_STRING(key))
        {
          keyStr = AS_STRING(key);
        }
        else
        {
          char keyBuffer[32];
          snprintf(keyBuffer, sizeof(keyBuffer), "%g", AS_NUMBER(key));
          keyStr = copyString(keyBuffer, strlen(keyBuffer));
        }

        tableSet(&hashmap->items, keyStr, value);
        push(value);
      }
      else
      {
        runtimeError("Can only index into lists and hashmaps.");
        return INTERPRET_RUNTIME_ERROR;
      }
      break;
    }
    case OP_NEW_LIST:
    {
      push(OBJ_VAL(newList()));
      break;
    }
    case OP_LIST_APPEND:
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
    case OP_LIST_ADD:
    {
      Value indexVal = pop();
      Value item = pop();
      Value listVal = pop();

      if (!IS_LIST(listVal))
      {
        runtimeError("Can only append to a list.");
        return INTERPRET_RUNTIME_ERROR;
      }

      ObjList *list = AS_LIST(listVal);
      int index = AS_NUMBER(indexVal);

      if (index < 0 || index >= list->items.count)
      {
        runtimeError("List index out of bounds.");
        return INTERPRET_RUNTIME_ERROR;
      }

      if (list->items.count + 1 > list->items.capacity)
      {
        int oldCapacity = list->items.capacity;
        list->items.capacity = GROW_CAPACITY(oldCapacity);
        list->items.values = GROW_ARRAY(Value, list->items.values, oldCapacity, list->items.capacity);
      }

      for (int i = list->items.count - 1; i >= index; i--)
      {
        list->items.values[i + 1] = list->items.values[i];
      }

      list->items.values[index] = item;
      list->items.count++;
      push(OBJ_VAL(list));
      break;
    }
    case OP_LIST_REMOVE:
    {
      Value indexVal = pop();
      Value listVal = pop();

      if (!IS_LIST(listVal))
      {
        runtimeError("Can only remove from a list.");
        return INTERPRET_RUNTIME_ERROR;
      }

      ObjList *list = AS_LIST(listVal);
      int index = AS_NUMBER(indexVal);

      for (int i = index; i < list->items.count - 1; i++)
      {
        list->items.values[i] = list->items.values[i + 1];
      }

      list->items.count--;
      push(OBJ_VAL(list));
      break;
    }
    case OP_LIST_POP:
    {
      Value listVal = pop();
      if (!IS_LIST(listVal))
      {
        runtimeError("Can only append to a list.");
        return INTERPRET_RUNTIME_ERROR;
      }

      ObjList *list = AS_LIST(listVal);
      list->items.count--;
      push(OBJ_VAL(list));
      break;
    }
    case OP_NEW_HASHMAP:
    {
      push(OBJ_VAL(newHashmap()));
      break;
    }
    case OP_HASHMAP_APPEND:
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
    case OP_HASHMAP_DELETE:
    {
      Value keyVal = pop();
      Value hashmapVal = pop();

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

      bool deleted = false;
      if (IS_STRING(keyVal))
      {
        ObjString *keyStr = AS_STRING(keyVal);
        deleted = tableDelete(&hashmap->items, keyStr);
      }
      else if (IS_NUMBER(keyVal))
      {
        char keyStr[32];
        snprintf(keyStr, sizeof(keyStr), "%g", AS_NUMBER(keyVal));
        ObjString *key = copyString(keyStr, strlen(keyStr));
        deleted = tableDelete(&hashmap->items, key);
      }

      if (deleted)
      {
        push(BOOL_VAL(true));
      }
      else
      {
        runtimeError("This key does not exist in the hashmap.");
      }
      break;
    }
    case OP_SIZE:
    {
      Value item = pop();
      if (IS_LIST(item))
      {
        ObjList *list = AS_LIST(item);
        int size = list->items.count;
        push(NUMBER_VAL(size));
      }
      else if (IS_STRING(item))
      {
        ObjString *string = AS_STRING(item);
        int size = string->length;
        push(NUMBER_VAL(size));
      }
      else if (IS_HASHMAP(item))
      {
        ObjHashmap *hashmap = AS_HASHMAP(item);
        int size = hashmap->items.count;
        push(NUMBER_VAL(size));
      }
      else
      {
        runtimeError("Size does not exist for this datatype.");
        push(NIL_VAL);
      }
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
  ObjFunction *function = compile(source);
  if (function == NULL)
    return INTERPRET_COMPILE_ERROR;

  push(OBJ_VAL(function));
  call(function, 0);

  return run();
}