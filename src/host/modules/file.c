#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#include "headers/pb.h"
#include "host/module_loader.h"
#include "host/modules/file.h"

#define FILE_READ_CAP (1 << 24)

static const char *fileRoot = ".";

static PbValue fileError(PbVM *vm, const char *message) {
  pbRuntimeError(vm, message);
  return pbNilValue();
}

static char *filePath(PbVM *vm, const char *name) {
  if (!validProjectPath(name)) {
    char message[512];
    snprintf(message, sizeof(message), "Invalid path '%s'.", name != NULL ? name : "");
    pbRuntimeError(vm, message);
    return NULL;
  }
  size_t rootLength = strlen(fileRoot);
  size_t nameLength = strlen(name);
  char *path = (char *)malloc(rootLength + nameLength + 2);
  if (path == NULL) {
    pbRuntimeError(vm, "Could not allocate a file path.");
    return NULL;
  }
  snprintf(path, rootLength + nameLength + 2, "%s/%s", fileRoot, name);
  return path;
}

static PbValue fileReadText(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_STRING) return fileError(vm, "readText(path) expected.");
  const char *name = args[0].as.string.chars;
  char *path = filePath(vm, name);
  if (path == NULL) return pbNilValue();
  errno = 0;
  FILE *file = fopen(path, "rb");
  if (file == NULL) {
    int error = errno;
    free(path);
    if (error == ENOENT) return pbNilValue();
    char message[512];
    snprintf(message, sizeof(message), "Could not open file '%s'.", name);
    return fileError(vm, message);
  }
  if (fseek(file, 0, SEEK_END) != 0) {
    fclose(file);
    free(path);
    char message[512];
    snprintf(message, sizeof(message), "Could not measure file '%s'.", name);
    return fileError(vm, message);
  }
  long length = ftell(file);
  if (length < 0 || (unsigned long)length > FILE_READ_CAP || fseek(file, 0, SEEK_SET) != 0) {
    fclose(file);
    free(path);
    char message[512];
    snprintf(message, sizeof(message), "Could not measure file '%s'.", name);
    return fileError(vm, message);
  }
  char *text = (char *)malloc((size_t)length + 1);
  if (text == NULL) {
    fclose(file);
    free(path);
    return fileError(vm, "Could not allocate file contents.");
  }
  size_t bytesRead = fread(text, 1, (size_t)length, file);
  fclose(file);
  if (bytesRead != (size_t)length) {
    free(text);
    free(path);
    char message[512];
    snprintf(message, sizeof(message), "Could not read file '%s'.", name);
    return fileError(vm, message);
  }
  PbValue result = pbStringCopyN(vm, text, bytesRead);
  free(text);
  free(path);
  return result;
}

static PbValue fileWriteMode(PbVM *vm, const PbValue *args, const char *mode, const char *name) {
  char *path = filePath(vm, name);
  if (path == NULL) return pbNilValue();
  FILE *file = fopen(path, mode);
  if (file == NULL) {
    free(path);
    char message[512];
    snprintf(message, sizeof(message), "Could not open file '%s'.", name);
    return fileError(vm, message);
  }
  const char *text = args[1].as.string.chars;
  size_t length = args[1].as.string.length;
  size_t written = 0;
  if (length > 0) written = fwrite(text != NULL ? text : "", 1, length, file);
  if (written != length || fclose(file) != 0) {
    free(path);
    char message[512];
    snprintf(message, sizeof(message), "Could not write file '%s'.", name);
    return fileError(vm, message);
  }
  free(path);
  return pbNilValue();
}

static PbValue fileWriteText(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || args[0].type != PB_VALUE_STRING || args[1].type != PB_VALUE_STRING)
    return fileError(vm, "writeText(path, text) expected.");
  return fileWriteMode(vm, args, "wb", args[0].as.string.chars);
}

static PbValue fileAppendText(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || args[0].type != PB_VALUE_STRING || args[1].type != PB_VALUE_STRING)
    return fileError(vm, "appendText(path, text) expected.");
  return fileWriteMode(vm, args, "ab", args[0].as.string.chars);
}

static PbValue fileExists(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_STRING) return fileError(vm, "exists(path) expected.");
  char *path = filePath(vm, args[0].as.string.chars);
  if (path == NULL) return pbNilValue();
#ifdef _WIN32
  struct _stat info;
  bool found = _stat(path, &info) == 0;
#else
  struct stat info;
  bool found = stat(path, &info) == 0;
#endif
  free(path);
  return pbBoolValue(found);
}

static PbValue fileDelete(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1 || args[0].type != PB_VALUE_STRING) return fileError(vm, "delete(path) expected.");
  const char *name = args[0].as.string.chars;
  char *path = filePath(vm, name);
  if (path == NULL) return pbNilValue();
  errno = 0;
  if (remove(path) == 0) {
    free(path);
    return pbBoolValue(true);
  }
  int error = errno;
  free(path);
  if (error == ENOENT) return pbBoolValue(false);
  char message[512];
  snprintf(message, sizeof(message), "Could not delete file '%s'.", name);
  return fileError(vm, message);
}

bool registerFileModule(PbVM *vm, const char *name, const char *projectRoot) {
  fileRoot = projectRoot != NULL && projectRoot[0] != '\0' ? projectRoot : ".";
  const PbNativeDefinition definitions[] = {
      {"readText", fileReadText, NULL},
      {"writeText", fileWriteText, NULL},
      {"appendText", fileAppendText, NULL},
      {"exists", fileExists, NULL},
      {"delete", fileDelete, NULL},
  };
  return pbRegisterCapability(vm, name, definitions, sizeof(definitions) / sizeof(definitions[0]));
}
