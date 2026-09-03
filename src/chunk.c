#include <stdlib.h>
#include "headers/chunk.h"
#include "headers/memory.h"
#include "headers/vm.h"

void initChunk(Chunk *chunk) {
  chunk->count = 0;
  chunk->capacity = 0;
  chunk->code = NULL;
  chunk->lines = NULL;
  chunk->globalCache = NULL;
  initValueArray(&chunk->constants);
}

// no memory leaks
void freeChunk(Chunk *chunk) {
  FREE_ARRAY(uint8_t, chunk->code, chunk->capacity);
  FREE_ARRAY(int, chunk->lines, chunk->capacity);
  FREE_ARRAY(GlobalCache, chunk->globalCache, chunk->constants.capacity);
  freeValueArray(&chunk->constants);
  initChunk(chunk); // init to zero out the fields, leaving chunk in a well defined empty state
}

// write data to our dynamic array (also resize it if necessary)
void writeChunk(Chunk *chunk, uint8_t byte, int line) {
  if (chunk->capacity < chunk->count + 1) {
    int oldCapacity = chunk->capacity;
    chunk->capacity = GROW_CAPACITY(oldCapacity);
    chunk->code = GROW_ARRAY(uint8_t, chunk->code, oldCapacity, chunk->capacity);
    chunk->lines = GROW_ARRAY(int, chunk->lines, oldCapacity, chunk->capacity);
  }

  chunk->code[chunk->count] = byte; // finally put in the value of opcode or any other data into our array "code"
  chunk->lines[chunk->count] = line;
  chunk->count++;
}

void writeChunkU16BE(Chunk *chunk, uint16_t value, int line) {
  uint8_t bytes[2];
  encodeU16BE(bytes, value);
  writeChunk(chunk, bytes[0], line);
  writeChunk(chunk, bytes[1], line);
}

int addConstant(Chunk *chunk, Value value) {
  push(value); // GC schenanigans
  int oldCapacity = chunk->constants.capacity;
  writeValueArray(&chunk->constants, value);
  int newCapacity = chunk->constants.capacity;
  if (newCapacity > oldCapacity) {
    chunk->globalCache = GROW_ARRAY(GlobalCache, chunk->globalCache, oldCapacity, newCapacity);
    for (int i = oldCapacity; i < newCapacity; i++) {
      chunk->globalCache[i].valuePtr = NULL;
      chunk->globalCache[i].version = 0;
    }
  }
  pop();
  return chunk->constants.count - 1;
}

// support for if we want more than 256 constants per chunk
void writeConstant(Chunk *chunk, Value value, int line) {
  int index = addConstant(chunk, value);

  if (index <= UINT8_MAX) {
    writeChunk(chunk, OP_CONSTANT, line);
    writeChunk(chunk, (uint8_t)index, line);
  } else {
    writeChunk(chunk, OP_CONSTANT_LONG, line);
    writeChunkU16BE(chunk, (uint16_t)index, line);
  }
}
