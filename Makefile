# Compiler
CC = gcc

# Compiler flags
CFLAGS = -Wall -std=c11 -I./src

# Linker flags
LIBS = -lm -lreadline

# Executable name
EXEC = pogberry

# Source and object directories
SRC_DIR = src
OBJ_DIR = build

# Source files
SRC = $(wildcard $(SRC_DIR)/*.c)

# Object files
OBJ = $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRC))

# Default target
all: $(EXEC)

# Link object files to create the executable
$(EXEC): $(OBJ)
	$(CC) $(OBJ) $(LIBS) -o $@

# Compile each .c to a .o in build/
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean build artifacts
clean:
ifeq ($(OS),Windows_NT)
	del /Q $(OBJ_DIR)\*.o $(EXEC)
else
	rm -rf $(OBJ_DIR) $(EXEC)
endif


.PHONY: all clean
