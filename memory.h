#ifndef clox_memory_h
#define clox_memory_h

#include "common.h"

// macro to resize arrays, returns '8' if dynamic array is empty rn, otherwise double
#define GROW_CAPACITY(capacity) \
  ((capacity) < 8 ? 8 : (capacity * 2))

// macro to call reallocate, allows reuse of reallocate and type safe!
#define GROW_ARRAY(type, pointer, oldCount, newCount) \
  (type*)reallocate(pointer, sizeof(type) * (oldCount), \
    sizeof(type) * (newCount))

#define FREE_ARRAY(type, pointer, oldCount) \
reallocate(pointer, sizeof(type) * (oldCount), 0)

void* reallocate(void* pointer, size_t oldSize, size_t newSize);

#endif // !clox_memory_h