#include <stdio.h>
#include <stdlib.h>
#ifndef _WIN32
#include <readline/readline.h>
#include <readline/history.h>
#endif

#include "headers/module_loader.h"
#include "headers/pb.h"

static void repl(PbVM *vm)
{
  for (;;)
  {
#ifdef _WIN32
    char line[1024];
    printf("> ");
    if (fgets(line, sizeof(line), stdin) == NULL)
    {
      printf("\n");
      return;
    }
    pbInterpret(vm, line);
#else
    char *line = readline("> ");
    if (line == NULL)
    {
      printf("\n");
      return;
    }
    if (line[0] != '\0')
      add_history(line);
    pbInterpret(vm, line);
    free(line);
#endif
  }
}

static char *readFile(const char *path)
{
  FILE *file = fopen(path, "rb");
  if (file == NULL)
  {
    fprintf(stderr, "Could not open file \"%s\".\n", path);
    return NULL;
  }

  if (fseek(file, 0, SEEK_END) != 0)
  {
    fclose(file);
    fprintf(stderr, "Could not read file \"%s\".\n", path);
    return NULL;
  }
  long fileSize = ftell(file);
  if (fileSize < 0 || fseek(file, 0, SEEK_SET) != 0)
  {
    fclose(file);
    fprintf(stderr, "Could not read file \"%s\".\n", path);
    return NULL;
  }

  char *buffer = (char *)malloc((size_t)fileSize + 1);
  if (buffer == NULL)
  {
    fclose(file);
    fprintf(stderr, "Not enough memory to read \"%s\".\n", path);
    return NULL;
  }

  size_t bytesRead = fread(buffer, 1, (size_t)fileSize, file);
  fclose(file);
  if (bytesRead != (size_t)fileSize)
  {
    free(buffer);
    fprintf(stderr, "Could not read file \"%s\".\n", path);
    return NULL;
  }
  buffer[bytesRead] = '\0';
  return buffer;
}

static int runFile(PbVM *vm, const char *path)
{
  char *source = readFile(path);
  if (source == NULL)
    return 74;
  PbResult result = pbInterpret(vm, source);
  free(source);

  if (result == INTERPRET_COMPILE_ERROR)
    return 65;
  if (result == INTERPRET_RUNTIME_ERROR)
    return 70;
  return 0;
}

int main(int argc, const char *argv[])
{
  if (argc > 2)
  {
    fprintf(stderr, "Usage: pb [path]\n");
    return 64;
  }

  ModuleLoader loader;
  if (!initModuleLoader(&loader, argc == 2 ? argv[1] : NULL))
  {
    fprintf(stderr, "Could not initialise project.\n");
    return 70;
  }

  PbConfig config = {0};
  config.resolveCapability = resolveModuleFromHost;
  config.userData = &loader;
  PbVM *vm = pbCreateVM(&config);
  if (vm == NULL)
  {
    freeModuleLoader(&loader);
    fprintf(stderr, "Could not create VM.\n");
    return 70;
  }

  int status;
  if (argc == 1)
  {
    repl(vm);
    status = 0;
  }
  else
  {
    status = runFile(vm, argv[1]);
  }

  pbDestroyVM(vm);
  freeModuleLoader(&loader);
  return status;
}
