#ifndef pogberry_h
#define pogberry_h

#include <stdbool.h>
#include <stddef.h>

#ifdef _WIN32
#define POGBERRY_API __declspec(dllexport)
#else
#define POGBERRY_API
#endif

#define POGBERRY_HOST_API_VERSION 2u

typedef struct PogberryVM PogberryVM;

typedef enum
{
  INTERPRET_OK,
  INTERPRET_COMPILE_ERROR,
  INTERPRET_RUNTIME_ERROR
} InterpretResult;

typedef InterpretResult PogberryResult;

typedef enum
{
  POGBERRY_VALUE_NIL,
  POGBERRY_VALUE_BOOL,
  POGBERRY_VALUE_NUMBER,
  POGBERRY_VALUE_STRING,
  POGBERRY_VALUE_OBJECT
} PogberryValueType;

typedef struct
{
  const char *chars;
  size_t length;
} PogberryString;

typedef struct
{
  PogberryValueType type;
  union
  {
    bool boolean;
    double number;
    PogberryString string;
    const void *object;
  } as;
} PogberryValue;

/* String and object values returned by a VM are borrowed until its next call.
 * Opaque objects may only be passed back to the VM that created them. */

typedef enum
{
  POGBERRY_DIAGNOSTIC_COMPILE,
  POGBERRY_DIAGNOSTIC_RUNTIME,
  POGBERRY_DIAGNOSTIC_HOST
} PogberryDiagnosticKind;

typedef void (*PogberryWriteFn)(PogberryVM *vm, const char *text,
                                size_t length, void *userData);
typedef void (*PogberryDiagnosticFn)(PogberryVM *vm,
                                     PogberryDiagnosticKind kind,
                                     const char *message, void *userData);
typedef bool (*PogberryCapabilityResolverFn)(PogberryVM *vm,
                                             const char *capability,
                                             void *userData);
typedef PogberryValue (*PogberryNativeFn)(PogberryVM *vm, int argCount,
                                          const PogberryValue *args,
                                          void *userData);

typedef struct
{
  PogberryWriteFn write;
  PogberryDiagnosticFn diagnostic;
  PogberryCapabilityResolverFn resolveCapability;
  void *userData;
} PogberryConfig;

/* A VM may be switched in and out sequentially. Concurrent use is not yet
 * supported. Callbacks run synchronously on the thread executing the VM. */

typedef struct
{
  const char *name;
  PogberryNativeFn function;
  void *userData;
} PogberryNativeDefinition;

POGBERRY_API PogberryVM *pogberryCreateVM(const PogberryConfig *config);
POGBERRY_API void pogberryDestroyVM(PogberryVM *vm);
POGBERRY_API PogberryResult pogberryInterpret(PogberryVM *vm,
                                              const char *source);
POGBERRY_API PogberryResult pogberryCall(PogberryVM *vm, const char *name,
                                         int argCount,
                                         const PogberryValue *args,
                                         PogberryValue *result);
POGBERRY_API bool pogberryDefineNative(PogberryVM *vm, const char *name,
                                       PogberryNativeFn function,
                                       void *userData);
POGBERRY_API bool pogberryRegisterCapability(
    PogberryVM *vm, const char *name,
    const PogberryNativeDefinition *definitions, size_t definitionCount);
/* Module names are opaque stable identifiers. The VM passes import strings to
 * the resolver unchanged and never interprets them as filesystem paths. The
 * source text is copied and may be released after this call returns. */
POGBERRY_API bool pogberryRegisterModuleSource(PogberryVM *vm,
                                               const char *name,
                                               const char *source);
POGBERRY_API void pogberryRuntimeError(PogberryVM *vm, const char *message);

POGBERRY_API PogberryValue pogberryNilValue(void);
POGBERRY_API PogberryValue pogberryBoolValue(bool value);
POGBERRY_API PogberryValue pogberryNumberValue(double value);
POGBERRY_API PogberryValue pogberryStringValue(const char *value);
POGBERRY_API PogberryValue pogberryStringValueN(const char *value,
                                                size_t length);

/* Compatibility API used by the existing compiler stub. */
POGBERRY_API void ext_initVM(void);
POGBERRY_API InterpretResult ext_interpret(const char *source);

#endif
