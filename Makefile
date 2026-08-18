CC ?= gcc
PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
RUNTIME_DIR ?= $(PREFIX)/lib/pb
INSTALL ?= install

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
CORE_LDLIBS := -lm -ldl
PLATFORM_CFLAGS := -fPIC
SHARED_LIBRARY := $(BUILD_DIR)/libpb.so
MAKE_DIR = mkdir -p "$(1)"
CLEAN_BUILD = rm -rf "$(BUILD_DIR)"
endif

TARGET := $(BUILD_DIR)/pb$(EXEEXT)
SOURCES := $(wildcard $(SRC_DIR)/*.c)
OBJECTS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SOURCES))
CORE_OBJECTS := $(filter-out $(BUILD_DIR)/main.o $(BUILD_DIR)/module_loader.o,$(OBJECTS))
DEPS := $(OBJECTS:.o=.d)

CPPFLAGS := -I$(SRC_DIR)
CFLAGS := -std=c11 -Wall -Wextra -Wpedantic -MMD -MP $(PLATFORM_CFLAGS)
PYTHON ?= python
TEST_PATH ?=
TEST_ARGS ?=
TEST_RUNNER := tests/runner/run_tests.py
CLI_MODULE_TEST := tests/runner/cli_module_test.py
HOST_API_TEST := $(BUILD_DIR)/host_api_test$(EXEEXT)

ifeq ($(OS),Windows_NT)
GUI_TEST_LIBRARY := $(BUILD_DIR)/pb_gui_test.dll
GUI_TEST_FLAGS :=
TEST_GUI_ENV := set "PB_GUI_LIBRARY=$(abspath $(GUI_TEST_LIBRARY))" &&
else
GUI_TEST_LIBRARY := $(BUILD_DIR)/pb_gui_test.so
GUI_TEST_FLAGS := -fPIC
TEST_GUI_ENV := PB_GUI_LIBRARY="$(abspath $(GUI_TEST_LIBRARY))"
endif

.PHONY: all shared test install clean

all: $(TARGET)

shared: $(SHARED_LIBRARY)

$(TARGET): $(OBJECTS) | $(BUILD_DIR)
	$(CC) $(OBJECTS) $(LDFLAGS) $(LDLIBS) -o $@

$(SHARED_LIBRARY): $(CORE_OBJECTS) | $(BUILD_DIR)
	$(CC) -shared $(CORE_OBJECTS) $(LDFLAGS) $(CORE_LDLIBS) -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR):
	@$(call MAKE_DIR,$@)

test: $(TARGET) $(GUI_TEST_LIBRARY) $(HOST_API_TEST)
	@$(TEST_GUI_ENV) $(HOST_API_TEST)
	@$(TEST_GUI_ENV) $(PYTHON) $(CLI_MODULE_TEST) $(TARGET)
	@$(TEST_GUI_ENV) $(PYTHON) $(TEST_RUNNER) $(TEST_PATH) $(TEST_ARGS)

ifeq ($(OS),Windows_NT)
install:
	@echo "make install is only available on Linux."
else
install: $(TARGET)
	$(INSTALL) -d "$(DESTDIR)$(BINDIR)" "$(DESTDIR)$(RUNTIME_DIR)"
	$(INSTALL) -m 755 "$(TARGET)" "$(DESTDIR)$(BINDIR)/pb"
	$(INSTALL) -m 644 "lib/pb_gui_linux.so" "$(DESTDIR)$(RUNTIME_DIR)/pb_gui_linux.so"
endif

$(GUI_TEST_LIBRARY): tests/runner/fake_gui.c | $(BUILD_DIR)
	$(CC) -std=c11 -Wall -Wextra -Wpedantic $(GUI_TEST_FLAGS) -shared $< -o $@

$(HOST_API_TEST): tests/runner/host_api_test.c $(CORE_OBJECTS) | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) -std=c11 -Wall -Wextra -Wpedantic $< $(CORE_OBJECTS) $(LDFLAGS) $(CORE_LDLIBS) -o $@

clean:
	@$(CLEAN_BUILD)

-include $(DEPS)
