#ifndef clox_value_h
#define clox_value_h

#include "common.h"

typedef double Value;

//a constant pool of sorts, chunk stored opcode this one will store data
typedef struct {
  int capacity;
  int count;
  Value* values;
} ValueArray;

//all the same functions as chunk as essentially the same task desired
void initValueArray(ValueArray* array);
void writeValueArray(ValueArray* array, Value value);
void freeValueArray(ValueArray* array);
void printValue(Value value);

#endif // !clox_value_h