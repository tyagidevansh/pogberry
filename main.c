#include "common.h"
#include "chunk.h"
#include "debug.h"

int main(int argc, const char* argv[]) {
  Chunk chunk;
  initChunk(&chunk);

  int constant = addConstant(&chunk, 1.2);  // add 1.2 to the constants array and get its index
  writeChunk(&chunk, OP_CONSTANT, 123);     // write the opcode OP_CONSTANT to the chunk's code array
  writeChunk(&chunk, constant, 123);        // write the index of 1.2 to chunk's code array

  writeChunk(&chunk, OP_RETURN, 123);

  writeConstant(&chunk, 3.5, 124);
  disassembleChunk(&chunk, "test chunk");

  freeChunk(&chunk);
}