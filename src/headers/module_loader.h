#ifndef PB_MODULE_LOADER_H
#define PB_MODULE_LOADER_H

#include "pb.h"

typedef struct
{
  char *root;
  bool *loadedProviders;
  size_t providerCount;
} ModuleLoader;

bool initModuleLoader(ModuleLoader *loader, const char *entryPath);
void freeModuleLoader(ModuleLoader *loader);
bool resolveModuleFromHost(PbVM *vm, const char *name, void *userData);

#endif
