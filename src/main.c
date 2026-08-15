#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef _WIN32
#include <readline/readline.h>
#include <readline/history.h>
#endif

#include "headers/gui.h"
#include "headers/pb.h"

static bool resolveCapability(PbVM *vm, const char *name, void *userData)
{
  (void)userData;
  if (strcmp(name, "pb_gui") != 0)
    return false;
  return registerGuiModule(vm, name);
}

static void repl(PbVM *vm) {
  char line[1024];
  for (;;) {
    #ifdef _WIN32
      // basic fgets for Windows
      printf("> ");
      if (!fgets(line, sizeof(line), stdin)) {
        printf("\n");
        break;
      }
    #else
      // use readline on Linux
      char* buffer = readline("> ");
      if (!buffer) {
        printf("\n");
        break;
      }
      if (strlen(buffer) > 0) {
        add_history(buffer);
      }
      if (buffer) strcpy(line, buffer);
    #endif
    
    pbInterpret(vm, line);
  }
}

static char* readFile(const char* path) {
  FILE* file = fopen(path, "rb");

  if (file == NULL) {
    fprintf(stderr, "Could not open file \"%s\".\n", path);
    exit(74);
  }

  fseek(file, 0L, SEEK_END); 
  size_t fileSize = ftell(file); 
  rewind(file);  

  char* buffer = (char*)malloc(fileSize + 1); 

  if (buffer == NULL) {
    fprintf(stderr, "Not enough memory to read \"%s\".\n", path);
    exit(74);
  }

  size_t bytesRead = fread(buffer, sizeof(char), fileSize, file); 
  // if the read itself fails (rare)
  if (bytesRead < fileSize) {
    fprintf(stderr, "Could not read file \"%s\".\n", path);
    exit(74);
  }
  buffer[bytesRead] = '\0';

  fclose(file);
  return buffer; // return the string to runFile 
}

static int runFile(PbVM *vm, const char* path) {
  char* source = readFile(path); // dynamically allocates and passes ownership to caller, so need to free the source
  PbResult result = pbInterpret(vm, source);
  free(source);

  if (result == INTERPRET_COMPILE_ERROR) return 65;
  if (result == INTERPRET_RUNTIME_ERROR) return 70;
  return 0;
}

int main(int argc, const char* argv[]) {
  PbConfig config = {0};
  config.resolveCapability = resolveCapability;
  PbVM *vm = pbCreateVM(&config);
  if (vm == NULL)
  {
    fprintf(stderr, "Could not create VM.\n");
    return 70;
  }
  int status = 0;

  if (argc == 1) {
    repl(vm);
  } else if (argc == 2) {
    status = runFile(vm, argv[1]);
  } else {
    fprintf(stderr, "Usage: pb [path]\n");
    status = 64;
  }

  pbDestroyVM(vm);
  freeGui();
  return status;
}
