#ifndef clox_vm_h
#define clox_vm_h

#include "object.h"
#include "table.h"
#include "value.h"
#include "pogberry.h"

#define FRAMES_MAX 64
#define STACK_MAX (FRAMES_MAX * UINT8_COUNT)

typedef struct
{
  ObjClosure *closure;
  uint8_t *ip;
  Value *slots;
} CallFrame;

typedef struct
{
  char *name;
  PogberryNativeDefinition *definitions;
  size_t definitionCount;
  char *source;
} HostCapability;

struct PogberryVM
{
  CallFrame frames[FRAMES_MAX];
  int frameCount;
  bool hadRuntimeError;

  Value stack[STACK_MAX]; // time for implementing a stack in the virtual machine babyyyy also this is the pointer to the first element of the array by default (if we dont do any pointer arithmetic)
  Value *stackTop;        // pointer to the element (pointer faster than indexing) just after the last stack, so pointing to 0 index means stack empty
  Table globals;
  Table prelude;
  Table strings; // for interning strings, each unique string will only be stored once in memory, so "=" operation can be carried out fast -> just compare the memory address rather than comparing the string character by character
  Table modules;
  ObjString *initString;
  ObjUpvalue *openUpvalues;

  size_t bytesAllocated;
  size_t nextGC;
  Obj *objects;
  int grayCount;
  int grayCapacity;
  Obj **grayStack;

  PogberryConfig config;
  HostCapability *capabilities;
  size_t capabilityCount;
  size_t capabilityCapacity;
  Value lastReturnValue;
  bool hasLastReturnValue;
  bool legacyGuiLoaded;
  uint32_t randomState;
};

typedef PogberryVM VM;

extern VM *activeVM;
#define vm (*activeVM)

void initVM(void);
void freeVM(void);
InterpretResult interpret(const char *source); // run the chunk and respond with a value from enum declared above
void runtimeError(const char *format, ...);
void writeVMOutput(const char *text, size_t length);
void reportDiagnostic(PogberryDiagnosticKind kind, const char *message);
bool resolveCapability(const char *name);
InterpretResult resolveModule(const char *name, Value *module);
bool push(Value value);
Value pop();

#endif
