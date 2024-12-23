#ifndef clox_chunk_h
#define clox_chunk_h

#include "common.h"
#include "value.h"

typedef enum {
  OP_CONSTANT,  // 8 bit store
  OP_CONSTANT_LONG, // 24 bit store
  OP_NIL,
  OP_TRUE,
  OP_FALSE,
  OP_EQUAL,
  OP_GREATER,
  OP_LESS,
  OP_ADD,
  OP_SUBTRACT,
  OP_MULTIPLY,
  OP_DIVIDE,
  OP_NOT,
  OP_NEGATE,
  OP_RETURN,
} OpCode;

// unit of bytecode, essentially the entire AST class from JLOX
typedef struct {
  int count; // number of places taken up in block
  int capacity; // size of allocated "code" block
  uint8_t* code; //dynamically allocated array
  int* lines; // separate array to store line numbers so we can retreieve when errors occurs, inefficient for memory but atleast keeps operations and line info separate - fewer cache misses when error DOESNT occur
  ValueArray constants; //chunk data
} Chunk;

void initChunk(Chunk* chunk);
void freeChunk(Chunk* chunk);
void writeChunk(Chunk* chunk, uint8_t byte, int line);
int addConstant(Chunk* chunk, Value value);
void writeConstant(Chunk* chunk, Value value, int line);

#endif // !clox_chunk_h