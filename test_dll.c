#include <windows.h>
#include <stdio.h>

// define function pointers
typedef void (*InitWindowFunc)(int, int, const char*);
typedef void (*BeginDrawingFunc)();
typedef void (*ClearBackgroundFunc)(int, int, int);
typedef void (*DrawTextFunc)(const char*, int, int, int, int, int, int);
typedef void (*EndDrawingFunc)();
typedef int (*WindowShouldCloseFunc)();  

int main() {
    printf("Loading DLL...\n"); // printfs dont work for some reason?
    HINSTANCE dllHandle = LoadLibrary("pogberry_gui.dll");
    if (!dllHandle) {
        printf("Failed to load pogberry_gui.dll. Error code: %lu\n", GetLastError());
        return 1;
    }
    printf("DLL loaded successfully!\n");

    // get function addresses
    InitWindowFunc initWindow = (InitWindowFunc)GetProcAddress(dllHandle, "initWindow");
    BeginDrawingFunc beginDrawing = (BeginDrawingFunc)GetProcAddress(dllHandle, "beginDrawing");
    ClearBackgroundFunc clearBackground = (ClearBackgroundFunc)GetProcAddress(dllHandle, "clearBackground");
    DrawTextFunc drawText = (DrawTextFunc)GetProcAddress(dllHandle, "drawText");
    EndDrawingFunc endDrawing = (EndDrawingFunc)GetProcAddress(dllHandle, "endDrawing");
    WindowShouldCloseFunc windowShouldClose = (WindowShouldCloseFunc)GetProcAddress(dllHandle, "windowShouldClose");

    if (!initWindow || !beginDrawing || !clearBackground || !drawText || !endDrawing || !windowShouldClose) {
        printf("Failed to get function addresses from DLL.\n");
        printf("initWindow: %p\n", initWindow);
        printf("beginDrawing: %p\n", beginDrawing);
        printf("clearBackground: %p\n", clearBackground);
        printf("drawText: %p\n", drawText);
        printf("endDrawing: %p\n", endDrawing);
        printf("windowShouldClose: %p\n", windowShouldClose);
        FreeLibrary(dllHandle);
        return 1;
    }

    printf("Initializing window...\n");
    initWindow(800, 600, "DLL Test");

    // event loop
    printf("Entering render loop...\n");
    while (!windowShouldClose()) {  
        beginDrawing();
        clearBackground(30, 30, 30);
        drawText("Hello from DLL!", 200, 300, 24, 255, 255, 255);
        endDrawing();
    }

    printf("Closing window...\n");
    FreeLibrary(dllHandle);
    return 0;
}

// gcc -o test_dll.exe test_dll.c