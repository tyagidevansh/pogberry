#ifndef PB_HOST_MODULE_LOADER_H
#define PB_HOST_MODULE_LOADER_H

#include "headers/pb.h"

typedef struct
{
  char *root;
  char *standardRoot;
  bool *loadedProviders;
  size_t providerCount;
} ModuleLoader;

bool initModuleLoader(ModuleLoader *loader, const char *entryPath);
void freeModuleLoader(ModuleLoader *loader);
bool resolveModuleFromHost(PbVM *vm, const char *name, void *userData);

#endif
