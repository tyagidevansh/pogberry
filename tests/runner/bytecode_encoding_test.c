#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "headers/chunk.h"
#include "headers/pb.h"
#include "headers/vm.h"

#define FILLER_COUNT 260

static void require(bool condition, const char *message) {
  if (condition) return;
  fprintf(stderr, "bytecode encoding test failed: %s\n", message);
  exit(1);
}

typedef struct {
  char output[128];
  size_t length;
} Capture;

static void captureOutput(PbVM *instance, const char *text, size_t length, void *userData) {
  (void)instance;
  Capture *capture = (Capture *)userData;
  require(capture->length + length < sizeof(capture->output), "captured output fits");
  memcpy(capture->output + capture->length, text, length);
  capture->length += length;
  capture->output[capture->length] = '\0';
}

static char *sourceWithFillers(const char *prefix, const char *suffix) {
  size_t capacity = strlen(prefix) + strlen(suffix) + (size_t)FILLER_COUNT * 24 + 1;
  char *source = (char *)malloc(capacity);
  require(source != NULL, "source allocation");

  size_t length = (size_t)snprintf(source, capacity, "%s", prefix);
  for (int i = 0; i < FILLER_COUNT; i++) {
    int written = snprintf(source + length, capacity - length, "\"constant-%d\";\n", i);
    require(written > 0 && (size_t)written < capacity - length, "filler source construction");
    length += (size_t)written;
  }
  int written = snprintf(source + length, capacity - length, "%s", suffix);
  require(written >= 0 && (size_t)written < capacity - length, "source suffix construction");
  return source;
}

static void runLongConstantProgram(const char *prefix, const char *suffix, const char *expectedOutput) {
  Capture capture = {0};
  PbConfig config = {.write = captureOutput, .userData = &capture};
  PbVM *instance = pbCreateVM(&config);
  require(instance != NULL, "VM creation");

  char *source = sourceWithFillers(prefix, suffix);
  require(pbInterpret(instance, source) == INTERPRET_OK, "program with long constants executes");
  require(strcmp(capture.output, expectedOutput) == 0, "program with long constants has expected output");

  free(source);
  pbDestroyVM(instance);
}

static void testLongImportAndExport(void) {
  Capture capture = {0};
  PbConfig config = {.write = captureOutput, .userData = &capture};
  PbVM *instance = pbCreateVM(&config);
  require(instance != NULL, "VM creation for long import/export");

  char *moduleSource = sourceWithFillers("", "export let answer = 42;\n");
  require(pbRegisterModuleSource(instance, "constants.module", moduleSource), "long export module registration");
  free(moduleSource);

  char *source = sourceWithFillers("", "use \"constants.module\" as constants;\nprint(constants.answer);\n");
  require(pbInterpret(instance, source) == INTERPRET_OK, "program with long import/export executes");
  require(strcmp(capture.output, "42\n") == 0, "long import/export output");

  free(source);
  pbDestroyVM(instance);
}

int main(void) {
  uint8_t shortBytes[2];
  encodeU16BE(shortBytes, UINT16_C(0xBEEF));
  require(shortBytes[0] == UINT8_C(0xBE) && shortBytes[1] == UINT8_C(0xEF), "16-bit big-endian encoding");
  require(decodeU16BE(shortBytes) == UINT16_C(0xBEEF), "16-bit big-endian decoding");

  uint8_t longBytes[3];
  encodeU24LE(longBytes, UINT32_C(0xAB12EF));
  require(longBytes[0] == UINT8_C(0xEF) && longBytes[1] == UINT8_C(0x12) && longBytes[2] == UINT8_C(0xAB),
          "24-bit little-endian encoding");
  require(decodeU24LE(longBytes) == UINT32_C(0xAB12EF), "24-bit little-endian decoding");
  encodeU24LE(longBytes, BYTECODE_U24_MAX);
  require(decodeU24LE(longBytes) == BYTECODE_U24_MAX, "24-bit maximum value round trip");

  initVM();
  Chunk chunk;
  initChunk(&chunk);
  writeChunkU16BE(&chunk, UINT16_C(0xABCD), 11);
  writeChunkU24LE(&chunk, UINT32_C(0x123456), 12);

  require(chunk.count == 5, "multi-byte chunk writes append all bytes");
  require(decodeU16BE(chunk.code) == UINT16_C(0xABCD), "chunk 16-bit write order");
  require(decodeU24LE(&chunk.code[2]) == UINT32_C(0x123456), "chunk 24-bit write order");
  require(chunk.lines[0] == 11 && chunk.lines[1] == 11 && chunk.lines[2] == 12 && chunk.lines[4] == 12,
          "multi-byte chunk writes preserve line information");

  freeChunk(&chunk);
  freeVM();

  runLongConstantProgram(
      "",
      "class Box { init(value) { this.value = value; } add(value) { return this.value + value; } }\n"
      "let box = Box(40);\n"
      "print(box.value);\n"
      "box.value = 41;\n"
      "box = box;\n"
      "print(box.add(1));\n"
      "fun functionConstant() { return 7; }\n"
      "print(functionConstant());\n",
      "40\n42\n7\n");

  testLongImportAndExport();

  runLongConstantProgram(
      "class Base { answer() { return 42; } }\nclass Child < Base { answer() {\n",
      "let method = super.answer;\nreturn method();\n} }\nprint(Child().answer());\n",
      "42\n");

  runLongConstantProgram(
      "class Base { answer() { return 42; } }\nclass Child < Base { answer() {\n",
      "return super.answer();\n} }\nprint(Child().answer());\n",
      "42\n");

  return 0;
}
