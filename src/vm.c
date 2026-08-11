#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include <limits.h>

#include "headers/common.h"
#include "headers/compiler.h"
#include "headers/debug.h"
#include "headers/gui.h"
#include "headers/object.h"
#include "headers/memory.h"
#include "headers/vm.h"
#include "headers/native.h"
#include "headers/pogberry.h"

VM *activeVM = NULL;
static VM defaultVM;
static bool defaultVMInitialised = false;

static void closeUpvalues(Value *last);

static void resetStack()
{
  vm.stackTop = vm.stack;
  vm.frameCount = 0;
  vm.openUpvalues = NULL;
}

void runtimeError(const char *format, ...)
{
  if (vm.hadRuntimeError)
    return;
  vm.hadRuntimeError = true;

  va_list args;
  va_start(args, format);
  va_list argsCopy;
  va_copy(argsCopy, args);
  int length = vsnprintf(NULL, 0, format, argsCopy);
  va_end(argsCopy);

  if (length >= 0)
  {
    char *message = (char *)malloc((size_t)length + 1);
    if (message != NULL)
    {
      vsnprintf(message, (size_t)length + 1, format, args);
      reportDiagnostic(POGBERRY_DIAGNOSTIC_RUNTIME, message);
      free(message);
    }
  }
  va_end(args);

  for (int i = vm.frameCount - 1; i >= 0; i--)
  {
    CallFrame *frame = &vm.frames[i];
    ObjFunction *function = frame->closure->function;
    size_t instruction = frame->ip - function->chunk.code - 1;
    char trace[256];
    if (function->name == NULL)
    {
      snprintf(trace, sizeof(trace), "[line %d] in script",
               function->chunk.lines[instruction]);
    }
    else
    {
      snprintf(trace, sizeof(trace), "[line %d] in %s()",
               function->chunk.lines[instruction], function->name->chars);
    }
    reportDiagnostic(POGBERRY_DIAGNOSTIC_RUNTIME, trace);
  }
  closeUpvalues(vm.stack);
  resetStack();
}

void writeVMOutput(const char *text, size_t length)
{
  if (vm.config.write != NULL)
  {
    vm.config.write(activeVM, text, length, vm.config.userData);
    return;
  }
  fwrite(text, sizeof(char), length, stdout);
}

void reportDiagnostic(PogberryDiagnosticKind kind, const char *message)
{
  if (vm.config.diagnostic != NULL)
  {
    vm.config.diagnostic(activeVM, kind, message, vm.config.userData);
    return;
  }
  fprintf(stderr, "%s\n", message);
}

static void initialiseActiveVM(const PogberryConfig *config)
{
  memset(activeVM, 0, sizeof(*activeVM));
  if (config != NULL)
    vm.config = *config;

  resetStack();
  vm.hadRuntimeError = false;
  vm.nextGC = 1024 * 1024;

  initTable(&vm.globals);
  initTable(&vm.strings);
  initTable(&vm.modules);

  vm.initString = copyString("init", 4);

  vm.randomState = (uint32_t)time(NULL) ^ (uint32_t)(uintptr_t)activeVM;
  if (vm.randomState == 0)
    vm.randomState = 0x9e3779b9u;
  defineNative("clock", clockNative);
  defineNative("rand", randNative);
  defineNative("floor", floorNative);
  defineNative("strInput", strInputNative);
  defineNative("sqrt", sqrtNative);
  defineNative("abs", absNative);
  defineNative("getTime", getTime);
  defineNative("len", lenNative);
  defineNative("type", typeNative);
  defineNative("str", strNative);
}

static void freeCapabilities(void)
{
  for (size_t i = 0; i < vm.capabilityCount; i++)
  {
    HostCapability *capability = &vm.capabilities[i];
    free(capability->name);
    for (size_t j = 0; j < capability->definitionCount; j++)
      free((char *)capability->definitions[j].name);
    free(capability->definitions);
  }
  free(vm.capabilities);
  vm.capabilities = NULL;
  vm.capabilityCount = 0;
  vm.capabilityCapacity = 0;
}

static void freeActiveVM(void)
{
  freeGui();
  freeTable(&vm.globals);
  freeTable(&vm.strings);
  freeTable(&vm.modules);
  vm.initString = NULL;
  freeObjects();
  freeCapabilities();
}

void initVM(void)
{
  if (defaultVMInitialised)
  {
    activeVM = &defaultVM;
    freeActiveVM();
  }
  activeVM = &defaultVM;
  initialiseActiveVM(NULL);
  defaultVMInitialised = true;
}

void freeVM(void)
{
  if (!defaultVMInitialised)
    return;
  activeVM = &defaultVM;
  freeActiveVM();
  memset(&defaultVM, 0, sizeof(defaultVM));
  defaultVMInitialised = false;
  activeVM = NULL;
}

bool push(Value value)
{
  if (vm.stackTop >= vm.stack + STACK_MAX)
  {
    runtimeError("Stack overflow.");
    return false;
  }
  *vm.stackTop = value; // put the new value in the empty spot
  vm.stackTop++;        // increase stackTop to point to the next empty spot
  return true;
}

Value pop()
{
  if (vm.stackTop <= vm.stack)
  {
    runtimeError("Stack underflow.");
    return NIL_VAL;
  }
  vm.stackTop--;
  return *vm.stackTop;
}

static Value peek(int distance)
{
  if (distance < 0 || vm.stackTop - vm.stack <= distance)
  {
    runtimeError("Stack underflow.");
    return NIL_VAL;
  }
  return vm.stackTop[-1 - distance];
}

bool call(ObjClosure *closure, int argCount)
{
  ObjFunction *function = closure->function;
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
  frame->closure = closure;
  frame->ip = function->chunk.code;

  frame->slots = vm.stackTop - argCount - 1;

  return true;
}

static PogberryValue valueToHost(Value value)
{
  PogberryValue result = pogberryNilValue();
  if (IS_NIL(value))
    return result;
  if (IS_BOOL(value))
    return pogberryBoolValue(AS_BOOL(value));
  if (IS_NUMBER(value))
    return pogberryNumberValue(AS_NUMBER(value));
  if (IS_STRING(value))
  {
    result.type = POGBERRY_VALUE_STRING;
    result.as.string.chars = AS_CSTRING(value);
    result.as.string.length = (size_t)AS_STRING(value)->length;
    return result;
  }
  result.type = POGBERRY_VALUE_OBJECT;
  result.as.object = AS_OBJ(value);
  return result;
}

static bool activeVMOwnsObject(const void *pointer)
{
  for (Obj *object = vm.objects; object != NULL; object = object->next)
  {
    if (object == pointer)
      return true;
  }
  return false;
}

static bool hostToValue(PogberryValue value, Value *result)
{
  switch (value.type)
  {
  case POGBERRY_VALUE_NIL:
    *result = NIL_VAL;
    return true;
  case POGBERRY_VALUE_BOOL:
    *result = BOOL_VAL(value.as.boolean);
    return true;
  case POGBERRY_VALUE_NUMBER:
    *result = NUMBER_VAL(value.as.number);
    return true;
  case POGBERRY_VALUE_STRING:
    if ((value.as.string.chars == NULL && value.as.string.length != 0) ||
        value.as.string.length > INT_MAX)
    {
      runtimeError("Host supplied an invalid string value.");
      return false;
    }
    *result = OBJ_VAL(copyString(value.as.string.chars != NULL
                                     ? value.as.string.chars
                                     : "",
                                 (int)value.as.string.length));
    return true;
  case POGBERRY_VALUE_OBJECT:
    if (!activeVMOwnsObject(value.as.object))
    {
      runtimeError("Host supplied an object that does not belong to this VM.");
      return false;
    }
    *result = OBJ_VAL((Obj *)value.as.object);
    return true;
  }
  runtimeError("Host supplied an unknown value type.");
  return false;
}

static bool callNativeObject(ObjNative *native, int argCount, Value *args,
                             Value *result)
{
  if (native->legacyFunction != NULL)
  {
    *result = native->legacyFunction(argCount, args);
    return !vm.hadRuntimeError;
  }

  PogberryValue *hostArgs = NULL;
  if (argCount > 0)
  {
    hostArgs = (PogberryValue *)malloc(sizeof(PogberryValue) * (size_t)argCount);
    if (hostArgs == NULL)
    {
      runtimeError("Could not allocate host-call arguments.");
      return false;
    }
    for (int i = 0; i < argCount; i++)
      hostArgs[i] = valueToHost(args[i]);
  }

  PogberryValue hostResult = native->hostFunction(
      activeVM, argCount, hostArgs, native->userData);
  free(hostArgs);

  if (vm.hadRuntimeError)
    return false;
  return hostToValue(hostResult, result);
}

static bool callValue(Value callee, int argCount)
{
  if (IS_OBJ(callee))
  {
    switch (OBJ_TYPE(callee))
    {
    case OBJ_CLOSURE:
      return call(AS_CLOSURE(callee), argCount);
    case OBJ_NATIVE:
    {
      Value result;
      if (!callNativeObject(AS_NATIVE(callee), argCount,
                            vm.stackTop - argCount, &result))
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
        return call(AS_CLOSURE(initializer), argCount);
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
  return call(AS_CLOSURE(method), argCount);
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

static bool invokeMapMethod(ObjString *name, int argCount)
{
  NativeFn method = NULL;

  if (strcmp(name->chars, "has") == 0)
  {
    method = mapHasNative;
  }
  else if (strcmp(name->chars, "get") == 0)
  {
    method = mapGetNative;
  }
  else if (strcmp(name->chars, "delete") == 0)
  {
    method = mapDeleteNative;
  }
  else if (strcmp(name->chars, "clear") == 0)
  {
    method = mapClearNative;
  }
  else
  {
    runtimeError("Maps do not have a method named '%s'.", name->chars);
    return false;
  }

  Value result = method(argCount + 1, vm.stackTop - argCount - 1);
  if (vm.hadRuntimeError) return false;

  vm.stackTop -= argCount + 1;
  push(result);
  return true;
}

static bool invoke(ObjString *name, int argCount)
{
  Value receiver = peek(argCount);

  if (IS_MODULE(receiver))
  {
    Value exported;
    ObjModule *module = AS_MODULE(receiver);
    if (!tableGet(&module->exports, name, &exported))
    {
      runtimeError("Module '%s' does not export '%s'.",
                   module->name->chars, name->chars);
      return false;
    }
    vm.stackTop[-argCount - 1] = exported;
    return callValue(exported, argCount);
  }

  if (IS_LIST(receiver))
  {
    return invokeListMethod(name, argCount);
  }

  if (IS_HASHMAP(receiver))
  {
    return invokeMapMethod(name, argCount);
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

  ObjBoundMethod *bound = newBoundMethod(peek(0), AS_CLOSURE(method));
  pop();
  push(OBJ_VAL(bound));
  return true;
}

// only nil and false are falsey
static bool isFalsey(Value value)
{
  return IS_NIL(value) || (IS_BOOL(value) && !AS_BOOL(value));
}

static ObjUpvalue *captureUpvalue(Value *local)
{
  ObjUpvalue *previous = NULL;
  ObjUpvalue *upvalue = vm.openUpvalues;

  while (upvalue != NULL && upvalue->location > local)
  {
    previous = upvalue;
    upvalue = upvalue->next;
  }

  if (upvalue != NULL && upvalue->location == local) return upvalue;

  ObjUpvalue *created = newUpvalue(local);
  created->next = upvalue;
  if (previous == NULL)
  {
    vm.openUpvalues = created;
  }
  else
  {
    previous->next = created;
  }
  return created;
}

static void closeUpvalues(Value *last)
{
  while (vm.openUpvalues != NULL && vm.openUpvalues->location >= last)
  {
    ObjUpvalue *upvalue = vm.openUpvalues;
    upvalue->closed = *upvalue->location;
    upvalue->location = &upvalue->closed;
    vm.openUpvalues = upvalue->next;
  }
}

static void concatenate()
{
  Value b = peek(0);
  Value a = peek(1);

  ObjString *strA = AS_STRING(a);
  ObjString *strB = AS_STRING(b);

  int length = strA->length + strB->length;
  char *chars = ALLOCATE(char, length + 1);
  memcpy(chars, strA->chars, strA->length);
  memcpy(chars + strA->length, strB->chars, strB->length);
  chars[length] = '\0';

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
  (frame->closure->function->chunk.constants.values[READ_BYTE()])

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
    disassembleInstruction(&frame->closure->function->chunk,
                           (int)(frame->ip - frame->closure->function->chunk.code));
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
    case OP_GET_UPVALUE:
    {
      uint8_t slot = READ_BYTE();
      push(*frame->closure->upvalues[slot]->location);
      break;
    }
    case OP_SET_UPVALUE:
    {
      uint8_t slot = READ_BYTE();
      *frame->closure->upvalues[slot]->location = peek(0);
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
      ObjString *name = READ_STRING();

      if (IS_MODULE(peek(0)))
      {
        ObjModule *module = AS_MODULE(peek(0));
        Value exported;
        if (!tableGet(&module->exports, name, &exported))
        {
          runtimeError("Module '%s' does not export '%s'.",
                       module->name->chars, name->chars);
          return INTERPRET_RUNTIME_ERROR;
        }
        pop();
        push(exported);
        break;
      }

      if (IS_HASHMAP(peek(0)))
      {
        if (strcmp(name->chars, "length") != 0)
        {
          runtimeError("Maps do not have a property named '%s'.", name->chars);
          return INTERPRET_RUNTIME_ERROR;
        }

        ObjHashmap *map = AS_HASHMAP(pop());
        push(NUMBER_VAL(mapCount(&map->items)));
        break;
      }

      if (!IS_INSTANCE(peek(0)))
      {
        runtimeError("Only instances have properties.");
        return INTERPRET_RUNTIME_ERROR;
      }

      ObjInstance *instance = AS_INSTANCE(peek(0));

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
      if (IS_MODULE(peek(1)))
      {
        runtimeError("Module exports are read-only.");
        return INTERPRET_RUNTIME_ERROR;
      }
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
      bool equal = valuesEqual(a, b);
      if (vm.hadRuntimeError) return INTERPRET_RUNTIME_ERROR;
      push(BOOL_VAL(equal));
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
      if (IS_STRING(peek(0)) && IS_STRING(peek(1)))
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
    {
      if (!IS_NUMBER(peek(0)) || !IS_NUMBER(peek(1)))
      {
        runtimeError("Operands must be numbers.");
        return INTERPRET_RUNTIME_ERROR;
      }

      double divisor = AS_NUMBER(pop());
      double dividend = AS_NUMBER(pop());
      if (divisor == 0)
      {
        runtimeError("Division by zero.");
        return INTERPRET_RUNTIME_ERROR;
      }

      push(NUMBER_VAL(dividend / divisor));
      break;
    }
    case OP_MODULO:
      if (!IS_NUMBER(peek(0)) || !IS_NUMBER(peek(1)))
      {
        runtimeError("Operands must be numbers.");
        return INTERPRET_RUNTIME_ERROR;
      }

      double b = AS_NUMBER(pop());
      double a = AS_NUMBER(pop());

      if (b == 0)
      {
        runtimeError("Modulo by zero.");
        return INTERPRET_RUNTIME_ERROR;
      }

      if (!isfinite(a) || !isfinite(b) || floor(b) != b || floor(a) != a)
      {
        runtimeError("Modulo only accepts finite integer operands.");
        return INTERPRET_RUNTIME_ERROR;
      }

      push(NUMBER_VAL(fmod(a, b)));
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
    {
      ObjString *rendered = valueToString(peek(0));
      writeVMOutput(rendered->chars, (size_t)rendered->length);
      pop();
      writeVMOutput("\n", 1);
      break;
    }
    case OP_PRINT_NO_NEWLINE:
    {
      ObjString *rendered = valueToString(peek(0));
      writeVMOutput(rendered->chars, (size_t)rendered->length);
      pop();
      break;
    }
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
        if (stringIndex < 0 || stringIndex >= string->length)
        {
          runtimeError("String index out of bounds.");
          return INTERPRET_RUNTIME_ERROR;
        }
        char chars[2] = {string->chars[(int)stringIndex], '\0'};

        ObjString *result = copyString(chars, 1);

        pop();
        pop();
        push(OBJ_VAL(result));
      }
      else if (IS_HASHMAP(container))
      {
        if (!mapKeyIsValid(index))
        {
          runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
          return INTERPRET_RUNTIME_ERROR;
        }

        Value result = NIL_VAL;
        mapGet(&AS_HASHMAP(container)->items, index, &result);

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
        if (!mapKeyIsValid(key))
        {
          runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
          return INTERPRET_RUNTIME_ERROR;
        }

        if (!mapSet(&AS_HASHMAP(container)->items, key, value, NULL))
        {
          runtimeError("Map key is invalid.");
          return INTERPRET_RUNTIME_ERROR;
        }

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

      if (!mapKeyIsValid(keyVal))
      {
        runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
        return INTERPRET_RUNTIME_ERROR;
      }

      if (!mapSet(&hashmap->items, keyVal, value, NULL))
      {
        runtimeError("Map key is invalid.");
        return INTERPRET_RUNTIME_ERROR;
      }

      pop();
      pop();
      pop();
      push(OBJ_VAL(hashmap));
      break;
    }
    case OP_CLOSURE:
    {
      ObjFunction *function = AS_FUNCTION(READ_CONSTANT());
      ObjClosure *closure = newClosure(function);
      if (!push(OBJ_VAL(closure))) return INTERPRET_RUNTIME_ERROR;
      for (int i = 0; i < closure->upvalueCount; i++)
      {
        uint8_t isLocal = READ_BYTE();
        uint8_t index = READ_BYTE();
        closure->upvalues[i] = isLocal
            ? captureUpvalue(frame->slots + index)
            : frame->closure->upvalues[index];
      }
      break;
    }
    case OP_CLOSE_UPVALUE:
      closeUpvalues(vm.stackTop - 1);
      pop();
      break;
    case OP_RETURN:
    {
      Value result = pop();
      closeUpvalues(frame->slots);
      vm.frameCount--;
      if (vm.frameCount == 0)
      {
        vm.lastReturnValue = result;
        vm.hasLastReturnValue = true;
        vm.stackTop = frame->slots;
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
    case OP_IMPORT:
    {
      ObjString *moduleName = READ_STRING();
      ObjString *alias = READ_STRING();
      Value existing;
      if (tableGet(&vm.globals, alias, &existing))
      {
        runtimeError("Import alias '%s' is already defined.", alias->chars);
        return INTERPRET_RUNTIME_ERROR;
      }

      Value module;
      if (!resolveModule(moduleName->chars, &module))
        return INTERPRET_RUNTIME_ERROR;
      tableSet(&vm.globals, alias, module);
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
      if (!resolveCapability(AS_CSTRING(name)))
        return INTERPRET_RUNTIME_ERROR;
      break;
    }
    }
    if (vm.hadRuntimeError) return INTERPRET_RUNTIME_ERROR;
  }
#undef BINARY_OP
#undef READ_CONSTANT
#undef READ_STRING
#undef READ_SHORT
#undef READ_BYTE
}

static InterpretResult interpretActive(const char *source)
{
  vm.hadRuntimeError = false;
  vm.hasLastReturnValue = false;

  ObjFunction *function = compile(source);
  if (function == NULL)
    return INTERPRET_COMPILE_ERROR;

  if (!push(OBJ_VAL(function))) return INTERPRET_RUNTIME_ERROR;
  ObjClosure *closure = newClosure(function);
  pop();
  if (!push(OBJ_VAL(closure))) return INTERPRET_RUNTIME_ERROR;
  if (!call(closure, 0))
  {
    return INTERPRET_RUNTIME_ERROR;
  }

  return run();
}

InterpretResult interpret(const char *source)
{
  if (!defaultVMInitialised)
    initVM();
  activeVM = &defaultVM;
  return interpretActive(source);
}

static VM *activateVM(PogberryVM *instance)
{
  VM *previous = activeVM;
  activeVM = (VM *)instance;
  return previous;
}

static char *copyHostString(const char *source)
{
  size_t length = strlen(source);
  char *copy = (char *)malloc(length + 1);
  if (copy != NULL)
    memcpy(copy, source, length + 1);
  return copy;
}

static bool validNativeName(const char *name)
{
  return name != NULL && name[0] != '\0' && strlen(name) <= INT_MAX;
}

static HostCapability *findCapability(const char *name)
{
  for (size_t i = 0; i < vm.capabilityCount; i++)
  {
    if (strcmp(vm.capabilities[i].name, name) == 0)
      return &vm.capabilities[i];
  }
  return NULL;
}

bool resolveCapability(const char *name)
{
  if (strcmp(name, "pogberry_gui") == 0)
    return initialiseGui();

  runtimeError("Module '%s' must be imported with an alias.", name);
  return false;
}

bool resolveModule(const char *name, Value *result)
{
  ObjString *moduleName = copyString(name, (int)strlen(name));
  if (!push(OBJ_VAL(moduleName)))
    return false;

  if (tableGet(&vm.modules, moduleName, result))
  {
    pop();
    return true;
  }

  HostCapability *capability = findCapability(name);
  if (capability == NULL && vm.config.resolveCapability != NULL)
  {
    vm.config.resolveCapability(activeVM, name, vm.config.userData);
    if (vm.hadRuntimeError)
      return false;
    capability = findCapability(name);
  }

  if (capability == NULL)
  {
    runtimeError("Host does not provide module '%s'.", name);
    return false;
  }

  ObjModule *module = newModule(moduleName);
  if (!push(OBJ_VAL(module)))
    return false;

  for (size_t i = 0; i < capability->definitionCount; i++)
  {
    PogberryNativeDefinition *definition = &capability->definitions[i];
    ObjString *exportName = copyString(
        definition->name, (int)strlen(definition->name));
    if (!push(OBJ_VAL(exportName)))
      return false;
    ObjNative *native = newHostNative(definition->function,
                                      definition->userData);
    if (!push(OBJ_VAL(native)))
      return false;
    tableSet(&module->exports, exportName, OBJ_VAL(native));
    pop();
    pop();
  }

  tableSet(&vm.modules, moduleName, OBJ_VAL(module));
  *result = OBJ_VAL(module);
  pop();
  pop();
  return true;
}

POGBERRY_API PogberryVM *pogberryCreateVM(const PogberryConfig *config)
{
  VM *instance = (VM *)malloc(sizeof(VM));
  if (instance == NULL)
    return NULL;
  VM *previous = activateVM(instance);
  initialiseActiveVM(config);
  activeVM = previous;
  return instance;
}

POGBERRY_API void pogberryDestroyVM(PogberryVM *instance)
{
  if (instance == NULL)
    return;
  VM *previous = activateVM(instance);
  if (vm.frameCount != 0)
  {
    reportDiagnostic(POGBERRY_DIAGNOSTIC_HOST,
                     "Cannot destroy a VM while it is running.");
    activeVM = previous;
    return;
  }
  freeActiveVM();
  memset(instance, 0, sizeof(VM));
  free(instance);
  activeVM = previous == (VM *)instance ? NULL : previous;
}

POGBERRY_API PogberryResult pogberryInterpret(PogberryVM *instance,
                                              const char *source)
{
  if (instance == NULL || source == NULL)
    return INTERPRET_RUNTIME_ERROR;
  VM *previous = activateVM(instance);
  if (vm.frameCount != 0 || vm.stackTop != vm.stack)
  {
    reportDiagnostic(POGBERRY_DIAGNOSTIC_HOST,
                     "Cannot interpret source while the VM is running.");
    activeVM = previous;
    return INTERPRET_RUNTIME_ERROR;
  }
  PogberryResult result = interpretActive(source);
  activeVM = previous;
  return result;
}

POGBERRY_API bool pogberryDefineNative(PogberryVM *instance, const char *name,
                                       PogberryNativeFn function,
                                       void *userData)
{
  if (instance == NULL || !validNativeName(name) || function == NULL)
    return false;
  VM *previous = activateVM(instance);
  defineHostNative(name, function, userData);
  activeVM = previous;
  return true;
}

POGBERRY_API bool pogberryRegisterCapability(
    PogberryVM *instance, const char *name,
    const PogberryNativeDefinition *definitions, size_t definitionCount)
{
  if (instance == NULL || name == NULL || name[0] == '\0' ||
      (definitionCount > 0 && definitions == NULL))
    return false;

  VM *previous = activateVM(instance);
  if (findCapability(name) != NULL)
  {
    reportDiagnostic(POGBERRY_DIAGNOSTIC_HOST,
                     "Capability is already registered in this VM.");
    activeVM = previous;
    return false;
  }

  for (size_t i = 0; i < definitionCount; i++)
  {
    if (!validNativeName(definitions[i].name) ||
        definitions[i].function == NULL)
    {
      reportDiagnostic(POGBERRY_DIAGNOSTIC_HOST,
                       "Capability contains an invalid native definition.");
      activeVM = previous;
      return false;
    }
  }

  if (vm.capabilityCount == vm.capabilityCapacity)
  {
    size_t capacity = vm.capabilityCapacity < 4 ? 4 : vm.capabilityCapacity * 2;
    HostCapability *capabilities = (HostCapability *)realloc(
        vm.capabilities, sizeof(HostCapability) * capacity);
    if (capabilities == NULL)
    {
      reportDiagnostic(POGBERRY_DIAGNOSTIC_HOST,
                       "Could not allocate capability registry.");
      activeVM = previous;
      return false;
    }
    vm.capabilities = capabilities;
    vm.capabilityCapacity = capacity;
  }

  HostCapability capability = {0};
  capability.name = copyHostString(name);
  if (capability.name == NULL)
  {
    activeVM = previous;
    return false;
  }

  if (definitionCount > 0)
  {
    capability.definitions = (PogberryNativeDefinition *)calloc(
        definitionCount, sizeof(PogberryNativeDefinition));
    if (capability.definitions == NULL)
    {
      free(capability.name);
      activeVM = previous;
      return false;
    }
  }
  capability.definitionCount = definitionCount;

  for (size_t i = 0; i < definitionCount; i++)
  {
    capability.definitions[i] = definitions[i];
    capability.definitions[i].name = copyHostString(definitions[i].name);
    if (capability.definitions[i].name == NULL)
    {
      for (size_t j = 0; j < i; j++)
        free((char *)capability.definitions[j].name);
      free(capability.definitions);
      free(capability.name);
      activeVM = previous;
      return false;
    }
  }

  vm.capabilities[vm.capabilityCount++] = capability;
  activeVM = previous;
  return true;
}

POGBERRY_API PogberryResult pogberryCall(PogberryVM *instance, const char *name,
                                         int argCount,
                                         const PogberryValue *args,
                                         PogberryValue *result)
{
  if (instance == NULL || !validNativeName(name) || argCount < 0 ||
      (argCount > 0 && args == NULL))
    return INTERPRET_RUNTIME_ERROR;

  VM *previous = activateVM(instance);
  vm.hadRuntimeError = false;

  if (vm.frameCount != 0 || vm.stackTop != vm.stack)
  {
    runtimeError("Cannot invoke a script function while the VM is running.");
    activeVM = previous;
    return INTERPRET_RUNTIME_ERROR;
  }

  ObjString *functionName = copyString(name, (int)strlen(name));
  Value callee;
  if (!tableGet(&vm.globals, functionName, &callee) || !IS_CLOSURE(callee))
  {
    runtimeError("No script function named '%s' is defined.", name);
    activeVM = previous;
    return INTERPRET_RUNTIME_ERROR;
  }

  push(callee);
  for (int i = 0; i < argCount; i++)
  {
    Value argument;
    if (!hostToValue(args[i], &argument) || !push(argument))
    {
      activeVM = previous;
      return INTERPRET_RUNTIME_ERROR;
    }
  }

  vm.hasLastReturnValue = false;
  if (!callValue(callee, argCount))
  {
    activeVM = previous;
    return INTERPRET_RUNTIME_ERROR;
  }

  PogberryResult callResult = run();
  if (callResult == INTERPRET_OK && result != NULL)
    *result = valueToHost(vm.lastReturnValue);
  activeVM = previous;
  return callResult;
}

POGBERRY_API void pogberryRuntimeError(PogberryVM *instance,
                                       const char *message)
{
  if (instance == NULL || message == NULL)
    return;
  VM *previous = activateVM(instance);
  runtimeError("%s", message);
  activeVM = previous;
}

POGBERRY_API PogberryValue pogberryNilValue(void)
{
  PogberryValue value = {0};
  value.type = POGBERRY_VALUE_NIL;
  return value;
}

POGBERRY_API PogberryValue pogberryBoolValue(bool boolean)
{
  PogberryValue value = pogberryNilValue();
  value.type = POGBERRY_VALUE_BOOL;
  value.as.boolean = boolean;
  return value;
}

POGBERRY_API PogberryValue pogberryNumberValue(double number)
{
  PogberryValue value = pogberryNilValue();
  value.type = POGBERRY_VALUE_NUMBER;
  value.as.number = number;
  return value;
}

POGBERRY_API PogberryValue pogberryStringValueN(const char *string,
                                                size_t length)
{
  PogberryValue value = pogberryNilValue();
  value.type = POGBERRY_VALUE_STRING;
  value.as.string.chars = string;
  value.as.string.length = length;
  return value;
}

POGBERRY_API PogberryValue pogberryStringValue(const char *string)
{
  return pogberryStringValueN(string, string != NULL ? strlen(string) : 0);
}

POGBERRY_API void ext_initVM(void)
{
  initVM();
}

POGBERRY_API InterpretResult ext_interpret(const char *source)
{
  return interpret(source);
}
