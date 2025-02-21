#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>

#include "common.h"
#include "compiler.h"
#include "debug.h"
#include "object.h"
#include "memory.h"
#include "vm.h"

// global declaration of VM so we dont have to pass it around everywhere, theres only going to be one VM so its ok
VM vm;

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

static Value clockNative(int argCount, Value *args)
{
  return NUMBER_VAL((double)clock() / CLOCKS_PER_SEC);
}

static Value randNative(int argCount, Value *args)
{
  if (argCount > 0 && IS_NUMBER(args[0]))
  {
    int max = (int)AS_NUMBER(args[0]);
    return NUMBER_VAL(rand() % max);
  }
  else
  {
    return NUMBER_VAL(rand() / (double)RAND_MAX);
  }
}

static Value strInputNative(int argCount, Value *args)
{
  if (argCount > 0 && IS_STRING(args[0]))
  {
    printf("%s", AS_CSTRING(args[0]));
  }
  else
  {
    printf("Enter input: ");
  }
  char buffer[256];
  if (!fgets(buffer, sizeof(buffer), stdin))
  {
    return NIL_VAL;
  }
  buffer[strcspn(buffer, "\n")] = 0;
  return OBJ_VAL(copyString(buffer, strlen(buffer)));
}

static Value sqrtNative(int argCount, Value* args) {
  if (argCount != 1 || !IS_NUMBER(args[0])) {
    runtimeError("sqrt expects a single number.");
    return NIL_VAL;
  }
  return NUMBER_VAL(sqrt(AS_NUMBER(args[0])));
}

static Value absNative(int argCount, Value* args) {
  if (argCount != 1 || !IS_NUMBER(args[0])) {
    runtimeError("abs expects a single value.");
    return NIL_VAL;
  }
  return NUMBER_VAL(abs(AS_NUMBER(args[0])));
}

static void defineNative(const char *name, NativeFn function)
{
  push(OBJ_VAL(copyString(name, (int)strlen(name))));
  push(OBJ_VAL(newNative(function)));
  tableSet(&vm.globals, AS_STRING(vm.stack[0]), vm.stack[1]);
  pop();
  pop();
}

void initVM()
{
  resetStack();
  vm.objects = NULL;

  initTable(&vm.globals);
  initTable(&vm.strings);

  srand(time(NULL)); // for the native function
  defineNative("clock", clockNative);
  defineNative("rand", randNative);
  defineNative("strInput", strInputNative);
  defineNative("sqrt", sqrtNative);
  defineNative("abs", absNative);
}

void freeVM()
{
  freeTable(&vm.globals);
  freeTable(&vm.strings);
  freeObjects();
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

  printf("CALL: Function '%s' at ip %p with %d arguments\n",
         function->name ? function->name->chars : "<script>", function->chunk.code, argCount);

  printf("Stack before function execution: ");
  for (Value *slot = vm.stack; slot < vm.stackTop; slot++)
  {
    printValue(*slot);
    printf(" | ");
  }
  printf("\n");

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
    default:
      break; // Non-callable object type.
    }
  }
  runtimeError("Can only call functions and classes.");
  return false;
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
  Value b = pop();
  Value a = pop();

  ObjString *strA = IS_STRING(a) ? AS_STRING(a) : copyString(formatNumber(a), strlen(formatNumber(a)));
  ObjString *strB = IS_STRING(b) ? AS_STRING(b) : copyString(formatNumber(b), strlen(formatNumber(b)));

  int length = strA->length + strB->length;
  char *chars = ALLOCATE(char, length + 1);
  memcpy(chars, strA->chars, strA->length);
  memcpy(chars + strA->length, strB->chars, strB->length);
  chars[length] = '\0';

  ObjString *result = takeString(chars, length);
  push(OBJ_VAL(result));
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
    // #ifdef DEBUG_TRACE_EXECUTION
    //     printf("        ");
    //     for (Value *slot = vm.stack; slot < vm.stackTop; slot++)
    //     {
    //       printf("[ ");
    //       printValue(*slot);
    //       printf(" ]");
    //     }
    //     printf("\n");
    //     disassembleInstruction(&frame->function->chunk,
    //                            (int)(frame->ip - frame->function->chunk.code));
    // #endif
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
      printValue(pop());
      printf("\n");
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
        return INTERPRET_RUNTIME_ERROR;
      }
      frame = &vm.frames[vm.frameCount - 1];
      break;
    }
    case OP_GET_INDEX: {
      Value indexVal = pop();
      Value listVal = pop();
  
      if (!IS_LIST(listVal) || !IS_NUMBER(indexVal)) {
          runtimeError("List index must be a number.");
          return INTERPRET_RUNTIME_ERROR;
      }
  
      ObjList* list = AS_LIST(listVal);
      int index = (int)AS_NUMBER(indexVal);
  
      if (index < 0 || index >= list->items.count) {
          runtimeError("List index out of bounds.");
          return INTERPRET_RUNTIME_ERROR;
      }
  
      push(list->items.values[index]);
      break;
    }
    case OP_NEW_LIST: {
      push(OBJ_VAL(newList()));  // Push an empty list onto the stack
      break;
    }
    
    case OP_LIST_APPEND: {
        Value item = pop();  // Get value to append
        Value listVal = pop();
    
        if (!IS_LIST(listVal)) {
            runtimeError("Can only append to a list.");
            return INTERPRET_RUNTIME_ERROR;
        }
    
        ObjList* list = AS_LIST(listVal);
        writeValueArray(&list->items, item);
        push(OBJ_VAL(list));  // Push updated list back
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