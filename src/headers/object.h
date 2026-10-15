#ifndef clox_object_h
#define clox_object_h

#include "common.h"
#include "chunk.h"
#include "value.h"
#include "table.h"
#include "map.h"
#include "pb.h"

#define OBJ_TYPE(value) (AS_OBJ(value)->type)

#define IS_FUNCTION(value) isObjType(value, OBJ_FUNCTION)
#define IS_CLOSURE(value) isObjType(value, OBJ_CLOSURE)
#define IS_NATIVE(value) isObjType(value, OBJ_NATIVE)
#define IS_STRING(value) isObjType(value, OBJ_STRING)
#define IS_LIST(value) isObjType(value, OBJ_LIST)
#define IS_HASHMAP(value) isObjType(value, OBJ_HASHMAP)
#define IS_CLASS(value) isObjType(value, OBJ_CLASS)
#define IS_INSTANCE(value) isObjType(value, OBJ_INSTANCE)
#define IS_BOUND_METHOD(value) isObjType(value, OBJ_BOUND_METHOD)
#define IS_MODULE(value) isObjType(value, OBJ_MODULE)
#define IS_RESOURCE(value) isObjType(value, OBJ_RESOURCE)
#define IS_VEC2(value) isObjType(value, OBJ_VEC2)
#define IS_VEC3(value) isObjType(value, OBJ_VEC3)
#define IS_VEC4(value) isObjType(value, OBJ_VEC4)
#define IS_VEC(value) (IS_VEC2(value) || IS_VEC3(value) || IS_VEC4(value))

#define AS_FUNCTION(value) ((ObjFunction *)AS_OBJ(value))
#define AS_CLOSURE(value) ((ObjClosure *)AS_OBJ(value))
#define AS_NATIVE(value) ((ObjNative *)AS_OBJ(value))
#define AS_STRING(value) ((ObjString *)AS_OBJ(value))
#define AS_CSTRING(value) (((ObjString *)AS_OBJ(value))->chars)
#define AS_LIST(value) ((ObjList *)AS_OBJ(value))
#define AS_HASHMAP(value) ((ObjHashmap *)AS_OBJ(value))
#define AS_CLASS(value) ((ObjClass *)AS_OBJ(value))
#define AS_INSTANCE(value) ((ObjInstance *)AS_OBJ(value))
#define AS_BOUND_METHOD(value) ((ObjBoundMethod *)AS_OBJ(value))
#define AS_MODULE(value) ((ObjModule *)AS_OBJ(value))
#define AS_RESOURCE(value) ((ObjResource *)AS_OBJ(value))
#define AS_VEC2(value) ((ObjVec2 *)AS_OBJ(value))
#define AS_VEC3(value) ((ObjVec3 *)AS_OBJ(value))
#define AS_VEC4(value) ((ObjVec4 *)AS_OBJ(value))
#define AS_MAT4(value) ((ObjMat4 *)AS_OBJ(value))
#define IS_MAT4(value) isObjType(value, OBJ_MAT4)

typedef enum {
  OBJ_FUNCTION,
  OBJ_CLOSURE,
  OBJ_UPVALUE,
  OBJ_NATIVE,
  OBJ_STRING,
  OBJ_LIST,
  OBJ_HASHMAP,
  OBJ_CLASS,
  OBJ_INSTANCE,
  OBJ_BOUND_METHOD,
  OBJ_MODULE,
  OBJ_RESOURCE,
  OBJ_VEC2,
  OBJ_VEC3,
  OBJ_VEC4,
  OBJ_MAT4,
} ObjType;

struct Obj {
  ObjType type;
  bool isMarked;
  struct Obj *next;
};

typedef struct ObjFunction {
  Obj obj;
  int arity;
  int upvalueCount;
  Chunk chunk;
  ObjString *name;
  ObjString *sourceName;
} ObjFunction;

typedef struct ObjModule ObjModule;

typedef struct ObjUpvalue {
  Obj obj;
  Value *location;
  Value closed;
  struct ObjUpvalue *next;
} ObjUpvalue;

typedef struct {
  Obj obj;
  ObjFunction *function;
  ObjUpvalue **upvalues;
  int upvalueCount;
  ObjModule *module;
} ObjClosure;

typedef Value (*NativeFn)(int argCount, Value *args);

typedef struct {
  Obj obj;
  NativeFn legacyFunction;
  PbNativeFn hostFunction;
  void *userData;
} ObjNative;

// string payload
struct ObjString {
  Obj obj;
  int length;
  int capacity;
  char *chars;
  uint32_t hash;
  bool isInterned;
};

typedef struct {
  Obj obj;
  // int length;
  ValueArray items;
} ObjList;

typedef struct {
  Obj obj;
  Map items;
} ObjHashmap;

typedef struct {
  Obj obj;
  ObjString *name;
  Table methods;
} ObjClass;

typedef struct {
  Obj obj;
  ObjClass *klass;
  Table fields;
} ObjInstance;

typedef struct {
  Obj obj;
  Value receiver;
  ObjClosure *method;
} ObjBoundMethod;

struct ObjModule {
  Obj obj;
  ObjString *name;
  Table globals;
  Table exports;
  bool isLoading;
};

typedef struct {
  Obj obj;
  double x;
  double y;
} ObjVec2;

typedef struct {
  Obj obj;
  double x;
  double y;
  double z;
} ObjVec3;

typedef struct {
  Obj obj;
  double x;
  double y;
  double z;
  double w;
} ObjVec4;

typedef struct {
  Obj obj;
  double m[16];
} ObjMat4;

typedef struct {
  Obj obj;
  const char *typeName;
  int tag;
  int backendId;
  bool closed;
  PbResourceFinalizer finalizer;
  void *ctx;
} ObjResource;

ObjFunction *newFunction();
ObjClosure *newClosure(ObjFunction *function);
ObjUpvalue *newUpvalue(Value *slot);
ObjNative *newNative(NativeFn function);
ObjNative *newHostNative(PbNativeFn function, void *userData);
ObjString *takeString(char *chars, int length);
ObjString *copyString(const char *chars, int length);
ObjString *createUninternedString(char *chars, int length, int capacity);
uint32_t stringGetHash(ObjString *string);
ObjList *newList();
ObjHashmap *newHashmap();
ObjClass *newClass(ObjString *name);
ObjInstance *newInstance(ObjClass *klass);
ObjBoundMethod *newBoundMethod(Value receiver, ObjClosure *method);
ObjModule *newModule(ObjString *name);
ObjResource *newResource(const char *typeName, int tag, int backendId, PbResourceFinalizer finalizer, void *ctx);
ObjVec2 *newVec2(double x, double y);
ObjVec3 *newVec3(double x, double y, double z);
ObjVec4 *newVec4(double x, double y, double z, double w);
int vecDimensions(Value value);
double vecComponent(Value value, int index);
ObjMat4 *newMat4Identity(void);
ObjMat4 *newMat4From(const double cells[16]);
void mat4Multiply(const double left[16], const double right[16], double out[16]);
void printObject(Value value);

// function rather than just putting it in the macro coz this uses a value twice, that would cause the macro to be
// evaluated twice
static inline bool isObjType(Value value, ObjType type) { return IS_OBJ(value) && AS_OBJ(value)->type == type; }

#endif
