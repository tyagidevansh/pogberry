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

OPTFLAGS ?= -O3 -DNDEBUG
CPPFLAGS := -I$(SRC_DIR)
CFLAGS := $(OPTFLAGS) -std=c11 -Wall -Wextra -Wpedantic -MMD -MP $(PLATFORM_CFLAGS)
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

.PHONY: all release shared raylib-backend test bench install clean

all: $(TARGET)

release: all

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

FILTER ?= $(TEST)
BENCH_FILTER_FLAG := $(if $(FILTER),--filter $(FILTER),)
BENCH_GUI_FLAG := $(if $(findstring no,$(GUI))$(findstring 0,$(GUI))$(NO_GUI),--no-gui,)
BENCH_RUNS_FLAG := $(if $(RUNS),--runs $(RUNS),)
BENCH_WARMUP_FLAG := $(if $(WARMUP),--warmup $(WARMUP),)
BENCH_PERF_FLAG := $(if $(NO_PERF),--no-perf,)

BENCH_ARGS ?= --html bench/report.html --json $(BENCH_FILTER_FLAG) $(BENCH_GUI_FLAG) $(BENCH_RUNS_FLAG) $(BENCH_WARMUP_FLAG) $(BENCH_PERF_FLAG)

bench: $(TARGET)
	@$(PYTHON) $(BENCH_RUNNER) --binary $(TARGET) $(BENCH_ARGS)

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
