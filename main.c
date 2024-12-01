#include "common.h"
#include "chunk.h"
#include "debug.h"
#include "vm.h"

int main(int argc, const char* argv[]) {
  initVM();  

  Chunk chunk;
  initChunk(&chunk);

  // 1 + 2 * 3

  int constant = addConstant(&chunk, 2);
  writeChunk(&chunk, OP_CONSTANT, 1);
  writeChunk(&chunk, constant, 1);

  constant = addConstant(&chunk, 3);
  writeChunk(&chunk, OP_CONSTANT, 1);
  writeChunk(&chunk, constant, 1);

  writeChunk(&chunk, OP_MULTIPLY, 1);

  constant = addConstant(&chunk, 1);
  writeChunk(&chunk, OP_CONSTANT, 1);
  writeChunk(&chunk, constant, 1);

  writeChunk(&chunk, OP_ADD, 1);

  // int constant = addConstant(&chunk, 1.2);  // add 1.2 to the constants array and get its index
  // writeChunk(&chunk, OP_CONSTANT, 123);     // write the opcode OP_CONSTANT to the chunk's code array
  // writeChunk(&chunk, constant, 123);        // write the index of 1.2 to chunk's code array
  
  // constant = addConstant(&chunk, 3.4);
  // writeChunk(&chunk, OP_CONSTANT, 123);
  // writeChunk(&chunk, constant, 123);

  // writeChunk(&chunk, OP_ADD, 123);

  // constant = addConstant(&chunk, 5.6);
  // writeChunk(&chunk, OP_CONSTANT, 123);
  // writeChunk(&chunk, constant, 123);

  // writeChunk(&chunk, OP_DIVIDE, 123);

  // writeChunk(&chunk, OP_NEGATE, 123);
  // writeChunk(&chunk, OP_RETURN, 123);

  disassembleChunk(&chunk, "test chunk");
  interpret(&chunk); // vm is commanded to interpret a chunk of bytecode
  freeVM();
  freeChunk(&chunk);
}