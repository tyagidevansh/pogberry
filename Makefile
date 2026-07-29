CC ?= gcc

SRC_DIR := src
BUILD_DIR := build

ifeq ($(OS),Windows_NT)
EXEEXT := .exe
LDLIBS := -static -lm
TEST_RUNNER := cmd /c tests\run_tests.bat
MAKE_DIR = cmd /c if not exist "$(1)" mkdir "$(1)"
CLEAN_BUILD = cmd /c if exist "$(BUILD_DIR)" rmdir /S /Q "$(BUILD_DIR)"
else
EXEEXT :=
LDLIBS := -lm -lreadline
TEST_RUNNER := bash tests/run_tests.sh
MAKE_DIR = mkdir -p "$(1)"
CLEAN_BUILD = rm -rf "$(BUILD_DIR)"
endif

TARGET := $(BUILD_DIR)/pogberry$(EXEEXT)
SOURCES := $(wildcard $(SRC_DIR)/*.c)
OBJECTS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SOURCES))
DEPS := $(OBJECTS:.o=.d)

CPPFLAGS := -I$(SRC_DIR)
CFLAGS := -std=c11 -Wall -Wextra -Wpedantic -MMD -MP
TEST_PATH ?=

.PHONY: all test clean

all: $(TARGET)

$(TARGET): $(OBJECTS) | $(BUILD_DIR)
	$(CC) $(OBJECTS) $(LDFLAGS) $(LDLIBS) -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR):
	@$(call MAKE_DIR,$@)

test: $(TARGET)
	@$(TEST_RUNNER) "$(TEST_PATH)"

clean:
	@$(CLEAN_BUILD)

-include $(DEPS)