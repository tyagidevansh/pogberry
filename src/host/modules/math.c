#include <math.h>

#include "host/modules/math.h"

static PbValue mathFloor(PbVM *vm, int argCount,
                         const PbValue *args, void *userData)
{
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_NUMBER)
  {
    pbRuntimeError(vm, "math.floor() expects one number.");
    return pbNilValue();
  }
  return pbNumberValue(floor(args[0].as.number));
}

static PbValue mathSqrt(PbVM *vm, int argCount,
                        const PbValue *args, void *userData)
{
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_NUMBER)
  {
    pbRuntimeError(vm, "math.sqrt() expects one number.");
    return pbNilValue();
  }
  return pbNumberValue(sqrt(args[0].as.number));
}

bool registerMathModule(PbVM *vm, const char *name)
{
  const PbNativeDefinition definitions[] = {
      {"floor", mathFloor, NULL},
      {"sqrt", mathSqrt, NULL},
  };
  return pbRegisterCapability(vm, name, definitions,
                              sizeof(definitions) / sizeof(definitions[0]));
}
