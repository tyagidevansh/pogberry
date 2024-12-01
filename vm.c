#include <stdio.h>

#include "common.h"
#include "debug.h"
#include "vm.h"

// global declaration of VM so we dont have to pass it around everywhere, theres only going to be one VM so its ok
VM vm;

static void resetStack() {
  vm.stackTop = vm.stack;
}

void initVM() {
  resetStack();
}

void freeVM() {

}

void push(Value value) {
  *vm.stackTop = value; // put the new value in the empty spot
  vm.stackTop++;  // increase stackTop to point to the next empty spot
}

Value pop() {
  vm.stackTop--;
  return *vm.stackTop;
}

static InterpretResult run() {
#define READ_BYTE() (*vm.ip++)
#define READ_CONSTANT() (vm.chunk->constants.values[READ_BYTE()]) 
//awkward do-while and then while(false) just to run it once so that this preprocessor can be defined at all. this faux loop is a workaround allowing preprocessor to take multiple statements 
//really pushing macros to the limit here
#define BINARY_OP(op) \   
  do { \
    double b = pop(); \
    double a = pop(); \
    push(a op b); \
  } while (false)

  for (;;) {
#ifdef DEBUG_TRACE_EXECUTION
    printf("        ");
    for (Value* slot = vm.stack; slot < vm.stackTop; slot++) {
      printf("[ ");
      printValue(*slot);
      printf(" ]");
    }
    printf("\n");
    disassembleInstruction(vm.chunk, (int)(vm.ip - vm.chunk->code));
#endif
    uint8_t instruction;
    switch (instruction = READ_BYTE()) {
      case OP_CONSTANT: {
        Value constant = READ_CONSTANT();
        push(constant);  //load a value (push it onto the stack)
        break;
      }
      case OP_ADD:      BINARY_OP(+); break;
      case OP_SUBTRACT: BINARY_OP(-); break;
      case OP_MULTIPLY: BINARY_OP(*); break;
      case OP_DIVIDE:   BINARY_OP(/); break;
      case OP_NEGATE: push(-pop()); break; // unary negatiion
      case OP_RETURN: {
        return INTERPRET_OK;
      }
    }
  }
#undef BINARY_OP
#undef READ_CONSTANT
#undef READ_BYTE
}

InterpretResult interpret(Chunk* chunk) {
  vm.chunk = chunk;
  vm.ip = vm.chunk->code;
  return run();
}