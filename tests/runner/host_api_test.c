#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "headers/pogberry.h"

typedef struct
{
  char output[4096];
  size_t outputLength;
  char diagnostics[4096];
  size_t diagnosticLength;
  int resolverCalls;
  int compileDiagnostics;
  int runtimeDiagnostics;
} Capture;

static void append(char *buffer, size_t *length, size_t capacity,
                   const char *text, size_t textLength)
{
  if (*length + textLength >= capacity)
  {
    fprintf(stderr, "host API test buffer overflow\n");
    exit(1);
  }
  memcpy(buffer + *length, text, textLength);
  *length += textLength;
  buffer[*length] = '\0';
}

static void captureOutput(PogberryVM *instance, const char *text,
                          size_t length, void *userData)
{
  (void)instance;
  Capture *capture = (Capture *)userData;
  append(capture->output, &capture->outputLength, sizeof(capture->output),
         text, length);
}

static void captureDiagnostic(PogberryVM *instance,
                              PogberryDiagnosticKind kind,
                              const char *message, void *userData)
{
  (void)instance;
  Capture *capture = (Capture *)userData;
  append(capture->diagnostics, &capture->diagnosticLength,
         sizeof(capture->diagnostics), message, strlen(message));
  append(capture->diagnostics, &capture->diagnosticLength,
         sizeof(capture->diagnostics), "\n", 1);
  if (kind == POGBERRY_DIAGNOSTIC_COMPILE)
    capture->compileDiagnostics++;
  if (kind == POGBERRY_DIAGNOSTIC_RUNTIME)
    capture->runtimeDiagnostics++;
}

static PogberryValue addNative(PogberryVM *instance, int argCount,
                               const PogberryValue *args, void *userData)
{
  (void)userData;
  if (argCount != 2 || args[0].type != POGBERRY_VALUE_NUMBER ||
      args[1].type != POGBERRY_VALUE_NUMBER)
  {
    pogberryRuntimeError(instance, "hostAdd() expects two numbers.");
    return pogberryNilValue();
  }
  return pogberryNumberValue(args[0].as.number + args[1].as.number);
}

static PogberryValue echoNative(PogberryVM *instance, int argCount,
                                const PogberryValue *args, void *userData)
{
  (void)userData;
  if (argCount != 1 || args[0].type != POGBERRY_VALUE_STRING)
  {
    pogberryRuntimeError(instance, "hostEcho() expects a string.");
    return pogberryNilValue();
  }
  return pogberryStringValueN(args[0].as.string.chars,
                              args[0].as.string.length);
}

static PogberryValue tripleNative(PogberryVM *instance, int argCount,
                                  const PogberryValue *args, void *userData)
{
  (void)userData;
  if (argCount != 1 || args[0].type != POGBERRY_VALUE_NUMBER)
  {
    pogberryRuntimeError(instance, "triple() expects a number.");
    return pogberryNilValue();
  }
  return pogberryNumberValue(args[0].as.number * 3);
}

static bool resolveCapability(PogberryVM *instance, const char *name,
                              void *userData)
{
  Capture *capture = (Capture *)userData;
  capture->resolverCalls++;
  if (strcmp(name, "lazy.words") == 0)
  {
    return pogberryRegisterModuleSource(
        instance, name, "export fun label() { return \"nested\"; }\n");
  }
  if (strcmp(name, "host.math") != 0)
    return false;

  const PogberryNativeDefinition definitions[] = {
      {"hostAdd", addNative, NULL},
      {"hostEcho", echoNative, NULL},
  };
  return pogberryRegisterCapability(
      instance, name, definitions,
      sizeof(definitions) / sizeof(definitions[0]));
}

static void require(bool condition, const char *message)
{
  if (!condition)
  {
    fprintf(stderr, "host API test failed: %s\n", message);
    exit(1);
  }
}

static void requireNumber(PogberryValue value, double expected,
                          const char *message)
{
  require(value.type == POGBERRY_VALUE_NUMBER && value.as.number == expected,
          message);
}

int main(void)
{
  Capture first = {0};
  Capture second = {0};
  PogberryConfig firstConfig = {
      captureOutput, captureDiagnostic, resolveCapability, &first};
  PogberryConfig secondConfig = {
      captureOutput, captureDiagnostic, resolveCapability, &second};

  PogberryVM *firstVM = pogberryCreateVM(&firstConfig);
  PogberryVM *secondVM = pogberryCreateVM(&secondConfig);
  require(firstVM != NULL && secondVM != NULL, "VM creation");

  require(pogberryRegisterModuleSource(
              firstVM, "game.base", "export let seed = 40;\n"),
          "source dependency registration");
  require(pogberryRegisterModuleSource(
              firstVM, "game.counter",
              "use \"game.base\" as base;\n"
              "use \"host.math\" as math;\n"
              "use \"lazy.words\" as words;\n"
              "let hidden = base.seed;\n"
              "export let answer = math.hostAdd(hidden, 2);\n"
              "export fun increment() { answer = answer + 1; return answer; }\n"
              "export fun rootHidden() { return hidden; }\n"
              "export fun baseModule() { return base; }\n"
              "export fun label() { return words.label(); }\n"
              "export fun size(value) { return len(value); }\n"
              "export class Counter {\n"
              "  init(start) { this.value = start; }\n"
              "  next() { this.value = this.value + 1; return this.value; }\n"
              "}\n"),
          "source module registration");
  require(pogberryRegisterModuleSource(
              firstVM, "broken.module", "export fun broken( {\n"),
          "broken source module registration");
  require(pogberryRegisterModuleSource(
              firstVM, "bad.runtime",
              "export fun explode() { return 1 / 0; }\n"),
          "runtime-error source module registration");
  require(pogberryRegisterModuleSource(
              firstVM, "cycle.a",
              "use \"cycle.b\" as b; export let value = b.value;\n"),
          "first circular module registration");
  require(pogberryRegisterModuleSource(
              firstVM, "cycle.b",
              "use \"cycle.a\" as a; export let value = a.value;\n"),
          "second circular module registration");

  require(pogberryInterpret(
              firstVM,
              "use \"host.math\" as math;\n"
              "fun update(dt) { return math.hostAdd(dt, 2); }\n"
              "fun greeting() { return \"he\" + \"llo\"; }\n"
              "fun identity(value) { return value; }\n"
              "print(math.hostAdd(3, 4));\n"
              "print(math.hostEcho(\"ready\"));\n"
              "print(type(math));\n"
              "let add = math.hostAdd;\n"
              "print(add(2, 3));\n") == INTERPRET_OK,
          "first VM interpretation");
  require(strcmp(first.output, "7\nready\nmodule\n5\n") == 0,
          "captured host-backed output");
  require(first.resolverCalls == 1, "lazy resolver called once");

  require(pogberryInterpret(firstVM,
                            "use \"host.math\" as mathAgain; "
                            "print(mathAgain.hostAdd(1, 1)); "
                            "print(math == mathAgain);") ==
              INTERPRET_OK,
          "cached module import");
  require(strcmp(first.output, "7\nready\nmodule\n5\n2\ntrue\n") == 0,
          "cached module output");
  require(first.resolverCalls == 1, "module cache");

  require(pogberryInterpret(firstVM,
                            "use \"host.math\" as math;") ==
              INTERPRET_RUNTIME_ERROR,
          "duplicate import alias error");
  require(strstr(first.diagnostics,
                 "Import alias 'math' is already defined.") != NULL,
          "duplicate alias diagnostic");
  require(first.resolverCalls == 1, "duplicate alias skips resolution");

  require(pogberryInterpret(
              firstVM,
              "let hidden = 1000;\n"
              "use \"game.counter\" as counter;\n"
              "print(counter.answer);\n"
              "print(counter.increment());\n"
              "print(counter.answer);\n"
              "let increment = counter.increment;\n"
              "print(increment());\n"
              "print(counter.answer);\n"
              "print(counter.rootHidden());\n"
              "print(counter.label());\n"
              "print(counter.size([1, 2, 3]));\n"
              "let counterObject = counter.Counter(5);\n"
              "print(counterObject.next());\n") == INTERPRET_OK,
          "source module import");
  require(strcmp(first.output,
                 "7\nready\nmodule\n5\n2\ntrue\n42\n43\n43\n44\n44\n40\nnested\n3\n6\n") == 0,
          "source module output and isolation");
  require(first.resolverCalls == 2,
          "nested source dependency resolved lazily once");

  require(pogberryInterpret(
              firstVM,
              "use \"game.counter\" as counterAgain;\n"
              "use \"game.base\" as baseAgain;\n"
              "print(counter == counterAgain);\n"
              "print(counterAgain.answer);\n"
              "print(counter.baseModule() == baseAgain);\n") == INTERPRET_OK,
          "cached source module import");
  require(strcmp(first.output,
                 "7\nready\nmodule\n5\n2\ntrue\n42\n43\n43\n44\n44\n40\nnested\n3\n6\ntrue\n44\ntrue\n") == 0,
          "source module cache output");
  require(first.resolverCalls == 2, "nested dependency cache");

  require(pogberryInterpret(firstVM, "counter.hidden;") ==
              INTERPRET_RUNTIME_ERROR,
          "unexported source module global is hidden");
  require(strstr(first.diagnostics,
                 "Module 'game.counter' does not export 'hidden'.") != NULL,
          "unexported source module diagnostic");

  require(pogberryInterpret(firstVM, "answer;") == INTERPRET_RUNTIME_ERROR,
          "source module global does not leak into importer");
  require(strstr(first.diagnostics, "Undefined variable 'answer'.") != NULL,
          "source module isolation diagnostic");

  require(pogberryInterpret(firstVM, "base;") == INTERPRET_RUNTIME_ERROR,
          "source dependency alias does not leak into importer");

  require(pogberryInterpret(firstVM,
                            "use \"broken.module\" as broken;") ==
              INTERPRET_COMPILE_ERROR,
          "source module compile error");
  require(strstr(first.diagnostics, "[broken.module line 1]") != NULL,
          "source module compile identifier");

  require(pogberryInterpret(firstVM,
                            "use \"bad.runtime\" as bad; bad.explode();") ==
              INTERPRET_RUNTIME_ERROR,
          "source module runtime error");
  require(strstr(first.diagnostics,
                 "[bad.runtime line 1] in explode()") != NULL,
          "source module runtime identifier");

  require(pogberryInterpret(firstVM,
                            "use \"cycle.a\" as cycle;") ==
              INTERPRET_COMPILE_ERROR,
          "circular source module import");
  require(strstr(first.diagnostics,
                 "Circular import of module 'cycle.a'.") != NULL,
          "circular import diagnostic");
  require(strstr(first.diagnostics, "[cycle.b line 1] Load error:") != NULL,
          "circular import source identifier");

  PogberryValue result;
  PogberryValue borrowed;
  require(pogberryCall(firstVM, "greeting", 0, NULL, &borrowed) == INTERPRET_OK,
          "string return value");
  require(borrowed.type == POGBERRY_VALUE_STRING &&
              borrowed.as.string.length == 5 &&
              memcmp(borrowed.as.string.chars, "hello", 5) == 0,
          "borrowed string contents");
  require(pogberryCall(firstVM, "identity", 1, &borrowed, &result) == INTERPRET_OK,
          "pass borrowed value back to its VM");
  require(result.type == POGBERRY_VALUE_STRING && result.as.string.length == 5,
          "borrowed value round trip");

  require(pogberryInterpret(
              secondVM,
              "fun update(dt) { return dt * 10; } print(\"second\");") ==
              INTERPRET_OK,
          "second VM interpretation");
  require(strcmp(second.output, "second\n") == 0, "second VM output isolation");

  require(pogberryInterpret(
              firstVM,
              "use \"pogberry_gui\"; fun screenWidth() { return getScreenWidth(); }") ==
              INTERPRET_OK,
          "legacy GUI registration in first VM");
  require(pogberryInterpret(
              secondVM,
              "use \"pogberry_gui\"; fun screenWidth() { return getScreenWidth(); }") ==
              INTERPRET_OK,
          "legacy GUI registration in second VM");

  PogberryValue argument = pogberryNumberValue(5);
  require(pogberryCall(firstVM, "update", 1, &argument, &result) == INTERPRET_OK,
          "call first VM function");
  requireNumber(result, 7, "first VM return value");
  require(pogberryCall(secondVM, "update", 1, &argument, &result) == INTERPRET_OK,
          "call second VM function");
  requireNumber(result, 50, "second VM return value");

  argument = pogberryNumberValue(1);
  require(pogberryCall(firstVM, "update", 1, &argument, &result) == INTERPRET_OK,
          "reactivate first VM");
  requireNumber(result, 3, "independent first VM state");

  require(pogberryDefineNative(secondVM, "triple", tripleNative, NULL),
          "direct native registration");
  require(pogberryInterpret(secondVM, "print(triple(6));") == INTERPRET_OK,
          "direct native call");
  require(strcmp(second.output, "second\n18\n") == 0,
          "direct native output");

  require(pogberryInterpret(secondVM, "break;") == INTERPRET_COMPILE_ERROR,
          "compile diagnostic callback");
  require(second.compileDiagnostics == 3,
          "source, marker, and compile message diagnostics");

  require(pogberryInterpret(secondVM,
                            "use \"missing.capability\" as missing;") ==
              INTERPRET_RUNTIME_ERROR,
          "missing module error");
  require(second.runtimeDiagnostics > 0, "runtime diagnostic callback");

  require(pogberryInterpret(firstVM, "math.missing();") ==
              INTERPRET_RUNTIME_ERROR,
          "missing module export error");
  require(strstr(first.diagnostics,
                 "Module 'host.math' does not export 'missing'.") != NULL,
          "missing export diagnostic");

  require(pogberryInterpret(firstVM,
                            "math.hostAdd = math.hostEcho;") ==
              INTERPRET_RUNTIME_ERROR,
          "module exports are read-only");
  require(strstr(first.diagnostics, "Module exports are read-only.") != NULL,
          "read-only export diagnostic");

  require(pogberryInterpret(firstVM, "math.hostAdd(\"bad\", 1);") ==
              INTERPRET_RUNTIME_ERROR,
          "native callback runtime error");
  require(strstr(first.diagnostics, "hostAdd() expects two numbers.") != NULL,
          "native error message");

  argument = pogberryNumberValue(2);
  require(pogberryCall(secondVM, "update", 1, &argument, &result) == INTERPRET_OK,
          "VM remains usable after errors");
  requireNumber(result, 20, "post-error return value");

  pogberryDestroyVM(firstVM);
  require(pogberryCall(secondVM, "screenWidth", 0, NULL, &result) == INTERPRET_OK,
          "shared GUI binding survives first VM destruction");
  requireNumber(result, 800, "headless GUI result");
  pogberryDestroyVM(secondVM);
  puts("host API test passed");
  return 0;
}
