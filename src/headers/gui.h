#ifndef PB_GUI_H
#define PB_GUI_H

#include "pb.h"

bool registerGuiModule(PbVM *vm, const char *name);
void freeGui(void);

#endif
