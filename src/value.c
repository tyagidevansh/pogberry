#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "headers/object.h"
#include "headers/memory.h"
#include "headers/value.h"
#include "headers/vm.h"

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
  ObjString* rendered = valueToString(value);
  fwrite(rendered->chars, sizeof(char), (size_t)rendered->length, stdout);
}

static bool stringsEqual(ObjString* left, ObjString* right) {
  return left->length == right->length && memcmp(left->chars, right->chars, (size_t)left->length) == 0;
}

#define EQUALITY_MAX_DEPTH 256

typedef struct {
  Obj* left[EQUALITY_MAX_DEPTH];
  Obj* right[EQUALITY_MAX_DEPTH];
  int count;
} EqualityContext;

static bool valuesEqualInternal(Value left, Value right, EqualityContext* context);

static bool beginContainerComparison(EqualityContext* context, Obj* left, Obj* right) {
  for (int i = 0; i < context->count; i++) {
    if ((context->left[i] == left && context->right[i] == right) ||
        (context->left[i] == right && context->right[i] == left)) {
      runtimeError("Cannot compare recursive containers.");
      return false;
    }
  }

  if (context->count == EQUALITY_MAX_DEPTH) {
    runtimeError("Collection equality exceeded the maximum depth.");
    return false;
  }

  context->left[context->count] = left;
  context->right[context->count] = right;
  context->count++;
  return true;
}

static bool listsEqual(ObjList* left, ObjList* right, EqualityContext* context) {
  if (left->items.count != right->items.count) return false;
  if (!beginContainerComparison(context, (Obj*)left, (Obj*)right)) return false;

  bool equal = true;
  for (int i = 0; i < left->items.count; i++) {
    if (!valuesEqualInternal(left->items.values[i], right->items.values[i], context)) {
      equal = false;
      break;
    }
  }

  context->count--;
  return equal;
}

static bool hashmapsEqual(ObjHashmap* left, ObjHashmap* right, EqualityContext* context) {
  if (mapCount(&left->items) != mapCount(&right->items)) return false;
  if (!beginContainerComparison(context, (Obj*)left, (Obj*)right)) return false;

  bool equal = true;
  for (int index = mapFirstEntry(&left->items); index != -1;
       index = mapNextEntry(&left->items, index)) {
    MapEntry* entry = mapEntryAt(&left->items, index);
    Value rightValue;
    if (!mapGet(&right->items, entry->key, &rightValue) ||
        !valuesEqualInternal(entry->value, rightValue, context)) {
      equal = false;
      break;
    }
  }

  context->count--;
  return equal;
}

static bool objectsEqual(Value left, Value right, EqualityContext* context) {
  Obj* leftObject = AS_OBJ(left);
  Obj* rightObject = AS_OBJ(right);

  if (leftObject == rightObject) return true;
  if (leftObject->type != rightObject->type) return false;

  switch (leftObject->type) {
    case OBJ_STRING:
      return stringsEqual((ObjString*)leftObject, (ObjString*)rightObject);

    case OBJ_LIST:
      return listsEqual((ObjList*)leftObject, (ObjList*)rightObject, context);
    
    case OBJ_HASHMAP:
      return hashmapsEqual((ObjHashmap*)leftObject, (ObjHashmap*)rightObject, context);
    
    default:
      return false;
  }
}

static bool valuesEqualInternal(Value left, Value right, EqualityContext* context) {
  if (left.type != right.type) return false;

  switch (left.type) {
    case VAL_BOOL:
      return AS_BOOL(left) == AS_BOOL(right);
    
    case VAL_NUMBER:
      return AS_NUMBER(left) == AS_NUMBER(right);

    case VAL_NIL:
      return true;
    
    case VAL_OBJ:
      return objectsEqual(left, right, context);
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

bool valuesEqual(Value left, Value right) {
  EqualityContext context = {0};
  return valuesEqualInternal(left, right, &context);
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

  if (object->type == OBJ_CLOSURE) {
    ObjFunction* function = AS_CLOSURE(value)->function;
    if (function->name == NULL) {
      appendCString(builder, "<script>");
    } else {
      appendCString(builder, "<fn ");
      appendChars(builder, function->name->chars, function->name->length);
      appendCString(builder, ">");
    }
    return;
  }

  if (object->type == OBJ_UPVALUE) {
    appendCString(builder, "<upvalue>");
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
  appendChars(builder, method->method->function->name->chars,
              method->method->function->name->length);
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
