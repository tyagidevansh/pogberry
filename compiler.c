#include <stdio.h>

#include "common.h"
#include "compiler.h"
#include "scanner.h"

void compile(const char* source) {
  initScanner(source);
  // temporary code to drive the scanner, as our compiler cannot yet ask the scanner for tokens
  int line = -1;
  for (;;) {
    Token token = scanToken();
    if (token.line != line) {
      printf("%4d ", token.line);
      line = token.line;
    } else {
      printf("  | ");
    }
    printf("%2d '%.*s'\n", token.type, token.length, token.start); // %.*s  allows us to pass the length of the string as an argument

    if (token.type == TOKEN_EOF) break;
  }
}