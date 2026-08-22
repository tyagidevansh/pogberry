#ifndef PB_HOST_RAYLIB_H
#define PB_HOST_RAYLIB_H

#include "headers/pb.h"

bool registerRaylibModule(PbVM *vm, const char *name);
void releaseRaylibModule(void);

#endif
