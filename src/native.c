#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

#include "headers/native.h"
#include "headers/memory.h"
#include "headers/object.h"
#include "headers/vm.h"

Value clockNative(int argCount, Value *args)
{
    (void)args;
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

Value listSortNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_LIST(args[0])) {
        runtimeError("sort() expects a list and no arguments.");
        return NIL_VAL;
    }

    ObjList *list = AS_LIST(args[0]);
    if (list->items.count < 2) {
        return NIL_VAL;
    }

    ValueType elementType = list->items.values[0].type;
    if (elementType != VAL_NUMBER &&
        !(elementType == VAL_OBJ && IS_STRING(list->items.values[0]))) {
        runtimeError("sort() only supports lists of numbers or strings.");
        return NIL_VAL;
    }

    for (int i = 1; i < list->items.count; i++) {
        Value element = list->items.values[i];
        if (element.type != elementType ||
            (elementType == VAL_OBJ && !IS_STRING(element))) {
            runtimeError("sort() requires values of one supported type.");
            return NIL_VAL;
        }
    }

    qsort(list->items.values, list->items.count, sizeof(Value), Valuecomp);
    return NIL_VAL;
}

Value listPushNative(int argCount, Value *args)
{
    if (argCount != 2 || !IS_LIST(args[0]))
    {
        runtimeError("push() expects one value.");
        return NIL_VAL;
    }

    ObjList *list = AS_LIST(args[0]);
    writeValueArray(&list->items, args[1]);

    return NIL_VAL;
}

static bool normalizeListIndex(Value indexValue, int listCount, int *outIndex)
{
    if (!IS_NUMBER(indexValue)) {
        runtimeError("List index must be a number.");
        return false;
    }

    double index = AS_NUMBER(indexValue);
    if (!isfinite(index) || floor(index) != index) {
        runtimeError("List index must be a finite integer.");
        return false;
    }

    if (index < 0) {
        index += listCount;
    }

    if (index < 0 || index >= listCount) {
        runtimeError("List index out of bounds.");
        return false;
    }

    *outIndex = (int)index;
    return true;
}

static bool normalizeInsertIndex(Value indexValue, int listCount, int *outIndex)
{
    if (!IS_NUMBER(indexValue)) {
        runtimeError("List index must be a number.");
        return false;
    }

    double index = AS_NUMBER(indexValue);
    if (!isfinite(index) || floor(index) != index) {
        runtimeError("List index must be a finite integer.");
        return false;
    }

    if (index < 0) {
        index += listCount;
    }

    if (index < 0) {
        index = 0;
    } else if (index > listCount) {
        index = listCount;
    }

    *outIndex = (int)index;
    return true;
}

Value listExtendNative(int argCount, Value *args)
{
    if (argCount != 2 || !IS_LIST(args[0]) || !IS_LIST(args[1])) {
        runtimeError("extend() expects two lists.");
        return NIL_VAL;
    }

    ObjList *list = AS_LIST(args[0]);
    ObjList *other = AS_LIST(args[1]);
    int otherCount = other->items.count;

    for (int i = 0; i < otherCount; i++) {
        writeValueArray(&list->items, other->items.values[i]);
    }

    return NIL_VAL;
}

Value listPopNative(int argCount, Value *args)
{
    if ((argCount != 1 && argCount != 2) || !IS_LIST(args[0])) {
        runtimeError("pop() expects a list and an optional index.");
        return NIL_VAL;
    }

    ObjList *list = AS_LIST(args[0]);
    if (list->items.count == 0) {
        runtimeError("Cannot pop from an empty list.");
        return NIL_VAL;
    }

    int index = list->items.count - 1;
    if (argCount == 2 &&
        !normalizeListIndex(args[1], list->items.count, &index)) {
        return NIL_VAL;
    }

    Value value = list->items.values[index];
    memmove(&list->items.values[index],
            &list->items.values[index + 1],
            sizeof(Value) * (list->items.count - index - 1));
    list->items.count--;

    return value;
}

Value listInsertNative(int argCount, Value *args)
{
    if (argCount != 3 || !IS_LIST(args[0])) {
        runtimeError("insert() expects a list, an index, and a value.");
        return NIL_VAL;
    }

    ObjList *list = AS_LIST(args[0]);
    int index;
    if (!normalizeInsertIndex(args[1], list->items.count, &index)) {
        return NIL_VAL;
    }

    int oldCount = list->items.count;
    writeValueArray(&list->items, NIL_VAL);
    memmove(&list->items.values[index + 1],
            &list->items.values[index],
            sizeof(Value) * (oldCount - index));
    list->items.values[index] = args[2];

    return NIL_VAL;
}

Value listRemoveNative(int argCount, Value *args)
{
    if (argCount != 2 || !IS_LIST(args[0])) {
        runtimeError("remove() expects a list and a value.");
        return NIL_VAL;
    }

    ObjList *list = AS_LIST(args[0]);
    for (int i = 0; i < list->items.count; i++) {
        if (!valuesEqual(list->items.values[i], args[1])) {
            if (vm.hadRuntimeError) return NIL_VAL;
            continue;
        }

        memmove(&list->items.values[i],
                &list->items.values[i + 1],
                sizeof(Value) * (list->items.count - i - 1));
        list->items.count--;
        return NIL_VAL;
    }

    runtimeError("List value not found.");
    return NIL_VAL;
}

Value listRemoveAtNative(int argCount, Value *args)
{
    if (argCount != 2 || !IS_LIST(args[0])) {
        runtimeError("removeAt() expects a list and an index.");
        return NIL_VAL;
    }

    ObjList *list = AS_LIST(args[0]);
    int index;
    if (!normalizeListIndex(args[1], list->items.count, &index)) {
        return NIL_VAL;
    }

    Value value = list->items.values[index];
    memmove(&list->items.values[index],
            &list->items.values[index + 1],
            sizeof(Value) * (list->items.count - index - 1));
    list->items.count--;

    return value;
}

Value listClearNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_LIST(args[0])) {
        runtimeError("clear() expects a list.");
        return NIL_VAL;
    }

    AS_LIST(args[0])->items.count = 0;
    return NIL_VAL;
}

Value listCopyNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_LIST(args[0])) {
        runtimeError("copy() expects a list.");
        return NIL_VAL;
    }

    ObjList *source = AS_LIST(args[0]);
    ObjList *copy = newList();

    // Keep the new list reachable if growing its backing array triggers GC.
    push(OBJ_VAL(copy));
    for (int i = 0; i < source->items.count; i++) {
        writeValueArray(&copy->items, source->items.values[i]);
    }
    return pop();
}

Value listIndexNative(int argCount, Value *args)
{
    if (argCount != 2 || !IS_LIST(args[0])) {
        runtimeError("index() expects a list and a value.");
        return NIL_VAL;
    }

    ObjList *list = AS_LIST(args[0]);
    for (int i = 0; i < list->items.count; i++) {
        if (valuesEqual(list->items.values[i], args[1])) {
            return NUMBER_VAL(i);
        }
        if (vm.hadRuntimeError) return NIL_VAL;
    }

    runtimeError("List value not found.");
    return NIL_VAL;
}

Value listCountNative(int argCount, Value *args)
{
    if (argCount != 2 || !IS_LIST(args[0])) {
        runtimeError("count() expects a list and a value.");
        return NIL_VAL;
    }

    ObjList *list = AS_LIST(args[0]);
    int count = 0;
    for (int i = 0; i < list->items.count; i++) {
        if (valuesEqual(list->items.values[i], args[1])) {
            count++;
        }
        if (vm.hadRuntimeError) return NIL_VAL;
    }

    return NUMBER_VAL(count);
}

Value listReverseNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_LIST(args[0])) {
        runtimeError("reverse() expects a list.");
        return NIL_VAL;
    }

    ObjList *list = AS_LIST(args[0]);
    for (int left = 0, right = list->items.count - 1; left < right;
         left++, right--) {
        Value temporary = list->items.values[left];
        list->items.values[left] = list->items.values[right];
        list->items.values[right] = temporary;
    }

    return NIL_VAL;
}

Value mapHasNative(int argCount, Value *args)
{
    if (argCount != 2 || !IS_HASHMAP(args[0])) {
        runtimeError("has() expects a map and a key.");
        return NIL_VAL;
    }
    if (!mapKeyIsValid(args[1])) {
        runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
        return NIL_VAL;
    }

    Value value;
    return BOOL_VAL(mapGet(&AS_HASHMAP(args[0])->items, args[1], &value));
}

Value mapGetNative(int argCount, Value *args)
{
    if (argCount != 3 || !IS_HASHMAP(args[0])) {
        runtimeError("get() expects a map, a key, and a default value.");
        return NIL_VAL;
    }
    if (!mapKeyIsValid(args[1])) {
        runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
        return NIL_VAL;
    }

    Value value;
    if (mapGet(&AS_HASHMAP(args[0])->items, args[1], &value)) {
        return value;
    }
    return args[2];
}

Value mapDeleteNative(int argCount, Value *args)
{
    if (argCount != 2 || !IS_HASHMAP(args[0])) {
        runtimeError("delete() expects a map and a key.");
        return NIL_VAL;
    }
    if (!mapKeyIsValid(args[1])) {
        runtimeError("Map keys must be nil, booleans, finite numbers, or strings.");
        return NIL_VAL;
    }

    return BOOL_VAL(mapDelete(&AS_HASHMAP(args[0])->items, args[1]));
}

Value mapClearNative(int argCount, Value *args)
{
    if (argCount != 1 || !IS_HASHMAP(args[0])) {
        runtimeError("clear() expects a map.");
        return NIL_VAL;
    }

    mapClear(&AS_HASHMAP(args[0])->items);
    return NIL_VAL;
}

Value lenNative(int argCount, Value *args)
{
    if (argCount != 1) {
        runtimeError("len() expects one value.");
        return NIL_VAL;
    }

    if (IS_STRING(args[0])) return NUMBER_VAL(AS_STRING(args[0])->length);
    if (IS_LIST(args[0])) return NUMBER_VAL(AS_LIST(args[0])->items.count);
    if (IS_HASHMAP(args[0])) return NUMBER_VAL(mapCount(&AS_HASHMAP(args[0])->items));

    runtimeError("len() expects a string, list, or map.");
    return NIL_VAL;
}

Value typeNative(int argCount, Value *args)
{
    if (argCount != 1) {
        runtimeError("type() expects one value.");
        return NIL_VAL;
    }

    const char* name;
    if (IS_NIL(args[0])) name = "nil";
    else if (IS_BOOL(args[0])) name = "bool";
    else if (IS_NUMBER(args[0])) name = "number";
    else if (IS_STRING(args[0])) name = "string";
    else if (IS_LIST(args[0])) name = "list";
    else if (IS_HASHMAP(args[0])) name = "map";
    else if (IS_CLOSURE(args[0])) name = "function";
    else if (IS_NATIVE(args[0])) name = "native";
    else if (IS_CLASS(args[0])) name = "class";
    else if (IS_INSTANCE(args[0])) name = "instance";
    else name = "bound_method";

    return OBJ_VAL(copyString(name, strlen(name)));
}

Value strNative(int argCount, Value *args)
{
    if (argCount != 1) {
        runtimeError("str() expects one value.");
        return NIL_VAL;
    }

    return OBJ_VAL(valueToString(args[0]));
}

Value getTime(int argCount, Value* args) {
    (void)args;
    if (argCount != 0) 
    {
        runtimeError("getTime() accepts no arguments");
        return NIL_VAL;
    }

    return NUMBER_VAL((double)clock() / CLOCKS_PER_SEC);
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
