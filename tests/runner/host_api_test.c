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

  require(pogberryInterpret(
              firstVM,
              "use \"host.math\";\n"
              "fun update(dt) { return hostAdd(dt, 2); }\n"
              "fun greeting() { return \"he\" + \"llo\"; }\n"
              "fun identity(value) { return value; }\n"
              "print(hostAdd(3, 4));\n"
              "print(hostEcho(\"ready\"));\n") == INTERPRET_OK,
          "first VM interpretation");
  require(strcmp(first.output, "7\nready\n") == 0,
          "captured host-backed output");
  require(first.resolverCalls == 1, "lazy resolver called once");

  require(pogberryInterpret(firstVM,
                            "use \"host.math\"; print(hostAdd(1, 1));") ==
              INTERPRET_OK,
          "cached capability import");
  require(first.resolverCalls == 1, "capability cache");

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

  require(pogberryInterpret(secondVM, "use \"missing.capability\";") ==
              INTERPRET_RUNTIME_ERROR,
          "missing capability error");
  require(second.runtimeDiagnostics > 0, "runtime diagnostic callback");

  require(pogberryInterpret(firstVM, "hostAdd(\"bad\", 1);") ==
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
