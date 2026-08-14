#include <stdio.h>
#include <string.h>

#include "headers/memory.h"
#include "headers/object.h"
#include "headers/table.h"
#include "headers/value.h"
#include "headers/vm.h"

#define ALLOCATE_OBJ(type, objectType) \
  (type*)allocateObject(sizeof(type), objectType)

static Obj* allocateObject(size_t size, ObjType type) {
  Obj* object = (Obj*)reallocate(NULL, 0, size);
  object->type = type;
  object->isMarked = false;
  object->next = vm.objects;
  vm.objects = object;
#ifdef DEBUG_LOG_GC
  printf("%p allocate %zu for %d\n", (void*)object, size, type);
#endif
  return object;
}

ObjFunction* newFunction() {
  ObjFunction* function = ALLOCATE_OBJ(ObjFunction, OBJ_FUNCTION);
  function->arity = 0;
  function->upvalueCount = 0;
  function->name = NULL;
  function->sourceName = NULL;
  initChunk(&function->chunk);

  return function;
}

ObjClosure* newClosure(ObjFunction* function) {
  ObjUpvalue** upvalues = ALLOCATE(ObjUpvalue*, function->upvalueCount);
  for (int i = 0; i < function->upvalueCount; i++) upvalues[i] = NULL;

  ObjClosure* closure = ALLOCATE_OBJ(ObjClosure, OBJ_CLOSURE);
  closure->function = function;
  closure->upvalues = upvalues;
  closure->upvalueCount = function->upvalueCount;
  closure->module = NULL;
  return closure;
}

ObjUpvalue* newUpvalue(Value* slot) {
  ObjUpvalue* upvalue = ALLOCATE_OBJ(ObjUpvalue, OBJ_UPVALUE);
  upvalue->location = slot;
  upvalue->closed = NIL_VAL;
  upvalue->next = NULL;
  return upvalue;
}

ObjNative* newNative(NativeFn function) {
  ObjNative* native = ALLOCATE_OBJ(ObjNative, OBJ_NATIVE);
  native->legacyFunction = function;
  native->hostFunction = NULL;
  native->userData = NULL;
  return native;
}

ObjNative* newHostNative(PbNativeFn function, void* userData) {
  ObjNative* native = ALLOCATE_OBJ(ObjNative, OBJ_NATIVE);
  native->legacyFunction = NULL;
  native->hostFunction = function;
  native->userData = userData;
  return native;
}

static ObjString* allocateString(char* chars, int length, uint32_t hash) {
  ObjString* string = ALLOCATE_OBJ(ObjString, OBJ_STRING);
  string->length = length;
  string->chars = chars;
  string->hash = hash;

  push(OBJ_VAL(string));
  tableSet(&vm.strings, string, NIL_VAL); // val nil as we only care about the key (string)
  pop();
  return string;
}

static uint32_t hashString(const char* key, int length) {
  uint32_t hash = 2166136261u;
  for (int i = 0; i < length; i++) {
    hash ^= (uint8_t)key[i];
    hash *= 16777619;
  }
  return hash;
}

ObjString* takeString(char* chars, int length) {
  uint32_t hash = hashString(chars, length);
  ObjString* interned = tableFindString(&vm.strings, chars, length, hash);

  if (interned != NULL) {
    FREE_ARRAY(char, chars, length + 1);
    return interned;
  }

  return allocateString(chars, length, hash);
}

ObjString* copyString(const char* chars, int length) {
  uint32_t hash = hashString(chars, length);
  ObjString* interned = tableFindString(&vm.strings, chars, length, hash);
  if (interned != NULL) return interned;
  char* heapChars = ALLOCATE(char, length + 1);
  memcpy(heapChars, chars, length);
  heapChars[length] = '\0';
  return allocateString(heapChars, length, hash);
}

ObjList* newList() {
  ObjList* list = ALLOCATE_OBJ(ObjList, OBJ_LIST);
  // push(OBJ_VAL(list));
  initValueArray(&list->items);
  return list;
}

ObjHashmap* newHashmap() {
  ObjHashmap* hashmap = ALLOCATE_OBJ(ObjHashmap, OBJ_HASHMAP);
  initMap(&hashmap->items);
  return hashmap;
}

ObjClass* newClass(ObjString* name) {
  ObjClass* klass = ALLOCATE_OBJ(ObjClass, OBJ_CLASS);
  klass->name = name;
  initTable(&klass->methods);
  return klass;
}

ObjInstance* newInstance(ObjClass* klass) {
  ObjInstance* instance = ALLOCATE_OBJ(ObjInstance, OBJ_INSTANCE);
  instance->klass = klass;
  initTable(&instance->fields);
  return instance;
}

ObjBoundMethod* newBoundMethod(Value receiver, ObjClosure* method) {
  ObjBoundMethod* bound = ALLOCATE_OBJ(ObjBoundMethod, OBJ_BOUND_METHOD);
  bound->receiver = receiver;
  bound->method = method;
  return bound;
}

ObjModule* newModule(ObjString* name) {
  ObjModule* module = ALLOCATE_OBJ(ObjModule, OBJ_MODULE);
  module->name = name;
  initTable(&module->globals);
  initTable(&module->exports);
  module->isLoading = false;
  return module;
}

static void printFunction(ObjFunction* function) {
  if (function->name == NULL) {
    printf("<script>");
    return;
  }
  printf("<fn %s>", function->name->chars);
}

static void printList(ObjList* list) {
  printf("[");
  for (int i = 0; i < list->items.count; i++) {
    if (i > 0) printf(", ");
    printValue(list->items.values[i]);
  }
  printf("]");
}

static void printHashmap(ObjHashmap* hashmap) {
  printf("{");
  bool first = true;
  for (int index = mapFirstEntry(&hashmap->items); index != -1;
       index = mapNextEntry(&hashmap->items, index)) {
    MapEntry* entry = mapEntryAt(&hashmap->items, index);
    if (!first) {
      printf(", ");
    }
    first = false;
    printValue(entry->key);
    printf(": ");
    printValue(entry->value);
  }
  printf("}");
}

void printObject(Value value) {
  switch (OBJ_TYPE(value)) {
    case OBJ_FUNCTION:
      printFunction(AS_FUNCTION(value));
      break;
    case OBJ_CLOSURE:
      printFunction(AS_CLOSURE(value)->function);
      break;
    case OBJ_UPVALUE:
      printf("upvalue");
      break;
    case OBJ_NATIVE:
      printf("<native fn>");
      break;
    case OBJ_STRING:
      printf("%s", AS_CSTRING(value));
      break;
    case OBJ_LIST:
      printList(AS_LIST(value));
      break;
    case OBJ_HASHMAP:
      printHashmap(AS_HASHMAP(value));  
      break;
    case OBJ_CLASS:
      printf("%s", AS_CLASS(value)->name->chars);
      break;
    case OBJ_INSTANCE:
      printf("%s instance", AS_INSTANCE(value)->klass->name->chars);
      break; // vm debugger was crashing bc i forgot this, spent over an hour finding trouble elsewhere
    case OBJ_BOUND_METHOD:
      printFunction(AS_BOUND_METHOD(value)->method->function);
      break;
    case OBJ_MODULE:
      printf("<module %s>", AS_MODULE(value)->name->chars);
      break;
  }
}
