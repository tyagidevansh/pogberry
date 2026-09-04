#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#ifndef _WIN32
#include <readline/readline.h>
#include <readline/history.h>
#endif

#include "host/module_loader.h"
#include "headers/pb.h"
#include "headers/debug.h"

#ifdef DEBUG_OPCODE_STATS
void printOpcodeStats(void);
#endif

static void printUsage(FILE *stream) {
  fprintf(stream, "Usage:\n"
                  "  pb run [path] [--opcodes]\n"
                  "  pb repl\n"
                  "  pb <path> [--opcodes]\n");
}

static bool isDirectory(const char *path) {
#ifdef _WIN32
  struct _stat info;
  return _stat(path, &info) == 0 && (info.st_mode & _S_IFDIR) != 0;
#else
  struct stat info;
  return stat(path, &info) == 0 && S_ISDIR(info.st_mode);
#endif
}

static char *entryPathFor(const char *path) {
  size_t pathLength = strlen(path);
  if (!isDirectory(path)) {
    char *copy = (char *)malloc(pathLength + 1);
    if (copy != NULL) memcpy(copy, path, pathLength + 1);
    return copy;
  }

  const char *entryName = "main.pb";
  size_t entryLength = strlen(entryName);
  bool hasSeparator = pathLength > 0 && (path[pathLength - 1] == '/' || path[pathLength - 1] == '\\');
  size_t separatorLength = hasSeparator ? 0 : 1;
  char *entryPath = (char *)malloc(pathLength + separatorLength + entryLength + 1);
  if (entryPath == NULL) return NULL;

  memcpy(entryPath, path, pathLength);
  if (!hasSeparator) entryPath[pathLength] = '/';
  memcpy(entryPath + pathLength + separatorLength, entryName, entryLength + 1);
  return entryPath;
}

static void repl(PbVM *vm) {
  for (;;) {
#ifdef _WIN32
    char line[1024];
    printf("> ");
    if (fgets(line, sizeof(line), stdin) == NULL) {
      printf("\n");
      return;
    }
    pbInterpret(vm, line);
#else
    char *line = readline("> ");
    if (line == NULL) {
      printf("\n");
      return;
    }
    if (line[0] != '\0') add_history(line);
    pbInterpret(vm, line);
    free(line);
#endif
  }
}

static char *readFile(const char *path) {
  FILE *file = fopen(path, "rb");
  if (file == NULL) {
    fprintf(stderr, "Could not open file \"%s\".\n", path);
    return NULL;
  }

  if (fseek(file, 0, SEEK_END) != 0) {
    fclose(file);
    fprintf(stderr, "Could not read file \"%s\".\n", path);
    return NULL;
  }
  long fileSize = ftell(file);
  if (fileSize < 0 || fseek(file, 0, SEEK_SET) != 0) {
    fclose(file);
    fprintf(stderr, "Could not read file \"%s\".\n", path);
    return NULL;
  }

  char *buffer = (char *)malloc((size_t)fileSize + 1);
  if (buffer == NULL) {
    fclose(file);
    fprintf(stderr, "Not enough memory to read \"%s\".\n", path);
    return NULL;
  }

  size_t bytesRead = fread(buffer, 1, (size_t)fileSize, file);
  fclose(file);
  if (bytesRead != (size_t)fileSize) {
    free(buffer);
    fprintf(stderr, "Could not read file \"%s\".\n", path);
    return NULL;
  }
  buffer[bytesRead] = '\0';
  return buffer;
}

static int runFile(PbVM *vm, const char *path) {
  char *source = readFile(path);
  if (source == NULL) return 74;
  PbResult result = pbInterpret(vm, source);
  free(source);

  if (result == INTERPRET_COMPILE_ERROR) return 65;
  if (result == INTERPRET_RUNTIME_ERROR) return 70;
  return 0;
}

int main(int argc, const char *argv[]) {
  bool startRepl = false;
  const char *target = NULL;
  bool showOpcodes = false;

  int nonFlagCount = 0;
  const char *nonFlags[4];

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--opcodes") == 0 || strcmp(argv[i], "-O") == 0) {
      showOpcodes = true;
    } else if (strcmp(argv[i], "help") == 0 || strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
      printUsage(stdout);
      return 0;
    } else {
      if (nonFlagCount < 4) {
        nonFlags[nonFlagCount++] = argv[i];
      } else {
        printUsage(stderr);
        return 64;
      }
    }
  }

  if (nonFlagCount == 0) {
    startRepl = true;
  } else if (nonFlagCount == 1 && strcmp(nonFlags[0], "repl") == 0) {
    startRepl = true;
  } else if (nonFlagCount == 1 && strcmp(nonFlags[0], "run") == 0) {
    target = ".";
  } else if (nonFlagCount == 1) {
    target = nonFlags[0];
  } else if (nonFlagCount == 2 && strcmp(nonFlags[0], "run") == 0) {
    target = nonFlags[1];
  } else {
    printUsage(stderr);
    return 64;
  }

  char *entryPath = target == NULL ? NULL : entryPathFor(target);
  if (target != NULL && entryPath == NULL) {
    fprintf(stderr, "Not enough memory to resolve entry path.\n");
    return 70;
  }

  ModuleLoader loader;
  if (!initModuleLoader(&loader, entryPath)) {
    free(entryPath);
    fprintf(stderr, "Could not initialise project.\n");
    return 70;
  }

  PbConfig config = {0};
  config.resolveCapability = resolveModuleFromHost;
  config.userData = &loader;
  PbVM *vm = pbCreateVM(&config);
  if (vm == NULL) {
    freeModuleLoader(&loader);
    free(entryPath);
    fprintf(stderr, "Could not create VM.\n");
    return 70;
  }

  int status;
  if (startRepl) {
    repl(vm);
    status = 0;
  } else {
    status = runFile(vm, entryPath);
  }

#ifdef DEBUG_OPCODE_STATS
  if (showOpcodes || getenv("PB_OPCODE_STATS") != NULL) {
    printOpcodeStats();
  }
#else
  if (showOpcodes) {
    fprintf(stderr, "Note: rebuild with 'make opcodes' or 'make OPCODES=1' to collect opcode statistics.\n");
  }
#endif

  pbDestroyVM(vm);
  freeModuleLoader(&loader);
  free(entryPath);
  return status;
}
