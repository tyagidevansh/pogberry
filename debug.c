#include <stdio.h>
#include "debug.h"
#include "value.h"

void disassembleChunk(Chunk* chunk, const char* name) {
  printf("== %s ==\n", name);

  for (int offset = 0; offset < chunk->count;) {
    offset = disassembleInstruction(chunk, offset);
  }
}

static int constantInstruction(const char* name, Chunk* chunk, int offset) {
  uint8_t constant = chunk->code[offset + 1];
  printf("%-16s %14d '", name, constant);  //-16s = left aligned 16 length string, 14d = 14 length int
  printValue(chunk->constants.values[constant]);
  printf("'\n");
  return offset + 2; // OP_CONSTANT is 2 bytes - one for opcode and one for operand
}

static int constantLongInstruction(const char* name, Chunk* chunk, int offset) {
  // to find the total 24 bit index we shift the later bits by 8 and then 16 and take their OR to fit all 24 bits stored at different offsets in the same number
  uint32_t constantIndex = chunk->code[offset + 1] | (chunk->code[offset + 2] << 8) | (chunk->code[offset + 3] << 16);
  printf("%-16s %14d '", name, constantIndex);
  printValue(chunk->constants.values[constantIndex]);
  printf("'\n");
  return offset + 4;
}

static int simpleInstruction(const char* name, int offset) {
  printf("%s\n", name);
  return offset + 1;
}

int disassembleInstruction(Chunk* chunk, int offset) {
  printf("%04d ", offset);

  // print line numbers 
  if (offset > 0 && chunk->lines[offset] == chunk->lines[offset - 1]) { // curr line same as prev line, so just print " | " for grouping
    printf("  | ");
  } else {
    printf("%4d ", chunk->lines[offset]);
  }

  // print bytecode instructions stored in memory
  uint8_t instruction = chunk->code[offset];
  switch(instruction) {
    case OP_CONSTANT:
      return constantInstruction("OP_CONSTANT", chunk, offset);
    case OP_CONSTANT_LONG:
      return constantLongInstruction("OP_CONSTANT_LONG", chunk, offset);
    case OP_ADD:
      return simpleInstruction("OP_ADD", offset);
    case OP_SUBTRACT:
      return simpleInstruction("OP_SUBTRACT", offset);
    case OP_MULTIPLY:
      return simpleInstruction("OP_MULTIPLY", offset);
    case OP_DIVIDE:
      return simpleInstruction("OP_DIVIDE", offset);
    case OP_NEGATE:
      return simpleInstruction("OP_NEGATE", offset);
    case OP_RETURN:
      return simpleInstruction("OP_RETURN", offset);
    default:
      printf("Unknown opcode %d\n", instruction);
      return offset + 1;
  }
}