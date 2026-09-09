#ifndef clox_chunk_h
#define clox_chunk_h

#include "common.h"
#include "value.h"

// Constant-pool references use this logical type while individual instructions
// retain a smaller encoding when the value fits.
typedef uint16_t ConstantIndex;

static inline void encodeU16BE(uint8_t *bytes, uint16_t value) {
  bytes[0] = (uint8_t)(value >> 8);
  bytes[1] = (uint8_t)value;
}

static inline uint16_t decodeU16BE(const uint8_t *bytes) {
  return (uint16_t)(((uint16_t)bytes[0] << 8) | bytes[1]);
}

typedef enum {
  OP_CONSTANT,      // 8-bit constant index
  OP_CONSTANT_LONG, // 16-bit constant index
  OP_NIL,
  OP_TRUE,
  OP_FALSE,
  OP_POP,
  OP_GET_LOCAL,
  OP_SET_LOCAL,
  OP_GET_UPVALUE,
  OP_SET_UPVALUE,
  OP_GET_GLOBAL,
  OP_DEFINE_GLOBAL,
  OP_SET_GLOBAL,
  OP_SET_PROPERTY,
  OP_GET_PROPERTY,
  OP_GET_SUPER,
  OP_SUPER_INVOKE,
  OP_INVOKE,
  OP_EQUAL,
  OP_GREATER,
  OP_LESS,
  OP_ADD,
  OP_INCREMENT,
  OP_SUBTRACT,
  OP_DECREMENT,
  OP_MULTIPLY,
  OP_DIVIDE,
  OP_MODULO,
  OP_NOT,
  OP_NEGATE,
  OP_PRINT,
  OP_PRINT_NO_NEWLINE,
  OP_JUMP,
  OP_JUMP_IF_FALSE,
  OP_LOOP,
  OP_CALL,
  OP_GET_INDEX,
  OP_SET_INDEX,
  OP_NEW_LIST,
  OP_LIST_LITERAL_APPEND,
  OP_NEW_HASHMAP,
  OP_HASHMAP_LITERAL_INSERT,
  OP_CLOSURE,
  OP_CLOSE_UPVALUE,
  OP_RETURN,
  OP_BREAK,
  OP_CLASS,
  OP_INHERIT,
  OP_METHOD,
  OP_IMPORT,
  OP_EXPORT,
  OP_POP_JUMP_IF_FALSE,
  OP_JUMP_IF_TRUE_OR_POP,
  OP_JUMP_IF_FALSE_OR_POP,
  OP_GET_GLOBAL_LONG,
  OP_DEFINE_GLOBAL_LONG,
  OP_SET_GLOBAL_LONG,
  OP_SET_PROPERTY_LONG,
  OP_GET_PROPERTY_LONG,
  OP_GET_SUPER_LONG,
  OP_SUPER_INVOKE_LONG,
  OP_INVOKE_LONG,
  OP_CLOSURE_LONG,
  OP_CLASS_LONG,
  OP_METHOD_LONG,
  OP_IMPORT_LONG,
  OP_EXPORT_LONG,
  OP_GET_LOCAL_0,
  OP_GET_LOCAL_1,
  OP_GET_LOCAL_2,
  OP_GET_LOCAL_3,
  OP_SET_LOCAL_0,
  OP_SET_LOCAL_1,
  OP_SET_LOCAL_2,
  OP_SET_LOCAL_3,
  OP_INT_0,
  OP_INT_1,
  OP_INT_2,
  OP_JUMP_IF_NOT_LESS,
  OP_JUMP_IF_NOT_GREATER,
  OP_JUMP_IF_NOT_EQUAL,
  OP_SET_LOCAL_POP,
  OP_SET_LOCAL_POP_0,
  OP_SET_LOCAL_POP_1,
  OP_SET_LOCAL_POP_2,
  OP_SET_LOCAL_POP_3,
  OP_SET_GLOBAL_POP,
  OP_SET_UPVALUE_POP,
  OP_SET_INDEX_POP,
} OpCode;

typedef struct {
  Value *valuePtr;
  uint32_t version;
} GlobalCache;

// unit of bytecode, essentially the entire AST class from JLOX
typedef struct {
  int count;     // number of places taken up in block
  int capacity;  // size of allocated "code" block
  uint8_t *code; // dynamically allocated array
  int *lines; // separate array to store line numbers so we can retreieve when errors occurs, inefficient for memory but
              // atleast keeps operations and line info separate - fewer cache misses when error DOESNT occur
  ValueArray constants; // chunk data
  GlobalCache *globalCache;
} Chunk;

void initChunk(Chunk *chunk);
void freeChunk(Chunk *chunk);
void writeChunk(Chunk *chunk, uint8_t byte, int line);
void writeChunkU16BE(Chunk *chunk, uint16_t value, int line);
int addConstant(Chunk *chunk, Value value);
void writeConstant(Chunk *chunk, Value value, int line);

#endif // !clox_chunk_h
