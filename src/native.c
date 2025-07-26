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

// map mouse button names to raylib constants
static int getMouseButtonCode(const char *name)
{
    if (strcmp(name, "LEFT") == 0)
        return 0;
    if (strcmp(name, "RIGHT") == 0)
        return 1;
    if (strcmp(name, "MIDDLE") == 0)
        return 2;
    return -1;
}

int getKeyCode(const char *name)
{
    if (strncmp(name, "KEY_", 4) != 0)
        return -1;
    switch (name[4])
    {
    case 'A':
        if (strcmp(name, "KEY_APOSTROPHE") == 0)
            return 39;
        if (strcmp(name, "KEY_A") == 0)
            return 65;
        break;
    case 'B':
        if (strcmp(name, "KEY_BACKSPACE") == 0)
            return 259;
        if (strcmp(name, "KEY_B") == 0)
            return 66;
        break;
    case 'C':
        if (strcmp(name, "KEY_CAPS_LOCK") == 0)
            return 280;
        if (strcmp(name, "KEY_COMMA") == 0)
            return 44;
        if (strcmp(name, "KEY_C") == 0)
            return 67;
        break;
    case 'D':
        if (strcmp(name, "KEY_DELETE") == 0)
            return 261;
        if (strcmp(name, "KEY_DOWN") == 0)
            return 264;
        if (strcmp(name, "KEY_D") == 0)
            return 68;
        break;
    case 'E':
        if (strcmp(name, "KEY_EQUAL") == 0)
            return 61;
        if (strcmp(name, "KEY_END") == 0)
            return 269;
        if (strcmp(name, "KEY_ENTER") == 0)
            return 257;
        if (strcmp(name, "KEY_ESCAPE") == 0)
            return 256;
        if (strcmp(name, "KEY_E") == 0)
            return 69;
        break;
    case 'F':
        if (strcmp(name, "KEY_F1") == 0)
            return 290;
        if (strcmp(name, "KEY_F2") == 0)
            return 291;
        if (strcmp(name, "KEY_F3") == 0)
            return 292;
        if (strcmp(name, "KEY_F4") == 0)
            return 293;
        if (strcmp(name, "KEY_F5") == 0)
            return 294;
        if (strcmp(name, "KEY_F6") == 0)
            return 295;
        if (strcmp(name, "KEY_F7") == 0)
            return 296;
        if (strcmp(name, "KEY_F8") == 0)
            return 297;
        if (strcmp(name, "KEY_F9") == 0)
            return 298;
        if (strcmp(name, "KEY_F10") == 0)
            return 299;
        if (strcmp(name, "KEY_F11") == 0)
            return 300;
        if (strcmp(name, "KEY_F12") == 0)
            return 301;
        if (strcmp(name, "KEY_F") == 0)
            return 70;
        break;
    case 'G':
        if (strcmp(name, "KEY_G") == 0)
            return 71;
        break;
    case 'H':
        if (strcmp(name, "KEY_HOME") == 0)
            return 268;
        if (strcmp(name, "KEY_H") == 0)
            return 72;
        break;
    case 'I':
        if (strcmp(name, "KEY_INSERT") == 0)
            return 260;
        if (strcmp(name, "KEY_I") == 0)
            return 73;
        break;
    case 'J':
        if (strcmp(name, "KEY_J") == 0)
            return 74;
        break;
    case 'K':
        if (strcmp(name, "KEY_KB_MENU") == 0)
            return 348;
        if (strcmp(name, "KEY_K") == 0)
            return 75;
        break;
    case 'L':
        if (strcmp(name, "KEY_LEFT") == 0)
            return 263;
        if (strcmp(name, "KEY_LEFT_ALT") == 0)
            return 342;
        if (strcmp(name, "KEY_LEFT_CONTROL") == 0)
            return 341;
        if (strcmp(name, "KEY_LEFT_SHIFT") == 0)
            return 340;
        if (strcmp(name, "KEY_LEFT_SUPER") == 0)
            return 343;
        if (strcmp(name, "KEY_L") == 0)
            return 76;
        break;
    case 'M':
        if (strcmp(name, "KEY_MINUS") == 0)
            return 45;
        if (strcmp(name, "KEY_M") == 0)
            return 77;
        break;
    case 'N':
        if (strcmp(name, "KEY_NUM_LOCK") == 0)
            return 282;
        if (strcmp(name, "KEY_N") == 0)
            return 78;
        break;
    case 'O':
        if (strcmp(name, "KEY_O") == 0)
            return 79;
        break;
    case 'P':
        if (strcmp(name, "KEY_PAGE_DOWN") == 0)
            return 267;
        if (strcmp(name, "KEY_PAGE_UP") == 0)
            return 266;
        if (strcmp(name, "KEY_PAUSE") == 0)
            return 284;
        if (strcmp(name, "KEY_PERIOD") == 0)
            return 46;
        if (strcmp(name, "KEY_PRINT_SCREEN") == 0)
            return 283;
        if (strcmp(name, "KEY_P") == 0)
            return 80;
        break;
    case 'Q':
        if (strcmp(name, "KEY_Q") == 0)
            return 81;
        break;
    case 'R':
        if (strcmp(name, "KEY_RIGHT") == 0)
            return 262;
        if (strcmp(name, "KEY_RIGHT_ALT") == 0)
            return 346;
        if (strcmp(name, "KEY_RIGHT_CONTROL") == 0)
            return 345;
        if (strcmp(name, "KEY_RIGHT_SHIFT") == 0)
            return 344;
        if (strcmp(name, "KEY_RIGHT_SUPER") == 0)
            return 347;
        if (strcmp(name, "KEY_R") == 0)
            return 82;
        break;
    case 'S':
        if (strcmp(name, "KEY_SCROLL_LOCK") == 0)
            return 281;
        if (strcmp(name, "KEY_SEMICOLON") == 0)
            return 59;
        if (strcmp(name, "KEY_SLASH") == 0)
            return 47;
        if (strcmp(name, "KEY_SPACE") == 0)
            return 32;
        if (strcmp(name, "KEY_S") == 0)
            return 83;
        break;
    case 'T':
        if (strcmp(name, "KEY_TAB") == 0)
            return 258;
        if (strcmp(name, "KEY_T") == 0)
            return 84;
        break;
    case 'U':
        if (strcmp(name, "KEY_UP") == 0)
            return 265;
        if (strcmp(name, "KEY_U") == 0)
            return 85;
        break;
    case 'V':
        if (strcmp(name, "KEY_V") == 0)
            return 86;
        break;
    case 'W':
        if (strcmp(name, "KEY_W") == 0)
            return 87;
        break;
    case 'X':
        if (strcmp(name, "KEY_X") == 0)
            return 88;
        break;
    case 'Y':
        if (strcmp(name, "KEY_Y") == 0)
            return 89;
        break;
    case 'Z':
        if (strcmp(name, "KEY_Z") == 0)
            return 90;
        break;
    }
    return -1;
}

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

Value getTime(int argCount, Value* args) {
    if (argCount != 0) 
    {
        runtimeError("getTime() accepts no arguments");
        return NIL_VAL;
    }

    return NUMBER_VAL((double)clock() / CLOCKS_PER_SEC);
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
    int key = getKeyCode(keyName);
    if (key < 0)
    {
        fprintf(stderr, "Invalid key name: %s\n", keyName);
        return NIL_VAL;
    }

    printf("key: %d\n", key);
    bool result = isKeyDown(key);
    printf("isKeyDown(%d) = %d\n", key, result);
    return BOOL_VAL(result);
}

Value isMouseButtonDownNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_STRING(args[0]))
    {
        fprintf(stderr, "isMouseButtonDown(string buttonName) expected.\n");
        return NIL_VAL;
    }
    const char *buttonName = AS_CSTRING(args[0]);
    int button = getMouseButtonCode(buttonName);
    if (button < 0)
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

// GUI native wrappers
Value swapScreenBufferNative(int argCount, Value *args)
{
    if (argCount != 0)
    {
        fprintf(stderr, "swapScreenBuffer() takes no arguments\n");
        return NIL_VAL;
    }
    swapScreenBuffer();
    return NIL_VAL;
}

Value drawPixelNative(int argCount, Value *args)
{
    if (argCount != 5 || !IS_NUMBER(args[0]) || !IS_NUMBER(args[1]) || !IS_NUMBER(args[2]) || !IS_NUMBER(args[3]) || !IS_NUMBER(args[4]))
    {
        fprintf(stderr, "drawPixel(x, y, r, g, b) expected\n");
        return NIL_VAL;
    }
    int x = AS_NUMBER(args[0]);
    int y = AS_NUMBER(args[1]);
    int r = AS_NUMBER(args[2]);
    int g = AS_NUMBER(args[3]);
    int b = AS_NUMBER(args[4]);
    drawPixel(x, y, r, g, b);
    return NIL_VAL;
}

Value drawEllipseNative(int argCount, Value *args)
{
    if (argCount != 7 || !IS_NUMBER(args[0]) || !IS_NUMBER(args[1]) || !IS_NUMBER(args[2]) || !IS_NUMBER(args[3]) || !IS_NUMBER(args[4]) || !IS_NUMBER(args[5]) || !IS_NUMBER(args[6]))
    {
        fprintf(stderr, "drawEllipse(x, y, radiusH, radiusV, r, g, b) expected\n");
        return NIL_VAL;
    }
    int x = AS_NUMBER(args[0]);
    int y = AS_NUMBER(args[1]);
    float radiusH = (float)AS_NUMBER(args[2]);
    float radiusV = (float)AS_NUMBER(args[3]);
    int r = AS_NUMBER(args[4]);
    int g = AS_NUMBER(args[5]);
    int b = AS_NUMBER(args[6]);
    drawEllipse(x, y, radiusH, radiusV, r, g, b);
    return NIL_VAL;
}

Value isKeyPressedNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_STRING(args[0]))
    {
        fprintf(stderr, "isKeyPressed(string keyName) expected\n");
        return NIL_VAL;
    }
    const char *name = AS_CSTRING(args[0]);
    int code = getKeyCode(name);
    if (code < 0)
    {
        fprintf(stderr, "Invalid key name: %s\n", name);
        return NIL_VAL;
    }
    return BOOL_VAL(isKeyPressed(code));
}

Value isKeyReleasedNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_STRING(args[0]))
    {
        fprintf(stderr, "isKeyReleased(string keyName) expected\n");
        return NIL_VAL;
    }
    const char *name = AS_CSTRING(args[0]);
    int code = getKeyCode(name);
    if (code < 0)
    {
        fprintf(stderr, "Invalid key name: %s\n", name);
        return NIL_VAL;
    }
    return BOOL_VAL(isKeyReleased(code));
}

Value isKeyUpNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_STRING(args[0]))
    {
        fprintf(stderr, "isKeyUp(string keyName) expected\n");
        return NIL_VAL;
    }
    const char *name = AS_CSTRING(args[0]);
    int code = getKeyCode(name);
    if (code < 0)
    {
        fprintf(stderr, "Invalid key name: %s\n", name);
        return NIL_VAL;
    }
    return BOOL_VAL(isKeyUp(code));
}

Value getKeyPressedNative(int argCount, Value *args)
{
    if (argCount != 0)
    {
        fprintf(stderr, "getKeyPressed() takes no arguments\n");
        return NIL_VAL;
    }
    return NUMBER_VAL(getKeyPressed());
}

Value getCharPressedNative(int argCount, Value *args)
{
    if (argCount != 0)
    {
        fprintf(stderr, "getCharPressed() takes no arguments\n");
        return NIL_VAL;
    }
    return NUMBER_VAL(getCharPressed());
}

Value setExitKeyNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_NUMBER(args[0]))
    {
        fprintf(stderr, "setExitKey(key) expected\n");
        return NIL_VAL;
    }
    int key = AS_NUMBER(args[0]);
    setExitKey(key);
    return NIL_VAL;
}

Value isMouseButtonPressedNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_STRING(args[0]))
    {
        fprintf(stderr, "isMouseButtonPressed(string buttonName) expected\n");
        return NIL_VAL;
    }
    const char *name = AS_CSTRING(args[0]);
    int button = getMouseButtonCode(name);
    if (button < 0)
    {
        fprintf(stderr, "Invalid button name: %s\n", name);
        return NIL_VAL;
    }
    return BOOL_VAL(isMouseButtonPressed(button));
}

Value isMouseButtonReleasedNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_STRING(args[0]))
    {
        fprintf(stderr, "isMouseButtonReleased(string buttonName) expected\n");
        return NIL_VAL;
    }
    const char *name = AS_CSTRING(args[0]);
    int button = getMouseButtonCode(name);
    if (button < 0)
    {
        fprintf(stderr, "Invalid button name: %s\n", name);
        return NIL_VAL;
    }
    return BOOL_VAL(isMouseButtonReleased(button));
}

Value isMouseButtonUpNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_STRING(args[0]))
    {
        fprintf(stderr, "isMouseButtonUp(string buttonName) expected\n");
        return NIL_VAL;
    }
    const char *name = AS_CSTRING(args[0]);
    int button = getMouseButtonCode(name);
    if (button < 0)
    {
        fprintf(stderr, "Invalid button name: %s\n", name);
        return NIL_VAL;
    }
    return BOOL_VAL(isMouseButtonUp(button));
}

Value getMouseXNative(int argCount, Value *args)
{
    if (argCount != 0)
    {
        fprintf(stderr, "getMouseX() takes no arguments\n");
        return NIL_VAL;
    }
    return NUMBER_VAL(getMouseX());
}

Value getMouseYNative(int argCount, Value *args)
{
    if (argCount != 0)
    {
        fprintf(stderr, "getMouseY() takes no arguments\n");
        return NIL_VAL;
    }
    return NUMBER_VAL(getMouseY());
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
