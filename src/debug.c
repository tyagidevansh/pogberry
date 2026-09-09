#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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
  case OP_GET_LOCAL_0:
    return simpleInstruction("OP_GET_LOCAL_0", offset);
  case OP_GET_LOCAL_1:
    return simpleInstruction("OP_GET_LOCAL_1", offset);
  case OP_GET_LOCAL_2:
    return simpleInstruction("OP_GET_LOCAL_2", offset);
  case OP_GET_LOCAL_3:
    return simpleInstruction("OP_GET_LOCAL_3", offset);
  case OP_SET_LOCAL_0:
    return simpleInstruction("OP_SET_LOCAL_0", offset);
  case OP_SET_LOCAL_1:
    return simpleInstruction("OP_SET_LOCAL_1", offset);
  case OP_SET_LOCAL_2:
    return simpleInstruction("OP_SET_LOCAL_2", offset);
  case OP_SET_LOCAL_3:
    return simpleInstruction("OP_SET_LOCAL_3", offset);
  case OP_INT_0:
    return simpleInstruction("OP_INT_0", offset);
  case OP_INT_1:
    return simpleInstruction("OP_INT_1", offset);
  case OP_INT_2:
    return simpleInstruction("OP_INT_2", offset);
  case OP_JUMP_IF_NOT_LESS:
    return jumpInstruction("OP_JUMP_IF_NOT_LESS", 1, chunk, offset);
  case OP_JUMP_IF_NOT_GREATER:
    return jumpInstruction("OP_JUMP_IF_NOT_GREATER", 1, chunk, offset);
  case OP_JUMP_IF_NOT_EQUAL:
    return jumpInstruction("OP_JUMP_IF_NOT_EQUAL", 1, chunk, offset);
  case OP_SET_LOCAL_POP:
    return byteInstruction("OP_SET_LOCAL_POP", chunk, offset);
  case OP_SET_LOCAL_POP_0:
    return simpleInstruction("OP_SET_LOCAL_POP_0", offset);
  case OP_SET_LOCAL_POP_1:
    return simpleInstruction("OP_SET_LOCAL_POP_1", offset);
  case OP_SET_LOCAL_POP_2:
    return simpleInstruction("OP_SET_LOCAL_POP_2", offset);
  case OP_SET_LOCAL_POP_3:
    return simpleInstruction("OP_SET_LOCAL_POP_3", offset);
  case OP_SET_GLOBAL_POP:
    return constantInstruction("OP_SET_GLOBAL_POP", chunk, offset);
  case OP_SET_UPVALUE_POP:
    return byteInstruction("OP_SET_UPVALUE_POP", chunk, offset);
  case OP_SET_INDEX_POP:
    return simpleInstruction("OP_SET_INDEX_POP", offset);
  default:
    printf("Unknown opcode %d\n", instruction);
    return offset + 1;
  }
}

#ifdef DEBUG_OPCODE_STATS
uint64_t opcodeCounts[256] = {0};

static const char *opcodeNames[256] = {
    [OP_CONSTANT] = "OP_CONSTANT",
    [OP_NIL] = "OP_NIL",
    [OP_TRUE] = "OP_TRUE",
    [OP_FALSE] = "OP_FALSE",
    [OP_POP] = "OP_POP",
    [OP_GET_LOCAL] = "OP_GET_LOCAL",
    [OP_SET_LOCAL] = "OP_SET_LOCAL",
    [OP_GET_GLOBAL] = "OP_GET_GLOBAL",
    [OP_DEFINE_GLOBAL] = "OP_DEFINE_GLOBAL",
    [OP_SET_GLOBAL] = "OP_SET_GLOBAL",
    [OP_GET_UPVALUE] = "OP_GET_UPVALUE",
    [OP_SET_UPVALUE] = "OP_SET_UPVALUE",
    [OP_GET_PROPERTY] = "OP_GET_PROPERTY",
    [OP_SET_PROPERTY] = "OP_SET_PROPERTY",
    [OP_GET_SUPER] = "OP_GET_SUPER",
    [OP_SUPER_INVOKE] = "OP_SUPER_INVOKE",
    [OP_INVOKE] = "OP_INVOKE",
    [OP_EQUAL] = "OP_EQUAL",
    [OP_GREATER] = "OP_GREATER",
    [OP_LESS] = "OP_LESS",
    [OP_ADD] = "OP_ADD",
    [OP_SUBTRACT] = "OP_SUBTRACT",
    [OP_MULTIPLY] = "OP_MULTIPLY",
    [OP_DIVIDE] = "OP_DIVIDE",
    [OP_MODULO] = "OP_MODULO",
    [OP_NOT] = "OP_NOT",
    [OP_NEGATE] = "OP_NEGATE",
    [OP_PRINT] = "OP_PRINT",
    [OP_PRINT_NO_NEWLINE] = "OP_PRINT_NO_NEWLINE",
    [OP_JUMP] = "OP_JUMP",
    [OP_JUMP_IF_FALSE] = "OP_JUMP_IF_FALSE",
    [OP_POP_JUMP_IF_FALSE] = "OP_POP_JUMP_IF_FALSE",
    [OP_JUMP_IF_TRUE_OR_POP] = "OP_JUMP_IF_TRUE_OR_POP",
    [OP_JUMP_IF_FALSE_OR_POP] = "OP_JUMP_IF_FALSE_OR_POP",
    [OP_LOOP] = "OP_LOOP",
    [OP_CALL] = "OP_CALL",
    [OP_GET_INDEX] = "OP_GET_INDEX",
    [OP_SET_INDEX] = "OP_SET_INDEX",
    [OP_NEW_LIST] = "OP_NEW_LIST",
    [OP_LIST_LITERAL_APPEND] = "OP_LIST_LITERAL_APPEND",
    [OP_NEW_HASHMAP] = "OP_NEW_HASHMAP",
    [OP_HASHMAP_LITERAL_INSERT] = "OP_HASHMAP_LITERAL_INSERT",
    [OP_CLOSURE] = "OP_CLOSURE",
    [OP_CLOSE_UPVALUE] = "OP_CLOSE_UPVALUE",
    [OP_RETURN] = "OP_RETURN",
    [OP_BREAK] = "OP_BREAK",
    [OP_CLASS] = "OP_CLASS",
    [OP_INHERIT] = "OP_INHERIT",
    [OP_METHOD] = "OP_METHOD",
    [OP_IMPORT] = "OP_IMPORT",
    [OP_EXPORT] = "OP_EXPORT",
    [OP_GET_GLOBAL_LONG] = "OP_GET_GLOBAL_LONG",
    [OP_DEFINE_GLOBAL_LONG] = "OP_DEFINE_GLOBAL_LONG",
    [OP_SET_GLOBAL_LONG] = "OP_SET_GLOBAL_LONG",
    [OP_SET_PROPERTY_LONG] = "OP_SET_PROPERTY_LONG",
    [OP_GET_PROPERTY_LONG] = "OP_GET_PROPERTY_LONG",
    [OP_GET_SUPER_LONG] = "OP_GET_SUPER_LONG",
    [OP_SUPER_INVOKE_LONG] = "OP_SUPER_INVOKE_LONG",
    [OP_INVOKE_LONG] = "OP_INVOKE_LONG",
    [OP_CLOSURE_LONG] = "OP_CLOSURE_LONG",
    [OP_CLASS_LONG] = "OP_CLASS_LONG",
    [OP_METHOD_LONG] = "OP_METHOD_LONG",
    [OP_IMPORT_LONG] = "OP_IMPORT_LONG",
    [OP_EXPORT_LONG] = "OP_EXPORT_LONG",
    [OP_GET_LOCAL_0] = "OP_GET_LOCAL_0",
    [OP_GET_LOCAL_1] = "OP_GET_LOCAL_1",
    [OP_GET_LOCAL_2] = "OP_GET_LOCAL_2",
    [OP_GET_LOCAL_3] = "OP_GET_LOCAL_3",
    [OP_SET_LOCAL_0] = "OP_SET_LOCAL_0",
    [OP_SET_LOCAL_1] = "OP_SET_LOCAL_1",
    [OP_SET_LOCAL_2] = "OP_SET_LOCAL_2",
    [OP_SET_LOCAL_3] = "OP_SET_LOCAL_3",
    [OP_INT_0] = "OP_INT_0",
    [OP_INT_1] = "OP_INT_1",
    [OP_INT_2] = "OP_INT_2",
    [OP_JUMP_IF_NOT_LESS] = "OP_JUMP_IF_NOT_LESS",
    [OP_JUMP_IF_NOT_GREATER] = "OP_JUMP_IF_NOT_GREATER",
    [OP_JUMP_IF_NOT_EQUAL] = "OP_JUMP_IF_NOT_EQUAL",
    [OP_SET_LOCAL_POP] = "OP_SET_LOCAL_POP",
    [OP_SET_LOCAL_POP_0] = "OP_SET_LOCAL_POP_0",
    [OP_SET_LOCAL_POP_1] = "OP_SET_LOCAL_POP_1",
    [OP_SET_LOCAL_POP_2] = "OP_SET_LOCAL_POP_2",
    [OP_SET_LOCAL_POP_3] = "OP_SET_LOCAL_POP_3",
    [OP_SET_GLOBAL_POP] = "OP_SET_GLOBAL_POP",
    [OP_SET_UPVALUE_POP] = "OP_SET_UPVALUE_POP",
    [OP_SET_INDEX_POP] = "OP_SET_INDEX_POP",
};

typedef struct {
  uint8_t opcode;
  uint64_t count;
} OpcodeStat;

static int compareOpcodeStats(const void *a, const void *b) {
  uint64_t countA = ((const OpcodeStat *)a)->count;
  uint64_t countB = ((const OpcodeStat *)b)->count;
  if (countB > countA) return 1;
  if (countB < countA) return -1;
  return 0;
}

void printOpcodeStats(void) {
  uint64_t total = 0;
  OpcodeStat stats[256];
  int activeCount = 0;

  for (int i = 0; i < 256; i++) {
    if (opcodeCounts[i] > 0) {
      total += opcodeCounts[i];
      stats[activeCount].opcode = (uint8_t)i;
      stats[activeCount].count = opcodeCounts[i];
      activeCount++;
    }
  }

  if (total == 0) return;

  qsort(stats, activeCount, sizeof(OpcodeStat), compareOpcodeStats);

  fprintf(stderr, "\n┌──────────────────────────────────────────────────────────┐\n");
  fprintf(stderr, "│                   Opcode Frequency                       │\n");
  fprintf(stderr, "├──────────────────────────┬───────────────┬───────────────┤\n");
  fprintf(stderr, "│ Opcode                   │         Count │    Percentage │\n");
  fprintf(stderr, "├──────────────────────────┼───────────────┼───────────────┤\n");
  for (int i = 0; i < activeCount; i++) {
    const char *name = opcodeNames[stats[i].opcode];
    char fallback[32];
    if (name == NULL) {
      snprintf(fallback, sizeof(fallback), "UNKNOWN_%d", stats[i].opcode);
      name = fallback;
    }
    double pct = ((double)stats[i].count / (double)total) * 100.0;
    fprintf(stderr, "│ %-24s │ %13llu │ %12.2f%% │\n", name, (unsigned long long)stats[i].count, pct);
  }
  fprintf(stderr, "├──────────────────────────┼───────────────┼───────────────┤\n");
  fprintf(stderr, "│ Total Dispatches         │ %13llu │       100.00%% │\n", (unsigned long long)total);
  fprintf(stderr, "└──────────────────────────┴───────────────┴───────────────┘\n\n");
}

void resetOpcodeStats(void) { memset(opcodeCounts, 0, sizeof(opcodeCounts)); }
#endif
