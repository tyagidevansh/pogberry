CC ?= gcc
PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
RUNTIME_DIR ?= $(PREFIX)/lib/pb
DATADIR ?= $(PREFIX)/share/pb
STDLIB_DIR ?= $(DATADIR)/stdlib
INSTALL ?= install
PKG_CONFIG ?= pkg-config

SRC_DIR := src
BUILD_DIR := build
RELEASE_BUILD_DIR := build/release

ifeq ($(OS),Windows_NT)
EXEEXT := .exe
LDLIBS := -static -lm
CORE_LDLIBS := -static -lm
PLATFORM_CFLAGS :=
SHARED_LIBRARY := $(BUILD_DIR)/pb.dll
MAKE_DIR = cmd /c if not exist "$(1)" mkdir "$(1)"
CLEAN_BUILD = cmd /c if exist "$(BUILD_DIR)" rmdir /S /Q "$(BUILD_DIR)"
else
EXEEXT :=
LDLIBS := -lm -lreadline -ldl
CORE_LDLIBS := -lm
PLATFORM_CFLAGS := -fPIC
SHARED_LIBRARY := $(BUILD_DIR)/libpb.so
MAKE_DIR = mkdir -p "$(1)"
CLEAN_BUILD = rm -rf "$(BUILD_DIR)"
endif

TARGET := $(BUILD_DIR)/pb$(EXEEXT)
CORE_SOURCES := $(wildcard $(SRC_DIR)/*.c)
HOST_SOURCES := $(wildcard $(SRC_DIR)/host/*.c) \
	$(wildcard $(SRC_DIR)/host/modules/*.c)
CORE_OBJECTS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(CORE_SOURCES))
HOST_OBJECTS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(HOST_SOURCES))
OBJECTS := $(CORE_OBJECTS) $(HOST_OBJECTS)
DEPS := $(OBJECTS:.o=.d)

CPPFLAGS := -I$(SRC_DIR)
CFLAGS := -std=c11 -Wall -Wextra -Wpedantic -MMD -MP $(PLATFORM_CFLAGS)
PYTHON ?= python
TEST_PATH ?=
TEST_ARGS ?=
TEST_RUNNER := tests/runner/run_tests.py
CLI_MODULE_TEST := tests/runner/cli_module_test.py
HOST_API_TEST := $(BUILD_DIR)/host_api_test$(EXEEXT)
BYTECODE_ENCODING_TEST := $(BUILD_DIR)/bytecode_encoding_test$(EXEEXT)
BENCH_RUNNER := bench/run_bench.py
RAYLIB_BACKEND := $(BUILD_DIR)/pb_raylib_linux.so
RAYLIB_CFLAGS ?= $(shell $(PKG_CONFIG) --cflags raylib)
RAYLIB_LIBS ?= $(shell $(PKG_CONFIG) --libs raylib)

ifeq ($(OS),Windows_NT)
RAYLIB_TEST_LIBRARY := $(BUILD_DIR)/pb_raylib_test.dll
RAYLIB_TEST_FLAGS :=
TEST_RAYLIB_ENV := set "PB_RAYLIB_LIBRARY=$(abspath $(RAYLIB_TEST_LIBRARY))" &&
else
RAYLIB_TEST_LIBRARY := $(BUILD_DIR)/pb_raylib_test.so
RAYLIB_TEST_FLAGS := -fPIC
TEST_RAYLIB_ENV := PB_RAYLIB_LIBRARY="$(abspath $(RAYLIB_TEST_LIBRARY))"
endif

RELEASE_CORE_OBJECTS := $(patsubst $(SRC_DIR)/%.c,$(RELEASE_BUILD_DIR)/%.o,$(CORE_SOURCES))
RELEASE_HOST_OBJECTS := $(patsubst $(SRC_DIR)/%.c,$(RELEASE_BUILD_DIR)/%.o,$(HOST_SOURCES))
RELEASE_OBJECTS := $(RELEASE_CORE_OBJECTS) $(RELEASE_HOST_OBJECTS)
RELEASE_TARGET := $(RELEASE_BUILD_DIR)/pb$(EXEEXT)

.PHONY: all release shared raylib-backend test bench install clean

release: $(RELEASE_TARGET)
	strip $(RELEASE_TARGET)

$(RELEASE_BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@$(call MAKE_DIR,$(@D))
	$(CC) $(CPPFLAGS) $(CFLAGS) -O3 -DNDEBUG -c $< -o $@

$(RELEASE_TARGET): $(RELEASE_OBJECTS) | $(RELEASE_BUILD_DIR)
	$(CC) $(RELEASE_OBJECTS) $(LDFLAGS) $(LDLIBS) -o $@

$(RELEASE_BUILD_DIR):
	@$(call MAKE_DIR,$@)

all: $(TARGET)

shared: $(SHARED_LIBRARY)

ifeq ($(OS),Windows_NT)
raylib-backend:
	@echo "raylib-backend is currently only available on Linux."
else
raylib-backend: $(RAYLIB_BACKEND)

$(RAYLIB_BACKEND): backends/raylib/linux.c | $(BUILD_DIR)
	@$(PKG_CONFIG) --exists raylib || { echo "Raylib development files were not found. Install raylib-devel."; exit 1; }
	$(CC) -std=c11 -Wall -Wextra -Wpedantic -fPIC $(RAYLIB_CFLAGS) -shared $< -o $@ $(RAYLIB_LIBS)
endif

$(TARGET): $(OBJECTS) | $(BUILD_DIR)
	$(CC) $(OBJECTS) $(LDFLAGS) $(LDLIBS) -o $@

$(SHARED_LIBRARY): $(CORE_OBJECTS) | $(BUILD_DIR)
	$(CC) -shared $(CORE_OBJECTS) $(LDFLAGS) $(CORE_LDLIBS) -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@$(call MAKE_DIR,$(@D))
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR):
	@$(call MAKE_DIR,$@)

test: $(TARGET) $(RAYLIB_TEST_LIBRARY) $(HOST_API_TEST) $(BYTECODE_ENCODING_TEST)
	@$(TEST_RAYLIB_ENV) $(HOST_API_TEST)
	@$(BYTECODE_ENCODING_TEST)
	@$(TEST_RAYLIB_ENV) $(PYTHON) $(CLI_MODULE_TEST) $(TARGET)
	@$(TEST_RAYLIB_ENV) $(PYTHON) $(TEST_RUNNER) $(TEST_PATH) $(TEST_ARGS)

bench: $(RELEASE_TARGET)
	@$(PYTHON) $(BENCH_RUNNER) --binary $(RELEASE_TARGET)

ifeq ($(OS),Windows_NT)
install:
	@echo "make install is only available on Linux."
else
install: $(TARGET)
	$(INSTALL) -d "$(DESTDIR)$(BINDIR)" "$(DESTDIR)$(RUNTIME_DIR)" "$(DESTDIR)$(STDLIB_DIR)"
	$(INSTALL) -m 755 "$(TARGET)" "$(DESTDIR)$(BINDIR)/pb"
	$(INSTALL) -m 644 "lib/pb_raylib_linux.so" "$(DESTDIR)$(RUNTIME_DIR)/pb_raylib_linux.so"
	$(INSTALL) -m 644 "lib/pb_raylib_runtime_linux.so" "$(DESTDIR)$(RUNTIME_DIR)/pb_raylib_runtime_linux.so"
	$(INSTALL) -m 644 "stdlib/std.math.pb" "$(DESTDIR)$(STDLIB_DIR)/std.math.pb"
endif

$(RAYLIB_TEST_LIBRARY): tests/runner/fake_raylib.c | $(BUILD_DIR)
	$(CC) -std=c11 -Wall -Wextra -Wpedantic $(RAYLIB_TEST_FLAGS) -shared $< -o $@

$(HOST_API_TEST): tests/runner/host_api_test.c $(CORE_OBJECTS) | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) -std=c11 -Wall -Wextra -Wpedantic $< $(CORE_OBJECTS) $(LDFLAGS) $(CORE_LDLIBS) -o $@

$(BYTECODE_ENCODING_TEST): tests/runner/bytecode_encoding_test.c $(CORE_OBJECTS) | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) -std=c11 -Wall -Wextra -Wpedantic $< $(CORE_OBJECTS) $(LDFLAGS) $(CORE_LDLIBS) -o $@

clean:
	@$(CLEAN_BUILD)

-include $(DEPS)
