#include <stdlib.h>
#include "headers/chunk.h"
#include "headers/memory.h"
#include "headers/vm.h"

void initChunk(Chunk *chunk)
{
  chunk->count = 0;
  chunk->capacity = 0;
  chunk->code = NULL;
  chunk->lines = NULL;
  initValueArray(&chunk->constants);
}

// no memory leaks
void freeChunk(Chunk *chunk)
{
  FREE_ARRAY(uint8_t, chunk->code, chunk->capacity);
  FREE_ARRAY(int, chunk->lines, chunk->capacity);
  freeValueArray(&chunk->constants);
  initChunk(chunk); // init to zero out the fields, leaving chunk in a well defined empty state
}

// write data to our dynamic array (also resize it if necessary)
void writeChunk(Chunk *chunk, uint8_t byte, int line)
{
  if (chunk->capacity < chunk->count + 1)
  {
    int oldCapacity = chunk->capacity;
    chunk->capacity = GROW_CAPACITY(oldCapacity);
    chunk->code = GROW_ARRAY(uint8_t, chunk->code, oldCapacity, chunk->capacity);
    chunk->lines = GROW_ARRAY(int, chunk->lines, oldCapacity, chunk->capacity);
  }

  chunk->code[chunk->count] = byte; // finally put in the value of opcode or any other data into our array "code"
  chunk->lines[chunk->count] = line;
  chunk->count++;
}

int addConstant(Chunk *chunk, Value value)
{
  push(value); // GC schenanigans
  writeValueArray(&chunk->constants, value);
  pop();
  return chunk->constants.count - 1;
}

// support for if we want more than 256 constants per chunk
void writeConstant(Chunk *chunk, Value value, int line)
{
  int index = addConstant(chunk, value);

  if (index < 255)
  {
    writeChunk(chunk, OP_CONSTANT, line);
    writeChunk(chunk, index, line);
  }
  else
  {
    writeChunk(chunk, OP_CONSTANT_LONG, line);

    // 24 bit support
    writeChunk(chunk, (index >> 0) & 0xFF, line);  // low byte
    writeChunk(chunk, (index >> 8) & 0xFF, line);  // mid byte, ">>" is rightshift operator and shifts the bits by 8, 0xff represents 1111 1111 and masks out all the bits except the last 8, essentially giving us
    writeChunk(chunk, (index >> 16) & 0xFF, line); // high byte
  }
}