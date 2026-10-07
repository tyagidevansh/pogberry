#ifndef _WIN32
#define _GNU_SOURCE
#endif

#include <math.h>
#include <stdio.h>
#include <string.h>
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

static bool timeZoneFlag(PbVM *vm, const PbValue *args, int index, bool *utc, const char *usage) {
  if (args[index].type != PB_VALUE_BOOL) {
    pbRuntimeError(vm, usage);
    return false;
  }
  *utc = args[index].as.boolean;
  return true;
}

static PbValue timeParts(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  static const char *usage = "parts() expects an optional timestamp and an optional utc flag.";
  double timestamp = (double)time(NULL);
  bool utc = false;
  if (argCount > 2) {
    pbRuntimeError(vm, usage);
    return pbNilValue();
  }
  if (argCount >= 1) {
    if (args[0].type != PB_VALUE_NUMBER || !isfinite(args[0].as.number)) {
      pbRuntimeError(vm, usage);
      return pbNilValue();
    }
    timestamp = args[0].as.number;
  }
  if (argCount == 2 && !timeZoneFlag(vm, args, 1, &utc, usage)) return pbNilValue();
  time_t when = (time_t)timestamp;
  struct tm *fields = utc ? gmtime(&when) : localtime(&when);
  if (fields == NULL) {
    pbRuntimeError(vm, "parts() could not break down that timestamp.");
    return pbNilValue();
  }
  PbValue parts = pbNewMap(vm);
  const char *names[] = {"year", "month", "day", "hour", "min", "sec", "wday", "yday", "isdst"};
  double values[] = {
      (double)(fields->tm_year + 1900), (double)(fields->tm_mon + 1), (double)fields->tm_mday,
      (double)fields->tm_hour,          (double)fields->tm_min,      (double)fields->tm_sec,
      (double)fields->tm_wday,           (double)fields->tm_yday,      (double)(fields->tm_isdst > 0),
  };
  for (size_t i = 0; i < sizeof(names) / sizeof(names[0]); i++) {
    if (!pbMapSet(vm, parts, pbStringValue(names[i]), pbNumberValue(values[i]))) return pbNilValue();
  }
  return parts;
}

static PbValue timeFormat(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  static const char *usage = "format() expects a pattern with an optional timestamp and an optional utc flag.";
  double timestamp = (double)time(NULL);
  const char *pattern = NULL;
  bool utc = false;
  if (argCount == 1) {
    if (args[0].type != PB_VALUE_STRING) {
      pbRuntimeError(vm, usage);
      return pbNilValue();
    }
    pattern = args[0].as.string.chars;
  } else if (argCount == 2 || argCount == 3) {
    if (args[0].type != PB_VALUE_NUMBER || !isfinite(args[0].as.number) || args[1].type != PB_VALUE_STRING) {
      pbRuntimeError(vm, usage);
      return pbNilValue();
    }
    timestamp = args[0].as.number;
    pattern = args[1].as.string.chars;
    if (argCount == 3 && !timeZoneFlag(vm, args, 2, &utc, usage)) return pbNilValue();
  } else {
    pbRuntimeError(vm, usage);
    return pbNilValue();
  }
  if (pattern[0] == '\0') return pbStringCopyN(vm, "", 0);
  time_t when = (time_t)timestamp;
  struct tm *fields = utc ? gmtime(&when) : localtime(&when);
  if (fields == NULL) {
    pbRuntimeError(vm, "format() could not break down that timestamp.");
    return pbNilValue();
  }
  char text[1024];
  if (strftime(text, sizeof(text), pattern, fields) == 0) {
    pbRuntimeError(vm, "format() output did not fit.");
    return pbNilValue();
  }
  return pbStringCopyN(vm, text, strlen(text));
}

static bool timeField(PbVM *vm, PbValue map, const char *field, int fallback, int *out) {
  PbValue found = pbNilValue();
  if (!pbMapGet(vm, map, pbStringValue(field), &found)) return false;
  if (found.type == PB_VALUE_NIL) {
    *out = fallback;
    return true;
  }
  if (found.type != PB_VALUE_NUMBER || !isfinite(found.as.number) || floor(found.as.number) != found.as.number) {
    char message[256];
    snprintf(message, sizeof(message), "fromParts() field '%s' must be a finite integer.", field);
    pbRuntimeError(vm, message);
    return false;
  }
  *out = (int)found.as.number;
  return true;
}

static PbValue timeFromParts(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  static const char *usage = "fromParts() expects a map of date fields with an optional utc flag.";
  if (argCount < 1 || argCount > 2) {
    pbRuntimeError(vm, usage);
    return pbNilValue();
  }
  if (args[0].type != PB_VALUE_OBJECT) {
    pbRuntimeError(vm, usage);
    return pbNilValue();
  }
  bool utc = false;
  if (argCount == 2 && !timeZoneFlag(vm, args, 1, &utc, usage)) return pbNilValue();
  time_t now = time(NULL);
  struct tm *present = localtime(&now);
  if (present == NULL) {
    pbRuntimeError(vm, "fromParts() could not read the current time.");
    return pbNilValue();
  }
  int year = 0;
  int month = 0;
  int day = 0;
  int hour = 0;
  int minute = 0;
  int second = 0;
  if (!timeField(vm, args[0], "year", present->tm_year + 1900, &year)) return pbNilValue();
  if (!timeField(vm, args[0], "month", present->tm_mon + 1, &month)) return pbNilValue();
  if (!timeField(vm, args[0], "day", present->tm_mday, &day)) return pbNilValue();
  if (!timeField(vm, args[0], "hour", present->tm_hour, &hour)) return pbNilValue();
  if (!timeField(vm, args[0], "min", present->tm_min, &minute)) return pbNilValue();
  if (!timeField(vm, args[0], "sec", present->tm_sec, &second)) return pbNilValue();
  struct tm fields;
  fields.tm_year = year - 1900;
  fields.tm_mon = month - 1;
  fields.tm_mday = day;
  fields.tm_hour = hour;
  fields.tm_min = minute;
  fields.tm_sec = second;
  fields.tm_isdst = -1;
  time_t result = 0;
  if (utc) {
#ifdef _WIN32
    result = _mkgmtime(&fields);
#else
    result = timegm(&fields);
#endif
  } else {
    result = mktime(&fields);
  }
  if (result == (time_t)-1) {
    pbRuntimeError(vm, "fromParts() could not construct a time.");
    return pbNilValue();
  }
  return pbNumberValue((double)result);
}

bool registerTimeModule(PbVM *vm, const char *name, const char *projectRoot) {
  (void)projectRoot;
  const PbNativeDefinition definitions[] = {
      {"unix", timeUnix, NULL},
      {"cpu", timeCpu, NULL},
      {"sleep", timeSleep, NULL},
      {"parts", timeParts, NULL},
      {"format", timeFormat, NULL},
      {"fromParts", timeFromParts, NULL},
  };
  return pbRegisterCapability(vm, name, definitions, sizeof(definitions) / sizeof(definitions[0]));
}
