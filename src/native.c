#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include <stdarg.h>

#include "headers/native.h"
#include "headers/memory.h"
#include "headers/object.h"
#include "headers/vm.h"

static void runtimeError(const char *format, ...)
{ // variadic function
    va_list args;
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
    fputs("\n", stderr);

    for (int i = vm.frameCount - 1; i >= 0; i--)
    {
        CallFrame *frame = &vm.frames[i];
        ObjFunction *function = frame->function;
        size_t instruction = frame->ip - function->chunk.code - 1;
        fprintf(stderr, "[line %d] in ",
                function->chunk.lines[instruction]);
        if (function->name == NULL)
        {
            fprintf(stderr, "script\n");
        }
        else
        {
            fprintf(stderr, "%s()\n", function->name->chars);
        }
    }
}

Value clockNative(int argCount, Value *args)
{
    if (argCount > 0)
    {
        runtimeError("Clock does not accept any arguments");
        return NIL_VAL;
    }
    return NUMBER_VAL((double)clock() / CLOCKS_PER_SEC);
}

Value randNative(int argCount, Value *args)
{
    if (argCount > 0 && IS_NUMBER(args[0]))
    {
        int max = (int)AS_NUMBER(args[0]);
        return NUMBER_VAL(rand() % max);
    }
    else
    {
        return NUMBER_VAL(rand() / (double)RAND_MAX);
    }
}

Value floorNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_NUMBER(args[0]))
    {
        runtimeError("floor expects a single number.");
        return NIL_VAL;
    }
    return NUMBER_VAL(floor(AS_NUMBER(args[0])));
}

Value strInputNative(int argCount, Value *args)
{
    if (argCount > 0 && IS_STRING(args[0]))
    {
        printf("%s", AS_CSTRING(args[0]));
    }
    else
    {
        printf("Enter input: ");
    }
    char buffer[256];
    if (!fgets(buffer, sizeof(buffer), stdin))
    {
        return NIL_VAL;
    }
    buffer[strcspn(buffer, "\n")] = 0;
    return OBJ_VAL(copyString(buffer, strlen(buffer)));
}

Value sqrtNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_NUMBER(args[0]))
    {
        runtimeError("sqrt expects a single number.");
        return NIL_VAL;
    }
    return NUMBER_VAL(sqrt(AS_NUMBER(args[0])));
}

Value absNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_NUMBER(args[0]))
    {
        runtimeError("abs expects a single value.");
        return NIL_VAL;
    }
    return NUMBER_VAL(fabs(AS_NUMBER(args[0])));
}

int Valuecomp(const void *elem1, const void *elem2)
{
    Value f = *((Value *)elem1);
    Value s = *((Value *)elem2);

    if (IS_NUMBER(f) && IS_NUMBER(s))
    {
        double df = AS_NUMBER(f);
        double ds = AS_NUMBER(s);
        if (df > ds)
            return 1;
        if (ds > df)
            return -1;
        return 0;
    }
    else if (IS_STRING(f) && IS_STRING(s))
    {
        ObjString *strF = AS_STRING(f);
        ObjString *strS = AS_STRING(s);
        return strcmp(strF->chars, strS->chars);
    }
    else
    {
        return 0;
    }
}

int ValuecompReverse(const void *elem1, const void *elem2)
{
    return Valuecomp(elem2, elem1);
}

int Strcomp(const void *elem1, const void *elem2)
{
    char f = *((char *)elem1);
    char s = *((char *)elem2);

    if (f > s)
        return 1;
    if (f < s)
        return -1;
    return 0;
}

int StrcompReverse(const void *elem1, const void *elem2)
{
    return Strcomp(elem2, elem1);
}

Value sortNative(int argCount, Value *args)
{
    if (argCount < 1)
    {
        runtimeError("Expect at least one argument.");
        return NIL_VAL;
    }
    if (argCount > 2)
    {
        runtimeError("Function cannot take more than two arguments [Container, Reverse = True | False]");
        return NIL_VAL;
    }

    bool reverse = false;
    if (argCount == 2)
    {
        if (!IS_BOOL(args[1]))
        {
            runtimeError("Second argument must be a boolean.");
            return NIL_VAL;
        }
        reverse = AS_BOOL(args[1]);
    }

    if (IS_LIST(args[0]))
    {
        ObjList *list = AS_LIST(args[0]);
        qsort(list->items.values, list->items.count, sizeof(Value), reverse ? ValuecompReverse : Valuecomp);
        return NIL_VAL;
    }
    else if (IS_STRING(args[0]))
    {
        ObjString *str = AS_STRING(args[0]);
        qsort(str->chars, str->length, sizeof(char), reverse ? StrcompReverse : Strcomp);
        return NIL_VAL;
    }
    else
    {
        runtimeError("First argument must be a list or a string.");
        return NIL_VAL;
    }
}

Value listAdd(int argCount, Value *args)
{
    if (argCount != 2 || !IS_LIST(args[0]))
    {
        runtimeError("Expected a list and a value");
        return NIL_VAL;
    }

    ObjList *list = AS_LIST(args[0]);
    Value value = args[1];

    if (list->items.count + 1 > list->items.capacity)
    {
        int oldCapacity = list->items.capacity;
        list->items.capacity = GROW_CAPACITY(oldCapacity);
        list->items.values = GROW_ARRAY(Value, list->items.values, oldCapacity, list->items.capacity);
    }

    list->items.values[list->items.count] = value;
    list->items.count++;

    return NIL_VAL;
}

Value listRemove(int argCount, Value *args)
{
    if (argCount != 2 || !IS_LIST(args[0]) || !IS_NUMBER(args[1]))
    {
        runtimeError("Expect a list and an index");
        return NIL_VAL;
    }

    ObjList *list = AS_LIST(args[0]);
    int index = AS_NUMBER(args[1]);

    if (index < 0 || index >= list->items.count)
    {
        runtimeError("Index out of bounds");
        return NIL_VAL;
    }

    Value removedVal = list->items.values[index];

    for (int i = index; i < list->items.count - 1; i++)
    {
        list->items.values[i] = list->items.values[i + 1];
    }

    list->items.count--;

    return removedVal;
}

Value initWindowNative(int argCount, Value *args)
{
    if (argCount != 3 || !IS_NUMBER(args[0]) || !IS_NUMBER(args[1]) || !IS_STRING(args[2]))
    {
        fprintf(stderr, "initWindow(width, height, title) expected\n");
        return NIL_VAL;
    }
    int width = AS_NUMBER(args[0]);
    int height = AS_NUMBER(args[1]);
    const char *title = AS_CSTRING(args[2]);

    initWindow(width, height, title);
    return NIL_VAL;
}

Value beginDrawingNative(int argCount, Value *args)
{
    if (argCount != 0)
    {
        fprintf(stderr, "beginDrawing() takes no arguments\n");
        return NIL_VAL;
    }
    beginDrawing();
    return NIL_VAL;
}

Value clearBackgroundNative(int argCount, Value *args)
{
    if (argCount != 3 || !IS_NUMBER(args[0]) || !IS_NUMBER(args[1]) || !IS_NUMBER(args[2]))
    {
        fprintf(stderr, "clearBackground(r, g, b) expected\n");
        return NIL_VAL;
    }
    int r = AS_NUMBER(args[0]);
    int g = AS_NUMBER(args[1]);
    int b = AS_NUMBER(args[2]);

    clearBackground(r, g, b);
    return NIL_VAL;
}

Value drawTextNative(int argCount, Value *args)
{
    if (argCount != 7 || !IS_STRING(args[0]) || !IS_NUMBER(args[1]) || !IS_NUMBER(args[2]) ||
        !IS_NUMBER(args[3]) || !IS_NUMBER(args[4]) || !IS_NUMBER(args[5]))
    {
        fprintf(stderr, "drawText(text, x, y, fontSize, r, g, b) expected\n");
        return NIL_VAL;
    }

    const char *text = AS_CSTRING(args[0]);
    int x = AS_NUMBER(args[1]);
    int y = AS_NUMBER(args[2]);
    int fontSize = AS_NUMBER(args[3]);
    int r = AS_NUMBER(args[4]);
    int g = AS_NUMBER(args[5]);
    int b = AS_NUMBER(args[6]);

    drawText(text, x, y, fontSize, r, g, b);
    return NIL_VAL;
}

Value endDrawingNative(int argCount, Value *args)
{
    if (argCount != 0)
    {
        fprintf(stderr, "endDrawing() takes no arguments\n");
        return NIL_VAL;
    }
    endDrawing();
    return NIL_VAL;
}

Value windowShouldCloseNative(int argCount, Value *args)
{
    if (argCount != 0)
    {
        fprintf(stderr, "windowShouldClose() takes no arguments\n");
        return BOOL_VAL(windowShouldClose());
    }

    if (windowShouldClose())
    {
        return BOOL_VAL(true);
    }
    else
    {
        return BOOL_VAL(false);
    }
    return NIL_VAL;
}

Value drawRectangleNative(int argCount, Value *args)
{
    if (argCount != 7 || !IS_NUMBER(args[0]) || !IS_NUMBER(args[1]) || !IS_NUMBER(args[2]) ||
        !IS_NUMBER(args[3]) || !IS_NUMBER(args[4]) || !IS_NUMBER(args[5]) || !IS_NUMBER(args[6]))
    {
        fprintf(stderr, "drawRectangle(x, y, width, height, r, g, b) expected\n");
        return NIL_VAL;
    }

    int x = AS_NUMBER(args[0]);
    int y = AS_NUMBER(args[1]);
    int width = AS_NUMBER(args[2]);
    int height = AS_NUMBER(args[3]);
    int r = AS_NUMBER(args[4]);
    int g = AS_NUMBER(args[5]);
    int b = AS_NUMBER(args[6]);

    drawRectangle(x, y, width, height, r, g, b);
    return NIL_VAL;
}

Value drawCircleNative(int argCount, Value *args)
{
    if (argCount != 6 || !IS_NUMBER(args[0]) || !IS_NUMBER(args[1]) || !IS_NUMBER(args[2]) ||
        !IS_NUMBER(args[3]) || !IS_NUMBER(args[4]) || !IS_NUMBER(args[5]))
    {
        fprintf(stderr, "drawCircle(x, y, radius, r, g, b) expected\n");
        return NIL_VAL;
    }

    int x = AS_NUMBER(args[0]);
    int y = AS_NUMBER(args[1]);
    int radius = AS_NUMBER(args[2]);
    int r = AS_NUMBER(args[3]);
    int g = AS_NUMBER(args[4]);
    int b = AS_NUMBER(args[5]);

    drawCircle(x, y, radius, r, g, b);
    return NIL_VAL;
}

Value drawLineNative(int argCount, Value *args)
{
    if (argCount != 7 || !IS_NUMBER(args[0]) || !IS_NUMBER(args[1]) || !IS_NUMBER(args[2]) ||
        !IS_NUMBER(args[3]) || !IS_NUMBER(args[4]) || !IS_NUMBER(args[5]) || !IS_NUMBER(args[6]))
    {
        fprintf(stderr, "drawLine(x1, y1, x2, y2, r, g, b) expected\n");
        return NIL_VAL;
    }

    int x1 = AS_NUMBER(args[0]);
    int y1 = AS_NUMBER(args[1]);
    int x2 = AS_NUMBER(args[2]);
    int y2 = AS_NUMBER(args[3]);
    int r = AS_NUMBER(args[4]);
    int g = AS_NUMBER(args[5]);
    int b = AS_NUMBER(args[6]);

    drawLine(x1, y1, x2, y2, r, g, b);
    return NIL_VAL;
}

Value setTargetFPSNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_NUMBER(args[0]))
    {
        fprintf(stderr, "setTargetFPS(fps) expected\n");
        return NIL_VAL;
    }

    int fps = AS_NUMBER(args[0]);
    setTargetFPS(fps);
    return NIL_VAL;
}

Value isKeyDownNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_STRING(args[0]))
    {
        fprintf(stderr, "isKeyDown(string keyName) expected\n");
        return NIL_VAL;
    }

    const char *keyName = AS_CSTRING(args[0]);
    int key = KEY_NULL;

    if (strcmp(keyName, "KEY_UP") == 0)
        key = KEY_UP;
    else if (strcmp(keyName, "KEY_DOWN") == 0)
        key = KEY_DOWN;
    else if (strcmp(keyName, "KEY_LEFT") == 0)
        key = KEY_LEFT;
    else if (strcmp(keyName, "KEY_RIGHT") == 0)
        key = KEY_RIGHT;
    else if (strcmp(keyName, "KEY_W") == 0)
        key = KEY_W;
    else if (strcmp(keyName, "KEY_A") == 0)
        key = KEY_A;
    else if (strcmp(keyName, "KEY_S") == 0)
        key = KEY_S;
    else if (strcmp(keyName, "KEY_D") == 0)
        key = KEY_D;
    else if (strcmp(keyName, "KEY_SPACE") == 0)
        key = KEY_SPACE;
    else if (strcmp(keyName, "KEY_ENTER") == 0)
        key = KEY_ENTER;
    else if (strcmp(keyName, "KEY_ESCAPE") == 0)
        key = KEY_ESCAPE;
    else
    {
        fprintf(stderr, "Invalid key name: %s\n", keyName);
        return NIL_VAL;
    }

    return BOOL_VAL(isKeyDown(key));
}

Value isMouseButtonDownNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_STRING(args[0]))
    {
        fprintf(stderr, "isMouseButtonDown(string buttonName) expected.");
        return NIL_VAL;
    }

    const char *buttonName = AS_CSTRING(args[0]);

    int button = -1;

    if (strcmp(buttonName, "MOUSE_LEFT") == 0)
        button = 0;
    else if (strcmp(buttonName, "MOUSE_RIGHT") == 0)
        button = 1;
    else if (strcmp(buttonName, "MOUSE_MIDDLE") == 0)
        button = 2;
    else
    {
        fprintf(stderr, "Invalid button name: %s\n", buttonName);
        return NIL_VAL;
    }

    return BOOL_VAL(isMouseButtonDown(button));
}

// Window close
Value closeWindowNative(int argCount, Value *args)
{
    if (argCount != 0)
    {
        fprintf(stderr, "closeWindow() takes no arguments\n");
        return NIL_VAL;
    }
    closeWindow();
    return NIL_VAL;
}

// Window state
Value isWindowMinimizedNative(int argCount, Value *args)
{
    if (argCount != 0)
    {
        fprintf(stderr, "isWindowMinimized() takes no arguments\n");
        return NIL_VAL;
    }
    return BOOL_VAL(isWindowMinimized());
}

// Toggle borderless
Value toggleBorderlessWindowedNative(int argCount, Value *args)
{
    if (argCount != 0)
    {
        fprintf(stderr, "toggleBorderlessWindowed() takes no arguments\n");
        return NIL_VAL;
    }
    toggleBorderlessWindowed();
    return NIL_VAL;
}

// Screen info
Value getScreenWidthNative(int argCount, Value *args)
{
    if (argCount != 0)
    {
        fprintf(stderr, "getScreenWidth() takes no arguments\n");
        return NIL_VAL;
    }
    return NUMBER_VAL(getScreenWidth());
}

Value getScreenHeightNative(int argCount, Value *args)
{
    if (argCount != 0)
    {
        fprintf(stderr, "getScreenHeight() takes no arguments\n");
        return NIL_VAL;
    }
    return NUMBER_VAL(getScreenHeight());
}

Value getFPSNative(int argCount, Value *args)
{
    if (argCount != 0)
    {
        fprintf(stderr, "getFPS() takes no arguments\n");
        return NIL_VAL;
    }
    return NUMBER_VAL(getFPS());
}

void defineNative(const char *name, NativeFn function)
{
    ObjString *nameObj = copyString(name, (int)strlen(name));
    push(OBJ_VAL(nameObj));
    push(OBJ_VAL(newNative(function)));

    tableSet(&vm.globals, nameObj, vm.stackTop[-1]);
    pop();
    pop();
}
