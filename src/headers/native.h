#ifndef clox_native_h
#define clox_native_h

#include "value.h"
#include "object.h"

// ordinary C native function implementations
Value clockNative(int argCount, Value *args);
Value randNative(int argCount, Value *args);
Value floorNative(int argCount, Value *args);
Value strInputNative(int argCount, Value *args);
Value sqrtNative(int argCount, Value *args);
Value absNative(int argCount, Value *args);
Value listSortNative(int argCount, Value *args);
Value listPushNative(int argCount, Value *args);
Value listExtendNative(int argCount, Value *args);
Value listPopNative(int argCount, Value *args);
Value listInsertNative(int argCount, Value *args);
Value listRemoveNative(int argCount, Value *args);
Value listRemoveAtNative(int argCount, Value *args);
Value listClearNative(int argCount, Value *args);
Value listCopyNative(int argCount, Value *args);
Value listIndexNative(int argCount, Value *args);
Value listCountNative(int argCount, Value *args);
Value listReverseNative(int argCount, Value *args);
Value mapHasNative(int argCount, Value *args);
Value mapGetNative(int argCount, Value *args);
Value mapDeleteNative(int argCount, Value *args);
Value mapClearNative(int argCount, Value *args);
Value lenNative(int argCount, Value *args);
Value typeNative(int argCount, Value *args);
Value strNative(int argCount, Value *args);
Value getTime(int argCount, Value* args);

void defineNative(const char *name, NativeFn function);

// comparison functions for sorting
int Valuecomp(const void *elem1, const void *elem2);

#endif
