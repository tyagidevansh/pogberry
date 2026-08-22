#ifndef PB_HOST_GUI_H
#define PB_HOST_GUI_H

#include "headers/pb.h"

bool registerGuiModule(PbVM *vm, const char *name);
void releaseGuiModule(void);

#endif
