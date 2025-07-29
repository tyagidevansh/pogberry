#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <stdint.h>
#include "src/headers/pogberry.h"

// build script will replace this
const char POGBERRY_SCRIPT[] = "/* SCRIPT_CONTENT_HERE */";

int main()
{
    ext_initVM();
    // printf("%s", POGBERRY_SCRIPT);
    ext_interpret(POGBERRY_SCRIPT);
    return 0;
}

// gcc -shared -o lib/pogberry.dll src/main.c src/value.c src/memory.c src/chunk.c src/native.c src/debug.c src/vm.c src/scanner.c src/compiler.c src/object.c src/table.c
// gcc -shared -o pogberry.dll value.c memory.c chunk.c native.c debug.c vm.c scanner.c compiler.c object.c table.c