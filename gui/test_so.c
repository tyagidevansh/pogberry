#include <stdio.h>
#include <dlfcn.h>
#include <stdlib.h>

typedef void (*InitWindowFunc)(int, int, const char*);
typedef int (*WindowShouldCloseFunc)();
typedef void (*SetTargetFPSFunc)(int);
typedef void (*BeginDrawingFunc)();
typedef void (*EndDrawingFunc)();
typedef void (*ClearBackgroundFunc)(int, int, int);
typedef void (*DrawTextFunc)(const char*, int, int, int, int, int, int);

int main() {
    void* handle = dlopen("../lib/pogberry_gui_linux.so", RTLD_LAZY);
    if (!handle) {
        fprintf(stderr, "Failed to load shared library: %s\n", dlerror());
        return 1;
    }

    dlerror();

    InitWindowFunc initWindow = (InitWindowFunc)dlsym(handle, "initWindow");
    SetTargetFPSFunc setTargetFPS = (SetTargetFPSFunc)dlsym(handle, "setTargetFPS");
    WindowShouldCloseFunc windowShouldClose = (WindowShouldCloseFunc)dlsym(handle, "windowShouldClose");
    BeginDrawingFunc beginDrawing = (BeginDrawingFunc)dlsym(handle, "beginDrawing");
    EndDrawingFunc endDrawing = (EndDrawingFunc)dlsym(handle, "endDrawing");
    ClearBackgroundFunc clearBackground = (ClearBackgroundFunc)dlsym(handle, "clearBackground");
    DrawTextFunc drawText = (DrawTextFunc)dlsym(handle, "drawText");

    char* error;
    if ((error = dlerror()) != NULL)  {
        fprintf(stderr, "Error loading symbols: %s\n", error);
        dlclose(handle);
        return 1;
    }

    initWindow(800, 600, "Test GUI");
    setTargetFPS(60);

    while (!windowShouldClose()) {
        beginDrawing();
        clearBackground(40, 45, 52);
        drawText("Hello from .so!", 200, 300, 30, 255, 255, 255);
        endDrawing();
    }

    dlclose(handle);
    return 0;
}

// gcc -o test_so test_so.c -ldl