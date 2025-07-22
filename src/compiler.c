#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "headers/common.h"
#include "headers/memory.h"
#include "headers/compiler.h"
#include "headers/scanner.h"

#ifdef DEBUG_PRINT_CODE
#include "debug.h"
#endif

typedef struct
{
  Token current;
  Token previous;
  bool hadError;
  bool panicMode;
} Parser;

typedef enum
{
  PREC_NONE,
  PREC_ASSIGNMENT, // =
  PREC_OR,         // or
  PREC_AND,        // and
  PREC_EQUALITY,   // == !=
  PREC_COMPARISON, // < > <= >=
  PREC_TERM,       // + -
  PREC_FACTOR,     // * /
  PREC_UNARY,      // ! -
  PREC_CALL,       // . ()
  PREC_PRIMARY
} Precedence;

typedef void (*ParseFn)(bool canAssign); // function pointer hidden behind a typedef to make it seem less ugly

typedef struct
{
  ParseFn prefix;
  ParseFn infix;
  Precedence precedence;
} ParseRule;

typedef struct
{
  Token name;
  int depth;
} Local;

typedef enum
{
  TYPE_FUNCTION,
  TYPE_SCRIPT,
  TYPE_METHOD,
  TYPE_INITIALIZER,
} FunctionType;

typedef struct Compiler
{
  struct Compiler *enclosing;
  ObjFunction *function;
  FunctionType type;

  Local locals[UINT8_COUNT];
  int localCount;
  int scopeDepth;
} Compiler;

typedef struct ClassCompiler
{
  struct ClassCompiler *enclosing;
  bool hasSuperclass;
} ClassCompiler;

Parser parser;
Compiler *current = NULL;
ClassCompiler *currentClass = NULL;

const char *src;

static Chunk *currentChunk()
{
  return &current->function->chunk;
}

void print_line(const char *s, int n)
{
  int i = 0, j = 1;
  while (s[i])
  {
    if (j == n)
    {
      while (s[i] && s[i] != '\n')
        putchar(s[i++]);
      putchar('\n');
      return;
    }
    if (s[i++] == '\n')
      j++;
  }
}

static void printErrorMarker(int column)
{
  for (int i = 0; i < column - 2; i++)
  {
    putchar(' ');
  }
  printf("^\n");
}

static void errorAt(Token *token, const char *message)
{
  if (parser.panicMode)
    return;
  parser.panicMode = true;

  print_line(src, token->line);
  printErrorMarker(token->column);

  fprintf(stderr, "[line %d] Error", token->line);

  if (token->type == TOKEN_EOF)
  {
    fprintf(stderr, " at end");
  }
  else if (token->type != TOKEN_ERROR)
  {
    fprintf(stderr, " at '%.*s'", token->length, token->start);
  }

  fprintf(stderr, ": %s\n", message);
  parser.hadError = true;
}

static void error(const char *message)
{
  errorAt(&parser.previous, message);
}

static void errorAtCurrent(const char *message)
{
  errorAt(&parser.current, message);
}

static void advance()
{
  parser.previous = parser.current;

  // detect all errors so that the rest of the compiler only sees valid tokens
  for (;;)
  {
    parser.current = scanToken();
    if (parser.current.type != TOKEN_ERROR)
      break; // end the loop if we see a non-error token or if we reach the end of file
    // scanner doesnt report lexical errors, it just creates error tokens, we detect those here
    errorAtCurrent(parser.current.start);
  }
}

static void consume(TokenType type, const char *message)
{
  if (parser.current.type == type)
  {
    advance();
    return;
  }

  errorAtCurrent(message);
}

static bool check(TokenType type)
{
  return parser.current.type == type;
}

static bool match(TokenType type)
{
  if (!check(type))
    return false;
  advance();
  return true;
}

static void emitByte(uint8_t byte)
{
  writeChunk(currentChunk(), byte, parser.previous.line);
}

static void emitBytes(uint8_t byte1, uint8_t byte2)
{
  emitByte(byte1);
  emitByte(byte2);
}

static void emitLoop(int loopStart)
{
  emitByte(OP_LOOP);

  int offset = currentChunk()->count - loopStart + 2;
  if (offset > UINT16_MAX)
    error("Loop body too large.");

  emitByte((offset >> 8) & 0xff);
  emitByte(offset & 0xff);
}

static int emitJump(uint8_t instruction)
{
  emitByte(instruction);
  emitByte(0xff);
  emitByte(0xff);
  return currentChunk()->count - 2;
}

static void emitReturn()
{
  if (current->type == TYPE_INITIALIZER)
  {
    emitBytes(OP_GET_LOCAL, 0);
  }
  else
  {
    emitByte(OP_NIL);
  }
  emitByte(OP_RETURN);
}

static uint8_t makeConstant(Value value)
{
  int constant = addConstant(currentChunk(), value);
  if (constant > UINT8_MAX)
  {
    error("Too many constants in one chunk.");
    return 0;
  }

  return (uint8_t)constant;
}

static void emitConstant(Value value)
{
  emitBytes(OP_CONSTANT, makeConstant(value));
}

static void patchJump(int offset)
{
  int jump = currentChunk()->count - offset - 2;

  if (jump > UINT16_MAX)
  {
    error("Too much code to jump over.");
  }

  currentChunk()->code[offset] = (jump >> 8) & 0xff;
  currentChunk()->code[offset + 1] = jump & 0xff;
}

static void initCompiler(Compiler *compiler, FunctionType type)
{
  compiler->enclosing = current;
  compiler->function = NULL;
  compiler->type = type;
  compiler->localCount = 0;
  compiler->scopeDepth = 0;
  compiler->function = newFunction();
  current = compiler;
  if (type != TYPE_SCRIPT)
  {
    current->function->name = copyString(parser.previous.start,
                                         parser.previous.length);
  }

  Local *local = &current->locals[current->localCount++];
  local->depth = 0;
  if (type != TYPE_FUNCTION)
  {
    local->name.start = "this";
    local->name.length = 4;
  }
  else
  {
    local->name.start = "";
    local->name.length = 0;
  }
}

static ObjFunction *endCompiler()
{
  emitReturn();
  ObjFunction *function = current->function;
#ifdef DEBUG_PRINT_CODE
  if (!parser.hadError)
  {
    disassembleChunk(currentChunk(), function->name != NULL
                                         ? function->name->chars
                                         : "<script>");
  }
#endif

  current = current->enclosing;
  return function;
}

static void beginScope()
{
  current->scopeDepth++;
}

static void endScope()
{
  current->scopeDepth--;

  while (current->localCount > 0 && current->locals[current->localCount - 1].depth > current->scopeDepth)
  {
    emitByte(OP_POP);
    current->localCount--;
  }
}

static void expression();
static void namedVariable(Token name, bool canAssign);
static void statement();
static void declaration();
static ParseRule *getRule(TokenType type);
static void parsePrecedence(Precedence precedence);

static uint8_t identifierConstant(Token *name)
{
  return makeConstant(OBJ_VAL(copyString(name->start, name->length)));
}

static bool identifiersEqual(Token *a, Token *b)
{
  if (a->length != b->length)
    return false;
  return memcmp(a->start, b->start, a->length) == 0;
}

static int resolveLocal(Compiler *compiler, Token *name)
{
  for (int i = compiler->localCount - 1; i >= 0; i--)
  {
    Local *local = &compiler->locals[i];
    if (identifiersEqual(name, &local->name))
    {
      if (local->depth == -1)
      {
        error("Can't read local variable in its own initializer.");
      }
      return i;
    }
  }

  return -1;
}

static void addLocal(Token name)
{
  // only 256 local variables lmao
  if (current->localCount == UINT8_COUNT)
  {
    error("Too many local variables in function.");
    return;
  }

  Local *local = &current->locals[current->localCount++];
  local->name = name;
  local->depth = -1;
}

static void declareVariable()
{
  if (current->scopeDepth == 0)
    return;

  Token *name = &parser.previous;
  for (int i = current->localCount - 1; i >= 0; i--)
  {
    Local *local = &current->locals[i];
    if (local->depth != -1 && local->depth < current->scopeDepth)
    {
      break;
    }

    if (identifiersEqual(name, &local->name))
    {
      error("Already a variable with this name in this scope.");
    }
  }

  addLocal(*name);
}

static uint8_t parseVariable(const char *errorMessage)
{
  consume(TOKEN_IDENTIFIER, errorMessage);

  declareVariable();
  if (current->scopeDepth > 0)
    return 0;

  return identifierConstant(&parser.previous);
}

static void markInitialized()
{
  if (current->scopeDepth == 0)
    return;
  current->locals[current->localCount - 1].depth = current->scopeDepth;
}

static void defineVariable(uint8_t global)
{
  if (current->scopeDepth > 0)
  {
    markInitialized();
    return;
  }

  emitBytes(OP_DEFINE_GLOBAL, global);
}

static uint8_t argumentList()
{
  uint8_t argCount = 0;
  if (!check(TOKEN_RIGHT_PAREN))
  {
    do
    {
      expression();
      if (argCount == 255)
      {
        error("Can't have more than 255 arguments.");
      }
      argCount++;
    } while (match(TOKEN_COMMA));
  }
  consume(TOKEN_RIGHT_PAREN, "Expect ')' after arguments.");
  return argCount;
}

static void and_(bool canAssign)
{
  int endJump = emitJump(OP_JUMP_IF_FALSE);

  emitByte(OP_POP);
  parsePrecedence(PREC_AND);

  patchJump(endJump);
}

static void binary(bool canAssign)
{
  TokenType operatorType = parser.previous.type;
  ParseRule *rule = getRule(operatorType);
  parsePrecedence((Precedence)(rule->precedence + 1));

  switch (operatorType)
  {
  case TOKEN_BANG_EQUAL:
    emitBytes(OP_EQUAL, OP_NOT);
    break;
  case TOKEN_EQUAL_EQUAL:
    emitByte(OP_EQUAL);
    break;
  case TOKEN_GREATER:
    emitByte(OP_GREATER);
    break;
  case TOKEN_GREATER_EQUAL:
    emitBytes(OP_LESS, OP_NOT);
    break;
  case TOKEN_LESS:
    emitByte(OP_LESS);
    break;
  case TOKEN_LESS_EQUAL:
    emitBytes(OP_GREATER, OP_NOT);
    break;
  case TOKEN_PLUS:
    emitByte(OP_ADD);
    break;
  case TOKEN_MINUS:
    emitByte(OP_SUBTRACT);
    break;
  case TOKEN_STAR:
    emitByte(OP_MULTIPLY);
    break;
  case TOKEN_MODULO:
    emitByte(OP_MODULO);
    break;
  case TOKEN_SLASH:
    emitByte(OP_DIVIDE);
    break;
  default:
    return; // unreachable
  }
}

static void call(bool canAssign)
{
  uint8_t argCount = argumentList();
  emitBytes(OP_CALL, argCount);
}

static void dot(bool canAssign)
{
  consume(TOKEN_IDENTIFIER, "Expect property name after '.'.");
  uint8_t name = identifierConstant(&parser.previous);

  if (canAssign && match(TOKEN_EQUAL))
  {
    expression();
    emitBytes(OP_SET_PROPERTY, name);
  }
  else if (match(TOKEN_LEFT_PAREN))
  {
    uint8_t argCount = argumentList();
    emitBytes(OP_INVOKE, name);
    emitByte(argCount);
  }
  else
  {
    emitBytes(OP_GET_PROPERTY, name);
  }
}

static void literal(bool canAssign)
{
  switch (parser.previous.type)
  {
  case TOKEN_FALSE:
    emitByte(OP_FALSE);
    break;
  case TOKEN_NIL:
    emitByte(OP_NIL);
    break;
  case TOKEN_TRUE:
    emitByte(OP_TRUE);
    break;
  default:
    return;
  }
}

static void grouping(bool canAssign)
{
  expression();
  consume(TOKEN_RIGHT_PAREN, "Expect ')' after expression.");
}

static void expression()
{
  parsePrecedence(PREC_ASSIGNMENT);
}

static void block()
{
  while (!check(TOKEN_RIGHT_BRACE) && !check(TOKEN_EOF))
  {
    declaration();
  }

  consume(TOKEN_RIGHT_BRACE, "Expect '}' after block.");
}

static void function(FunctionType type)
{
  Compiler compiler;
  initCompiler(&compiler, type);
  beginScope();

  consume(TOKEN_LEFT_PAREN, "Expect '(' after function name.");
  if (!check(TOKEN_RIGHT_PAREN))
  {
    do
    {
      current->function->arity++;
      if (current->function->arity > 255)
      {
        errorAtCurrent("Can't have more than 255 parameters.");
      }
      uint8_t constant = parseVariable("Expect parameter name.");
      defineVariable(constant);
    } while (match(TOKEN_COMMA));
  }
  consume(TOKEN_RIGHT_PAREN, "Expect ')' after parameters.");
  consume(TOKEN_LEFT_BRACE, "Expect '{' before function body.");
  block();

  ObjFunction *function = endCompiler();
  emitBytes(OP_CONSTANT, makeConstant(OBJ_VAL(function)));
}

static void method()
{
  consume(TOKEN_IDENTIFIER, "Expect method name.");
  uint8_t constant = identifierConstant(&parser.previous);

  FunctionType type = TYPE_METHOD;
  if (parser.previous.length == 4 &&
      memcmp(parser.previous.start, "init", 4) == 0)
  {
    type = TYPE_INITIALIZER;
  }
  function(type);
  emitBytes(OP_METHOD, constant);
}

static void funDeclaration()
{
  uint8_t global = parseVariable("Expect function name.");
  markInitialized();
  function(TYPE_FUNCTION);
  defineVariable(global);
}

static void varDeclaration()
{
  uint8_t global = parseVariable("Expect variable name.");

  if (match(TOKEN_EQUAL))
  {
    expression();
  }
  else
  {
    emitByte(OP_NIL);
  }
  consume(TOKEN_SEMICOLON, "Expect ';' after declaration");

  defineVariable(global);
}

static void variable(bool canAssign);
static Token syntheticToken(const char *text);

static void classDeclaration()
{
  consume(TOKEN_IDENTIFIER, "Expect class name.");
  Token className = parser.previous;
  uint8_t nameConstant = identifierConstant(&parser.previous);
  declareVariable();

  emitBytes(OP_CLASS, nameConstant);
  defineVariable(nameConstant);

  ClassCompiler classCompiler;
  classCompiler.hasSuperclass = false;
  classCompiler.enclosing = currentClass;
  currentClass = &classCompiler;

  if (match(TOKEN_LESS))
  {
    consume(TOKEN_IDENTIFIER, "Expect superclass name.");
    variable(false);

    if (identifiersEqual(&className, &parser.previous))
    {
      error("A class can't inherit from itself.");
    }

    beginScope();
    addLocal(syntheticToken("super"));
    defineVariable(0);

    namedVariable(className, false);
    emitByte(OP_INHERIT);

    classCompiler.hasSuperclass = true;
  }

  namedVariable(className, false);
  consume(TOKEN_LEFT_BRACE, "Expect '{' before class body.");
  while (!check(TOKEN_RIGHT_BRACE) && !check(TOKEN_EOF))
  {
    method();
  }

  consume(TOKEN_RIGHT_BRACE, "Expect '}' after class body.");
  emitByte(OP_POP);

  currentClass = currentClass->enclosing;
}

static void expressionStatement()
{
  expression();
  consume(TOKEN_SEMICOLON, "Expect ';' after an expression.");
  emitByte(OP_POP);
}

static void forStatement()
{
  beginScope(); // wrap the whole statement in a block for proper scoping for variables
  consume(TOKEN_LEFT_PAREN, "Expect '(' after 'for'.");
  if (match(TOKEN_SEMICOLON))
  {
    // no initializer.
  }
  else if (match(TOKEN_VAR))
  {
    varDeclaration();
  }
  else
  {
    expressionStatement();
  }

  int loopStart = currentChunk()->count;
  int exitJump = -1;
  if (!match(TOKEN_SEMICOLON))
  {
    expression();
    consume(TOKEN_SEMICOLON, "Expect ';' after loop condition.");

    // jump out of the loop if the condition is false.
    exitJump = emitJump(OP_JUMP_IF_FALSE);
    emitByte(OP_POP); // condition.
  }

  if (!match(TOKEN_RIGHT_PAREN))
  {
    int bodyJump = emitJump(OP_JUMP);
    int incrementStart = currentChunk()->count;
    expression();
    emitByte(OP_POP);
    consume(TOKEN_RIGHT_PAREN, "Expect ')' after for clauses.");

    emitLoop(loopStart);
    loopStart = incrementStart;
    patchJump(bodyJump);
  }

  statement();
  emitLoop(loopStart);

  if (exitJump != -1)
  {
    patchJump(exitJump);
    emitByte(OP_POP);
  }

  endScope();
}

static void ifStatement()
{
  consume(TOKEN_LEFT_PAREN, "Expect '(' after 'if'.");
  expression();
  consume(TOKEN_RIGHT_PAREN, "Expect ')' after condition.");

  int thenJump = emitJump(OP_JUMP_IF_FALSE);
  emitByte(OP_POP);
  statement();

  int elseJump = emitJump(OP_JUMP);

  patchJump(thenJump);
  emitByte(OP_POP);

  if (match(TOKEN_ELSE))
    statement();
  patchJump(elseJump);
}

static void printStatement()
{
  consume(TOKEN_LEFT_PAREN, "Expect '(' after 'print'.");
  expression();

  bool newline = true;
  if (match(TOKEN_COMMA))
  {
    consume(TOKEN_IDENTIFIER, "Expect 'newline' after comma.");
    if (strncmp(parser.previous.start, "newline", parser.previous.length) == 0)
    {
      consume(TOKEN_EQUAL, "Expect '=' after 'newline'.");
      if (match(TOKEN_TRUE))
      {
        newline = true;
      }
      else if (match(TOKEN_FALSE))
      {
        newline = false;
      }
      else
      {
        error("Expect 'true' or 'false' after 'newline='.");
      }
    }
    else
    {
      error("Expect 'newline' after comma.");
    }
  }

  consume(TOKEN_RIGHT_PAREN, "Expect ')' after arguments.");
  consume(TOKEN_SEMICOLON, "Expect ';' after value.");

  if (!newline)
  {
    emitByte(OP_PRINT_NO_NEWLINE);
    return;
  }
  emitByte(OP_PRINT);
}

static void returnStatement()
{
  if (current->type == TYPE_SCRIPT)
  {
    error("Can't return from top-level code.");
  }

  if (match(TOKEN_SEMICOLON))
  {
    emitReturn();
  }
  else
  {
    if (current->type == TYPE_INITIALIZER)
    {
      error("Can't return a value from an initializer.");
    }

    expression();
    consume(TOKEN_SEMICOLON, "Expect ';' after return value.");
    emitByte(OP_RETURN);
  }
}

static void whileStatement()
{
  int loopStart = currentChunk()->count;
  consume(TOKEN_LEFT_PAREN, "Expect '(' after 'while'.");
  expression();
  consume(TOKEN_RIGHT_PAREN, "Expect ')' after condition.");

  int exitJump = emitJump(OP_JUMP_IF_FALSE);
  emitByte(OP_POP);
  statement();
  emitLoop(loopStart);

  patchJump(exitJump);
  emitByte(OP_POP);
}

static void useStatement()
{
  if (current->type != TYPE_SCRIPT)
  {
    error("Can only include libraries in top-level code.");
    return;
  }

  // consume(TOKEN_STRING, "Expect library name after 'use'.");
  // uint8_t constant = makeConstant(OBJ_VAL(copyString(parser.previous.start + 1, parser.previous.length - 2)));
  expression();
  consume(TOKEN_SEMICOLON, "Expect ';'");
  emitByte(OP_USE);
}

static void list(bool canAssign)
{
  int itemCount = 0;
  emitByte(OP_NEW_LIST);

  if (!check(TOKEN_RIGHT_BRACKET))
  {
    do
    {
      if (match(TOKEN_LEFT_BRACKET))
      {
        list(canAssign);
      }
      else
      {
        expression();
      }

      emitByte(OP_LIST_APPEND);
      itemCount++;

    } while (match(TOKEN_COMMA));
  }

  consume(TOKEN_RIGHT_BRACKET, "Expect ']' after list elements.");
}

static void hashmap(bool canAssign)
{
  int itemCount = 0;
  emitByte(OP_NEW_HASHMAP);

  if (!check(TOKEN_RIGHT_BRACE))
  {
    do
    {
      expression();
      consume(TOKEN_COLON, "Expect ':' between key and value.");
      expression();
      emitByte(OP_HASHMAP_APPEND);
      itemCount++;
    } while (match(TOKEN_COMMA));
  }

  consume(TOKEN_RIGHT_BRACE, "Expect '}' after hashmap elements.");
}

static void containerIndex(bool canAssign)
{
  do
  {
    expression();
    consume(TOKEN_RIGHT_BRACKET, "Expect ']' after list index.");

    if (canAssign && match(TOKEN_EQUAL))
    {
      expression();
      emitByte(OP_SET_INDEX); // also works with hashmap keys
      break;
    }
    else
    {
      emitByte(OP_GET_INDEX);
    }
  } while (match(TOKEN_LEFT_BRACKET));
}

static void handleDot(bool canAssign)
{
  consume(TOKEN_IDENTIFIER, "Expect property name after '.'.");
  if (parser.previous.length == 4 && memcmp(parser.previous.start, "push", 4) == 0)
  {
    consume(TOKEN_LEFT_PAREN, "Expect '(' after 'push'.");
    expression();
    consume(TOKEN_RIGHT_PAREN, "Expect ')' after value.");
    emitByte(OP_LIST_APPEND);
  }
  else if (parser.previous.length == 3 && memcmp(parser.previous.start, "add", 3) == 0)
  {
    consume(TOKEN_LEFT_PAREN, "Expect '(' after 'add'.");
    expression();
    consume(TOKEN_COMMA, "Expect two parameters: value and index.");
    expression();
    consume(TOKEN_RIGHT_PAREN, "Expect ')' after 'index'.");
    emitByte(OP_LIST_ADD);
  }
  else if (parser.previous.length == 6 && memcmp(parser.previous.start, "remove", 6) == 0)
  {
    consume(TOKEN_LEFT_PAREN, "Expect '(' after 'remove'.");
    expression();
    consume(TOKEN_RIGHT_PAREN, "Expect ')' after index.");
    emitByte(OP_LIST_REMOVE);
  }
  else if (parser.previous.length == 3 && memcmp(parser.previous.start, "pop", 3) == 0)
  {
    consume(TOKEN_LEFT_PAREN, "Expect '(' after 'pop'.");
    consume(TOKEN_RIGHT_PAREN, "Expect ')', 'pop' does not accept any parameters.");
    emitByte(OP_LIST_POP);
  }
  else if (parser.previous.length == 4 && memcmp(parser.previous.start, "size", 4) == 0)
  {
    consume(TOKEN_LEFT_PAREN, "Expect '(' after 'size'.");
    consume(TOKEN_RIGHT_PAREN, "Expect ')', 'size' does not accept any parameters.");
    emitByte(OP_SIZE);
  }
  else if (parser.previous.length == 4 && memcmp(parser.previous.start, "find", 4) == 0)
  {
    consume(TOKEN_LEFT_PAREN, "Expect '(' after 'find'.");
    expression();
    consume(TOKEN_RIGHT_PAREN, "Expect ')' after 'find'.");
    emitByte(OP_GET_INDEX);
  }
  else if (parser.previous.length == 6 && memcmp(parser.previous.start, "delete", 6) == 0)
  {
    consume(TOKEN_LEFT_PAREN, "Expect '(' after 'find'.");
    expression();
    consume(TOKEN_RIGHT_PAREN, "Expect ')' after 'find'.");
    emitByte(OP_HASHMAP_DELETE);
  }
  else
  {
    uint8_t name = identifierConstant(&parser.previous);

    if (canAssign && match(TOKEN_EQUAL))
    {
      expression();
      emitBytes(OP_SET_PROPERTY, name);
    }
    else if (match(TOKEN_LEFT_PAREN))
    {
      uint8_t argCount = argumentList();
      emitBytes(OP_INVOKE, name);
      emitByte(argCount);
    }
    else
    {
      emitBytes(OP_GET_PROPERTY, name);
    }
  }

  if (match(TOKEN_DOT))
  {
    handleDot(canAssign);
  }

  if (match(TOKEN_LEFT_BRACKET))
  {
    expression();
    emitByte(OP_GET_INDEX);
    consume(TOKEN_RIGHT_BRACKET, "Expect ']' after list elements.");
  }
}

static void synchronize()
{
  parser.panicMode = false;

  while (parser.current.type != TOKEN_EOF)
  {
    // look if the prev token ended the statement
    if (parser.previous.type == TOKEN_SEMICOLON)
      return;
    // or if the current token marks the end of a new statement
    switch (parser.current.type)
    {
    case TOKEN_CLASS:
    case TOKEN_FUN:
    case TOKEN_VAR:
    case TOKEN_FOR:
    case TOKEN_IF:
    case TOKEN_WHILE:
    case TOKEN_PRINT:
    case TOKEN_RETURN:
      return;

    default:; // do nothing
    }
  }
}

static void declaration()
{
  if (match(TOKEN_FUN))
  {
    funDeclaration();
  }
  else if (match(TOKEN_VAR))
  {
    varDeclaration();
  }
  else if (match(TOKEN_CLASS))
  {
    classDeclaration();
  }
  else
  {
    statement();
  }

  if (parser.panicMode)
    synchronize();
}

static void statement()
{
  if (match(TOKEN_PRINT))
  {
    printStatement();
  }
  else if (match(TOKEN_IF))
  {
    ifStatement();
  }
  else if (match(TOKEN_RETURN))
  {
    returnStatement();
  }
  else if (match(TOKEN_WHILE))
  {
    whileStatement();
  }
  else if (match(TOKEN_FOR))
  {
    forStatement();
  }
  else if (match(TOKEN_LEFT_BRACE))
  {
    beginScope();
    block();
    endScope();
  }
  else if (match(TOKEN_LEFT_BRACKET))
  {
    consume(TOKEN_RIGHT_BRACKET, "expect ']'");
  }
  else if (match(TOKEN_USE))
  {
    useStatement();
  }
  else
  {
    expressionStatement();
  }
}

static void number(bool canAssign)
{
  double value = strtod(parser.previous.start, NULL);
  emitConstant(NUMBER_VAL(value));
}

static void or_(bool canAssign)
{
  int elseJump = emitJump(OP_JUMP_IF_FALSE);
  int endJump = emitJump(OP_JUMP);

  patchJump(elseJump);
  emitByte(OP_POP);

  parsePrecedence(PREC_OR);
  patchJump(endJump);
}

static void string(bool canAssign)
{
  emitConstant(OBJ_VAL(copyString(parser.previous.start + 1, parser.previous.length - 2)));
}

static void namedVariable(Token name, bool canAssign)
{
  uint8_t getOp, setOp;
  int arg = resolveLocal(current, &name);
  if (arg != -1)
  {
    getOp = OP_GET_LOCAL;
    setOp = OP_SET_LOCAL;
  }
  else
  {
    arg = identifierConstant(&name);
    getOp = OP_GET_GLOBAL;
    setOp = OP_SET_GLOBAL;
  }

  if (match(TOKEN_LEFT_BRACKET))
  {
    emitBytes(getOp, (uint8_t)arg);
    containerIndex(canAssign);
  }
  else if (match(TOKEN_DOT))
  {
    emitBytes(getOp, (uint8_t)arg);
    handleDot(canAssign);
  }
  else if (canAssign && match(TOKEN_EQUAL))
  {
    if (name.length == 4 && memcmp(name.start, "this", 4) == 0)
    {
      error("Cannot assign to 'this'.");
    }
    expression();
    emitBytes(setOp, (uint8_t)arg);
  }
  else
  {
    emitBytes(getOp, (uint8_t)arg);
  }
}

static void variable(bool canAssign)
{
  namedVariable(parser.previous, canAssign);
}

static Token syntheticToken(const char *text)
{
  Token token;
  token.start = text;
  token.length = (int)strlen(text);
  return token;
}

static void super_(bool canAssign)
{
  if (currentClass == NULL)
  {
    error("Can't use 'super' outside of a class.");
  }
  else if (!currentClass->hasSuperclass)
  {
    error("Can't use 'super' in a class with no superclass.");
  }

  consume(TOKEN_DOT, "Expect '.' after 'super'.");
  consume(TOKEN_IDENTIFIER, "Expect superclass method name.");
  uint8_t name = identifierConstant(&parser.previous);

  namedVariable(syntheticToken("this"), false);
  if (match(TOKEN_LEFT_PAREN))
  {
    uint8_t argCount = argumentList();
    namedVariable(syntheticToken("super"), false);
    emitBytes(OP_SUPER_INVOKE, name);
    emitByte(argCount);
  }
  else
  {
    namedVariable(syntheticToken("super"), false);
    emitBytes(OP_GET_SUPER, name);
  }
}

static void this_(bool canAssign)
{
  if (currentClass == NULL)
  {
    error("Can't use 'this' outside of a class.");
    return;
  }

  variable(canAssign);
}

static void unary(bool canAssign)
{
  TokenType operatorType = parser.previous.type;

  parsePrecedence(PREC_UNARY);

  switch (operatorType)
  {
  case TOKEN_BANG:
    emitByte(OP_NOT);
    break;
  case TOKEN_MINUS:
    emitByte(OP_NEGATE);
    break;
  default:
    return;
  }
}

ParseRule rules[] = {
    [TOKEN_LEFT_PAREN] = {grouping, call, PREC_CALL},
    [TOKEN_RIGHT_PAREN] = {NULL, NULL, PREC_NONE},
    [TOKEN_LEFT_BRACE] = {hashmap, NULL, PREC_CALL},
    [TOKEN_RIGHT_BRACE] = {NULL, NULL, PREC_NONE},
    [TOKEN_LEFT_BRACKET] = {list, NULL, PREC_CALL},
    [TOKEN_RIGHT_BRACKET] = {NULL, NULL, PREC_NONE},
    [TOKEN_COMMA] = {NULL, NULL, PREC_NONE},
    [TOKEN_DOT] = {NULL, dot, PREC_CALL},
    [TOKEN_MINUS] = {unary, binary, PREC_TERM},
    [TOKEN_PLUS] = {NULL, binary, PREC_TERM},
    [TOKEN_SEMICOLON] = {NULL, NULL, PREC_NONE},
    [TOKEN_SLASH] = {NULL, binary, PREC_FACTOR},
    [TOKEN_STAR] = {NULL, binary, PREC_FACTOR},
    [TOKEN_MODULO] = {NULL, binary, PREC_FACTOR},
    [TOKEN_BANG] = {unary, NULL, PREC_NONE},
    [TOKEN_BANG_EQUAL] = {NULL, binary, PREC_EQUALITY},
    [TOKEN_EQUAL] = {NULL, NULL, PREC_NONE},
    [TOKEN_EQUAL_EQUAL] = {NULL, binary, PREC_EQUALITY},
    [TOKEN_GREATER] = {NULL, binary, PREC_COMPARISON},
    [TOKEN_GREATER_EQUAL] = {NULL, binary, PREC_COMPARISON},
    [TOKEN_LESS] = {NULL, binary, PREC_COMPARISON},
    [TOKEN_LESS_EQUAL] = {NULL, binary, PREC_COMPARISON},
    [TOKEN_IDENTIFIER] = {variable, NULL, PREC_NONE},
    [TOKEN_STRING] = {string, NULL, PREC_NONE},
    [TOKEN_NUMBER] = {number, NULL, PREC_NONE},
    [TOKEN_AND] = {NULL, and_, PREC_AND},
    [TOKEN_CLASS] = {NULL, NULL, PREC_NONE},
    [TOKEN_ELSE] = {NULL, NULL, PREC_NONE},
    [TOKEN_FALSE] = {literal, NULL, PREC_NONE},
    [TOKEN_FOR] = {NULL, NULL, PREC_NONE},
    [TOKEN_FUN] = {NULL, NULL, PREC_NONE},
    [TOKEN_IF] = {NULL, NULL, PREC_NONE},
    [TOKEN_NIL] = {literal, NULL, PREC_NONE},
    [TOKEN_OR] = {NULL, or_, PREC_OR},
    [TOKEN_PRINT] = {NULL, NULL, PREC_NONE},
    [TOKEN_RETURN] = {NULL, NULL, PREC_NONE},
    [TOKEN_SUPER] = {super_, NULL, PREC_NONE},
    [TOKEN_THIS] = {this_, NULL, PREC_NONE},
    [TOKEN_TRUE] = {literal, NULL, PREC_NONE},
    [TOKEN_VAR] = {NULL, NULL, PREC_NONE},
    [TOKEN_WHILE] = {NULL, NULL, PREC_NONE},
    [TOKEN_USE] = {NULL, NULL, PREC_NONE},
    [TOKEN_ERROR] = {NULL, NULL, PREC_NONE},
    [TOKEN_EOF] = {NULL, NULL, PREC_NONE},
};

static void parsePrecedence(Precedence precedence)
{
  advance();
  ParseFn prefixRule = getRule(parser.previous.type)->prefix;
  if (prefixRule == NULL)
  {
    error("Expect expression.");
    return;
  }

  bool canAssign = precedence <= PREC_ASSIGNMENT; // only consume the '=' if it is in context of a low-precedence expression
  prefixRule(canAssign);

  while (precedence <= getRule(parser.current.type)->precedence)
  {
    advance();
    ParseFn infixRule = getRule(parser.previous.type)->infix;
    infixRule(canAssign);
  }

  if (canAssign && match(TOKEN_EQUAL))
  {
    error("Invalid assignment target.");
  }
}

static ParseRule *getRule(TokenType type)
{
  return &rules[type];
}

// pratt's parsing technique oooh very exclusive
// single-pass compiler - it only has a peephole view into the user's program so only works if the language requires very little context around the code that its parsing (and producing bytecode both at once)
ObjFunction *compile(const char *source)
{
  src = source;
  initScanner(source);
  Compiler compiler;
  initCompiler(&compiler, TYPE_SCRIPT);

  parser.hadError = false;
  parser.panicMode = false;

  advance();

  while (!match(TOKEN_EOF))
  {
    declaration();
  }

  ObjFunction *function = endCompiler();
  return parser.hadError ? NULL : function;
}

void markCompilerRoots()
{
  Compiler *compiler = current;
  while (compiler != NULL)
  {
    markObject((Obj *)compiler->function);
    compiler = compiler->enclosing;
  }
}
