#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "common.h"
#include "chunk.h"
#include "debug.h"
#include "vm.h"

// read-eval-print loop (write code on the terminal)
static void repl() {
  char line[1024];
  for (;;) {
    printf("> ");

    if (!fgets(line, sizeof(line), stdin)) { // buffer, size of buffer, input stream (params)
      printf("\n");
      break;
    }

    interpret(line);
  }
}

static char* readFile(const char* path) {
  FILE* file = fopen(path, "rb"); // rb = read binary, wont convert stuff like newlines
  // handle if we fail to open the file for eg if user typed the wrong path
  if (file == NULL) {
    fprintf(stderr, "Could not open file \"%s\".\n", path);
    exit(74);
  }

  fseek(file, 0L, SEEK_END); //move the file pointer from offset 0 to the end of the file
  size_t fileSize = ftell(file); // ftell tells the value of the the FILE pointer, as file as at the end it returns the size of the file
  rewind(file);  // return the file pointer to the start

  char* buffer = (char*)malloc(fileSize + 1); // allocate a string thats just the right size for the whole file to fit
  // if we cant even allocate enough memory read the file (crazy)
  if (buffer == NULL) {
    fprintf(stderr, "Not enough memory to read \"%s\".\n", path);
    exit(74);
  }

  size_t bytesRead = fread(buffer, sizeof(char), fileSize, file); // read the file and put its entire contents in the string
  // if the read itself fails (rare0)
  if (bytesRead < fileSize) {
    fprintf(stderr, "Could not read file \"%s\".\n", path);
    exit(74);
  }
  buffer[bytesRead] = '\0'; // terminate the string

  fclose(file);
  return buffer; // return the string to runFile 
}

// execute code from a text file
static void runFile(const char* path) {
  char* source = readFile(path); // dynamically allocates and passes ownership to caller, so need to free the source
  InterpretResult result = interpret(source);
  free(source);

  if (result == INTERPRET_COMPILE_ERROR) exit(65);
  if (result == INTERPRET_RUNTIME_ERROR) exit(70);
}

int main(int argc, const char* argv[]) {
  initVM();

  if (argc == 1) {
    repl();
  } else if (argc == 2) {
    runFile(argv[1]);
  } else {
    fprintf(stderr, "Usage: clox [path]\n");
    exit(64);
  }

  return 0;
}