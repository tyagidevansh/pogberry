#ifndef clox_vm_h
#define clox_vm_h

#include "chunk.h"
#include "table.h"
#include "value.h"

#define STACK_MAX 256

typedef struct {
  Chunk* chunk;
  uint8_t* ip; //keeping track of where the VM is, IP = Instruction Pointer
  Value stack[STACK_MAX];  // time for implementing a stack in the virtual machine babyyyy also this is the pointer to the first element of the array by default (if we dont do any pointer arithmetic)
  Value* stackTop;  // pointer to the element (pointer faster than indexing) just after the last stack, so pointing to 0 index means stack empty
  Table strings; // for interning strings, each unique string will only be stored once in memory, so "=" operation can be carried out fast -> just compare the memory address rather than comparing the string character by character
  Obj* objects;
} VM;

typedef enum {
  INTERPRET_OK,
  INTERPRET_COMPILE_ERROR,
  INTERPRET_RUNTIME_ERROR,
} InterpretResult;

extern VM vm;

void initVM();
void freeVM();
InterpretResult interpret(const char* source); //run the chunk and respond with a value from enum declared above
void push(Value value);
Value pop();

#endif 