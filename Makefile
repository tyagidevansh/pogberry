# Compiler
CC = gcc

# Compiler flags
CFLAGS = -Wall -std=c11

# Linker flags
LIBS = -lm -lreadline

# Executable name
EXEC = pogberry

# Source files
SRC = main.c value.c memory.c chunk.c debug.c vm.c scanner.c compiler.c object.c table.c native.c

# Object files
OBJ = main.o value.o memory.o chunk.o debug.o vm.o scanner.o compiler.o object.o table.o native.o

# Default target
all: $(EXEC)

# Link object files to create the executable
$(EXEC): $(OBJ)
	$(CC) $(OBJ) $(LIBS) -o $(EXEC)

# Compile each source file into an object file
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	del /Q $(OBJ)
