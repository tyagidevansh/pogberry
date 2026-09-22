#include <math.h>

#include "host/modules/math.h"

static PbValue mathFloor(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_NUMBER) {
    pbRuntimeError(vm, "math.floor() expects one number.");
    return pbNilValue();
  }
  return pbNumberValue(floor(args[0].as.number));
}

static PbValue mathCeil(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_NUMBER) {
    pbRuntimeError(vm, "math.ceil() expects one number.");
    return pbNilValue();
  }
  return pbNumberValue(ceil(args[0].as.number));
}

static PbValue mathRound(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_NUMBER) {
    pbRuntimeError(vm, "math.round() expects one number.");
    return pbNilValue();
  }
  return pbNumberValue(round(args[0].as.number));
}

static PbValue mathSqrt(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_NUMBER) {
    pbRuntimeError(vm, "math.sqrt() expects one number.");
    return pbNilValue();
  }
  return pbNumberValue(sqrt(args[0].as.number));
}

static PbValue mathSin(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_NUMBER) {
    pbRuntimeError(vm, "math.sin() expects one number.");
    return pbNilValue();
  }
  return pbNumberValue(sin(args[0].as.number));
}

static PbValue mathCos(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_NUMBER) {
    pbRuntimeError(vm, "math.cos() expects one number.");
    return pbNilValue();
  }
  return pbNumberValue(cos(args[0].as.number));
}

static PbValue mathTan(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_NUMBER) {
    pbRuntimeError(vm, "math.tan() expects one number.");
    return pbNilValue();
  }
  return pbNumberValue(tan(args[0].as.number));
}

static PbValue mathAsin(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_NUMBER) {
    pbRuntimeError(vm, "math.asin() expects one number.");
    return pbNilValue();
  }
  return pbNumberValue(asin(args[0].as.number));
}

static PbValue mathAcos(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_NUMBER) {
    pbRuntimeError(vm, "math.acos() expects one number.");
    return pbNilValue();
  }
  return pbNumberValue(acos(args[0].as.number));
}

static PbValue mathAtan(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_NUMBER) {
    pbRuntimeError(vm, "math.atan() expects one number.");
    return pbNilValue();
  }
  return pbNumberValue(atan(args[0].as.number));
}

static PbValue mathAtan2(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || args[0].type != PB_VALUE_NUMBER || args[1].type != PB_VALUE_NUMBER) {
    pbRuntimeError(vm, "math.atan2() expects two numbers (y, x).");
    return pbNilValue();
  }
  return pbNumberValue(atan2(args[0].as.number, args[1].as.number));
}

static PbValue mathPow(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || args[0].type != PB_VALUE_NUMBER || args[1].type != PB_VALUE_NUMBER) {
    pbRuntimeError(vm, "math.pow() expects two numbers (base, exponent).");
    return pbNilValue();
  }
  return pbNumberValue(pow(args[0].as.number, args[1].as.number));
}

bool registerMathModule(PbVM *vm, const char *name) {
  const PbNativeDefinition definitions[] = {
      {"floor", mathFloor, NULL},
      {"ceil", mathCeil, NULL},
      {"round", mathRound, NULL},
      {"sqrt", mathSqrt, NULL},
      {"sin", mathSin, NULL},
      {"cos", mathCos, NULL},
      {"tan", mathTan, NULL},
      {"asin", mathAsin, NULL},
      {"acos", mathAcos, NULL},
      {"atan", mathAtan, NULL},
      {"atan2", mathAtan2, NULL},
      {"pow", mathPow, NULL},
  };
  return pbRegisterCapability(vm, name, definitions, sizeof(definitions) / sizeof(definitions[0]));
}
