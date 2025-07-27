#ifndef pogberry_h
#define pogberry_h

#ifdef _WIN32
    #define POGBERRY_API __declspec(dllexport)
#else
    #define POGBERRY_API
#endif

typedef enum {
  INTERPRET_OK,
  INTERPRET_COMPILE_ERROR,
  INTERPRET_RUNTIME_ERROR
} InterpretResult;

POGBERRY_API void ext_initVM();
POGBERRY_API InterpretResult ext_interpret(const char* source);

#endif