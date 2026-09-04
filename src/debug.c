#include <stdio.h>
#include "headers/debug.h"
#include "headers/object.h"
#include "headers/value.h"

void disassembleChunk(Chunk *chunk, const char *name) {
  printf("== %s ==\n", name);

  for (int offset = 0; offset < chunk->count;) {
    offset = disassembleInstruction(chunk, offset);
  }
}

static int constantInstruction(const char *name, Chunk *chunk, int offset) {
  uint8_t constant = chunk->code[offset + 1];
  printf("%-16s %14d '", name, constant); //-16s = left aligned 16 length string, 14d = 14 length int
  printValue(chunk->constants.values[constant]);
  printf("'\n");
  return offset + 2; // OP_CONSTANT is 2 bytes - one for opcode and one for operand
}

static int invokeInstruction(const char *name, Chunk *chunk, int offset) {
  uint8_t constant = chunk->code[offset + 1];
  uint8_t argCount = chunk->code[offset + 2];
  printf("%-16s (%d args) %4d '", name, argCount, constant);
  printValue(chunk->constants.values[constant]);
  printf("'\n");
  return offset + 3;
}

static int invokeLongInstruction(const char *name, Chunk *chunk, int offset) {
  ConstantIndex constant = decodeU16BE(&chunk->code[offset + 1]);
  uint8_t argCount = chunk->code[offset + 3];
  printf("%-16s (%d args) %4u '", name, argCount, (unsigned int)constant);
  printValue(chunk->constants.values[constant]);
  printf("'\n");
  return offset + 4;
}

static int importInstruction(Chunk *chunk, int offset) {
  uint8_t module = chunk->code[offset + 1];
  uint8_t alias = chunk->code[offset + 2];
  printf("%-16s %4d '", "OP_IMPORT", module);
  printValue(chunk->constants.values[module]);
  printf("' as %4d '", alias);
  printValue(chunk->constants.values[alias]);
  printf("'\n");
  return offset + 3;
}

static int importLongInstruction(Chunk *chunk, int offset) {
  ConstantIndex module = decodeU16BE(&chunk->code[offset + 1]);
  ConstantIndex alias = decodeU16BE(&chunk->code[offset + 3]);
  printf("%-16s %4u '", "OP_IMPORT_LONG", (unsigned int)module);
  printValue(chunk->constants.values[module]);
  printf("' as %4u '", (unsigned int)alias);
  printValue(chunk->constants.values[alias]);
  printf("'\n");
  return offset + 5;
}

static int constantLongInstruction(const char *name, Chunk *chunk, int offset) {
  ConstantIndex constantIndex = decodeU16BE(&chunk->code[offset + 1]);
  printf("%-16s %14u '", name, (unsigned int)constantIndex);
  printValue(chunk->constants.values[constantIndex]);
  printf("'\n");
  return offset + 3;
}

static int simpleInstruction(const char *name, int offset) {
  printf("%s\n", name);
  return offset + 1;
}

static int byteInstruction(const char *name, Chunk *chunk, int offset) {
  uint8_t slot = chunk->code[offset + 1];
  printf("%-16s %4d\n", name, slot);
  return offset + 2;
}

static int jumpInstruction(const char *name, int sign, Chunk *chunk, int offset) {
  uint16_t jump = decodeU16BE(&chunk->code[offset + 1]);
  printf("%-16s %4d -> %d\n", name, offset, offset + 3 + sign * jump);
  return offset + 3;
}

static int closureInstruction(const char *name, Chunk *chunk, int offset, bool isLong) {
  offset++;
  ConstantIndex constant;
  if (isLong) {
    constant = decodeU16BE(&chunk->code[offset]);
    offset += 2;
  } else {
    constant = chunk->code[offset++];
  }
  printf("%-16s %4u '", name, (unsigned int)constant);
  printValue(chunk->constants.values[constant]);
  printf("'\n");

  ObjFunction *function = AS_FUNCTION(chunk->constants.values[constant]);
  for (int i = 0; i < function->upvalueCount; i++) {
    int isLocal = chunk->code[offset++];
    int index = chunk->code[offset++];
    printf("%04d      |                     %s %d\n", offset - 2, isLocal ? "local" : "upvalue", index);
  }
  return offset;
}

int disassembleInstruction(Chunk *chunk, int offset) {
  printf("%04d ", offset);

  // print line numbers
  if (offset > 0 && chunk->lines[offset] ==
                        chunk->lines[offset - 1]) { // curr line same as prev line, so just print " | " for grouping
    printf("  | ");
  } else {
    printf("%4d ", chunk->lines[offset]);
  }

  // print bytecode instructions stored in memory
  uint8_t instruction = chunk->code[offset];
  switch (instruction) {
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
  case OP_GET_UPVALUE:
    return byteInstruction("OP_GET_UPVALUE", chunk, offset);
  case OP_SET_UPVALUE:
    return byteInstruction("OP_SET_UPVALUE", chunk, offset);
  case OP_GET_GLOBAL:
    return constantInstruction("OP_GET_GLOBAL", chunk, offset);
  case OP_GET_GLOBAL_LONG:
    return constantLongInstruction("OP_GET_GLOBAL_LONG", chunk, offset);
  case OP_POP_JUMP_IF_FALSE:
    return jumpInstruction("OP_POP_JUMP_IF_FALSE", 1, chunk, offset);
  case OP_JUMP_IF_TRUE_OR_POP:
    return jumpInstruction("OP_JUMP_IF_TRUE_OR_POP", 1, chunk, offset);
  case OP_JUMP_IF_FALSE_OR_POP:
    return jumpInstruction("OP_JUMP_IF_FALSE_OR_POP", 1, chunk, offset);
  case OP_DEFINE_GLOBAL:
    return constantInstruction("OP_DEFINE_GLOBAL", chunk, offset);
  case OP_DEFINE_GLOBAL_LONG:
    return constantLongInstruction("OP_DEFINE_GLOBAL_LONG", chunk, offset);
  case OP_SET_GLOBAL:
    return constantInstruction("OP_SET_GLOBAL", chunk, offset);
  case OP_SET_GLOBAL_LONG:
    return constantLongInstruction("OP_SET_GLOBAL_LONG", chunk, offset);
  case OP_GET_PROPERTY:
    return constantInstruction("OP_GET_PROPERTY", chunk, offset);
  case OP_GET_PROPERTY_LONG:
    return constantLongInstruction("OP_GET_PROPERTY_LONG", chunk, offset);
  case OP_SET_PROPERTY:
    return constantInstruction("OP_SET_PROPERTY", chunk, offset);
  case OP_SET_PROPERTY_LONG:
    return constantLongInstruction("OP_SET_PROPERTY_LONG", chunk, offset);
  case OP_INVOKE:
    return invokeInstruction("OP_INVOKE", chunk, offset);
  case OP_INVOKE_LONG:
    return invokeLongInstruction("OP_INVOKE_LONG", chunk, offset);
  case OP_GET_SUPER:
    return constantInstruction("OP_GET_SUPER", chunk, offset);
  case OP_GET_SUPER_LONG:
    return constantLongInstruction("OP_GET_SUPER_LONG", chunk, offset);
  case OP_SUPER_INVOKE:
    return invokeInstruction("OP_SUPER_INVOKE", chunk, offset);
  case OP_SUPER_INVOKE_LONG:
    return invokeLongInstruction("OP_SUPER_INVOKE_LONG", chunk, offset);
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
  case OP_LIST_LITERAL_APPEND:
    return simpleInstruction("OP_LIST_LITERAL_APPEND", offset);
  case OP_NEW_HASHMAP:
    return simpleInstruction("OP_NEW_HASHMAP", offset);
  case OP_HASHMAP_LITERAL_INSERT:
    return simpleInstruction("OP_HASHMAP_LITERAL_INSERT", offset);
  case OP_CLOSURE:
    return closureInstruction("OP_CLOSURE", chunk, offset, false);
  case OP_CLOSURE_LONG:
    return closureInstruction("OP_CLOSURE_LONG", chunk, offset, true);
  case OP_CLOSE_UPVALUE:
    return simpleInstruction("OP_CLOSE_UPVALUE", offset);
  case OP_RETURN:
    return simpleInstruction("OP_RETURN", offset);
  case OP_CLASS:
    return constantInstruction("OP_CLASS", chunk, offset);
  case OP_CLASS_LONG:
    return constantLongInstruction("OP_CLASS_LONG", chunk, offset);
  case OP_INHERIT:
    return simpleInstruction("OP_INHERIT", offset);
  case OP_METHOD:
    return constantInstruction("OP_METHOD", chunk, offset);
  case OP_METHOD_LONG:
    return constantLongInstruction("OP_METHOD_LONG", chunk, offset);
  case OP_IMPORT:
    return importInstruction(chunk, offset);
  case OP_IMPORT_LONG:
    return importLongInstruction(chunk, offset);
  case OP_EXPORT:
    return constantInstruction("OP_EXPORT", chunk, offset);
  case OP_EXPORT_LONG:
    return constantLongInstruction("OP_EXPORT_LONG", chunk, offset);
  default:
    printf("Unknown opcode %d\n", instruction);
    return offset + 1;
  }
}
