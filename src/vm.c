#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include <limits.h>

#include "headers/common.h"
#include "headers/compiler.h"
#include "headers/debug.h"
#include "headers/object.h"
#include "headers/memory.h"
#include "headers/value.h"
#include "headers/vm.h"
#include "headers/native.h"
#include "headers/pb.h"

#ifdef DEBUG_OPCODE_STATS
extern uint64_t opcodeCounts[256];
#endif

VM *activeVM = NULL;
static VM defaultVM;
static bool defaultVMInitialised = false;

static void closeUpvalues(Value *last);

static void resetStack() {
  vm.stackTop = vm.stack;
  vm.frameCount = 0;
  vm.openUpvalues = NULL;
}

void runtimeError(const char *format, ...) {
  if (vm.hadRuntimeError) return;
  vm.hadRuntimeError = true;

  va_list args;
  va_start(args, format);
  va_list argsCopy;
  va_copy(argsCopy, args);
  int length = vsnprintf(NULL, 0, format, argsCopy);
  va_end(argsCopy);

  if (length >= 0) {
    char *message = (char *)malloc((size_t)length + 1);
    if (message != NULL) {
      vsnprintf(message, (size_t)length + 1, format, args);
      reportDiagnostic(PB_DIAGNOSTIC_RUNTIME, message);
      free(message);
    }
  }
  va_end(args);

  for (int i = vm.frameCount - 1; i >= 0; i--) {
    CallFrame *frame = &vm.frames[i];
    ObjFunction *function = frame->closure->function;
    size_t instruction = frame->ip - function->chunk.code - 1;
    char trace[256];
    if (function->sourceName != NULL && function->name == NULL) {
      snprintf(trace, sizeof(trace), "[%s line %d] in module", function->sourceName->chars,
               function->chunk.lines[instruction]);
    } else if (function->sourceName != NULL) {
      snprintf(trace, sizeof(trace), "[%s line %d] in %s()", function->sourceName->chars,
               function->chunk.lines[instruction], function->name->chars);
    } else if (function->name == NULL) {
      snprintf(trace, sizeof(trace), "[line %d] in script", function->chunk.lines[instruction]);
    } else {
      snprintf(trace, sizeof(trace), "[line %d] in %s()", function->chunk.lines[instruction], function->name->chars);
    }
    reportDiagnostic(PB_DIAGNOSTIC_RUNTIME, trace);
  }
  closeUpvalues(vm.stack);
  resetStack();
}

void writeVMOutput(const char *text, size_t length) {
  if (vm.config.write != NULL) {
    vm.config.write(activeVM, text, length, vm.config.userData);
    return;
  }
  fwrite(text, sizeof(char), length, stdout);
}

void reportDiagnostic(PbDiagnosticKind kind, const char *message) {
  if (vm.config.diagnostic != NULL) {
    vm.config.diagnostic(activeVM, kind, message, vm.config.userData);
    return;
  }
  fprintf(stderr, "%s\n", message);
}

static void initialiseActiveVM(const PbConfig *config) {
  memset(activeVM, 0, sizeof(*activeVM));
  if (config != NULL) vm.config = *config;

  resetStack();
  vm.hadRuntimeError = false;
  vm.nextGC = 1024 * 1024;

  initTable(&vm.globals);
  initTable(&vm.prelude);
  initTable(&vm.strings);
  initTable(&vm.modules);

  vm.initString = copyString("init", 4);
  for (int i = 0; i < 256; i++) {
    char c[2] = {(char)i, '\0'};
    vm.charStrings[i] = copyString(c, 1);
  }

  vm.randomState = (uint32_t)time(NULL) ^ (uint32_t)(uintptr_t)activeVM;
  if (vm.randomState == 0) vm.randomState = 0x9e3779b9u;
  defineNative("clock", clockNative);
  defineNative("rand", randNative);
  defineNative("strInput", strInputNative);
  defineNative("getTime", getTime);
  defineNative("len", lenNative);
  defineNative("type", typeNative);
  defineNative("str", strNative);
  defineNative("join", joinNative);
  tableAddAll(&vm.globals, &vm.prelude);
}

static void freeCapabilities(void) {
  for (size_t i = 0; i < vm.capabilityCount; i++) {
    HostCapability *capability = &vm.capabilities[i];
    free(capability->name);
    free(capability->source);
    for (size_t j = 0; j < capability->definitionCount; j++) free((char *)capability->definitions[j].name);
    free(capability->definitions);
  }
  free(vm.capabilities);
  vm.capabilities = NULL;
  vm.capabilityCount = 0;
  vm.capabilityCapacity = 0;
}

static void freeActiveVM(void) {
  freeTable(&vm.globals);
  freeTable(&vm.prelude);
  freeTable(&vm.strings);
  freeTable(&vm.modules);
  vm.initString = NULL;
  freeObjects();
  freeCapabilities();
}

void initVM(void) {
  if (defaultVMInitialised) {
    activeVM = &defaultVM;
    freeActiveVM();
  }
  activeVM = &defaultVM;
  initialiseActiveVM(NULL);
  defaultVMInitialised = true;
}

void freeVM(void) {
  if (!defaultVMInitialised) return;
  activeVM = &defaultVM;
  freeActiveVM();
  memset(&defaultVM, 0, sizeof(defaultVM));
  defaultVMInitialised = false;
  activeVM = NULL;
}

bool push(Value value) {
  if (vm.stackTop >= vm.stack + STACK_MAX) {
    runtimeError("Stack overflow.");
    return false;
  }
  *vm.stackTop = value; // put the new value in the empty spot
  vm.stackTop++;        // increase stackTop to point to the next empty spot
  return true;
}

Value pop() {
  if (vm.stackTop <= vm.stack) {
    runtimeError("Stack underflow.");
    return NIL_VAL;
  }
  vm.stackTop--;
  return *vm.stackTop;
}

static Value peek(int distance) {
  if (distance < 0 || vm.stackTop - vm.stack <= distance) {
    runtimeError("Stack underflow.");
    return NIL_VAL;
  }
  return vm.stackTop[-1 - distance];
}

bool call(ObjClosure *closure, int argCount) {
  ObjFunction *function = closure->function;
  if (argCount != function->arity) {
    runtimeError("Expected %d arguments but got %d.", function->arity, argCount);
    return false;
  }

  if (vm.frameCount == FRAMES_MAX) {
    runtimeError("Stack overflow.");
    return false;
  }

  CallFrame *frame = &vm.frames[vm.frameCount++];
  frame->closure = closure;
  frame->ip = function->chunk.code;

  frame->slots = vm.stackTop - argCount - 1;

  return true;
}

static PbValue valueToHost(Value value) {
  PbValue result = pbNilValue();
  if (IS_NIL(value)) return result;
  if (IS_BOOL(value)) return pbBoolValue(AS_BOOL(value));
  if (IS_NUMBER(value)) return pbNumberValue(AS_NUMBER(value));
  if (IS_STRING(value)) {
    result.type = PB_VALUE_STRING;
    result.as.string.chars = AS_CSTRING(value);
    result.as.string.length = (size_t)AS_STRING(value)->length;
    return result;
  }
  result.type = PB_VALUE_OBJECT;
  result.as.object = AS_OBJ(value);
  return result;
}

static bool activeVMOwnsObject(const void *pointer) {
  for (Obj *object = vm.objects; object != NULL; object = object->next) {
    if (object == pointer) return true;
  }
  return false;
}

static bool hostToValue(PbValue value, Value *result) {
  switch (value.type) {
  case PB_VALUE_NIL:
    *result = NIL_VAL;
    return true;
  case PB_VALUE_BOOL:
    *result = BOOL_VAL(value.as.boolean);
    return true;
  case PB_VALUE_NUMBER:
    *result = NUMBER_VAL(value.as.number);
    return true;
  case PB_VALUE_STRING:
    if ((value.as.string.chars == NULL && value.as.string.length != 0) || value.as.string.length > INT_MAX) {
      runtimeError("Host supplied an invalid string value.");
      return false;
    }
    *result =
        OBJ_VAL(copyString(value.as.string.chars != NULL ? value.as.string.chars : "", (int)value.as.string.length));
    return true;
  case PB_VALUE_OBJECT:
    if (!activeVMOwnsObject(value.as.object)) {
      runtimeError("Host supplied an object that does not belong to this VM.");
      return false;
    }
    *result = OBJ_VAL((Obj *)value.as.object);
    return true;
  }
  runtimeError("Host supplied an unknown value type.");
  return false;
}

static bool callNativeObject(ObjNative *native, int argCount, Value *args, Value *result) {
  if (native->legacyFunction != NULL) {
    *result = native->legacyFunction(argCount, args);
    return !vm.hadRuntimeError;
  }

  PbValue *hostArgs = NULL;
  if (argCount > 0) {
    hostArgs = (PbValue *)malloc(sizeof(PbValue) * (size_t)argCount);
    if (hostArgs == NULL) {
      runtimeError("Could not allocate host-call arguments.");
      return false;
    }
    for (int i = 0; i < argCount; i++) hostArgs[i] = valueToHost(args[i]);
  }

  PbValue hostResult = native->hostFunction(activeVM, argCount, hostArgs, native->userData);
  free(hostArgs);

  if (vm.hadRuntimeError) return false;
  return hostToValue(hostResult, result);
}

static bool callValue(Value callee, int argCount) {
  if (IS_OBJ(callee)) {
    switch (OBJ_TYPE(callee)) {
    case OBJ_CLOSURE:
      return call(AS_CLOSURE(callee), argCount);
    case OBJ_NATIVE: {
      Value result;
      if (!callNativeObject(AS_NATIVE(callee), argCount, vm.stackTop - argCount, &result)) return false;

      vm.stackTop -= argCount + 1;
      push(result);
      return true;
    }
    case OBJ_CLASS: {
      ObjClass *klass = AS_CLASS(callee);
      vm.stackTop[-argCount - 1] = OBJ_VAL(newInstance(klass));
      Value initializer;
      if (tableGet(&klass->methods, vm.initString, &initializer)) {
        return call(AS_CLOSURE(initializer), argCount);
      } else if (argCount != 0) {
        runtimeError("Expected 0 arguments but got %d.", argCount);
        return false;
      }
      return true;
    }
    case OBJ_BOUND_METHOD: {
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

static bool invokeFromClass(ObjClass *klass, ObjString *name, int argCount) {
  Value method;
  if (!tableGet(&klass->methods, name, &method)) {
    runtimeError("Undefined property '%s'.", name->chars);
    return false;
  }
  return call(AS_CLOSURE(method), argCount);
}

static bool invokeListMethod(ObjString *name, int argCount) {
  NativeFn method = NULL;

  switch (name->length) {
  case 3:
    if (memcmp(name->chars, "pop", 3) == 0) method = listPopNative;
    break;
  case 4:
    if (memcmp(name->chars, "push", 4) == 0) method = listPushNative;
    else if (memcmp(name->chars, "copy", 4) == 0) method = listCopyNative;
    else if (memcmp(name->chars, "sort", 4) == 0) method = listSortNative;
    break;
  case 5:
    if (memcmp(name->chars, "clear", 5) == 0) method = listClearNative;
    else if (memcmp(name->chars, "index", 5) == 0) method = listIndexNative;
    else if (memcmp(name->chars, "count", 5) == 0) method = listCountNative;
    break;
  case 6:
    if (memcmp(name->chars, "extend", 6) == 0) method = listExtendNative;
    else if (memcmp(name->chars, "insert", 6) == 0) method = listInsertNative;
    else if (memcmp(name->chars, "remove", 6) == 0) method = listRemoveNative;
    break;
  case 7:
    if (memcmp(name->chars, "reverse", 7) == 0) method = listReverseNative;
    break;
  case 8:
    if (memcmp(name->chars, "removeAt", 8) == 0) method = listRemoveAtNative;
    break;
  }

  if (method == NULL) {
    runtimeError("Lists do not have a method named '%s'.", name->chars);
    return false;
  }

  Value result = method(argCount + 1, vm.stackTop - argCount - 1);
  if (vm.hadRuntimeError) return false;

  vm.stackTop -= argCount + 1;
  push(result);
  return true;
}

static bool invokeMapMethod(ObjString *name, int argCount) {
  if (name->length == 3 && memcmp(name->chars, "has", 3) == 0) {
    if (argCount != 1) {
      runtimeError("has() expects 1 argument but got %d.", argCount);
      return false;
    }
    Value key = vm.stackTop[-1];
    if (!mapKeyIsValid(key)) {
      runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
      return false;
    }
    ObjHashmap *map = AS_HASHMAP(vm.stackTop[-2]);
    Value val;
    bool found = mapGet(&map->items, key, &val);
    vm.stackTop[-2] = BOOL_VAL(found);
    vm.stackTop--;
    return true;
  }

  if (name->length == 3 && memcmp(name->chars, "get", 3) == 0) {
    if (argCount != 2) {
      runtimeError("get() expects 2 arguments but got %d.", argCount);
      return false;
    }
    Value defVal = vm.stackTop[-1];
    Value key = vm.stackTop[-2];
    if (!mapKeyIsValid(key)) {
      runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
      return false;
    }
    ObjHashmap *map = AS_HASHMAP(vm.stackTop[-3]);
    Value val;
    if (!mapGet(&map->items, key, &val)) {
      val = defVal;
    }
    vm.stackTop[-3] = val;
    vm.stackTop -= 2;
    return true;
  }

  if (name->length == 6 && memcmp(name->chars, "delete", 6) == 0) {
    if (argCount != 1) {
      runtimeError("delete() expects 1 argument but got %d.", argCount);
      return false;
    }
    Value key = vm.stackTop[-1];
    if (!mapKeyIsValid(key)) {
      runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
      return false;
    }
    ObjHashmap *map = AS_HASHMAP(vm.stackTop[-2]);
    bool deleted = mapDelete(&map->items, key);
    vm.stackTop[-2] = BOOL_VAL(deleted);
    vm.stackTop--;
    return true;
  }

  if (name->length == 5 && memcmp(name->chars, "clear", 5) == 0) {
    if (argCount != 0) {
      runtimeError("clear() expects 0 arguments but got %d.", argCount);
      return false;
    }
    ObjHashmap *map = AS_HASHMAP(vm.stackTop[-1]);
    mapClear(&map->items);
    vm.stackTop[-1] = NIL_VAL;
    return true;
  }

  runtimeError("Maps do not have a method named '%s'.", name->chars);
  return false;
}

static bool invoke(ObjString *name, int argCount) {
  Value receiver = peek(argCount);

  if (IS_MODULE(receiver)) {
    Value exported;
    ObjModule *module = AS_MODULE(receiver);
    if (!tableGet(&module->exports, name, &exported)) {
      runtimeError("Module '%s' does not export '%s'.", module->name->chars, name->chars);
      return false;
    }
    vm.stackTop[-argCount - 1] = exported;
    return callValue(exported, argCount);
  }

  if (IS_LIST(receiver)) {
    return invokeListMethod(name, argCount);
  }

  if (IS_HASHMAP(receiver)) {
    return invokeMapMethod(name, argCount);
  }

  if (!IS_INSTANCE(receiver)) {
    runtimeError("Only instances have methods.");
    return false;
  }

  ObjInstance *instance = AS_INSTANCE(receiver);

  Value value;
  if (tableGet(&instance->fields, name, &value)) {
    vm.stackTop[-argCount - 1] = value;
    return callValue(value, argCount);
  }

  return invokeFromClass(instance->klass, name, argCount);
}

static bool bindMethod(ObjClass *klass, ObjString *name) {
  Value method;
  if (!tableGet(&klass->methods, name, &method)) {
    runtimeError("Undefined property '%s'.", name->chars);
    return false;
  }

  ObjBoundMethod *bound = newBoundMethod(peek(0), AS_CLOSURE(method));
  pop();
  push(OBJ_VAL(bound));
  return true;
}

// only nil and false are falsey
static bool isFalsey(Value value) { return IS_NIL(value) || (IS_BOOL(value) && !AS_BOOL(value)); }

static ObjUpvalue *captureUpvalue(Value *local) {
  ObjUpvalue *previous = NULL;
  ObjUpvalue *upvalue = vm.openUpvalues;

  while (upvalue != NULL && upvalue->location > local) {
    previous = upvalue;
    upvalue = upvalue->next;
  }

  if (upvalue != NULL && upvalue->location == local) return upvalue;

  ObjUpvalue *created = newUpvalue(local);
  created->next = upvalue;
  if (previous == NULL) {
    vm.openUpvalues = created;
  } else {
    previous->next = created;
  }
  return created;
}

static void closeUpvalues(Value *last) {
  while (vm.openUpvalues != NULL && vm.openUpvalues->location >= last) {
    ObjUpvalue *upvalue = vm.openUpvalues;
    upvalue->closed = *upvalue->location;
    upvalue->location = &upvalue->closed;
    vm.openUpvalues = upvalue->next;
  }
}

static void concatenate() {
  Value b = peek(0);
  Value a = peek(1);

  ObjString *strA = AS_STRING(a);
  ObjString *strB = AS_STRING(b);

  int newLength = strA->length + strB->length;
  int newCapacity = GROW_CAPACITY(newLength + 1);
  char *chars = ALLOCATE(char, newCapacity);
  if (strA->length > 0) memcpy(chars, strA->chars, (size_t)strA->length);
  if (strB->length > 0) memcpy(chars + strA->length, strB->chars, (size_t)strB->length);
  chars[newLength] = '\0';

  pop();
  pop();

  ObjString *result = createUninternedString(chars, newLength, newCapacity);
  push(OBJ_VAL(result));
}

static void defineMethod(ObjString *name) {
  Value method = peek(0);
  ObjClass *klass = AS_CLASS(peek(1));
  tableSet(&klass->methods, name, method);
  pop();
}

static bool normalizeListIndex(Value indexValue, int listCount, int *outIndex) {
  if (!IS_NUMBER(indexValue)) {
    runtimeError("List index must be a number.");
    return false;
  }

  double index = AS_NUMBER(indexValue);
  if (!isfinite(index) || floor(index) != index) {
    runtimeError("List index must be a finite integer.");
    return false;
  }

  if (index < 0) {
    index += listCount;
  }

  if (index < 0 || index >= listCount) {
    runtimeError("List index out of bounds.");
    return false;
  }

  *outIndex = (int)index;
  return true;
}

static Table *globalsForFrame(CallFrame *frame) {
  if (frame->closure->module != NULL) return &frame->closure->module->globals;
  return &vm.globals;
}

#ifdef DEBUG_OPCODE_STATS
#define RECORD_OPCODE(op) (opcodeCounts[op]++)
#else
#define RECORD_OPCODE(op) ((void)0)
#endif

#if !defined(DEBUG_TRACE_EXECUTION) && (defined(__GNUC__) || defined(__clang__))
#define USE_COMPUTED_GOTO 1
#else
#define USE_COMPUTED_GOTO 0
#endif

#if USE_COMPUTED_GOTO
#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpedantic"
#pragma clang diagnostic ignored "-Winitializer-overrides"
#elif defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpedantic"
#pragma GCC diagnostic ignored "-Woverride-init"
#endif

#define TARGET(op) target_##op:
#define DISPATCH() \
  do { \
    instruction = READ_BYTE(); \
    RECORD_OPCODE(instruction); \
    goto *dispatchTable[instruction]; \
  } while (0)
#else
#define TARGET(op) case op:
#define DISPATCH() break
#endif

static InterpretResult run(int stopFrameCount) {
  CallFrame *frame = &vm.frames[vm.frameCount - 1];
  register uint8_t *ip = frame->ip;
  register Value *stackTop = vm.stackTop;
  register Value *slots = frame->slots;

#define STORE_FRAME() \
  do { \
    frame->ip = ip; \
    vm.stackTop = stackTop; \
  } while (0)
#define LOAD_FRAME() \
  do { \
    frame = &vm.frames[vm.frameCount - 1]; \
    ip = frame->ip; \
    stackTop = vm.stackTop; \
    slots = frame->slots; \
  } while (0)

#define READ_BYTE() (*ip++)
#define READ_SHORT() (ip += 2, decodeU16BE(ip - 2))
#define READ_CONSTANT() (frame->closure->function->chunk.constants.values[READ_BYTE()])
#define READ_CONSTANT_LONG() (ip += 2, frame->closure->function->chunk.constants.values[decodeU16BE(ip - 2)])
#define READ_STRING() AS_STRING(READ_CONSTANT())
#define READ_STRING_LONG() AS_STRING(READ_CONSTANT_LONG())

#define PUSH(val) (*stackTop++ = (val))
#define POP() (*(--stackTop))
#define DROP() ((void)(--stackTop))
#define PEEK(d) (stackTop[-1 - (d)])

#define BINARY_OP(valueType, op) \
  do { \
    if (!IS_NUMBER(stackTop[-1]) || !IS_NUMBER(stackTop[-2])) { \
      STORE_FRAME(); \
      runtimeError("Operands must be numbers."); \
      return INTERPRET_RUNTIME_ERROR; \
    } \
    double b = AS_NUMBER(stackTop[-1]); \
    double a = AS_NUMBER(stackTop[-2]); \
    stackTop[-2] = valueType(a op b); \
    stackTop--; \
  } while (false)

#if USE_COMPUTED_GOTO
  static const void *const dispatchTable[256] = {
    [0 ... 255] = &&target_OP_UNKNOWN,
    [OP_CONSTANT] = &&target_OP_CONSTANT,
    [OP_CONSTANT_LONG] = &&target_OP_CONSTANT_LONG,
    [OP_NIL] = &&target_OP_NIL,
    [OP_TRUE] = &&target_OP_TRUE,
    [OP_FALSE] = &&target_OP_FALSE,
    [OP_POP] = &&target_OP_POP,
    [OP_GET_LOCAL] = &&target_OP_GET_LOCAL,
    [OP_SET_LOCAL] = &&target_OP_SET_LOCAL,
    [OP_GET_LOCAL_0] = &&target_OP_GET_LOCAL_0,
    [OP_GET_LOCAL_1] = &&target_OP_GET_LOCAL_1,
    [OP_GET_LOCAL_2] = &&target_OP_GET_LOCAL_2,
    [OP_GET_LOCAL_3] = &&target_OP_GET_LOCAL_3,
    [OP_SET_LOCAL_0] = &&target_OP_SET_LOCAL_0,
    [OP_SET_LOCAL_1] = &&target_OP_SET_LOCAL_1,
    [OP_SET_LOCAL_2] = &&target_OP_SET_LOCAL_2,
    [OP_SET_LOCAL_3] = &&target_OP_SET_LOCAL_3,
    [OP_INT_0] = &&target_OP_INT_0,
    [OP_INT_1] = &&target_OP_INT_1,
    [OP_INT_2] = &&target_OP_INT_2,
    [OP_GET_UPVALUE] = &&target_OP_GET_UPVALUE,
    [OP_SET_UPVALUE] = &&target_OP_SET_UPVALUE,
    [OP_GET_GLOBAL] = &&target_OP_GET_GLOBAL,
    [OP_GET_GLOBAL_LONG] = &&target_OP_GET_GLOBAL_LONG,
    [OP_DEFINE_GLOBAL] = &&target_OP_DEFINE_GLOBAL,
    [OP_DEFINE_GLOBAL_LONG] = &&target_OP_DEFINE_GLOBAL_LONG,
    [OP_SET_GLOBAL] = &&target_OP_SET_GLOBAL,
    [OP_SET_GLOBAL_LONG] = &&target_OP_SET_GLOBAL_LONG,
    [OP_GET_PROPERTY] = &&target_OP_GET_PROPERTY,
    [OP_GET_PROPERTY_LONG] = &&target_OP_GET_PROPERTY_LONG,
    [OP_SET_PROPERTY] = &&target_OP_SET_PROPERTY,
    [OP_SET_PROPERTY_LONG] = &&target_OP_SET_PROPERTY_LONG,
    [OP_INVOKE] = &&target_OP_INVOKE,
    [OP_INVOKE_LONG] = &&target_OP_INVOKE_LONG,
    [OP_SUPER_INVOKE] = &&target_OP_SUPER_INVOKE,
    [OP_SUPER_INVOKE_LONG] = &&target_OP_SUPER_INVOKE_LONG,
    [OP_GET_SUPER] = &&target_OP_GET_SUPER,
    [OP_GET_SUPER_LONG] = &&target_OP_GET_SUPER_LONG,
    [OP_EQUAL] = &&target_OP_EQUAL,
    [OP_GREATER] = &&target_OP_GREATER,
    [OP_LESS] = &&target_OP_LESS,
    [OP_ADD] = &&target_OP_ADD,
    [OP_SUBTRACT] = &&target_OP_SUBTRACT,
    [OP_MULTIPLY] = &&target_OP_MULTIPLY,
    [OP_DIVIDE] = &&target_OP_DIVIDE,
    [OP_MODULO] = &&target_OP_MODULO,
    [OP_NOT] = &&target_OP_NOT,
    [OP_NEGATE] = &&target_OP_NEGATE,
    [OP_PRINT] = &&target_OP_PRINT,
    [OP_PRINT_NO_NEWLINE] = &&target_OP_PRINT_NO_NEWLINE,
    [OP_JUMP] = &&target_OP_JUMP,
    [OP_JUMP_IF_FALSE] = &&target_OP_JUMP_IF_FALSE,
    [OP_POP_JUMP_IF_FALSE] = &&target_OP_POP_JUMP_IF_FALSE,
    [OP_JUMP_IF_NOT_LESS] = &&target_OP_JUMP_IF_NOT_LESS,
    [OP_JUMP_IF_NOT_GREATER] = &&target_OP_JUMP_IF_NOT_GREATER,
    [OP_JUMP_IF_NOT_EQUAL] = &&target_OP_JUMP_IF_NOT_EQUAL,
    [OP_JUMP_IF_TRUE_OR_POP] = &&target_OP_JUMP_IF_TRUE_OR_POP,
    [OP_JUMP_IF_FALSE_OR_POP] = &&target_OP_JUMP_IF_FALSE_OR_POP,
    [OP_LOOP] = &&target_OP_LOOP,
    [OP_CALL] = &&target_OP_CALL,
    [OP_GET_INDEX] = &&target_OP_GET_INDEX,
    [OP_SET_INDEX] = &&target_OP_SET_INDEX,
    [OP_NEW_LIST] = &&target_OP_NEW_LIST,
    [OP_LIST_LITERAL_APPEND] = &&target_OP_LIST_LITERAL_APPEND,
    [OP_NEW_HASHMAP] = &&target_OP_NEW_HASHMAP,
    [OP_HASHMAP_LITERAL_INSERT] = &&target_OP_HASHMAP_LITERAL_INSERT,
    [OP_CLOSURE] = &&target_OP_CLOSURE,
    [OP_CLOSURE_LONG] = &&target_OP_CLOSURE_LONG,
    [OP_CLOSE_UPVALUE] = &&target_OP_CLOSE_UPVALUE,
    [OP_RETURN] = &&target_OP_RETURN,
    [OP_CLASS] = &&target_OP_CLASS,
    [OP_CLASS_LONG] = &&target_OP_CLASS_LONG,
    [OP_INHERIT] = &&target_OP_INHERIT,
    [OP_METHOD] = &&target_OP_METHOD,
    [OP_METHOD_LONG] = &&target_OP_METHOD_LONG,
    [OP_IMPORT] = &&target_OP_IMPORT,
    [OP_IMPORT_LONG] = &&target_OP_IMPORT_LONG,
    [OP_EXPORT] = &&target_OP_EXPORT,
    [OP_EXPORT_LONG] = &&target_OP_EXPORT_LONG,
    [OP_SET_LOCAL_POP] = &&target_OP_SET_LOCAL_POP,
    [OP_SET_LOCAL_POP_0] = &&target_OP_SET_LOCAL_POP_0,
    [OP_SET_LOCAL_POP_1] = &&target_OP_SET_LOCAL_POP_1,
    [OP_SET_LOCAL_POP_2] = &&target_OP_SET_LOCAL_POP_2,
    [OP_SET_LOCAL_POP_3] = &&target_OP_SET_LOCAL_POP_3,
    [OP_SET_GLOBAL_POP] = &&target_OP_SET_GLOBAL_POP,
    [OP_SET_UPVALUE_POP] = &&target_OP_SET_UPVALUE_POP,
    [OP_SET_INDEX_POP] = &&target_OP_SET_INDEX_POP,
  };

  uint8_t instruction;
  DISPATCH();
#else
  for (;;) {
#ifdef DEBUG_TRACE_EXECUTION
    printf("        ");
    for (Value *slot = vm.stack; slot < stackTop; slot++) {
      printf("[ ");
      printValue(*slot);
      printf(" ]");
    }
    printf("\n");
    disassembleInstruction(&frame->closure->function->chunk, (int)(ip - frame->closure->function->chunk.code));
#endif
    uint8_t instruction = READ_BYTE();
    RECORD_OPCODE(instruction);
    switch (instruction) {
#endif
    TARGET(OP_CONSTANT) {
      Value constant = READ_CONSTANT();
      PUSH(constant);
      DISPATCH();
    }
    TARGET(OP_CONSTANT_LONG) {
      Value constant = READ_CONSTANT_LONG();
      PUSH(constant);
      DISPATCH();
    }
    TARGET(OP_NIL)
      PUSH(NIL_VAL);
      DISPATCH();
    TARGET(OP_TRUE)
      PUSH(BOOL_VAL(true));
      DISPATCH();
    TARGET(OP_FALSE)
      PUSH(BOOL_VAL(false));
      DISPATCH();
    TARGET(OP_INT_0)
      PUSH(NUMBER_VAL(0.0));
      DISPATCH();
    TARGET(OP_INT_1)
      PUSH(NUMBER_VAL(1.0));
      DISPATCH();
    TARGET(OP_INT_2)
      PUSH(NUMBER_VAL(2.0));
      DISPATCH();
    TARGET(OP_POP)
      DROP();
      DISPATCH();
    TARGET(OP_GET_LOCAL) {
      uint8_t slot = READ_BYTE();
      PUSH(slots[slot]);
      DISPATCH();
    }
    TARGET(OP_GET_LOCAL_0)
      PUSH(slots[0]);
      DISPATCH();
    TARGET(OP_GET_LOCAL_1)
      PUSH(slots[1]);
      DISPATCH();
    TARGET(OP_GET_LOCAL_2)
      PUSH(slots[2]);
      DISPATCH();
    TARGET(OP_GET_LOCAL_3)
      PUSH(slots[3]);
      DISPATCH();
    TARGET(OP_SET_LOCAL) {
      uint8_t slot = READ_BYTE();
      slots[slot] = PEEK(0);
      DISPATCH();
    }
    TARGET(OP_SET_LOCAL_0)
      slots[0] = PEEK(0);
      DISPATCH();
    TARGET(OP_SET_LOCAL_1)
      slots[1] = PEEK(0);
      DISPATCH();
    TARGET(OP_SET_LOCAL_2)
      slots[2] = PEEK(0);
      DISPATCH();
    TARGET(OP_SET_LOCAL_3)
      slots[3] = PEEK(0);
      DISPATCH();
    TARGET(OP_SET_LOCAL_POP) {
      uint8_t slot = READ_BYTE();
      slots[slot] = POP();
      DISPATCH();
    }
    TARGET(OP_SET_LOCAL_POP_0)
      slots[0] = POP();
      DISPATCH();
    TARGET(OP_SET_LOCAL_POP_1)
      slots[1] = POP();
      DISPATCH();
    TARGET(OP_SET_LOCAL_POP_2)
      slots[2] = POP();
      DISPATCH();
    TARGET(OP_SET_LOCAL_POP_3)
      slots[3] = POP();
      DISPATCH();
    TARGET(OP_GET_UPVALUE) {
      uint8_t slot = READ_BYTE();
      PUSH(*frame->closure->upvalues[slot]->location);
      DISPATCH();
    }
    TARGET(OP_SET_UPVALUE) {
      uint8_t slot = READ_BYTE();
      *frame->closure->upvalues[slot]->location = PEEK(0);
      DISPATCH();
    }
    TARGET(OP_SET_UPVALUE_POP) {
      uint8_t slot = READ_BYTE();
      *frame->closure->upvalues[slot]->location = POP();
      DISPATCH();
    }
    TARGET(OP_GET_GLOBAL) {
      uint8_t slot = READ_BYTE();
      GlobalCache *cache = &frame->closure->function->chunk.globalCache[slot];
      Table *globals = globalsForFrame(frame);
      if (cache->version == globals->version && cache->valuePtr != NULL) {
        PUSH(*cache->valuePtr);
        DISPATCH();
      }
      ObjString *name = AS_STRING(frame->closure->function->chunk.constants.values[slot]);
      Entry *entry = tableFindEntry(globals, name);
      if (entry == NULL) {
        STORE_FRAME();
        runtimeError("Undefined variable '%s'.", name->chars);
        return INTERPRET_RUNTIME_ERROR;
      }
      cache->valuePtr = &entry->value;
      cache->version = globals->version;
      PUSH(entry->value);
      DISPATCH();
    }
    TARGET(OP_GET_GLOBAL_LONG) {
      uint16_t slot = READ_SHORT();
      GlobalCache *cache = &frame->closure->function->chunk.globalCache[slot];
      Table *globals = globalsForFrame(frame);
      if (cache->version == globals->version && cache->valuePtr != NULL) {
        PUSH(*cache->valuePtr);
        DISPATCH();
      }
      ObjString *name = AS_STRING(frame->closure->function->chunk.constants.values[slot]);
      Entry *entry = tableFindEntry(globals, name);
      if (entry == NULL) {
        STORE_FRAME();
        runtimeError("Undefined variable '%s'.", name->chars);
        return INTERPRET_RUNTIME_ERROR;
      }
      cache->valuePtr = &entry->value;
      cache->version = globals->version;
      PUSH(entry->value);
      DISPATCH();
    }
    TARGET(OP_DEFINE_GLOBAL)
    TARGET(OP_DEFINE_GLOBAL_LONG) {
      ObjString *name = instruction == OP_DEFINE_GLOBAL ? READ_STRING() : READ_STRING_LONG();
      tableSet(globalsForFrame(frame), name, PEEK(0));
      DROP();
      DISPATCH();
    }
    TARGET(OP_SET_GLOBAL)
    TARGET(OP_SET_GLOBAL_LONG) {
      ObjString *name = instruction == OP_SET_GLOBAL ? READ_STRING() : READ_STRING_LONG();
      Table *globals = globalsForFrame(frame);
      if (tableSet(globals, name, PEEK(0))) {
        tableDelete(globals, name);
        STORE_FRAME();
        runtimeError("Undefined variable '%s'.", name->chars);
        return INTERPRET_RUNTIME_ERROR;
      }
      ObjModule *module = frame->closure->module;
      Value previousExport;
      if (module != NULL && tableGet(&module->exports, name, &previousExport))
        tableSet(&module->exports, name, PEEK(0));
      DISPATCH();
    }
    TARGET(OP_SET_GLOBAL_POP) {
      ObjString *name = READ_STRING();
      Table *globals = globalsForFrame(frame);
      if (tableSet(globals, name, PEEK(0))) {
        tableDelete(globals, name);
        STORE_FRAME();
        runtimeError("Undefined variable '%s'.", name->chars);
        return INTERPRET_RUNTIME_ERROR;
      }
      ObjModule *module = frame->closure->module;
      Value previousExport;
      if (module != NULL && tableGet(&module->exports, name, &previousExport))
        tableSet(&module->exports, name, PEEK(0));
      DROP();
      DISPATCH();
    }
    TARGET(OP_GET_PROPERTY)
    TARGET(OP_GET_PROPERTY_LONG) {
      ObjString *name = instruction == OP_GET_PROPERTY ? READ_STRING() : READ_STRING_LONG();

      if (IS_MODULE(PEEK(0))) {
        ObjModule *module = AS_MODULE(PEEK(0));
        Value exported;
        if (!tableGet(&module->exports, name, &exported)) {
          STORE_FRAME();
          runtimeError("Module '%s' does not export '%s'.", module->name->chars, name->chars);
          return INTERPRET_RUNTIME_ERROR;
        }
        stackTop[-1] = exported;
        DISPATCH();
      }

      if (IS_HASHMAP(PEEK(0))) {
        if (strcmp(name->chars, "length") != 0) {
          STORE_FRAME();
          runtimeError("Maps do not have a property named '%s'.", name->chars);
          return INTERPRET_RUNTIME_ERROR;
        }

        ObjHashmap *map = AS_HASHMAP(POP());
        PUSH(NUMBER_VAL(mapCount(&map->items)));
        DISPATCH();
      }

      if (!IS_INSTANCE(PEEK(0))) {
        STORE_FRAME();
        runtimeError("Only instances have properties.");
        return INTERPRET_RUNTIME_ERROR;
      }

      ObjInstance *instance = AS_INSTANCE(PEEK(0));

      Value value;
      if (tableGet(&instance->fields, name, &value)) {
        stackTop[-1] = value;
        DISPATCH();
      }

      STORE_FRAME();
      if (!bindMethod(instance->klass, name)) {
        return INTERPRET_RUNTIME_ERROR;
      }
      LOAD_FRAME();
      DISPATCH();
    }
    TARGET(OP_SET_PROPERTY)
    TARGET(OP_SET_PROPERTY_LONG) {
      if (IS_MODULE(PEEK(1))) {
        STORE_FRAME();
        runtimeError("Module exports are read-only.");
        return INTERPRET_RUNTIME_ERROR;
      }
      if (!IS_INSTANCE(PEEK(1))) {
        STORE_FRAME();
        runtimeError("Only instances have fields.");
        return INTERPRET_RUNTIME_ERROR;
      }

      ObjInstance *instance = AS_INSTANCE(PEEK(1));
      ObjString *name = instruction == OP_SET_PROPERTY ? READ_STRING() : READ_STRING_LONG();
      tableSet(&instance->fields, name, PEEK(0));
      Value value = POP();
      stackTop[-1] = value;
      DISPATCH();
    }
    TARGET(OP_INVOKE)
    TARGET(OP_INVOKE_LONG) {
      ObjString *method = instruction == OP_INVOKE ? READ_STRING() : READ_STRING_LONG();
      int argCount = READ_BYTE();
      STORE_FRAME();
      if (!invoke(method, argCount)) {
        return INTERPRET_RUNTIME_ERROR;
      }
      LOAD_FRAME();
      DISPATCH();
    }
    TARGET(OP_SUPER_INVOKE)
    TARGET(OP_SUPER_INVOKE_LONG) {
      ObjString *method = instruction == OP_SUPER_INVOKE ? READ_STRING() : READ_STRING_LONG();
      int argCount = READ_BYTE();
      ObjClass *superclass = AS_CLASS(POP());
      STORE_FRAME();
      if (!invokeFromClass(superclass, method, argCount)) {
        return INTERPRET_RUNTIME_ERROR;
      }
      LOAD_FRAME();
      DISPATCH();
    }
    TARGET(OP_GET_SUPER)
    TARGET(OP_GET_SUPER_LONG) {
      ObjString *name = instruction == OP_GET_SUPER ? READ_STRING() : READ_STRING_LONG();
      ObjClass *superclass = AS_CLASS(POP());

      STORE_FRAME();
      if (!bindMethod(superclass, name)) {
        return INTERPRET_RUNTIME_ERROR;
      }
      LOAD_FRAME();
      DISPATCH();
    }
    TARGET(OP_EQUAL) {
      Value b = POP();
      Value a = stackTop[-1];
      bool equal = false;
      if (a.type == b.type) {
        if (a.type == VAL_NUMBER) {
          equal = (a.as.number == b.as.number);
        } else if (a.type == VAL_BOOL) {
          equal = (a.as.boolean == b.as.boolean);
        } else if (a.type == VAL_NIL) {
          equal = true;
        } else if (a.type == VAL_OBJ && a.as.obj == b.as.obj) {
          equal = true;
        } else {
          STORE_FRAME();
          equal = valuesEqual(a, b);
          LOAD_FRAME();
          if (vm.hadRuntimeError) return INTERPRET_RUNTIME_ERROR;
        }
      }
      stackTop[-1] = BOOL_VAL(equal);
      DISPATCH();
    }
    TARGET(OP_GREATER)
      BINARY_OP(BOOL_VAL, >);
      DISPATCH();
    TARGET(OP_LESS)
      BINARY_OP(BOOL_VAL, <);
      DISPATCH();
    TARGET(OP_ADD) {
      if (IS_NUMBER(stackTop[-1]) && IS_NUMBER(stackTop[-2])) {
        double b = AS_NUMBER(stackTop[-1]);
        double a = AS_NUMBER(stackTop[-2]);
        stackTop[-2] = NUMBER_VAL(a + b);
        stackTop--;
      } else if (IS_STRING(stackTop[-1]) && IS_STRING(stackTop[-2])) {
        STORE_FRAME();
        concatenate();
        LOAD_FRAME();
      } else {
        STORE_FRAME();
        runtimeError("Operands must be two numbers or two strings.");
        return INTERPRET_RUNTIME_ERROR;
      }
      DISPATCH();
    }
    TARGET(OP_SUBTRACT)
      BINARY_OP(NUMBER_VAL, -);
      DISPATCH();
    TARGET(OP_MULTIPLY)
      BINARY_OP(NUMBER_VAL, *);
      DISPATCH();
    TARGET(OP_DIVIDE) {
      if (!IS_NUMBER(stackTop[-1]) || !IS_NUMBER(stackTop[-2])) {
        STORE_FRAME();
        runtimeError("Operands must be numbers.");
        return INTERPRET_RUNTIME_ERROR;
      }

      double divisor = AS_NUMBER(stackTop[-1]);
      double dividend = AS_NUMBER(stackTop[-2]);
      if (divisor == 0) {
        STORE_FRAME();
        runtimeError("Division by zero.");
        return INTERPRET_RUNTIME_ERROR;
      }

      stackTop[-2] = NUMBER_VAL(dividend / divisor);
      stackTop--;
      DISPATCH();
    }
    TARGET(OP_MODULO)
      if (!IS_NUMBER(stackTop[-1]) || !IS_NUMBER(stackTop[-2])) {
        STORE_FRAME();
        runtimeError("Operands must be numbers.");
        return INTERPRET_RUNTIME_ERROR;
      }

      double b = AS_NUMBER(stackTop[-1]);
      double a = AS_NUMBER(stackTop[-2]);

      if (b == 0) {
        STORE_FRAME();
        runtimeError("Modulo by zero.");
        return INTERPRET_RUNTIME_ERROR;
      }

      if (!isfinite(a) || !isfinite(b) || floor(b) != b || floor(a) != a) {
        STORE_FRAME();
        runtimeError("Modulo only accepts finite integer operands.");
        return INTERPRET_RUNTIME_ERROR;
      }

      stackTop[-2] = NUMBER_VAL(fmod(a, b));
      stackTop--;
      DISPATCH();
    TARGET(OP_NOT)
      stackTop[-1] = BOOL_VAL(isFalsey(stackTop[-1]));
      DISPATCH();
    TARGET(OP_NEGATE)
      if (!IS_NUMBER(PEEK(0))) {
        STORE_FRAME();
        runtimeError("Operand must be a number.");
        return INTERPRET_RUNTIME_ERROR;
      }
      stackTop[-1] = NUMBER_VAL(-AS_NUMBER(stackTop[-1]));
      DISPATCH();
    TARGET(OP_PRINT) {
      STORE_FRAME();
      ObjString *rendered = valueToString(POP());
      writeVMOutput(rendered->chars, (size_t)rendered->length);
      writeVMOutput("\n", 1);
      DISPATCH();
    }
    TARGET(OP_PRINT_NO_NEWLINE) {
      STORE_FRAME();
      ObjString *rendered = valueToString(POP());
      writeVMOutput(rendered->chars, (size_t)rendered->length);
      DISPATCH();
    }
    TARGET(OP_JUMP) {
      uint16_t offset = READ_SHORT();
      ip += offset;
      DISPATCH();
    }
    TARGET(OP_JUMP_IF_FALSE) {
      uint16_t offset = READ_SHORT();
      if (isFalsey(PEEK(0))) ip += offset;
      DISPATCH();
    }
    TARGET(OP_POP_JUMP_IF_FALSE) {
      uint16_t offset = READ_SHORT();
      Value val = POP();
      if (isFalsey(val)) ip += offset;
      DISPATCH();
    }
    TARGET(OP_JUMP_IF_NOT_LESS) {
      uint16_t offset = READ_SHORT();
      if (!IS_NUMBER(stackTop[-1]) || !IS_NUMBER(stackTop[-2])) {
        STORE_FRAME();
        runtimeError("Operands must be numbers.");
        return INTERPRET_RUNTIME_ERROR;
      }
      double b = AS_NUMBER(stackTop[-1]);
      double a = AS_NUMBER(stackTop[-2]);
      stackTop -= 2;
      if (!(a < b)) {
        ip += offset;
      }
      DISPATCH();
    }
    TARGET(OP_JUMP_IF_NOT_GREATER) {
      uint16_t offset = READ_SHORT();
      if (!IS_NUMBER(stackTop[-1]) || !IS_NUMBER(stackTop[-2])) {
        STORE_FRAME();
        runtimeError("Operands must be numbers.");
        return INTERPRET_RUNTIME_ERROR;
      }
      double b = AS_NUMBER(stackTop[-1]);
      double a = AS_NUMBER(stackTop[-2]);
      stackTop -= 2;
      if (!(a > b)) {
        ip += offset;
      }
      DISPATCH();
    }
    TARGET(OP_JUMP_IF_NOT_EQUAL) {
      uint16_t offset = READ_SHORT();
      Value b = stackTop[-1];
      Value a = stackTop[-2];
      stackTop -= 2;
      bool equal = false;
      if (a.type == b.type) {
        if (a.type == VAL_NUMBER) {
          equal = (a.as.number == b.as.number);
        } else if (a.type == VAL_BOOL) {
          equal = (a.as.boolean == b.as.boolean);
        } else if (a.type == VAL_NIL) {
          equal = true;
        } else if (a.type == VAL_OBJ && a.as.obj == b.as.obj) {
          equal = true;
        } else {
          STORE_FRAME();
          equal = valuesEqual(a, b);
          LOAD_FRAME();
          if (vm.hadRuntimeError) return INTERPRET_RUNTIME_ERROR;
        }
      }
      if (!equal) {
        ip += offset;
      }
      DISPATCH();
    }
    TARGET(OP_JUMP_IF_TRUE_OR_POP) {
      uint16_t offset = READ_SHORT();
      if (!isFalsey(PEEK(0))) {
        ip += offset;
      } else {
        DROP();
      }
      DISPATCH();
    }
    TARGET(OP_JUMP_IF_FALSE_OR_POP) {
      uint16_t offset = READ_SHORT();
      if (isFalsey(PEEK(0))) {
        ip += offset;
      } else {
        DROP();
      }
      DISPATCH();
    }
    TARGET(OP_LOOP) {
      uint16_t offset = READ_SHORT();
      ip -= offset;
      DISPATCH();
    }
    TARGET(OP_CALL) {
      int argCount = READ_BYTE();
      Value callee = PEEK(argCount);
      if (IS_OBJ(callee) && OBJ_TYPE(callee) == OBJ_CLOSURE) {
        ObjClosure *closure = AS_CLOSURE(callee);
        ObjFunction *function = closure->function;
        if (argCount != function->arity) {
          STORE_FRAME();
          runtimeError("Expected %d arguments but got %d.", function->arity, argCount);
          return INTERPRET_RUNTIME_ERROR;
        }
        if (vm.frameCount == FRAMES_MAX) {
          STORE_FRAME();
          runtimeError("Stack overflow.");
          return INTERPRET_RUNTIME_ERROR;
        }
        frame->ip = ip;
        frame = &vm.frames[vm.frameCount++];
        frame->closure = closure;
        frame->ip = function->chunk.code;
        frame->slots = stackTop - argCount - 1;
        ip = frame->ip;
        slots = frame->slots;
        DISPATCH();
      }
      STORE_FRAME();
      if (!callValue(callee, argCount)) {
        return INTERPRET_RUNTIME_ERROR;
      }
      LOAD_FRAME();
      DISPATCH();
    }
    TARGET(OP_GET_INDEX) {
      Value index = PEEK(0);
      Value container = PEEK(1);

      if (IS_LIST(container)) {
        ObjList *list = AS_LIST(container);
        int listIndex;

        STORE_FRAME();
        if (!normalizeListIndex(index, list->items.count, &listIndex)) {
          return INTERPRET_RUNTIME_ERROR;
        }

        Value result = list->items.values[listIndex];
        stackTop[-2] = result;
        stackTop--;
      } else if (IS_STRING(container)) {
        if (!IS_NUMBER(index)) {
          STORE_FRAME();
          runtimeError("String index must be a number.");
          return INTERPRET_RUNTIME_ERROR;
        }

        double stringIndex = AS_NUMBER(index);
        if (!isfinite(stringIndex) || floor(stringIndex) != stringIndex) {
          STORE_FRAME();
          runtimeError("String index must be a finite integer.");
          return INTERPRET_RUNTIME_ERROR;
        }

        ObjString *string = AS_STRING(container);
        if (stringIndex < 0 || stringIndex >= string->length) {
          STORE_FRAME();
          runtimeError("String index out of bounds.");
          return INTERPRET_RUNTIME_ERROR;
        }

        unsigned char ch = (unsigned char)string->chars[(int)stringIndex];
        ObjString *result = vm.charStrings[ch];

        stackTop[-2] = OBJ_VAL(result);
        stackTop--;
      } else if (IS_HASHMAP(container)) {
        if (!mapKeyIsValid(index)) {
          STORE_FRAME();
          runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
          return INTERPRET_RUNTIME_ERROR;
        }

        Value result = NIL_VAL;
        mapGet(&AS_HASHMAP(container)->items, index, &result);

        stackTop[-2] = result;
        stackTop--;
      } else {
        STORE_FRAME();
        runtimeError("Can only index into lists, strings, and hashmaps.");
        return INTERPRET_RUNTIME_ERROR;
      }

      DISPATCH();
    }

    TARGET(OP_SET_INDEX) {
      Value value = PEEK(0);
      Value key = PEEK(1);
      Value container = PEEK(2);

      if (IS_LIST(container)) {
        ObjList *list = AS_LIST(container);
        int index;

        STORE_FRAME();
        if (!normalizeListIndex(key, list->items.count, &index)) {
          return INTERPRET_RUNTIME_ERROR;
        }

        list->items.values[index] = value;

        stackTop -= 2;
        stackTop[-1] = value;
      } else if (IS_HASHMAP(container)) {
        if (!mapKeyIsValid(key)) {
          STORE_FRAME();
          runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
          return INTERPRET_RUNTIME_ERROR;
        }

        STORE_FRAME();
        if (!mapSet(&AS_HASHMAP(container)->items, key, value, NULL)) {
          runtimeError("Map key is invalid.");
          return INTERPRET_RUNTIME_ERROR;
        }

        stackTop -= 2;
        stackTop[-1] = value;
      } else {
        STORE_FRAME();
        runtimeError("Can only assign through a list or hashmap index.");
        return INTERPRET_RUNTIME_ERROR;
      }

      DISPATCH();
    }

    TARGET(OP_SET_INDEX_POP) {
      Value value = PEEK(0);
      Value key = PEEK(1);
      Value container = PEEK(2);

      if (IS_LIST(container)) {
        ObjList *list = AS_LIST(container);
        int index;

        STORE_FRAME();
        if (!normalizeListIndex(key, list->items.count, &index)) {
          return INTERPRET_RUNTIME_ERROR;
        }

        list->items.values[index] = value;
        stackTop -= 3;
      } else if (IS_HASHMAP(container)) {
        if (!mapKeyIsValid(key)) {
          STORE_FRAME();
          runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
          return INTERPRET_RUNTIME_ERROR;
        }

        STORE_FRAME();
        if (!mapSet(&AS_HASHMAP(container)->items, key, value, NULL)) {
          runtimeError("Map key is invalid.");
          return INTERPRET_RUNTIME_ERROR;
        }

        stackTop -= 3;
      } else {
        STORE_FRAME();
        runtimeError("Can only assign through a list or hashmap index.");
        return INTERPRET_RUNTIME_ERROR;
      }

      DISPATCH();
    }

    TARGET(OP_NEW_LIST) {
      STORE_FRAME();
      PUSH(OBJ_VAL(newList()));
      DISPATCH();
    }
    TARGET(OP_LIST_LITERAL_APPEND) {
      Value item = POP();
      Value listVal = PEEK(0);

      if (!IS_LIST(listVal)) {
        STORE_FRAME();
        runtimeError("Can only append to a list.");
        return INTERPRET_RUNTIME_ERROR;
      }

      ObjList *list = AS_LIST(listVal);
      PUSH(item);
      STORE_FRAME();
      writeValueArray(&list->items, item);
      DROP();
      DISPATCH();
    }
    TARGET(OP_NEW_HASHMAP) {
      STORE_FRAME();
      PUSH(OBJ_VAL(newHashmap()));
      DISPATCH();
    }
    TARGET(OP_HASHMAP_LITERAL_INSERT) {
      Value value = PEEK(0);
      Value keyVal = PEEK(1);
      Value hashmapVal = PEEK(2);

      if (!IS_HASHMAP(hashmapVal)) {
        STORE_FRAME();
        runtimeError("Expect a hashmap.");
        return INTERPRET_RUNTIME_ERROR;
      }

      ObjHashmap *hashmap = AS_HASHMAP(hashmapVal);

      if (!mapKeyIsValid(keyVal)) {
        STORE_FRAME();
        runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
        return INTERPRET_RUNTIME_ERROR;
      }

      STORE_FRAME();
      if (!mapSet(&hashmap->items, keyVal, value, NULL)) {
        runtimeError("Map key is invalid.");
        return INTERPRET_RUNTIME_ERROR;
      }

      stackTop -= 2;
      DISPATCH();
    }
    TARGET(OP_CLOSURE)
    TARGET(OP_CLOSURE_LONG) {
      ObjFunction *function = AS_FUNCTION(instruction == OP_CLOSURE ? READ_CONSTANT() : READ_CONSTANT_LONG());
      STORE_FRAME();
      ObjClosure *closure = newClosure(function);
      closure->module = frame->closure->module;
      PUSH(OBJ_VAL(closure));
      for (int i = 0; i < closure->upvalueCount; i++) {
        uint8_t isLocal = READ_BYTE();
        uint8_t index = READ_BYTE();
        STORE_FRAME();
        closure->upvalues[i] = isLocal ? captureUpvalue(slots + index) : frame->closure->upvalues[index];
      }
      DISPATCH();
    }
    TARGET(OP_CLOSE_UPVALUE)
      STORE_FRAME();
      closeUpvalues(stackTop - 1);
      DROP();
      DISPATCH();
    TARGET(OP_RETURN) {
      Value result = POP();
      if (vm.openUpvalues != NULL) {
        closeUpvalues(frame->slots);
      }
      Value *calleeSlots = frame->slots;
      vm.frameCount--;
      if (vm.frameCount == 0) {
        vm.lastReturnValue = result;
        vm.hasLastReturnValue = true;
        vm.stackTop = calleeSlots;
        return INTERPRET_OK;
      }

      stackTop = calleeSlots;
      *stackTop++ = result;
      frame = &vm.frames[vm.frameCount - 1];
      ip = frame->ip;
      slots = frame->slots;
      if (vm.frameCount == stopFrameCount) {
        STORE_FRAME();
        return INTERPRET_OK;
      }
      DISPATCH();
    }
    TARGET(OP_CLASS)
    TARGET(OP_CLASS_LONG) {
      ObjString *name = instruction == OP_CLASS ? READ_STRING() : READ_STRING_LONG();
      STORE_FRAME();
      PUSH(OBJ_VAL(newClass(name)));
      DISPATCH();
    }
    TARGET(OP_INHERIT) {
      Value superclass = PEEK(1);
      if (!IS_CLASS(superclass)) {
        STORE_FRAME();
        runtimeError("Superclass must be a class.");
        return INTERPRET_RUNTIME_ERROR;
      }
      ObjClass *subclass = AS_CLASS(PEEK(0));
      tableAddAll(&AS_CLASS(superclass)->methods, &subclass->methods);
      DROP();
      DISPATCH();
    }
    TARGET(OP_METHOD)
    TARGET(OP_METHOD_LONG) {
      ObjString *name = instruction == OP_METHOD ? READ_STRING() : READ_STRING_LONG();
      STORE_FRAME();
      defineMethod(name);
      LOAD_FRAME();
      DISPATCH();
    }
    TARGET(OP_IMPORT)
    TARGET(OP_IMPORT_LONG) {
      ObjString *moduleName = instruction == OP_IMPORT ? READ_STRING() : READ_STRING_LONG();
      ObjString *alias = instruction == OP_IMPORT ? READ_STRING() : READ_STRING_LONG();
      Table *globals = globalsForFrame(frame);
      Value existing;
      if (tableGet(globals, alias, &existing)) {
        STORE_FRAME();
        runtimeError("Import alias '%s' is already defined.", alias->chars);
        return INTERPRET_RUNTIME_ERROR;
      }

      Value module;
      STORE_FRAME();
      InterpretResult importResult = resolveModule(moduleName->chars, &module);
      if (importResult != INTERPRET_OK) return importResult;
      LOAD_FRAME();
      tableSet(globalsForFrame(frame), alias, module);
      DISPATCH();
    }
    TARGET(OP_EXPORT)
    TARGET(OP_EXPORT_LONG) {
      ObjString *name = instruction == OP_EXPORT ? READ_STRING() : READ_STRING_LONG();
      ObjModule *module = frame->closure->module;
      Value exported;
      if (module == NULL || !tableGet(&module->globals, name, &exported)) {
        STORE_FRAME();
        runtimeError("Could not export '%s'.", name->chars);
        return INTERPRET_RUNTIME_ERROR;
      }
      tableSet(&module->exports, name, exported);
      DISPATCH();
    }
#if USE_COMPUTED_GOTO
    TARGET(OP_UNKNOWN)
#else
    default:
#endif
      STORE_FRAME();
      runtimeError("Unknown opcode %d.", instruction);
      return INTERPRET_RUNTIME_ERROR;
#if !USE_COMPUTED_GOTO
    }
    if (vm.hadRuntimeError) return INTERPRET_RUNTIME_ERROR;
  }
#endif
#undef PUSH
#undef POP
#undef DROP
#undef PEEK
#undef STORE_FRAME
#undef LOAD_FRAME
#undef BINARY_OP
#undef READ_STRING_LONG
#undef READ_CONSTANT
#undef READ_CONSTANT_LONG
#undef READ_STRING
#undef READ_SHORT
#undef READ_BYTE
#undef TARGET
#undef DISPATCH
#undef RECORD_OPCODE
#if USE_COMPUTED_GOTO
#if defined(__clang__)
#pragma clang diagnostic pop
#elif defined(__GNUC__)
#pragma GCC diagnostic pop
#endif
#endif
#undef USE_COMPUTED_GOTO
}

static InterpretResult interpretActive(const char *source) {
  vm.hadRuntimeError = false;
  vm.hasLastReturnValue = false;

  ObjFunction *function = compile(source);
  if (function == NULL) return INTERPRET_COMPILE_ERROR;

  if (!push(OBJ_VAL(function))) return INTERPRET_RUNTIME_ERROR;
  ObjClosure *closure = newClosure(function);
  pop();
  if (!push(OBJ_VAL(closure))) return INTERPRET_RUNTIME_ERROR;
  if (!call(closure, 0)) {
    return INTERPRET_RUNTIME_ERROR;
  }

  return run(0);
}

InterpretResult interpret(const char *source) {
  if (!defaultVMInitialised) initVM();
  activeVM = &defaultVM;
  return interpretActive(source);
}

static VM *activateVM(PbVM *instance) {
  VM *previous = activeVM;
  activeVM = (VM *)instance;
  return previous;
}

static char *copyHostString(const char *source) {
  size_t length = strlen(source);
  char *copy = (char *)malloc(length + 1);
  if (copy != NULL) memcpy(copy, source, length + 1);
  return copy;
}

static bool validNativeName(const char *name) { return name != NULL && name[0] != '\0' && strlen(name) <= INT_MAX; }

static HostCapability *findCapability(const char *name) {
  for (size_t i = 0; i < vm.capabilityCount; i++) {
    if (strcmp(vm.capabilities[i].name, name) == 0) return &vm.capabilities[i];
  }
  return NULL;
}

static InterpretResult circularImportError(const char *name) {
  char diagnostic[512];
  if (vm.frameCount > 0) {
    CallFrame *frame = &vm.frames[vm.frameCount - 1];
    ObjFunction *function = frame->closure->function;
    size_t instruction = frame->ip - function->chunk.code - 1;
    if (function->sourceName != NULL) {
      snprintf(diagnostic, sizeof(diagnostic), "[%s line %d] Load error: Circular import of module '%s'.",
               function->sourceName->chars, function->chunk.lines[instruction], name);
    } else {
      snprintf(diagnostic, sizeof(diagnostic), "[line %d] Load error: Circular import of module '%s'.",
               function->chunk.lines[instruction], name);
    }
  } else {
    snprintf(diagnostic, sizeof(diagnostic), "Load error: Circular import of module '%s'.", name);
  }

  reportDiagnostic(PB_DIAGNOSTIC_COMPILE, diagnostic);
  closeUpvalues(vm.stack);
  resetStack();
  return INTERPRET_COMPILE_ERROR;
}

InterpretResult resolveModule(const char *name, Value *result) {
  ObjString *moduleName = copyString(name, (int)strlen(name));
  if (!push(OBJ_VAL(moduleName))) return INTERPRET_RUNTIME_ERROR;

  if (tableGet(&vm.modules, moduleName, result)) {
    if (AS_MODULE(*result)->isLoading) return circularImportError(name);
    pop();
    return INTERPRET_OK;
  }

  HostCapability *capability = findCapability(name);
  if (capability == NULL && vm.config.resolveCapability != NULL) {
    vm.config.resolveCapability(activeVM, name, vm.config.userData);
    if (vm.hadRuntimeError) return INTERPRET_RUNTIME_ERROR;
    capability = findCapability(name);
  }

  if (capability == NULL) {
    runtimeError("Host does not provide module '%s'.", name);
    return INTERPRET_RUNTIME_ERROR;
  }

  ObjModule *module = newModule(moduleName);
  if (!push(OBJ_VAL(module))) return INTERPRET_RUNTIME_ERROR;
  tableAddAll(&vm.prelude, &module->globals);

  if (capability->source != NULL) {
    module->isLoading = true;
    tableSet(&vm.modules, moduleName, OBJ_VAL(module));

    ObjFunction *function = compileModule(capability->source, name);
    if (function == NULL) {
      tableDelete(&vm.modules, moduleName);
      resetStack();
      return INTERPRET_COMPILE_ERROR;
    }

    if (!push(OBJ_VAL(function))) return INTERPRET_RUNTIME_ERROR;
    ObjClosure *closure = newClosure(function);
    closure->module = module;
    pop();
    if (!push(OBJ_VAL(closure)) || !call(closure, 0)) return INTERPRET_RUNTIME_ERROR;

    int enclosingFrameCount = vm.frameCount - 1;
    InterpretResult moduleResult = run(enclosingFrameCount);
    if (moduleResult != INTERPRET_OK) {
      tableDelete(&vm.modules, moduleName);
      return moduleResult;
    }
    pop();
    module->isLoading = false;
  } else {
    for (size_t i = 0; i < capability->definitionCount; i++) {
      PbNativeDefinition *definition = &capability->definitions[i];
      ObjString *exportName = copyString(definition->name, (int)strlen(definition->name));
      if (!push(OBJ_VAL(exportName))) return INTERPRET_RUNTIME_ERROR;
      ObjNative *native = newHostNative(definition->function, definition->userData);
      if (!push(OBJ_VAL(native))) return INTERPRET_RUNTIME_ERROR;
      tableSet(&module->exports, exportName, OBJ_VAL(native));
      pop();
      pop();
    }
  }

  tableSet(&vm.modules, moduleName, OBJ_VAL(module));
  *result = OBJ_VAL(module);
  pop();
  pop();
  return INTERPRET_OK;
}

PB_API PbVM *pbCreateVM(const PbConfig *config) {
  VM *instance = (VM *)malloc(sizeof(VM));
  if (instance == NULL) return NULL;
  VM *previous = activateVM(instance);
  initialiseActiveVM(config);
  activeVM = previous;
  return instance;
}

PB_API void pbDestroyVM(PbVM *instance) {
  if (instance == NULL) return;
  VM *previous = activateVM(instance);
  if (vm.frameCount != 0) {
    reportDiagnostic(PB_DIAGNOSTIC_HOST, "Cannot destroy a VM while it is running.");
    activeVM = previous;
    return;
  }
  freeActiveVM();
  memset(instance, 0, sizeof(VM));
  free(instance);
  activeVM = previous == (VM *)instance ? NULL : previous;
}

PB_API PbResult pbInterpret(PbVM *instance, const char *source) {
  if (instance == NULL || source == NULL) return INTERPRET_RUNTIME_ERROR;
  VM *previous = activateVM(instance);
  if (vm.frameCount != 0 || vm.stackTop != vm.stack) {
    reportDiagnostic(PB_DIAGNOSTIC_HOST, "Cannot interpret source while the VM is running.");
    activeVM = previous;
    return INTERPRET_RUNTIME_ERROR;
  }
  PbResult result = interpretActive(source);
  activeVM = previous;
  return result;
}

PB_API bool pbDefineNative(PbVM *instance, const char *name, PbNativeFn function, void *userData) {
  if (instance == NULL || !validNativeName(name) || function == NULL) return false;
  VM *previous = activateVM(instance);
  defineHostNative(name, function, userData);
  activeVM = previous;
  return true;
}

PB_API bool pbRegisterCapability(PbVM *instance, const char *name, const PbNativeDefinition *definitions,
                                 size_t definitionCount) {
  if (instance == NULL || name == NULL || name[0] == '\0' || (definitionCount > 0 && definitions == NULL)) return false;

  VM *previous = activateVM(instance);
  if (findCapability(name) != NULL) {
    reportDiagnostic(PB_DIAGNOSTIC_HOST, "Capability is already registered in this VM.");
    activeVM = previous;
    return false;
  }

  for (size_t i = 0; i < definitionCount; i++) {
    if (!validNativeName(definitions[i].name) || definitions[i].function == NULL) {
      reportDiagnostic(PB_DIAGNOSTIC_HOST, "Capability contains an invalid native definition.");
      activeVM = previous;
      return false;
    }
  }

  if (vm.capabilityCount == vm.capabilityCapacity) {
    size_t capacity = vm.capabilityCapacity < 4 ? 4 : vm.capabilityCapacity * 2;
    HostCapability *capabilities = (HostCapability *)realloc(vm.capabilities, sizeof(HostCapability) * capacity);
    if (capabilities == NULL) {
      reportDiagnostic(PB_DIAGNOSTIC_HOST, "Could not allocate capability registry.");
      activeVM = previous;
      return false;
    }
    vm.capabilities = capabilities;
    vm.capabilityCapacity = capacity;
  }

  HostCapability capability = {0};
  capability.name = copyHostString(name);
  if (capability.name == NULL) {
    activeVM = previous;
    return false;
  }

  if (definitionCount > 0) {
    capability.definitions = (PbNativeDefinition *)calloc(definitionCount, sizeof(PbNativeDefinition));
    if (capability.definitions == NULL) {
      free(capability.name);
      activeVM = previous;
      return false;
    }
  }
  capability.definitionCount = definitionCount;

  for (size_t i = 0; i < definitionCount; i++) {
    capability.definitions[i] = definitions[i];
    capability.definitions[i].name = copyHostString(definitions[i].name);
    if (capability.definitions[i].name == NULL) {
      for (size_t j = 0; j < i; j++) free((char *)capability.definitions[j].name);
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

PB_API bool pbRegisterModuleSource(PbVM *instance, const char *name, const char *source) {
  if (instance == NULL || !validNativeName(name) || source == NULL) return false;

  VM *previous = activateVM(instance);
  if (findCapability(name) != NULL) {
    reportDiagnostic(PB_DIAGNOSTIC_HOST, "Module is already registered in this VM.");
    activeVM = previous;
    return false;
  }

  if (vm.capabilityCount == vm.capabilityCapacity) {
    size_t capacity = vm.capabilityCapacity < 4 ? 4 : vm.capabilityCapacity * 2;
    HostCapability *capabilities = (HostCapability *)realloc(vm.capabilities, sizeof(HostCapability) * capacity);
    if (capabilities == NULL) {
      reportDiagnostic(PB_DIAGNOSTIC_HOST, "Could not allocate module registry.");
      activeVM = previous;
      return false;
    }
    vm.capabilities = capabilities;
    vm.capabilityCapacity = capacity;
  }

  HostCapability capability = {0};
  capability.name = copyHostString(name);
  capability.source = copyHostString(source);
  if (capability.name == NULL || capability.source == NULL) {
    free(capability.name);
    free(capability.source);
    activeVM = previous;
    return false;
  }

  vm.capabilities[vm.capabilityCount++] = capability;
  activeVM = previous;
  return true;
}

PB_API PbResult pbCall(PbVM *instance, const char *name, int argCount, const PbValue *args, PbValue *result) {
  if (instance == NULL || !validNativeName(name) || argCount < 0 || (argCount > 0 && args == NULL))
    return INTERPRET_RUNTIME_ERROR;

  VM *previous = activateVM(instance);
  vm.hadRuntimeError = false;

  if (vm.frameCount != 0 || vm.stackTop != vm.stack) {
    runtimeError("Cannot invoke a script function while the VM is running.");
    activeVM = previous;
    return INTERPRET_RUNTIME_ERROR;
  }

  ObjString *functionName = copyString(name, (int)strlen(name));
  Value callee;
  if (!tableGet(&vm.globals, functionName, &callee) || !IS_CLOSURE(callee)) {
    runtimeError("No script function named '%s' is defined.", name);
    activeVM = previous;
    return INTERPRET_RUNTIME_ERROR;
  }

  push(callee);
  for (int i = 0; i < argCount; i++) {
    Value argument;
    if (!hostToValue(args[i], &argument) || !push(argument)) {
      activeVM = previous;
      return INTERPRET_RUNTIME_ERROR;
    }
  }

  vm.hasLastReturnValue = false;
  if (!callValue(callee, argCount)) {
    activeVM = previous;
    return INTERPRET_RUNTIME_ERROR;
  }

  PbResult callResult = run(0);
  if (callResult == INTERPRET_OK && result != NULL) *result = valueToHost(vm.lastReturnValue);
  activeVM = previous;
  return callResult;
}

PB_API void pbRuntimeError(PbVM *instance, const char *message) {
  if (instance == NULL || message == NULL) return;
  VM *previous = activateVM(instance);
  runtimeError("%s", message);
  activeVM = previous;
}

PB_API PbValue pbNilValue(void) {
  PbValue value = {0};
  value.type = PB_VALUE_NIL;
  return value;
}

PB_API PbValue pbBoolValue(bool boolean) {
  PbValue value = pbNilValue();
  value.type = PB_VALUE_BOOL;
  value.as.boolean = boolean;
  return value;
}

PB_API PbValue pbNumberValue(double number) {
  PbValue value = pbNilValue();
  value.type = PB_VALUE_NUMBER;
  value.as.number = number;
  return value;
}

PB_API PbValue pbStringValueN(const char *string, size_t length) {
  PbValue value = pbNilValue();
  value.type = PB_VALUE_STRING;
  value.as.string.chars = string;
  value.as.string.length = length;
  return value;
}

PB_API PbValue pbStringValue(const char *string) { return pbStringValueN(string, string != NULL ? strlen(string) : 0); }

PB_API void ext_initVM(void) { initVM(); }

PB_API InterpretResult ext_interpret(const char *source) { return interpret(source); }
