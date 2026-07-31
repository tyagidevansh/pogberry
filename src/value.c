#include <stdio.h>
#include <string.h>

#include "headers/object.h"
#include "headers/memory.h"
#include "headers/value.h"

void initValueArray(ValueArray* array) {
  array->values = NULL;
  array->capacity = 0;
  array->count = 0;
}

void writeValueArray(ValueArray* array, Value value) {
  if (array->capacity < array->count + 1) {
    int oldCapacity = array->capacity;
    array->capacity = GROW_CAPACITY(oldCapacity);
    array->values = GROW_ARRAY(Value, array->values, oldCapacity, array->capacity);
  }

  array->values[array->count] = value;
  array->count++;
}

void freeValueArray(ValueArray* array) {
  FREE_ARRAY(Value, array->values, array->capacity);
  initValueArray(array);
}

void printValue(Value value) {
  switch (value.type) {
    case VAL_BOOL:
      printf(AS_BOOL(value) ? "true" : "false");
      break;
    case VAL_NIL: printf("nil"); break;
    case VAL_NUMBER: printf("%g", AS_NUMBER(value)); break;
    case VAL_OBJ: printObject(value); break;
  }
}

static bool stringsEqual(ObjString* left, ObjString* right) {
  return left->length == right->length && memcmp(left->chars, right->chars, (size_t)left->length) == 0;
}

static bool listsEqual(ObjList* left, ObjList* right) {
  if (left == right) return true;
  if (left->items.count != right->items.count) {
    return false;
  }

  for (int i = 0; i < left->items.count; i++) {
    if (!valuesEqual(left->items.values[i], right->items.values[i])) {
      return false;
    }
  }

  return true;
}

static bool objectsEqual(Value left, Value right) {
  Obj* leftObject = AS_OBJ(left);
  Obj* rightObject = AS_OBJ(right);

  if (leftObject == rightObject) return true;
  if (leftObject->type != rightObject->type) return false;

  switch (leftObject->type) {
    case OBJ_STRING:
      return stringsEqual((ObjString*)leftObject, (ObjString*)rightObject);

    case OBJ_LIST:
    return listsEqual((ObjList*)leftObject, (ObjList*)rightObject);
    
    default:
      return false;
  }
}

bool valuesEqual(Value left, Value right) {
  if (left.type != right.type) return false;


  switch (left.type) {
    case VAL_BOOL:
      return AS_BOOL(left) == AS_BOOL(right);
    
    case VAL_NUMBER:
      return AS_NUMBER(left) == AS_NUMBER(right);

    case VAL_NIL:
      return true;
    
    case VAL_OBJ:
    return objectsEqual(left, right);
  }
}