#include <stdio.h>
#include <string.h>

#include "common.h"
#include "scanner.h"

typedef struct
{
  const char *start;   // marks the beginning of current lexeme being scanned
  const char *current; // current character being scanned
  int line;            // line number for error reporting
  int column;          // column number for error reporting
} Scanner;

Scanner scanner;

void initScanner(const char *source)
{
  scanner.start = source;
  scanner.current = source;
  scanner.line = 1;
  scanner.column = 0;
}

static bool isAlpha(char c)
{
  return (c >= 'a' && c <= 'z') ||
         (c >= 'A' && c <= 'Z') ||
         c == '_';
}

static bool isDigit(char c)
{
  return c >= '0' && c <= '9';
}

static bool isAtEnd()
{
  return *scanner.current == '\0';
}

static char advance()
{
  scanner.current++;
  scanner.column++;
  return scanner.current[-1]; // immediate previous element
}

static char peek()
{
  return *scanner.current;
}

static char peekNext()
{
  if (isAtEnd())
    return '\0';
  return scanner.current[1];
}

static bool match(char expected)
{
  if (isAtEnd())
    return false;
  if (*scanner.current != expected)
    return false;
  scanner.current++;
  scanner.column++;
  return true;
}

static Token makeToken(TokenType type)
{
  Token token;
  token.type = type;
  token.start = scanner.start;
  token.length = (int)(scanner.current - scanner.start);
  token.line = scanner.line;
  token.column = (int)(scanner.start - scanner.current) + scanner.column;
  return token;
}

static Token errorToken(const char *message)
{
  Token token;
  token.type = TOKEN_ERROR;
  token.start = message;
  token.length = (int)strlen(message);
  token.line = scanner.line;
  token.column = scanner.column;
  return token;
}

static void skipWhitespace()
{
  for (;;)
  {
    char c = peek();
    switch (c)
    {
    case ' ':
    case '\r':
    case '\t':
      advance();
      // scanner.column++;
      break;
    case '\n':
      scanner.line++;
      scanner.column = 1;
      advance();
      break;
    case '/':
      if (peekNext() == '/')
      {
        // comment goes on till the end of line
        while (peek() != '\n' && !isAtEnd())
          advance();
      }
      else
      {
        return;
      }
      break;
    default:
      return;
    }
  }
}

static TokenType checkKeyword(int start, int length, const char *rest, TokenType type)
{
  if (scanner.current - scanner.start == start + length &&
      memcmp(scanner.start + start, rest, length) == 0)
  {
    return type;
  }

  // its an identifier if we cant match it to any keyword
  return TOKEN_IDENTIFIER;
}

static TokenType identifierType()
{
  // checking to see if the literal is a keyword or a user defined variable name
  // literally just seeing if the identifier begins with a certain character and then checking if we have a LOX keyword that begins with that character and checking the rest
  switch (scanner.start[0])
  {
  // if there is only one keyword corresponding to a character (for eg F does NOT, as it can have for, false and fun while 'i' can only have 'if')
  case 'a':
    return checkKeyword(1, 2, "nd", TOKEN_AND);
  case 'c':
    if (scanner.current - scanner.start > 1) {
      switch(scanner.start[1]) {
        case 'l':
          return checkKeyword(1, 4, "lass", TOKEN_CLASS);
        case 'a':
        return checkKeyword(1, 3, "ase", TOKEN_CASE);
      }
    }
    break;
  case 'd':
    return checkKeyword(1, 6, "efault", TOKEN_DEFAULT);  
  case 'e':
    return checkKeyword(1, 3, "lse", TOKEN_ELSE);
  // here we do check multiple branching paths
  case 'f':
    if (scanner.current - scanner.start > 1)
    {
      switch (scanner.start[1])
      {
      case 'a':
        return checkKeyword(2, 3, "lse", TOKEN_FALSE);
      case 'o':
        return checkKeyword(2, 1, "r", TOKEN_FOR);
      case 'u':
        return checkKeyword(2, 1, "n", TOKEN_FUN);
      }
    }
    break;
  case 'i':
    return checkKeyword(1, 1, "f", TOKEN_IF);
  case 'n':
    return checkKeyword(1, 2, "il", TOKEN_NIL);
  case 'o':
    return checkKeyword(1, 1, "r", TOKEN_OR);
  case 'p':
    return checkKeyword(1, 4, "rint", TOKEN_PRINT);
  case 'r':
    if (scanner.current - scanner.start > 1) {
      switch (scanner.start[1]) {
      case 'e':
        return checkKeyword(2, 4, "turn", TOKEN_RETURN);
      case 'i':
        return checkKeyword(2, 2, "zz", TOKEN_RETURN);
      }
    }
    break;
  case 's':
    return checkKeyword(1, 4, "uper", TOKEN_SUPER);
  case 't':
    if (scanner.current - scanner.start > 1)
    {
      switch (scanner.start[1])
      {
      case 'h':
        return checkKeyword(2, 2, "is", TOKEN_THIS);
      case 'r':
        return checkKeyword(2, 2, "ue", TOKEN_TRUE);
      }
    }
    break;
  case 'u':
    return checkKeyword(1, 2, "se", TOKEN_USE);
  case 'v':
    return checkKeyword(1, 2, "ar", TOKEN_VAR);
  case 'w':
    return checkKeyword(1, 4, "hile", TOKEN_WHILE);
  case 'y':
    return checkKeyword(1, 2, "ap", TOKEN_PRINT);
  }
  return TOKEN_IDENTIFIER;
}

static Token identifier()
{
  while (isAlpha(peek()) || isDigit(peek()))
    advance();
  return makeToken(identifierType());
}

static Token number()
{
  while (isDigit(peek()))
    advance();

  // look for the fractional part
  if (peek() == '.' && isDigit(peekNext()))
  {
    advance();

    // no conversion of lexeme to double yet
    while (isDigit(peek()))
      advance();
  }

  return makeToken(TOKEN_NUMBER);
}

static Token string()
{
  while (peek() != '"' && !isAtEnd())
  {
    if (peek() == '\n'){
        scanner.line++;
        scanner.column = 0;
    }
    advance();
  }

  if (isAtEnd())
    return errorToken("Unterminated string.");

  // closing quotation mark
  advance();
  return makeToken(TOKEN_STRING);
}

Token scanToken()
{
  skipWhitespace(); // ignore spaces, tabs, newlines, comments all that stuff before looking at tokens
  // set the start of current lexeme, useful in knowing the length of the lexeme
  scanner.start = scanner.current; 

  // if we've reached null terminator bing bang boom the string is over and our work here is done, point that compiler to an End Of File token
  if (isAtEnd())
    return makeToken(TOKEN_EOF);

  char c = advance();
  if (isAlpha(c))
    return identifier();
  if (isDigit(c))
    return number();

  switch (c)
  {
  // recognize simple single letter characters
  case '(':
    return makeToken(TOKEN_LEFT_PAREN);
  case ')':
    return makeToken(TOKEN_RIGHT_PAREN);
  case '{':
    return makeToken(TOKEN_LEFT_BRACE);
  case '}':
    return makeToken(TOKEN_RIGHT_BRACE);
  case '[':
    return makeToken(TOKEN_LEFT_BRACKET);
  case ']':
    return makeToken(TOKEN_RIGHT_BRACKET);
  case ';':
    return makeToken(TOKEN_SEMICOLON);
  case ':':
    return makeToken(TOKEN_COLON);
  case ',':
    return makeToken(TOKEN_COMMA);
  case '.':
    return makeToken(TOKEN_DOT);
  case '-':
    return makeToken(TOKEN_MINUS);
  case '+':
    return makeToken(TOKEN_PLUS);
  case '/':
    return makeToken(TOKEN_SLASH);
  case '*':
    return makeToken(TOKEN_STAR);
  case '%':
    return makeToken(TOKEN_MODULO);
  case '!':
    return makeToken(
        match('=') ? TOKEN_BANG_EQUAL : TOKEN_BANG);
  case '=':
    return makeToken(
        match('=') ? TOKEN_EQUAL_EQUAL : TOKEN_EQUAL);
  case '<':
    return makeToken(
        match('=') ? TOKEN_LESS_EQUAL : TOKEN_LESS);
  case '>':
    return makeToken(
        match('=') ? TOKEN_GREATER_EQUAL : TOKEN_GREATER);
  case '"':
    return string();
  }

  return errorToken("Unexpected character.");
}
