#ifndef PB_H
#define PB_H

#include <stdbool.h>
#include <stddef.h>

#ifdef _WIN32
#define PB_API __declspec(dllexport)
#else
#define PB_API
#endif

#define PB_HOST_API_VERSION 3u

typedef struct PbVM PbVM;

typedef enum
{
  INTERPRET_OK,
  INTERPRET_COMPILE_ERROR,
  INTERPRET_RUNTIME_ERROR
} InterpretResult;

typedef InterpretResult PbResult;

typedef enum
{
  PB_VALUE_NIL,
  PB_VALUE_BOOL,
  PB_VALUE_NUMBER,
  PB_VALUE_STRING,
  PB_VALUE_OBJECT
} PbValueType;

typedef struct
{
  const char *chars;
  size_t length;
} PbString;

typedef struct
{
  PbValueType type;
  union
  {
    bool boolean;
    double number;
    PbString string;
    const void *object;
  } as;
} PbValue;

typedef enum
{
  PB_DIAGNOSTIC_COMPILE,
  PB_DIAGNOSTIC_RUNTIME,
  PB_DIAGNOSTIC_HOST
} PbDiagnosticKind;

typedef void (*PbWriteFn)(PbVM *vm, const char *text,
                          size_t length, void *userData);
typedef void (*PbDiagnosticFn)(PbVM *vm,
                               PbDiagnosticKind kind,
                               const char *message, void *userData);
typedef bool (*PbCapabilityResolverFn)(PbVM *vm,
                                       const char *capability,
                                       void *userData);
typedef PbValue (*PbNativeFn)(PbVM *vm, int argCount,
                              const PbValue *args,
                              void *userData);

typedef struct
{
  PbWriteFn write;
  PbDiagnosticFn diagnostic;
  PbCapabilityResolverFn resolveCapability;
  void *userData;
} PbConfig;

typedef struct
{
  const char *name;
  PbNativeFn function;
  void *userData;
} PbNativeDefinition;

PB_API PbVM *pbCreateVM(const PbConfig *config);
PB_API void pbDestroyVM(PbVM *vm);
PB_API PbResult pbInterpret(PbVM *vm, const char *source);
PB_API PbResult pbCall(PbVM *vm, const char *name,
                       int argCount, const PbValue *args,
                       PbValue *result);
PB_API bool pbDefineNative(PbVM *vm, const char *name,
                           PbNativeFn function, void *userData);
PB_API bool pbRegisterCapability(
    PbVM *vm, const char *name,
    const PbNativeDefinition *definitions, size_t definitionCount);
PB_API bool pbRegisterModuleSource(PbVM *vm,
                                   const char *name,
                                   const char *source);
PB_API void pbRuntimeError(PbVM *vm, const char *message);

PB_API PbValue pbNilValue(void);
PB_API PbValue pbBoolValue(bool value);
PB_API PbValue pbNumberValue(double value);
PB_API PbValue pbStringValue(const char *value);
PB_API PbValue pbStringValueN(const char *value,
                              size_t length);

/* Compatibility API used by the existing compiler stub. */
PB_API void ext_initVM(void);
PB_API InterpretResult ext_interpret(const char *source);

#endif
