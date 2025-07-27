#include <stdio.h>
#include "headers/pogberry.h"

// build script will replace this
const char POGBERRY_SCRIPT[] = "print(\"hello world!\");\n";

int main() {
    printf("HERE \n");
    printf("%s", POGBERRY_SCRIPT);
    ext_interpret(POGBERRY_SCRIPT);    
    return 0;
}

// gcc -shared -o lib/pogberry.dll src/value.c src/memory.c src/chunk.c src/native.c src/debug.c src/vm.c src/scanner.c src/compiler.c src/object.c src/table.c  