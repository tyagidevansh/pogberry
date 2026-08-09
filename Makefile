CC ?= gcc

SRC_DIR := src
BUILD_DIR := build

ifeq ($(OS),Windows_NT)
EXEEXT := .exe
LDLIBS := -static -lm
MAKE_DIR = cmd /c if not exist "$(1)" mkdir "$(1)"
CLEAN_BUILD = cmd /c if exist "$(BUILD_DIR)" rmdir /S /Q "$(BUILD_DIR)"
else
EXEEXT :=
LDLIBS := -lm -lreadline -ldl
MAKE_DIR = mkdir -p "$(1)"
CLEAN_BUILD = rm -rf "$(BUILD_DIR)"
endif

TARGET := $(BUILD_DIR)/pogberry$(EXEEXT)
SOURCES := $(wildcard $(SRC_DIR)/*.c)
OBJECTS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SOURCES))
DEPS := $(OBJECTS:.o=.d)

CPPFLAGS := -I$(SRC_DIR)
CFLAGS := -std=c11 -Wall -Wextra -Wpedantic -MMD -MP
PYTHON ?= python
TEST_PATH ?=
TEST_ARGS ?=
TEST_RUNNER := tests/runner/run_tests.py

ifeq ($(OS),Windows_NT)
GUI_TEST_LIBRARY := $(BUILD_DIR)/pogberry_gui_test.dll
GUI_TEST_FLAGS :=
TEST_GUI_ENV := set "POGBERRY_GUI_LIBRARY=$(abspath $(GUI_TEST_LIBRARY))" &&
else
GUI_TEST_LIBRARY := $(BUILD_DIR)/pogberry_gui_test.so
GUI_TEST_FLAGS := -fPIC
TEST_GUI_ENV := POGBERRY_GUI_LIBRARY="$(abspath $(GUI_TEST_LIBRARY))"
endif

.PHONY: all test clean

all: $(TARGET)

$(TARGET): $(OBJECTS) | $(BUILD_DIR)
	$(CC) $(OBJECTS) $(LDFLAGS) $(LDLIBS) -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR):
	@$(call MAKE_DIR,$@)

test: $(TARGET) $(GUI_TEST_LIBRARY)
	@$(TEST_GUI_ENV) $(PYTHON) $(TEST_RUNNER) $(TEST_PATH) $(TEST_ARGS)

$(GUI_TEST_LIBRARY): tests/runner/fake_gui.c | $(BUILD_DIR)
	$(CC) -std=c11 -Wall -Wextra -Wpedantic $(GUI_TEST_FLAGS) -shared $< -o $@

clean:
	@$(CLEAN_BUILD)

-include $(DEPS)
