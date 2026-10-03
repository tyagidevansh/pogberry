#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#include "headers/pb.h"
#include "host/module_loader.h"
#include "host/modules/file.h"

#define FILE_READ_CAP (1 << 24)

#define MAX_OPEN_FILES 64

typedef enum {
  FILE_READ_TAG = 1,
  FILE_WRITE_TAG = 2,
  FILE_APPEND_TAG = 3,
} FileTag;

typedef struct {
  FILE *handle;
  char name[256];
} OpenFileSlot;

static OpenFileSlot openFiles[MAX_OPEN_FILES];
static const char *fileRoot = ".";

static PbValue fileError(PbVM *vm, const char *message) {
  pbRuntimeError(vm, message);
  return pbNilValue();
}

static void closeFileFinalizer(int backendId, void *ctx) {
  (void)ctx;
  if (backendId < 0 || backendId >= MAX_OPEN_FILES) return;
  if (openFiles[backendId].handle != NULL) {
    fclose(openFiles[backendId].handle);
    openFiles[backendId].handle = NULL;
  }
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

static PbValue fileOpen(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || args[0].type != PB_VALUE_STRING || args[1].type != PB_VALUE_STRING)
    return fileError(vm, "open(path, mode) expected a path with mode \"r\", \"w\", or \"a\".");
  const char *name = args[0].as.string.chars;
  const char *modeName = args[1].as.string.chars;
  int tag = 0;
  const char *mode = NULL;
  if (strcmp(modeName, "r") == 0) {
    tag = FILE_READ_TAG;
    mode = "rb";
  } else if (strcmp(modeName, "w") == 0) {
    tag = FILE_WRITE_TAG;
    mode = "wb";
  } else if (strcmp(modeName, "a") == 0) {
    tag = FILE_APPEND_TAG;
    mode = "ab";
  } else {
    return fileError(vm, "open(path, mode) expected mode \"r\", \"w\", or \"a\".");
  }
  char *path = filePath(vm, name);
  if (path == NULL) return pbNilValue();
  int slot = -1;
  for (int i = 0; i < MAX_OPEN_FILES; i++) {
    if (openFiles[i].handle == NULL) {
      slot = i;
      break;
    }
  }
  if (slot < 0) {
    free(path);
    return fileError(vm, "Too many open files.");
  }
  errno = 0;
  FILE *handle = fopen(path, mode);
  free(path);
  if (handle == NULL) {
    if (tag == FILE_READ_TAG && errno == ENOENT) return pbNilValue();
    char message[512];
    snprintf(message, sizeof(message), "Could not open file '%s'.", name);
    return fileError(vm, message);
  }
  openFiles[slot].handle = handle;
  strncpy(openFiles[slot].name, name, sizeof(openFiles[slot].name) - 1);
  openFiles[slot].name[sizeof(openFiles[slot].name) - 1] = '\0';
  return pbNewResource(vm, "file", tag, slot, closeFileFinalizer, NULL);
}

static PbValue fileRead(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1) return fileError(vm, "read(handle) expected a readable file.");
  int tag = 0;
  int slot = 0;
  bool closed = false;
  if (!pbResourceInfo(args[0], NULL, &tag, &slot, &closed) || tag != FILE_READ_TAG)
    return fileError(vm, "read(handle) expected a readable file.");
  if (closed || slot < 0 || slot >= MAX_OPEN_FILES || openFiles[slot].handle == NULL)
    return fileError(vm, "file has been closed.");
  FILE *handle = openFiles[slot].handle;
  long start = ftell(handle);
  if (start < 0 || fseek(handle, 0, SEEK_END) != 0) {
    char message[512];
    snprintf(message, sizeof(message), "Could not read file '%s'.", openFiles[slot].name);
    return fileError(vm, message);
  }
  long finish = ftell(handle);
  if (finish < 0 || fseek(handle, start, SEEK_SET) != 0) {
    char message[512];
    snprintf(message, sizeof(message), "Could not read file '%s'.", openFiles[slot].name);
    return fileError(vm, message);
  }
  long length = finish - start;
  if ((unsigned long)length > FILE_READ_CAP) {
    char message[512];
    snprintf(message, sizeof(message), "Could not read file '%s'.", openFiles[slot].name);
    return fileError(vm, message);
  }
  char *text = (char *)malloc((size_t)length + 1);
  if (text == NULL) return fileError(vm, "Could not allocate file contents.");
  size_t bytesRead = fread(text, 1, (size_t)length, handle);
  if (bytesRead != (size_t)length) {
    free(text);
    char message[512];
    snprintf(message, sizeof(message), "Could not read file '%s'.", openFiles[slot].name);
    return fileError(vm, message);
  }
  PbValue result = pbStringCopyN(vm, text, bytesRead);
  free(text);
  return result;
}

static PbValue fileWrite(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 2 || args[1].type != PB_VALUE_STRING)
    return fileError(vm, "write(handle, text) expected a writable file.");
  int tag = 0;
  int slot = 0;
  bool closed = false;
  if (!pbResourceInfo(args[0], NULL, &tag, &slot, &closed) || (tag != FILE_WRITE_TAG && tag != FILE_APPEND_TAG))
    return fileError(vm, "write(handle, text) expected a writable file.");
  if (closed || slot < 0 || slot >= MAX_OPEN_FILES || openFiles[slot].handle == NULL)
    return fileError(vm, "file has been closed.");
  const char *text = args[1].as.string.chars;
  size_t length = args[1].as.string.length;
  size_t written = 0;
  if (length > 0) written = fwrite(text != NULL ? text : "", 1, length, openFiles[slot].handle);
  if (written != length) {
    char message[512];
    snprintf(message, sizeof(message), "Could not write file '%s'.", openFiles[slot].name);
    return fileError(vm, message);
  }
  return pbNilValue();
}

static PbValue fileClose(PbVM *vm, int argCount, const PbValue *args, void *userData) {
  (void)userData;
  if (argCount != 1) return fileError(vm, "close(handle) expected a file.");
  int tag = 0;
  int slot = 0;
  if (!pbResourceInfo(args[0], NULL, &tag, &slot, NULL) ||
      (tag != FILE_READ_TAG && tag != FILE_WRITE_TAG && tag != FILE_APPEND_TAG))
    return fileError(vm, "close(handle) expected a file.");
  if (slot >= 0 && slot < MAX_OPEN_FILES && openFiles[slot].handle != NULL) {
    fclose(openFiles[slot].handle);
    openFiles[slot].handle = NULL;
  }
  pbResourceClose(args[0]);
  return pbNilValue();
}

bool registerFileModule(PbVM *vm, const char *name, const char *projectRoot) {
  fileRoot = projectRoot != NULL && projectRoot[0] != '\0' ? projectRoot : ".";
  const PbNativeDefinition definitions[] = {
      {"readText", fileReadText, NULL},
      {"writeText", fileWriteText, NULL},
      {"appendText", fileAppendText, NULL},
      {"exists", fileExists, NULL},
      {"delete", fileDelete, NULL},
      {"open", fileOpen, NULL},
      {"read", fileRead, NULL},
      {"write", fileWrite, NULL},
      {"close", fileClose, NULL},
  };
  return pbRegisterCapability(vm, name, definitions, sizeof(definitions) / sizeof(definitions[0]));
}
