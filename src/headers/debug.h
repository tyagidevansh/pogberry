#ifndef clox_debug_h
#define clox_debug_h

#include <stdint.h>
#include "chunk.h"

void disassembleChunk(Chunk *chunk, const char *name);
int disassembleInstruction(Chunk *chunk, int offset);

#ifdef DEBUG_OPCODE_STATS
extern uint64_t opcodeCounts[256];
void printOpcodeStats(void);
void resetOpcodeStats(void);
#else
static inline void printOpcodeStats(void) {}
static inline void resetOpcodeStats(void) {}
#endif

#endif // !clox_debug_h