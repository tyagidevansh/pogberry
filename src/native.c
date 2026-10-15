#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>
#include <time.h>
#include <math.h>
#include <limits.h>

#include "headers/native.h"
#include "headers/memory.h"
#include "headers/object.h"
#include "headers/vm.h"

static uint32_t nextRandom(void) {
  uint32_t state = vm.randomState;
  state ^= state << 13;
  state ^= state >> 17;
  state ^= state << 5;
  vm.randomState = state;
  return state;
}

Value randNative(int argCount, Value *args) {
  if (argCount == 0) {
    return NUMBER_VAL(nextRandom() / (double)UINT32_MAX);
  }
  if (argCount != 1 || !IS_NUMBER(args[0])) {
    runtimeError("rand() expects zero arguments or one positive integer.");
    return NIL_VAL;
  }

  double bound = AS_NUMBER(args[0]);
  if (!isfinite(bound) || floor(bound) != bound || bound <= 0 || bound > INT_MAX) {
    runtimeError("rand() bound must be a positive integer.");
    return NIL_VAL;
  }

  return NUMBER_VAL(nextRandom() % (uint32_t)bound);
}

Value seedNative(int argCount, Value *args) {
  if (argCount != 1 || !IS_NUMBER(args[0])) {
    runtimeError("seed() expects one non-negative integer.");
    return NIL_VAL;
  }

  double seed = AS_NUMBER(args[0]);
  if (!isfinite(seed) || floor(seed) != seed || seed < 0 || seed > UINT32_MAX) {
    runtimeError("seed() expects one non-negative integer.");
    return NIL_VAL;
  }

  vm.randomState = (uint32_t)seed;
  if (vm.randomState == 0) vm.randomState = 0x9e3779b9u;
  return NIL_VAL;
}

Value strInputNative(int argCount, Value *args) {
  if (argCount > 1 || (argCount == 1 && !IS_STRING(args[0]))) {
    runtimeError("strInput() expects zero arguments or one prompt string.");
    return NIL_VAL;
  }
  if (argCount == 1) {
    writeVMOutput(AS_CSTRING(args[0]), (size_t)AS_STRING(args[0])->length);
  } else {
    writeVMOutput("Enter input: ", 13);
  }
  fflush(stdout);
  char buffer[256];
  if (!fgets(buffer, sizeof(buffer), stdin)) {
    return NIL_VAL;
  }
  buffer[strcspn(buffer, "\n")] = 0;
  return OBJ_VAL(copyString(buffer, strlen(buffer)));
}

int Valuecomp(const void *elem1, const void *elem2) {
  Value f = *((Value *)elem1);
  Value s = *((Value *)elem2);

  if (IS_NUMBER(f) && IS_NUMBER(s)) {
    double df = AS_NUMBER(f);
    double ds = AS_NUMBER(s);
    if (df > ds) return 1;
    if (ds > df) return -1;
    return 0;
  } else if (IS_STRING(f) && IS_STRING(s)) {
    ObjString *strF = AS_STRING(f);
    ObjString *strS = AS_STRING(s);
    return strcmp(strF->chars, strS->chars);
  } else {
    return 0;
  }
}

Value listSortNative(int argCount, Value *args) {
  if (argCount != 1 || !IS_LIST(args[0])) {
    runtimeError("sort() expects a list and no arguments.");
    return NIL_VAL;
  }

  ObjList *list = AS_LIST(args[0]);
  if (list->items.count < 2) {
    return NIL_VAL;
  }

  bool isNumber = IS_NUMBER(list->items.values[0]);
  bool isString = IS_STRING(list->items.values[0]);
  if (!isNumber && !isString) {
    runtimeError("sort() only supports lists of numbers or strings.");
    return NIL_VAL;
  }

  for (int i = 1; i < list->items.count; i++) {
    Value element = list->items.values[i];
    if ((isNumber && !IS_NUMBER(element)) || (isString && !IS_STRING(element))) {
      runtimeError("sort() requires values of one supported type.");
      return NIL_VAL;
    }
  }

  qsort(list->items.values, list->items.count, sizeof(Value), Valuecomp);
  return NIL_VAL;
}

Value listPushNative(int argCount, Value *args) {
  if (argCount != 2 || !IS_LIST(args[0])) {
    runtimeError("push() expects one value.");
    return NIL_VAL;
  }

  ObjList *list = AS_LIST(args[0]);
  writeValueArray(&list->items, args[1]);

  return NIL_VAL;
}

static bool normalizeListIndex(Value indexValue, int listCount, int *outIndex) {
  if (!IS_NUMBER(indexValue)) {
    runtimeError("List index must be a number.");
    return false;
  }

  double index = AS_NUMBER(indexValue);
  if (!isfinite(index) || floor(index) != index) {
    runtimeError("List index must be a finite integer.");
    return false;
  }

  if (index < 0) {
    index += listCount;
  }

  if (index < 0 || index >= listCount) {
    runtimeError("List index out of bounds.");
    return false;
  }

  *outIndex = (int)index;
  return true;
}

static bool normalizeInsertIndex(Value indexValue, int listCount, int *outIndex) {
  if (!IS_NUMBER(indexValue)) {
    runtimeError("List index must be a number.");
    return false;
  }

  double index = AS_NUMBER(indexValue);
  if (!isfinite(index) || floor(index) != index) {
    runtimeError("List index must be a finite integer.");
    return false;
  }

  if (index < 0) {
    index += listCount;
  }

  if (index < 0) {
    index = 0;
  } else if (index > listCount) {
    index = listCount;
  }

  *outIndex = (int)index;
  return true;
}

Value listExtendNative(int argCount, Value *args) {
  if (argCount != 2 || !IS_LIST(args[0]) || !IS_LIST(args[1])) {
    runtimeError("extend() expects two lists.");
    return NIL_VAL;
  }

  ObjList *list = AS_LIST(args[0]);
  ObjList *other = AS_LIST(args[1]);
  int otherCount = other->items.count;

  for (int i = 0; i < otherCount; i++) {
    writeValueArray(&list->items, other->items.values[i]);
  }

  return NIL_VAL;
}

Value listPopNative(int argCount, Value *args) {
  if ((argCount != 1 && argCount != 2) || !IS_LIST(args[0])) {
    runtimeError("pop() expects a list and an optional index.");
    return NIL_VAL;
  }

  ObjList *list = AS_LIST(args[0]);
  if (list->items.count == 0) {
    runtimeError("Cannot pop from an empty list.");
    return NIL_VAL;
  }

  int index = list->items.count - 1;
  if (argCount == 2 && !normalizeListIndex(args[1], list->items.count, &index)) {
    return NIL_VAL;
  }

  Value value = list->items.values[index];
  memmove(&list->items.values[index], &list->items.values[index + 1], sizeof(Value) * (list->items.count - index - 1));
  list->items.count--;

  return value;
}

Value listInsertNative(int argCount, Value *args) {
  if (argCount != 3 || !IS_LIST(args[0])) {
    runtimeError("insert() expects a list, an index, and a value.");
    return NIL_VAL;
  }

  ObjList *list = AS_LIST(args[0]);
  int index;
  if (!normalizeInsertIndex(args[1], list->items.count, &index)) {
    return NIL_VAL;
  }

  int oldCount = list->items.count;
  writeValueArray(&list->items, NIL_VAL);
  memmove(&list->items.values[index + 1], &list->items.values[index], sizeof(Value) * (oldCount - index));
  list->items.values[index] = args[2];

  return NIL_VAL;
}

Value listRemoveNative(int argCount, Value *args) {
  if (argCount != 2 || !IS_LIST(args[0])) {
    runtimeError("remove() expects a list and a value.");
    return NIL_VAL;
  }

  ObjList *list = AS_LIST(args[0]);
  for (int i = 0; i < list->items.count; i++) {
    if (!valuesEqual(list->items.values[i], args[1])) {
      if (vm.hadRuntimeError) return NIL_VAL;
      continue;
    }

    memmove(&list->items.values[i], &list->items.values[i + 1], sizeof(Value) * (list->items.count - i - 1));
    list->items.count--;
    return NIL_VAL;
  }

  runtimeError("List value not found.");
  return NIL_VAL;
}

Value listRemoveAtNative(int argCount, Value *args) {
  if (argCount != 2 || !IS_LIST(args[0])) {
    runtimeError("removeAt() expects a list and an index.");
    return NIL_VAL;
  }

  ObjList *list = AS_LIST(args[0]);
  int index;
  if (!normalizeListIndex(args[1], list->items.count, &index)) {
    return NIL_VAL;
  }

  Value value = list->items.values[index];
  memmove(&list->items.values[index], &list->items.values[index + 1], sizeof(Value) * (list->items.count - index - 1));
  list->items.count--;

  return value;
}

Value listClearNative(int argCount, Value *args) {
  if (argCount != 1 || !IS_LIST(args[0])) {
    runtimeError("clear() expects a list.");
    return NIL_VAL;
  }

  AS_LIST(args[0])->items.count = 0;
  return NIL_VAL;
}

Value listCopyNative(int argCount, Value *args) {
  if (argCount != 1 || !IS_LIST(args[0])) {
    runtimeError("copy() expects a list.");
    return NIL_VAL;
  }

  ObjList *source = AS_LIST(args[0]);
  ObjList *copy = newList();

  // Keep the new list reachable if growing its backing array triggers GC.
  push(OBJ_VAL(copy));
  for (int i = 0; i < source->items.count; i++) {
    writeValueArray(&copy->items, source->items.values[i]);
  }
  return pop();
}

Value listIndexNative(int argCount, Value *args) {
  if (argCount != 2 || !IS_LIST(args[0])) {
    runtimeError("index() expects a list and a value.");
    return NIL_VAL;
  }

  ObjList *list = AS_LIST(args[0]);
  for (int i = 0; i < list->items.count; i++) {
    if (valuesEqual(list->items.values[i], args[1])) {
      return NUMBER_VAL(i);
    }
    if (vm.hadRuntimeError) return NIL_VAL;
  }

  runtimeError("List value not found.");
  return NIL_VAL;
}

Value listCountNative(int argCount, Value *args) {
  if (argCount != 2 || !IS_LIST(args[0])) {
    runtimeError("count() expects a list and a value.");
    return NIL_VAL;
  }

  ObjList *list = AS_LIST(args[0]);
  int count = 0;
  for (int i = 0; i < list->items.count; i++) {
    if (valuesEqual(list->items.values[i], args[1])) {
      count++;
    }
    if (vm.hadRuntimeError) return NIL_VAL;
  }

  return NUMBER_VAL(count);
}

Value listReverseNative(int argCount, Value *args) {
  if (argCount != 1 || !IS_LIST(args[0])) {
    runtimeError("reverse() expects a list.");
    return NIL_VAL;
  }

  ObjList *list = AS_LIST(args[0]);
  for (int left = 0, right = list->items.count - 1; left < right; left++, right--) {
    Value temporary = list->items.values[left];
    list->items.values[left] = list->items.values[right];
    list->items.values[right] = temporary;
  }

  return NIL_VAL;
}

Value stringSplitNative(int argCount, Value *args) {
  if (argCount != 2 || !IS_STRING(args[1])) {
    runtimeError("split() expects a separator string.");
    return NIL_VAL;
  }

  ObjString *source = AS_STRING(args[0]);
  ObjString *separator = AS_STRING(args[1]);
  if (separator->length == 0) {
    runtimeError("split() separator must not be empty.");
    return NIL_VAL;
  }

  ObjList *parts = newList();
  push(OBJ_VAL(parts));
  int begin = 0;
  for (int i = 0; i <= source->length - separator->length; i++) {
    if (memcmp(source->chars + i, separator->chars, (size_t)separator->length) == 0) {
      ObjString *part = copyString(source->chars + begin, i - begin);
      push(OBJ_VAL(part));
      writeValueArray(&parts->items, OBJ_VAL(part));
      pop();
      begin = i + separator->length;
      i = begin - 1;
    }
  }
  ObjString *tail = copyString(source->chars + begin, source->length - begin);
  push(OBJ_VAL(tail));
  writeValueArray(&parts->items, OBJ_VAL(tail));
  pop();
  return pop();
}

Value stringFindNative(int argCount, Value *args) {
  if (argCount != 2 || !IS_STRING(args[1])) {
    runtimeError("find() expects a string to find.");
    return NIL_VAL;
  }

  ObjString *source = AS_STRING(args[0]);
  ObjString *needle = AS_STRING(args[1]);
  for (int i = 0; i <= source->length - needle->length; i++) {
    if (memcmp(source->chars + i, needle->chars, (size_t)needle->length) == 0) return NUMBER_VAL(i);
  }
  return NUMBER_VAL(-1);
}

Value stringSubstrNative(int argCount, Value *args) {
  if ((argCount != 2 && argCount != 3) || !IS_NUMBER(args[1]) || (argCount == 3 && !IS_NUMBER(args[2]))) {
    runtimeError("substr() expects a start index and an optional length.");
    return NIL_VAL;
  }

  ObjString *source = AS_STRING(args[0]);
  double start = AS_NUMBER(args[1]);
  if (!isfinite(start) || floor(start) != start || start < 0 || start > source->length) {
    runtimeError("substr() start out of bounds.");
    return NIL_VAL;
  }

  int count = source->length - (int)start;
  if (argCount == 3) {
    double length = AS_NUMBER(args[2]);
    if (!isfinite(length) || floor(length) != length || length < 0) {
      runtimeError("substr() length must be a non-negative finite integer.");
      return NIL_VAL;
    }
    if (length < count) count = (int)length;
  }
  return OBJ_VAL(copyString(source->chars + (int)start, count));
}

Value stringTrimNative(int argCount, Value *args) {
  if (argCount != 1) {
    runtimeError("trim() expects no arguments.");
    return NIL_VAL;
  }

  ObjString *source = AS_STRING(args[0]);
  int begin = 0;
  int end = source->length;
  while (begin < end && isspace((unsigned char)source->chars[begin])) begin++;
  while (end > begin && isspace((unsigned char)source->chars[end - 1])) end--;
  return OBJ_VAL(copyString(source->chars + begin, end - begin));
}

Value mapHasNative(int argCount, Value *args) {
  if (argCount != 2 || !IS_HASHMAP(args[0])) {
    runtimeError("has() expects a map and a key.");
    return NIL_VAL;
  }
  if (!mapKeyIsValid(args[1])) {
    runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
    return NIL_VAL;
  }

  Value value;
  return BOOL_VAL(mapGet(&AS_HASHMAP(args[0])->items, args[1], &value));
}

Value mapGetNative(int argCount, Value *args) {
  if (argCount != 3 || !IS_HASHMAP(args[0])) {
    runtimeError("get() expects a map, a key, and a default value.");
    return NIL_VAL;
  }
  if (!mapKeyIsValid(args[1])) {
    runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
    return NIL_VAL;
  }

  Value value;
  if (mapGet(&AS_HASHMAP(args[0])->items, args[1], &value)) {
    return value;
  }
  return args[2];
}

Value mapDeleteNative(int argCount, Value *args) {
  if (argCount != 2 || !IS_HASHMAP(args[0])) {
    runtimeError("delete() expects a map and a key.");
    return NIL_VAL;
  }
  if (!mapKeyIsValid(args[1])) {
    runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
    return NIL_VAL;
  }

  return BOOL_VAL(mapDelete(&AS_HASHMAP(args[0])->items, args[1]));
}

Value mapClearNative(int argCount, Value *args) {
  if (argCount != 1 || !IS_HASHMAP(args[0])) {
    runtimeError("clear() expects a map.");
    return NIL_VAL;
  }

  mapClear(&AS_HASHMAP(args[0])->items);
  return NIL_VAL;
}

Value lenNative(int argCount, Value *args) {
  if (argCount != 1) {
    runtimeError("len() expects one value.");
    return NIL_VAL;
  }

  if (IS_STRING(args[0])) return NUMBER_VAL(AS_STRING(args[0])->length);
  if (IS_LIST(args[0])) return NUMBER_VAL(AS_LIST(args[0])->items.count);
  if (IS_HASHMAP(args[0])) return NUMBER_VAL(mapCount(&AS_HASHMAP(args[0])->items));

  runtimeError("len() expects a string, list, or map.");
  return NIL_VAL;
}

Value typeNative(int argCount, Value *args) {
  if (argCount != 1) {
    runtimeError("type() expects one value.");
    return NIL_VAL;
  }

  const char *name;
  if (IS_NIL(args[0]))
    name = "nil";
  else if (IS_BOOL(args[0]))
    name = "bool";
  else if (IS_NUMBER(args[0]))
    name = "number";
  else if (IS_STRING(args[0]))
    name = "string";
  else if (IS_LIST(args[0]))
    name = "list";
  else if (IS_HASHMAP(args[0]))
    name = "map";
  else if (IS_CLOSURE(args[0]))
    name = "function";
  else if (IS_NATIVE(args[0]))
    name = "native";
  else if (IS_CLASS(args[0]))
    name = "class";
  else if (IS_INSTANCE(args[0]))
    name = "instance";
  else if (IS_MODULE(args[0]))
    name = "module";
  else if (IS_VEC2(args[0]))
    name = "vec2";
  else if (IS_VEC3(args[0]))
    name = "vec3";
  else if (IS_VEC4(args[0]))
    name = "vec4";
  else if (IS_MAT4(args[0]))
    name = "mat4";
  else if (IS_RESOURCE(args[0]))
    name = AS_RESOURCE(args[0])->typeName;
  else
    name = "bound_method";

  return OBJ_VAL(copyString(name, strlen(name)));
}

Value strNative(int argCount, Value *args) {
  if (argCount != 1) {
    runtimeError("str() expects one value.");
    return NIL_VAL;
  }

  return OBJ_VAL(valueToString(args[0]));
}

Value numNative(int argCount, Value *args) {
  if (argCount != 1 || !IS_STRING(args[0])) {
    runtimeError("num() expects one string.");
    return NIL_VAL;
  }

  ObjString *source = AS_STRING(args[0]);
  char *end = NULL;
  double value = strtod(source->chars, &end);
  const char *rest = end;
  while (*rest != '\0' && isspace((unsigned char)*rest)) rest++;
  if (end == source->chars || *rest != '\0' || !isfinite(value)) {
    runtimeError("num() could not parse '%s'.", source->chars);
    return NIL_VAL;
  }
  return NUMBER_VAL(value);
}

static bool vecNumbers(const Value *args, int count) {
  for (int i = 0; i < count; i++) {
    if (!IS_NUMBER(args[i]) || !isfinite(AS_NUMBER(args[i]))) return false;
  }
  return true;
}

Value vec2Native(int argCount, Value *args) {
  if (argCount != 2 || !vecNumbers(args, 2)) {
    runtimeError("vec2() expects 2 finite numbers.");
    return NIL_VAL;
  }
  return OBJ_VAL(newVec2(AS_NUMBER(args[0]), AS_NUMBER(args[1])));
}

Value vec3Native(int argCount, Value *args) {
  if (argCount != 3 || !vecNumbers(args, 3)) {
    runtimeError("vec3() expects 3 finite numbers.");
    return NIL_VAL;
  }
  return OBJ_VAL(newVec3(AS_NUMBER(args[0]), AS_NUMBER(args[1]), AS_NUMBER(args[2])));
}

Value vec4Native(int argCount, Value *args) {
  if (argCount != 4 || !vecNumbers(args, 4)) {
    runtimeError("vec4() expects 4 finite numbers.");
    return NIL_VAL;
  }
  return OBJ_VAL(newVec4(AS_NUMBER(args[0]), AS_NUMBER(args[1]), AS_NUMBER(args[2]), AS_NUMBER(args[3])));
}

Value vecDotNative(int argCount, Value *args) {
  if (argCount != 2) {
    runtimeError("dot() expects a vector.");
    return NIL_VAL;
  }
  int dims = vecDimensions(args[0]);
  if (dims == 0 || vecDimensions(args[1]) != dims) {
    runtimeError("dot() expects a vector of the same size.");
    return NIL_VAL;
  }
  double total = 0;
  for (int i = 0; i < dims; i++) total = total + vecComponent(args[0], i) * vecComponent(args[1], i);
  return NUMBER_VAL(total);
}

Value vecLengthNative(int argCount, Value *args) {
  if (argCount != 1) {
    runtimeError("length() expects no arguments.");
    return NIL_VAL;
  }
  int dims = vecDimensions(args[0]);
  double total = 0;
  for (int i = 0; i < dims; i++) total = total + vecComponent(args[0], i) * vecComponent(args[0], i);
  return NUMBER_VAL(sqrt(total));
}

Value vecNormalizeNative(int argCount, Value *args) {
  if (argCount != 1) {
    runtimeError("normalize() expects no arguments.");
    return NIL_VAL;
  }
  int dims = vecDimensions(args[0]);
  double total = 0;
  for (int i = 0; i < dims; i++) total = total + vecComponent(args[0], i) * vecComponent(args[0], i);
  double length = sqrt(total);
  if (length == 0) {
    runtimeError("Cannot normalize a zero-length vector.");
    return NIL_VAL;
  }
  double parts[4] = {0, 0, 0, 0};
  for (int i = 0; i < dims; i++) parts[i] = vecComponent(args[0], i) / length;
  if (dims == 2) return OBJ_VAL(newVec2(parts[0], parts[1]));
  if (dims == 3) return OBJ_VAL(newVec3(parts[0], parts[1], parts[2]));
  return OBJ_VAL(newVec4(parts[0], parts[1], parts[2], parts[3]));
}

Value mat4Native(int argCount, Value *args) {
  (void)args;
  if (argCount != 0) {
    runtimeError("mat4() expects no arguments.");
    return NIL_VAL;
  }
  return OBJ_VAL(newMat4Identity());
}

Value matTranslateNative(int argCount, Value *args) {
  if ((argCount != 3 && argCount != 4) || !IS_NUMBER(args[1]) || !isfinite(AS_NUMBER(args[1])) ||
      !IS_NUMBER(args[2]) || !isfinite(AS_NUMBER(args[2]))) {
    runtimeError("translate() expects x, y, and an optional z.");
    return NIL_VAL;
  }
  double z = 0;
  if (argCount == 4) {
    if (!IS_NUMBER(args[3]) || !isfinite(AS_NUMBER(args[3]))) {
      runtimeError("translate() expects x, y, and an optional z.");
      return NIL_VAL;
    }
    z = AS_NUMBER(args[3]);
  }
  double cells[16] = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, AS_NUMBER(args[1]), AS_NUMBER(args[2]), z, 1};
  double out[16];
  mat4Multiply(AS_MAT4(args[0])->m, cells, out);
  return OBJ_VAL(newMat4From(out));
}

Value matScaleNative(int argCount, Value *args) {
  if (argCount < 2 || argCount > 4) {
    runtimeError("scale() expects a factor, or x, y, and an optional z.");
    return NIL_VAL;
  }
  double x = 0;
  double y = 0;
  double z = 1;
  if (argCount == 2) {
    if (!IS_NUMBER(args[1]) || !isfinite(AS_NUMBER(args[1]))) {
      runtimeError("scale() expects a factor, or x, y, and an optional z.");
      return NIL_VAL;
    }
    x = AS_NUMBER(args[1]);
    y = x;
    z = x;
  } else {
    if (!IS_NUMBER(args[1]) || !isfinite(AS_NUMBER(args[1])) || !IS_NUMBER(args[2]) ||
        !isfinite(AS_NUMBER(args[2]))) {
      runtimeError("scale() expects a factor, or x, y, and an optional z.");
      return NIL_VAL;
    }
    x = AS_NUMBER(args[1]);
    y = AS_NUMBER(args[2]);
    if (argCount == 4) {
      if (!IS_NUMBER(args[3]) || !isfinite(AS_NUMBER(args[3]))) {
        runtimeError("scale() expects a factor, or x, y, and an optional z.");
        return NIL_VAL;
      }
      z = AS_NUMBER(args[3]);
    }
  }
  double cells[16] = {x, 0, 0, 0, 0, y, 0, 0, 0, 0, z, 0, 0, 0, 0, 1};
  double out[16];
  mat4Multiply(AS_MAT4(args[0])->m, cells, out);
  return OBJ_VAL(newMat4From(out));
}

Value matRotateXNative(int argCount, Value *args) {
  if (argCount != 2 || !IS_NUMBER(args[1]) || !isfinite(AS_NUMBER(args[1]))) {
    runtimeError("rotateX() expects an angle in radians.");
    return NIL_VAL;
  }
  double cosine = cos(AS_NUMBER(args[1]));
  double sine = sin(AS_NUMBER(args[1]));
  double cells[16] = {1, 0, 0, 0, 0, cosine, sine, 0, 0, -sine, cosine, 0, 0, 0, 0, 1};
  double out[16];
  mat4Multiply(AS_MAT4(args[0])->m, cells, out);
  return OBJ_VAL(newMat4From(out));
}

Value matRotateYNative(int argCount, Value *args) {
  if (argCount != 2 || !IS_NUMBER(args[1]) || !isfinite(AS_NUMBER(args[1]))) {
    runtimeError("rotateY() expects an angle in radians.");
    return NIL_VAL;
  }
  double cosine = cos(AS_NUMBER(args[1]));
  double sine = sin(AS_NUMBER(args[1]));
  double cells[16] = {cosine, 0, -sine, 0, 0, 1, 0, 0, sine, 0, cosine, 0, 0, 0, 0, 1};
  double out[16];
  mat4Multiply(AS_MAT4(args[0])->m, cells, out);
  return OBJ_VAL(newMat4From(out));
}

Value matRotateZNative(int argCount, Value *args) {
  if (argCount != 2 || !IS_NUMBER(args[1]) || !isfinite(AS_NUMBER(args[1]))) {
    runtimeError("rotateZ() expects an angle in radians.");
    return NIL_VAL;
  }
  double cosine = cos(AS_NUMBER(args[1]));
  double sine = sin(AS_NUMBER(args[1]));
  double cells[16] = {cosine, sine, 0, 0, -sine, cosine, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1};
  double out[16];
  mat4Multiply(AS_MAT4(args[0])->m, cells, out);
  return OBJ_VAL(newMat4From(out));
}

Value joinNative(int argCount, Value *args) {
  if (argCount < 1 || argCount > 2 || !IS_LIST(args[0])) {
    runtimeError("join() expects a list and an optional delimiter string.");
    return NIL_VAL;
  }

  ObjList *list = AS_LIST(args[0]);
  ObjString *delim = NULL;
  if (argCount == 2) {
    if (!IS_STRING(args[1])) {
      runtimeError("join() delimiter must be a string.");
      return NIL_VAL;
    }
    delim = AS_STRING(args[1]);
  }

  int itemCount = list->items.count;
  if (itemCount == 0) {
    return OBJ_VAL(copyString("", 0));
  }

  int delimLen = delim != NULL ? delim->length : 0;
  const char *delimChars = delim != NULL ? delim->chars : "";

  ObjString **elementStrings = ALLOCATE(ObjString *, itemCount);
  int totalLength = 0;

  for (int i = 0; i < itemCount; i++) {
    Value val = list->items.values[i];
    ObjString *s = IS_STRING(val) ? AS_STRING(val) : valueToString(val);
    elementStrings[i] = s;
    totalLength += s->length;
    if (i > 0) totalLength += delimLen;
  }

  char *chars = ALLOCATE(char, totalLength + 1);
  int offset = 0;

  for (int i = 0; i < itemCount; i++) {
    if (i > 0 && delimLen > 0) {
      memcpy(chars + offset, delimChars, (size_t)delimLen);
      offset += delimLen;
    }
    ObjString *s = elementStrings[i];
    if (s->length > 0) {
      memcpy(chars + offset, s->chars, (size_t)s->length);
      offset += s->length;
    }
  }
  chars[totalLength] = '\0';
  FREE_ARRAY(ObjString *, elementStrings, itemCount);

  return OBJ_VAL(takeString(chars, totalLength));
}

void defineNative(const char *name, NativeFn function) {
  ObjString *nameObj = copyString(name, (int)strlen(name));
  push(OBJ_VAL(nameObj));
  push(OBJ_VAL(newNative(function)));

  tableSet(&vm.globals, nameObj, vm.stackTop[-1]);
  pop();
  pop();
}

void defineHostNative(const char *name, PbNativeFn function, void *userData) {
  ObjString *nameObj = copyString(name, (int)strlen(name));
  push(OBJ_VAL(nameObj));
  push(OBJ_VAL(newHostNative(function, userData)));

  tableSet(&vm.globals, nameObj, vm.stackTop[-1]);
  pop();
  pop();
}
