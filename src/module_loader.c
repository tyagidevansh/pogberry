#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "headers/gui.h"
#include "headers/module_loader.h"

typedef bool (*ModuleProviderLoadFn)(PbVM *vm, const char *name);
typedef void (*ModuleProviderUnloadFn)(void);

typedef struct
{
  const char *name;
  ModuleProviderLoadFn load;
  ModuleProviderUnloadFn unload;
} ModuleProvider;

static const ModuleProvider providers[] = {
    {"pb_gui", registerGuiModule, releaseGuiModule},
};

static char *copyText(const char *text, size_t length)
{
  char *copy = (char *)malloc(length + 1);
  if (copy == NULL)
    return NULL;
  memcpy(copy, text, length);
  copy[length] = '\0';
  return copy;
}

bool initModuleLoader(ModuleLoader *loader, const char *entryPath)
{
  memset(loader, 0, sizeof(*loader));
  loader->providerCount = sizeof(providers) / sizeof(providers[0]);
  loader->loadedProviders = (bool *)calloc(loader->providerCount, sizeof(bool));
  if (loader->loadedProviders == NULL)
    return false;

  if (entryPath == NULL)
  {
    loader->root = copyText(".", 1);
    if (loader->root != NULL)
      return true;
    free(loader->loadedProviders);
    loader->loadedProviders = NULL;
    return false;
  }

  const char *slash = strrchr(entryPath, '/');
  const char *backslash = strrchr(entryPath, '\\');
  if (backslash != NULL && (slash == NULL || backslash > slash))
    slash = backslash;

  if (slash == NULL)
    loader->root = copyText(".", 1);
  else if (slash == entryPath)
    loader->root = copyText(entryPath, 1);
  else
    loader->root = copyText(entryPath, (size_t)(slash - entryPath));

  if (loader->root == NULL)
  {
    free(loader->loadedProviders);
    loader->loadedProviders = NULL;
    return false;
  }
  return true;
}

void freeModuleLoader(ModuleLoader *loader)
{
  for (size_t i = loader->providerCount; i > 0; i--)
  {
    size_t index = i - 1;
    if (loader->loadedProviders[index] && providers[index].unload != NULL)
      providers[index].unload();
  }
  free(loader->loadedProviders);
  free(loader->root);
  memset(loader, 0, sizeof(*loader));
}

static bool loadProvidedModule(ModuleLoader *loader, PbVM *vm,
                               const char *name, bool *matched)
{
  for (size_t i = 0; i < loader->providerCount; i++)
  {
    if (strcmp(providers[i].name, name) != 0)
      continue;
    *matched = true;
    if (!providers[i].load(vm, name))
      return false;
    loader->loadedProviders[i] = true;
    return true;
  }
  *matched = false;
  return false;
}

static bool validModuleName(const char *name)
{
  if (name == NULL || name[0] == '\0' || name[0] == '/' ||
      name[0] == '\\')
    return false;

  const char *segment = name;
  for (const char *current = name;; current++)
  {
    unsigned char character = (unsigned char)*current;
    if (character == '\\')
      return false;
    if (character != '\0' && character != '/' && character != '_' &&
        character != '-' && character != '.' && !isalnum(character))
      return false;
    if (character != '\0' && character != '/')
      continue;

    size_t length = (size_t)(current - segment);
    if (length == 0 || (length == 1 && segment[0] == '.') ||
        (length == 2 && segment[0] == '.' && segment[1] == '.'))
      return false;
    if (character == '\0')
      return true;
    segment = current + 1;
  }
}

static char *modulePath(ModuleLoader *loader, PbVM *vm, const char *name)
{
  if (!validModuleName(name))
  {
    char message[512];
    snprintf(message, sizeof(message), "Invalid module name '%s'.",
             name != NULL ? name : "");
    pbRuntimeError(vm, message);
    return NULL;
  }

  size_t rootLength = strlen(loader->root);
  size_t nameLength = strlen(name);
  char *path = (char *)malloc(rootLength + nameLength + 5);
  if (path == NULL)
  {
    pbRuntimeError(vm, "Could not allocate a module path.");
    return NULL;
  }
  snprintf(path, rootLength + nameLength + 5, "%s/%s.pb",
           loader->root, name);
  return path;
}

static char *readModule(PbVM *vm, const char *name, const char *path)
{
  errno = 0;
  FILE *file = fopen(path, "rb");
  if (file == NULL)
  {
    char message[512];
    if (errno == ENOENT)
      snprintf(message, sizeof(message), "Could not find module '%s'.", name);
    else
      snprintf(message, sizeof(message), "Could not open module file '%s'.",
               path);
    pbRuntimeError(vm, message);
    return NULL;
  }

  if (fseek(file, 0, SEEK_END) != 0)
  {
    fclose(file);
    pbRuntimeError(vm, "Could not measure a module file.");
    return NULL;
  }
  long length = ftell(file);
  if (length < 0 || fseek(file, 0, SEEK_SET) != 0)
  {
    fclose(file);
    pbRuntimeError(vm, "Could not measure a module file.");
    return NULL;
  }

  char *source = (char *)malloc((size_t)length + 1);
  if (source == NULL)
  {
    fclose(file);
    pbRuntimeError(vm, "Could not allocate module source.");
    return NULL;
  }
  size_t bytesRead = fread(source, 1, (size_t)length, file);
  fclose(file);
  if (bytesRead != (size_t)length)
  {
    free(source);
    pbRuntimeError(vm, "Could not read a module file.");
    return NULL;
  }
  source[bytesRead] = '\0';
  return source;
}

static bool loadSourceModule(ModuleLoader *loader, PbVM *vm,
                             const char *name)
{
  char *path = modulePath(loader, vm, name);
  if (path == NULL)
    return false;
  char *source = readModule(vm, name, path);
  free(path);
  if (source == NULL)
    return false;
  bool registered = pbRegisterModuleSource(vm, name, source);
  free(source);
  return registered;
}

bool resolveModuleFromHost(PbVM *vm, const char *name, void *userData)
{
  ModuleLoader *loader = (ModuleLoader *)userData;
  bool matched;
  bool loaded = loadProvidedModule(loader, vm, name, &matched);
  if (matched)
    return loaded;
  return loadSourceModule(loader, vm, name);
}
