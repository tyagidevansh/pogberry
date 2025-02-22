#include <stdio.h>
#include "debug.h"
#include "value.h"

void disassembleChunk(Chunk *chunk, const char *name)
{
  printf("== %s ==\n", name);

  for (int offset = 0; offset < chunk->count;)
  {
    offset = disassembleInstruction(chunk, offset);
  }
}

static int constantInstruction(const char *name, Chunk *chunk, int offset)
{
  uint8_t constant = chunk->code[offset + 1];
  printf("%-16s %14d '", name, constant); //-16s = left aligned 16 length string, 14d = 14 length int
  printValue(chunk->constants.values[constant]);
  printf("'\n");
  return offset + 2; // OP_CONSTANT is 2 bytes - one for opcode and one for operand
}

static int constantLongInstruction(const char *name, Chunk *chunk, int offset)
{
  // to find the total 24 bit index we shift the later bits by 8 and then 16 and take their OR to fit all 24 bits stored at different offsets in the same number
  uint32_t constantIndex = chunk->code[offset + 1] | (chunk->code[offset + 2] << 8) | (chunk->code[offset + 3] << 16);
  printf("%-16s %14d '", name, constantIndex);
  printValue(chunk->constants.values[constantIndex]);
  printf("'\n");
  return offset + 4;
}

static int simpleInstruction(const char *name, int offset)
{
  printf("%s\n", name);
  return offset + 1;
}

static int byteInstruction(const char *name, Chunk *chunk,
                           int offset)
{
  uint8_t slot = chunk->code[offset + 1];
  printf("%-16s %4d\n", name, slot);
  return offset + 2; 
}

static int jumpInstruction(const char *name, int sign,
                           Chunk *chunk, int offset)
{
  uint16_t jump = (uint16_t)(chunk->code[offset + 1] << 8);
  jump |= chunk->code[offset + 2];
  printf("%-16s %4d -> %d\n", name, offset,
         offset + 3 + sign * jump);
  return offset + 3;
}

int disassembleInstruction(Chunk *chunk, int offset)
{
  printf("%04d ", offset);

  // print line numbers
  if (offset > 0 && chunk->lines[offset] == chunk->lines[offset - 1])
  { // curr line same as prev line, so just print " | " for grouping
    printf("  | ");
  }
  else
  {
    printf("%4d ", chunk->lines[offset]);
  }

  // print bytecode instructions stored in memory
  uint8_t instruction = chunk->code[offset];
  switch (instruction)
  {
  case OP_CONSTANT:
    return constantInstruction("OP_CONSTANT", chunk, offset);
  case OP_CONSTANT_LONG:
    return constantLongInstruction("OP_CONSTANT_LONG", chunk, offset);
  case OP_NIL:
    return simpleInstruction("OP_NIL", offset);
  case OP_TRUE:
    return simpleInstruction("OP_TRUE", offset);
  case OP_FALSE:
    return simpleInstruction("OP_FALSE", offset);
  case OP_POP:
    return simpleInstruction("OP_POP", offset);
  case OP_GET_LOCAL:
    return byteInstruction("OP_GET_LOCAL", chunk, offset);
  case OP_SET_LOCAL:
    return byteInstruction("OP_SET_LOCAL", chunk, offset);
  case OP_GET_GLOBAL:
    return constantInstruction("OP_GET_GLOBAL", chunk, offset);
  case OP_DEFINE_GLOBAL:
    return constantInstruction("OP_DEFINE_GLOBAL", chunk, offset);
  case OP_SET_GLOBAL:
    return constantInstruction("OP_SET_GLOBAL", chunk, offset);
  case OP_EQUAL:
    return simpleInstruction("OP_EQUAL", offset);
  case OP_GREATER:
    return simpleInstruction("OP_GREATER", offset);
  case OP_LESS:
    return simpleInstruction("OP_LESS", offset);
  case OP_ADD:
    return simpleInstruction("OP_ADD", offset);
  case OP_SUBTRACT:
    return simpleInstruction("OP_SUBTRACT", offset);
  case OP_MULTIPLY:
    return simpleInstruction("OP_MULTIPLY", offset);
  case OP_DIVIDE:
    return simpleInstruction("OP_DIVIDE", offset);
  case OP_NOT:
    return simpleInstruction("OP_NOT", offset);
  case OP_NEGATE:
    return simpleInstruction("OP_NEGATE", offset);
  case OP_PRINT:
    return simpleInstruction("OP_PRINT", offset);
  case OP_JUMP:
    return jumpInstruction("OP_JUMP", 1, chunk, offset);
  case OP_JUMP_IF_FALSE:
    return jumpInstruction("OP_JUMP_IF_FALSE", 1, chunk, offset);
  case OP_LOOP:
    return jumpInstruction("OP_LOOP", -1, chunk, offset);
  case OP_CALL:
    return byteInstruction("OP_CALL", chunk, offset);
  case OP_GET_INDEX:
    return simpleInstruction("OP_GET_INDEX", offset);
  case OP_SET_INDEX:
    return simpleInstruction("OP_SET_INDEX", offset);
  case OP_NEW_LIST:
    return simpleInstruction("OP_NEW_LIST", offset);
  case OP_LIST_APPEND:
    return simpleInstruction("OP_LIST_APPEND", offset);
  case OP_LIST_ADD:
    return simpleInstruction("OP_LIST_ADD", offset);
  case OP_LIST_REMOVE:
    return simpleInstruction("OP_LIST_REMOVE", offset);
  case OP_SIZE:
    return simpleInstruction("OP_SIZE", offset);
  case OP_RETURN:
    return simpleInstruction("OP_RETURN", offset);
  default:
    printf("Unknown opcode %d\n", instruction);
    return offset + 1;
  }
}