#ifndef _WIN32
#define _POSIX_C_SOURCE 200809L
#endif

#include <math.h>
#include <time.h>

#ifdef _WIN32
#include <windows.h>
#endif

#include "headers/pb.h"
#include "host/modules/time.h"

static PbValue timeUnix(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) {
    pbRuntimeError(vm, "unix() expects no arguments.");
    return pbNilValue();
  }
  return pbNumberValue((double)time(NULL));
}

static PbValue timeCpu(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)args;
  (void)userData;
  if (argCount != 0) {
    pbRuntimeError(vm, "cpu() expects no arguments.");
    return pbNilValue();
  }
  return pbNumberValue((double)clock() / CLOCKS_PER_SEC);
}

static PbValue timeSleep(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_NUMBER || !isfinite(args[0].as.number) ||
      args[0].as.number < 0) {
    pbRuntimeError(vm, "sleep() expects a non-negative number of seconds.");
    return pbNilValue();
  }
  double seconds = args[0].as.number;
#ifdef _WIN32
  Sleep((DWORD)(seconds * 1000.0));
#else
  struct timespec wait;
  wait.tv_sec = (time_t)seconds;
  wait.tv_nsec = (long)((seconds - floor(seconds)) * 1000000000.0);
  nanosleep(&wait, NULL);
#endif
  return pbNilValue();
}

bool registerTimeModule(PbVM *vm, const char *name, const char *projectRoot) {
  (void)projectRoot;
  const PbNativeDefinition definitions[] = {
      {"unix", timeUnix, NULL},
      {"cpu", timeCpu, NULL},
      {"sleep", timeSleep, NULL},
  };
  return pbRegisterCapability(vm, name, definitions, sizeof(definitions) / sizeof(definitions[0]));
}
