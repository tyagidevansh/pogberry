#ifndef clox_object_h
#define clox_object_h

#include "common.h"
#include "chunk.h"
#include "value.h"
#include "table.h"

#define OBJ_TYPE(value)      (AS_OBJ(value)->type)

#define IS_FUNCTION(value)    isObjType(value, OBJ_FUNCTION)
#define IS_NATIVE(value)      isObjType(value, OBJ_NATIVE)
#define IS_STRING(value)      isObjType(value, OBJ_STRING)
#define IS_LIST(value)        isObjType(value, OBJ_LIST)
#define IS_HASHMAP(value)     isObjType(value, OBJ_HASHMAP)
#define IS_CLASS(value)       isObjType(value, OBJ_CLASS)
#define IS_INSTANCE(value)    isObjType(value, OBJ_INSTANCE)
#define IS_BOUND_METHOD(value) isObjType(value, OBJ_BOUND_METHOD)

#define AS_FUNCTION(value)     ((ObjFunction*)AS_OBJ(value))
#define AS_NATIVE(value) \
    (((ObjNative*)AS_OBJ(value))->function)
#define AS_STRING(value)      ((ObjString*)AS_OBJ(value))
#define AS_CSTRING(value)     (((ObjString*)AS_OBJ(value))->chars)
#define AS_LIST(value)        ((ObjList*)AS_OBJ(value))
#define AS_HASHMAP(value)     ((ObjHashmap*)AS_OBJ(value))
#define AS_CLASS(value)       ((ObjClass*)AS_OBJ(value))
#define AS_INSTANCE(value)    ((ObjInstance*)AS_OBJ(value))
#define AS_BOUND_METHOD(value) ((ObjBoundMethod*)AS_OBJ(value))

typedef enum {
  OBJ_FUNCTION,
  OBJ_NATIVE,
  OBJ_STRING,
  OBJ_LIST,
  OBJ_HASHMAP,
  OBJ_CLASS,
  OBJ_INSTANCE,
  OBJ_BOUND_METHOD,
} ObjType;

struct Obj {
  ObjType type;
  bool isMarked;
  struct Obj* next;
};

typedef struct {
  Obj obj;
  int arity;
  Chunk chunk;
  ObjString* name;
} ObjFunction;

typedef Value (*NativeFn)(int argCount, Value* args);

typedef struct {
  Obj obj;
  NativeFn function;
} ObjNative;

// string payload
struct ObjString {
  Obj obj;
  int length;
  char* chars;
  uint32_t hash; //each string stores its own hash so we dont have to calculate it everytime we have to look something up in the hashmap
};

typedef struct {
  Obj obj;
  // int length;
  ValueArray items;
} ObjList;

typedef struct {
  Obj obj;
  Table items;
} ObjHashmap;

typedef struct {
  Obj obj;
  ObjString* name;
  Table methods;
} ObjClass;

typedef struct {
  Obj obj;
  ObjClass* klass;
  Table fields;
} ObjInstance;

typedef struct {
  Obj obj;
  Value receiver;
  ObjFunction* method;
} ObjBoundMethod;

ObjFunction* newFunction();
ObjNative* newNative(NativeFn function);
ObjString* takeString(char* chars, int length);
ObjString* copyString(const char* chars, int length);
ObjList* newList();
ObjHashmap* newHashmap();
ObjClass* newClass(ObjString* name);
ObjInstance* newInstance(ObjClass* klass);
ObjBoundMethod* newBoundMethod(Value receiver, ObjFunction* method);
void printObject(Value value);

// function rather than just putting it in the macro coz this uses a value twice, that would cause the macro to be evaluated twice
static inline bool isObjType(Value value, ObjType type) {
  return IS_OBJ(value) && AS_OBJ(value)->type == type;
}

#endif 