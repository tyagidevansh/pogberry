#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>
#include <math.h>

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
  if (argCount > 0)
  {
    runtimeError("Clock does not accept any arguments");
    return NIL_VAL;
  }
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

static Value sqrtNative(int argCount, Value *args)
{
  if (argCount != 1 || !IS_NUMBER(args[0]))
  {
    runtimeError("sqrt expects a single number.");
    return NIL_VAL;
  }
  return NUMBER_VAL(sqrt(AS_NUMBER(args[0])));
}

static Value absNative(int argCount, Value *args)
{
  if (argCount != 1 || !IS_NUMBER(args[0]))
  {
    runtimeError("abs expects a single value.");
    return NIL_VAL;
  }
  return NUMBER_VAL(fabs(AS_NUMBER(args[0])));
}

int Valuecomp(const void *elem1, const void *elem2)
{
  Value f = *((Value *)elem1);
  Value s = *((Value *)elem2);

  if (IS_NUMBER(f) && IS_NUMBER(s))
  {
    double df = AS_NUMBER(f);
    double ds = AS_NUMBER(s);
    if (df > ds)
      return 1;
    if (ds > df)
      return -1;
    return 0;
  }
  else if (IS_STRING(f) && IS_STRING(s))
  {
    ObjString *strF = AS_STRING(f);
    ObjString *strS = AS_STRING(s);
    return strcmp(strF->chars, strS->chars);
  }
  else
  {
    return 0; 
  }
}

int ValuecompReverse(const void *elem1, const void *elem2)
{
  return Valuecomp(elem2, elem1);
}

int Strcomp(const void *elem1, const void *elem2)
{
  char f = *((char *)elem1);
  char s = *((char *)elem2);

  if (f > s)
    return 1;
  if (f < s)
    return -1;
  return 0;
}

int StrcompReverse(const void *elem1, const void *elem2)
{
  return Strcomp(elem2, elem1);
}

static Value sortNative(int argCount, Value *args)
{
  if (argCount < 1)
  {
    runtimeError("Expect at least one argument.");
    return NIL_VAL;
  }
  if (argCount > 2)
  {
    runtimeError("Function cannot take more than two arguments [Container, Reverse = True | False]");
    return NIL_VAL;
  }

  bool reverse = false;
  if (argCount == 2)
  {
    if (!IS_BOOL(args[1]))
    {
      runtimeError("Second argument must be a boolean.");
      return NIL_VAL;
    }
    reverse = AS_BOOL(args[1]);
  }

  if (IS_LIST(args[0]))
  {
    ObjList *list = AS_LIST(args[0]);
    qsort(list->items.values, list->items.count, sizeof(Value), reverse ? ValuecompReverse : Valuecomp);
    return NIL_VAL;
  }
  else if (IS_STRING(args[0]))
  {
    ObjString *str = AS_STRING(args[0]);
    qsort(str->chars, str->length, sizeof(char), reverse ? StrcompReverse : Strcomp);
    return NIL_VAL;
  }
  else
  {
    runtimeError("First argument must be a list or a string.");
    return NIL_VAL;
  }
}

static Value listAdd(int argCount, Value *args)
{
  if (argCount != 2 || !IS_LIST(args[0]))
  {
    runtimeError("Expected a list and a value");
    return NIL_VAL;
  }

  ObjList *list = AS_LIST(args[0]);
  Value value = args[1];

  if (list->items.count + 1 > list->items.capacity)
  {
    int oldCapacity = list->items.capacity;
    list->items.capacity = GROW_CAPACITY(oldCapacity);
    list->items.values = GROW_ARRAY(Value, list->items.values, oldCapacity, list->items.capacity);
  }

  list->items.values[list->items.count] = value;
  list->items.count++;

  return NIL_VAL;
}

static Value listRemove(int argCount, Value *args)
{
  if (argCount != 2 || !IS_LIST(args[0]) || !IS_NUMBER(args[1]))
  {
    runtimeError("Expect a list and an index");
    return NIL_VAL;
  }

  ObjList *list = AS_LIST(args[0]);
  int index = AS_NUMBER(args[1]);

  if (index < 0 || index >= list->items.count)
  {
    runtimeError("Index out of bounds");
    return NIL_VAL;
  }

  Value removedVal = list->items.values[index];

  for (int i = index; i < list->items.count - 1; i++)
  {
    list->items.values[i] = list->items.values[i + 1];
  }

  list->items.count--;

  return removedVal;
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
  defineNative("add", listAdd);
  defineNative("remove", listRemove);
  defineNative("sort", sortNative);
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
    case OP_GET_INDEX:
    {
      if (IS_NUMBER(peek(0)) && IS_STRING(peek(1))) {
        Value key = pop();
        Value container = pop();

        ObjString *string = AS_STRING(container);
        int i = (int)AS_NUMBER(key);
        if (i < 0 || i >= string->length)
        {
          runtimeError("String index out of bounds.");
          return INTERPRET_RUNTIME_ERROR;
        }

        char chars[2] = {string->chars[i], '\0'};
        push(OBJ_VAL(copyString(chars, 1)));
      }
      else if (IS_STRING(peek(0)) && IS_HASHMAP(peek(1)))
      {
        Value key = pop();
        Value container = pop();

        ObjHashmap *hashmap = AS_HASHMAP(container);

        if (!IS_STRING(key))
        {
          runtimeError("Hashmap key must be a string");
          return INTERPRET_RUNTIME_ERROR;
        }

        ObjString *keyStr = AS_STRING(key);
        Value value;

        if (tableGet(&hashmap->items, keyStr, &value))
        {
          push(value);
        }
        else
        {
          push(NIL_VAL);
          //runtimeError("This key does not exist in this hashmap.");
        }
      } else if (IS_NUMBER(peek(0))) {
        int keyCount = 0;

        while (IS_NUMBER(peek(keyCount))) {
          keyCount++;
        }

        Value container = peek(keyCount);

        if (!IS_LIST(container)) {
          if (keyCount == 1) {
            runtimeError("Can only index into lists, strings and hashmaps.");
            return INTERPRET_RUNTIME_ERROR;
          } else {
            runtimeError("Multi-level indexing is only supported in lists.");
            return INTERPRET_RUNTIME_ERROR;
          }
        }

        for (int i = keyCount - 1; i >= 0; i--) {
          if (!IS_LIST(container)) {
            runtimeError("Cannot index non-list value.");
            return INTERPRET_RUNTIME_ERROR;
          }

          ObjList* objList = AS_LIST(container);
          int index = (int)AS_NUMBER(peek(i));

          if (index < 0 || index >= objList->items.count) {
            runtimeError("List index out of bounds.");
            return INTERPRET_RUNTIME_ERROR;
          }

          container = objList->items.values[index];
        }

        for (int i = 0; i <= keyCount; i++) {
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
      printf("im here \n");
      Value value = pop();
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
        printf("it is a hashmap \n");
        ObjHashmap *hashmap = AS_HASHMAP(container);
        if (!IS_STRING(key))
        {
          printf("key is not string");
          runtimeError("Hashmap key must be a string");
          return INTERPRET_RUNTIME_ERROR;
        }
        printf("here now");
        ObjString *keyStr = AS_STRING(key);
        !tableSet(&hashmap->items, keyStr, value);
        push(OBJ_VAL(keyStr));
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
      writeValueArray(&list->items, item);
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
      Value value = pop();
      Value keyVal = pop();
      Value hashmapVal = pop();

      if (!IS_HASHMAP(hashmapVal))
      {
        runtimeError("Expect a hashmap.");
        return INTERPRET_RUNTIME_ERROR;
      }

      ObjHashmap *hashmap = AS_HASHMAP(hashmapVal);
      ObjString *key = AS_STRING(keyVal);
      tableSet(&hashmap->items, key, value);
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
      ObjString *keyStr = AS_STRING(keyVal);

      if (tableDelete(&hashmap->items, keyStr))
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