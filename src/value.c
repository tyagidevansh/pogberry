#include <stdio.h>
#include <stdlib.h>
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

static bool hashmapsEqual(ObjHashmap* left, ObjHashmap* right) {
  if (left == right) return true;

  if (mapCount(&left->items) != mapCount(&right->items)) return false;

  for (int index = mapFirstEntry(&left->items); index != -1;
       index = mapNextEntry(&left->items, index)) {
    MapEntry* entry = mapEntryAt(&left->items, index);

    Value rightValue;
    if (!mapGet(&right->items, entry->key, &rightValue)) return false;

    if (!valuesEqual(entry->value, rightValue)) return false;
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
    
    case OBJ_HASHMAP:
      return hashmapsEqual((ObjHashmap*)leftObject, (ObjHashmap*)rightObject);
    
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

  return false;
}

typedef struct {
  char* chars;
  int count;
  int capacity;
  Obj** active;
  int activeCount;
  int activeCapacity;
} StringBuilder;

static void appendChars(StringBuilder* builder, const char* chars, int length) {
  if (builder->count + length + 1 > builder->capacity) {
    int capacity = builder->capacity < 8 ? 8 : builder->capacity;
    while (builder->count + length + 1 > capacity) capacity *= 2;
    char* charsBuffer = (char*)realloc(builder->chars, (size_t)capacity);
    if (charsBuffer == NULL) exit(1);
    builder->chars = charsBuffer;
    builder->capacity = capacity;
  }

  memcpy(builder->chars + builder->count, chars, (size_t)length);
  builder->count += length;
  builder->chars[builder->count] = '\0';
}

static void appendCString(StringBuilder* builder, const char* chars) {
  appendChars(builder, chars, (int)strlen(chars));
}

static bool isActive(StringBuilder* builder, Obj* object) {
  for (int i = 0; i < builder->activeCount; i++) {
    if (builder->active[i] == object) return true;
  }
  return false;
}

static void pushActive(StringBuilder* builder, Obj* object) {
  if (builder->activeCount == builder->activeCapacity) {
    int capacity = builder->activeCapacity < 8 ? 8 : builder->activeCapacity * 2;
    Obj** active = (Obj**)realloc(builder->active, sizeof(Obj*) * (size_t)capacity);
    if (active == NULL) exit(1);
    builder->active = active;
    builder->activeCapacity = capacity;
  }
  builder->active[builder->activeCount++] = object;
}

static void appendValue(StringBuilder* builder, Value value) {
  char number[32];

  switch (value.type) {
    case VAL_BOOL:
      appendCString(builder, AS_BOOL(value) ? "true" : "false");
      return;
    case VAL_NIL:
      appendCString(builder, "nil");
      return;
    case VAL_NUMBER:
      snprintf(number, sizeof(number), "%g", AS_NUMBER(value));
      appendCString(builder, number);
      return;
    case VAL_OBJ:
      break;
  }

  Obj* object = AS_OBJ(value);
  if (object->type == OBJ_STRING) {
    appendChars(builder, AS_STRING(value)->chars, AS_STRING(value)->length);
    return;
  }

  if (object->type == OBJ_LIST) {
    if (isActive(builder, object)) {
      appendCString(builder, "<cycle>");
      return;
    }
    pushActive(builder, object);
    ObjList* list = AS_LIST(value);
    appendCString(builder, "[");
    for (int i = 0; i < list->items.count; i++) {
      if (i > 0) appendCString(builder, ", ");
      appendValue(builder, list->items.values[i]);
    }
    appendCString(builder, "]");
    builder->activeCount--;
    return;
  }

  if (object->type == OBJ_HASHMAP) {
    if (isActive(builder, object)) {
      appendCString(builder, "<cycle>");
      return;
    }
    pushActive(builder, object);
    ObjHashmap* map = AS_HASHMAP(value);
    appendCString(builder, "{");
    bool first = true;
    for (int index = mapFirstEntry(&map->items); index != -1;
         index = mapNextEntry(&map->items, index)) {
      MapEntry* entry = mapEntryAt(&map->items, index);
      if (!first) appendCString(builder, ", ");
      first = false;
      appendValue(builder, entry->key);
      appendCString(builder, ": ");
      appendValue(builder, entry->value);
    }
    appendCString(builder, "}");
    builder->activeCount--;
    return;
  }

  if (object->type == OBJ_FUNCTION) {
    ObjFunction* function = AS_FUNCTION(value);
    if (function->name == NULL) {
      appendCString(builder, "<script>");
    } else {
      appendCString(builder, "<fn ");
      appendChars(builder, function->name->chars, function->name->length);
      appendCString(builder, ">");
    }
    return;
  }

  if (object->type == OBJ_NATIVE) {
    appendCString(builder, "<native fn>");
    return;
  }

  if (object->type == OBJ_CLASS) {
    ObjClass* klass = AS_CLASS(value);
    appendChars(builder, klass->name->chars, klass->name->length);
    return;
  }

  if (object->type == OBJ_INSTANCE) {
    ObjInstance* instance = AS_INSTANCE(value);
    appendChars(builder, instance->klass->name->chars, instance->klass->name->length);
    appendCString(builder, " instance");
    return;
  }

  ObjBoundMethod* method = AS_BOUND_METHOD(value);
  appendCString(builder, "<fn ");
  appendChars(builder, method->method->name->chars, method->method->name->length);
  appendCString(builder, ">");
}

ObjString* valueToString(Value value) {
  StringBuilder builder = {0};
  appendValue(&builder, value);
  ObjString* string = copyString(builder.chars, builder.count);
  free(builder.chars);
  free(builder.active);
  return string;
}
