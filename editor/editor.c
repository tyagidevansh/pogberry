#include "raylib.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#if defined(_WIN32)
#include <direct.h> // this is seriously so cool
#define MKDIR(path) _mkdir(path)
#else
#include <sys/stat.h>
#define MKDIR(path) mkdir(path, 0755)
#endif

#define EDITOR_FONT_SIZE 20
#define EDITOR_LINE_SPACING 1.5f
#define EDITOR_TEXT_BUFFER_GROW_FACTOR 2
#define EDITOR_DEFAULT_BUFFER_CAPACITY 8192
#define MAX_UNDO_LEVELS 100
#define MAX_FILENAME_LEN 256

typedef struct
{
    char *buffer;
    int capacity;
    int length;
    int cursor;
    int selectionStart;
    int selectionEnd;
} TextBuffer;

typedef struct
{
    char *buffer;
    int length;
    int cursor;
    int selectionStart;
    int selectionEnd;
} HistoryState;

typedef enum
{
    MODE_EDIT,
    MODE_OPEN_FILE,
    MODE_SAVE_AS,
} EditorMode;

static HistoryState undoStack[MAX_UNDO_LEVELS] = {0};
static int undoTop = -1;
static HistoryState redoStack[MAX_UNDO_LEVELS] = {0};
static int redoTop = -1;
static char currentFilename[MAX_FILENAME_LEN] = "untitled.pb";
static char saveAsBuffer[MAX_FILENAME_LEN] = {0};
static int saveAsCursor = 0;
static char statusMessage[128] = "";
static float statusMessageTimer = 0.0f;

static void EnsureFilesDirExists(void);
static void SaveFile(TextBuffer *tb, const char *filename);
static void LoadFile(TextBuffer *tb, const char *filename);
static void NewFile(TextBuffer *tb);

static void InitTextBuffer(TextBuffer *tb);
static void FreeTextBuffer(TextBuffer *tb);
static void InsertChar(TextBuffer *tb, char c);
static void InsertString(TextBuffer *tb, const char *text);
static void DeleteChar(TextBuffer *tb);
static void DeleteSelection(TextBuffer *tb);

static void PushUndoState(TextBuffer *tb);
static void ClearRedoStack(void);
static void ClearUndoStack(void);
static void Undo(TextBuffer *tb);
static void Redo(TextBuffer *tb);

static void MoveCursorUp(TextBuffer *tb);
static void MoveCursorDown(TextBuffer *tb);
static void ClearSelection(TextBuffer *tb);
static bool HasSelection(TextBuffer *tb);
static const char *GetSelection(TextBuffer *tb);

static int CountLines(const char *text, int length);
static Vector2 GetCursorScreenPos(const char *text, int cursorPosition, Font font, float lineSpacing);
static int GetLineForIndex(const char *text, int index);
static int GetStartOfLine(const char *text, int line);
static int GetColumnForIndex(const char *text, int index);
static void SetStatusMessage(const char *message);

int main(void)
{
    SetTraceLogLevel(LOG_ERROR);

    const int screenWidth = 1280;
    const int screenHeight = 720;

    InitWindow(screenWidth, screenHeight, "Pogberry Editor");
    SetExitKey(0);
    SetWindowState(FLAG_WINDOW_RESIZABLE);

    EnsureFilesDirExists();

    Font font = GetFontDefault();

    Color bgColor = {40, 42, 54, 255};
    Color textColor = {248, 248, 242, 255};
    Color gutterColor = {30, 32, 42, 255};
    Color gutterTextColor = {100, 108, 140, 255};
    Color cursorColor = {248, 248, 242, 255};
    Color selectionColor = {68, 71, 90, 200};
    Color statusColor = {68, 71, 90, 255};

    TextBuffer textBuffer = {0};
    InitTextBuffer(&textBuffer);

    LoadFile(&textBuffer, currentFilename); // Load default or create new

    EditorMode mode = MODE_EDIT;
    FilePathList fileList = {0};
    int fileSelection = 0;

    SetTargetFPS(60);

    while (!WindowShouldClose())
    {
        if (statusMessageTimer > 0)
            statusMessageTimer -= GetFrameTime();

        if (mode == MODE_EDIT)
        {
            bool textChanged = false;
            bool selectionChangedByKey = false;

            if (IsKeyDown(KEY_LEFT_CONTROL))
            {
                if (IsKeyPressed(KEY_S))
                {
                    if (strcmp(currentFilename, "untitled.pb") == 0) {
                        memset(saveAsBuffer, 0, MAX_FILENAME_LEN); //clear the buffer
                        saveAsCursor = 0;
                        mode = MODE_SAVE_AS;
                    } else {
                        SaveFile(&textBuffer, currentFilename);
                    }
                }
                else if (IsKeyPressed(KEY_O))
                {
                    fileList = LoadDirectoryFiles("files");
                    fileSelection = 0;
                    mode = MODE_OPEN_FILE;
                }
                else if (IsKeyPressed(KEY_N))
                {
                    NewFile(&textBuffer);
                }
                else if (IsKeyPressed(KEY_Z))
                {
                    Undo(&textBuffer);
                }
                else if (IsKeyPressed(KEY_Y))
                {
                    Redo(&textBuffer);
                }
                else if (IsKeyPressed(KEY_A))
                {
                    textBuffer.selectionStart = 0;
                    textBuffer.selectionEnd = textBuffer.length;
                }
                else if (IsKeyPressed(KEY_C))
                {
                    if (HasSelection(&textBuffer))
                        SetClipboardText(GetSelection(&textBuffer));
                }
                else if (IsKeyPressed(KEY_X))
                {
                    if (HasSelection(&textBuffer))
                    {
                        PushUndoState(&textBuffer);
                        SetClipboardText(GetSelection(&textBuffer));
                        DeleteSelection(&textBuffer);
                        textChanged = true;
                    }
                }
                else if (IsKeyPressed(KEY_V))
                {
                    PushUndoState(&textBuffer);
                    InsertString(&textBuffer, GetClipboardText());
                    textChanged = true;
                }
            }
            else
            {
                int key = GetCharPressed();
                while (key > 0)
                {
                    if ((key >= 32) && (key <= 125))
                    {
                        PushUndoState(&textBuffer);
                        InsertChar(&textBuffer, (char)key);
                        textChanged = true;
                    }
                    key = GetCharPressed();
                }

                if (IsKeyPressed(KEY_ENTER))
                {
                    PushUndoState(&textBuffer);
                    InsertChar(&textBuffer, '\n');
                    textChanged = true;
                }
                if (IsKeyPressedRepeat(KEY_BACKSPACE) || IsKeyPressed(KEY_BACKSPACE))
                {
                    PushUndoState(&textBuffer);
                    DeleteChar(&textBuffer);
                    textChanged = true;
                }

                bool shift = IsKeyDown(KEY_LEFT_SHIFT) || IsKeyDown(KEY_RIGHT_SHIFT);
                if (IsKeyPressed(KEY_LEFT) || IsKeyPressedRepeat(KEY_LEFT))
                {
                    if (!shift && HasSelection(&textBuffer))
                        textBuffer.cursor = (textBuffer.selectionStart < textBuffer.selectionEnd) ? textBuffer.selectionStart : textBuffer.selectionEnd;
                    else if (textBuffer.cursor > 0)
                        textBuffer.cursor--;
                    selectionChangedByKey = true;
                }
                if (IsKeyPressed(KEY_RIGHT) || IsKeyPressedRepeat(KEY_RIGHT))
                {
                    if (!shift && HasSelection(&textBuffer))
                        textBuffer.cursor = (textBuffer.selectionStart > textBuffer.selectionEnd) ? textBuffer.selectionStart : textBuffer.selectionEnd;
                    else if (textBuffer.cursor < textBuffer.length)
                        textBuffer.cursor++;
                    selectionChangedByKey = true;
                }
                if (IsKeyPressed(KEY_UP) || IsKeyPressedRepeat(KEY_UP))
                {
                    MoveCursorUp(&textBuffer);
                    selectionChangedByKey = true;
                }
                if (IsKeyPressed(KEY_DOWN) || IsKeyPressedRepeat(KEY_DOWN))
                {
                    MoveCursorDown(&textBuffer);
                    selectionChangedByKey = true;
                }

                if (selectionChangedByKey)
                {
                    if (shift)
                    {
                        if (textBuffer.selectionStart == textBuffer.selectionEnd)
                            textBuffer.selectionStart = textBuffer.cursor;
                        textBuffer.selectionEnd = textBuffer.cursor;
                    }
                    else
                    {
                        ClearSelection(&textBuffer);
                    }
                }
            }
            if (textChanged)
                ClearRedoStack();
        }
        else if (mode == MODE_SAVE_AS)
        {
            int key = GetCharPressed();
            if ((key >= 32) && (key <= 125) && (saveAsCursor < MAX_FILENAME_LEN - 1))
            {
                saveAsBuffer[saveAsCursor] = (char)key;
                saveAsCursor++;
            }

            if (IsKeyPressedRepeat(KEY_BACKSPACE) || IsKeyPressed(KEY_BACKSPACE))
            {
                if (saveAsCursor > 0) {
                    saveAsCursor--;
                    saveAsBuffer[saveAsCursor] = '\0';
                }
            }

            if (IsKeyPressed(KEY_ENTER))
            {
                if (saveAsCursor > 0) {
                    // if user didnt add the extension, add it
                    if (!TextIsEqual(GetFileExtension(saveAsBuffer), ".pb")) {
                        strcat(saveAsBuffer, ".pb");
                    }

                    strncpy(currentFilename, saveAsBuffer, MAX_FILENAME_LEN - 1);
                    SaveFile(&textBuffer, currentFilename);
                }
                mode = MODE_EDIT; //back to editing
            }
            else if (IsKeyPressed(KEY_ESCAPE)) 
            {
                mode = MODE_EDIT;
            }
        }
        else if (mode == MODE_OPEN_FILE)
        {
            if (IsKeyPressed(KEY_UP))
                fileSelection--;
            if (IsKeyPressed(KEY_DOWN))
                fileSelection++;
            if (fileSelection < 0)
                fileSelection = 0;
            if (fileSelection >= (int)fileList.count)
                fileSelection = fileList.count - 1;

            if (IsKeyPressed(KEY_ENTER))
            {
                const char *filename = GetFileName(fileList.paths[fileSelection]);
                LoadFile(&textBuffer, filename);
                UnloadDirectoryFiles(fileList);
                mode = MODE_EDIT;
            }
            if (IsKeyPressed(KEY_ESCAPE))
            {
                UnloadDirectoryFiles(fileList);
                mode = MODE_EDIT;
            }
        }

        // -- Draw --
        BeginDrawing();
        ClearBackground(bgColor);

        if (mode == MODE_EDIT)
        {
            int totalLines = CountLines(textBuffer.buffer, textBuffer.length);
            char lineNumText[16];
            sprintf(lineNumText, "%d", totalLines);
            float gutterWidth = MeasureTextEx(font, lineNumText, EDITOR_FONT_SIZE, 1).x + 20;

            DrawRectangle(0, 0, gutterWidth, GetScreenHeight(), gutterColor);

            float textY = 5.0f;
            int lineCount = 1;
            const char *currentLineStart = textBuffer.buffer;
            for (int i = 0; i <= textBuffer.length; i++)
            {
                if (textBuffer.buffer[i] == '\n' || textBuffer.buffer[i] == '\0')
                {
                    int lineLength = &textBuffer.buffer[i] - currentLineStart;
                    const char *lineText = TextSubtext(currentLineStart, 0, lineLength);

                    if (HasSelection(&textBuffer))
                    {
                        int selStart = (textBuffer.selectionStart < textBuffer.selectionEnd) ? textBuffer.selectionStart : textBuffer.selectionEnd;
                        int selEnd = (textBuffer.selectionStart > textBuffer.selectionEnd) ? textBuffer.selectionStart : textBuffer.selectionEnd;
                        int lineStartIdx = currentLineStart - textBuffer.buffer;

                        if (selStart < lineStartIdx + lineLength && selEnd > lineStartIdx)
                        {
                            int startX = 0;
                            if (selStart > lineStartIdx)
                            {
                                startX = MeasureTextEx(font, TextSubtext(currentLineStart, 0, selStart - lineStartIdx), EDITOR_FONT_SIZE, 1).x;
                            }
                            int endX = MeasureTextEx(font, TextSubtext(currentLineStart, 0, (selEnd > lineStartIdx + lineLength) ? lineLength : selEnd - lineStartIdx), EDITOR_FONT_SIZE, 1).x;
                            DrawRectangle(gutterWidth + 10 + startX, textY, endX - startX, EDITOR_FONT_SIZE * EDITOR_LINE_SPACING, selectionColor);
                        }
                    }

                    DrawTextEx(font, lineText, (Vector2){gutterWidth + 10, textY}, EDITOR_FONT_SIZE, 1, textColor);
                    sprintf(lineNumText, "%d", lineCount);
                    DrawTextEx(font, lineNumText, (Vector2){10, textY}, EDITOR_FONT_SIZE, 1, gutterTextColor);

                    currentLineStart = &textBuffer.buffer[i + 1];
                    textY += EDITOR_FONT_SIZE * EDITOR_LINE_SPACING;
                    lineCount++;
                    if (textBuffer.buffer[i] == '\0')
                        break;
                }
            }

            if (fmod(GetTime(), 1.0) > 0.5)
            {
                Vector2 cursorPos = GetCursorScreenPos(textBuffer.buffer, textBuffer.cursor, font, EDITOR_LINE_SPACING);
                cursorPos.x += gutterWidth + 10;
                cursorPos.y += 5.0f;
                DrawRectangle(cursorPos.x, cursorPos.y, 2, EDITOR_FONT_SIZE, cursorColor);
            }
        }
        else if (mode == MODE_OPEN_FILE)
        {
            DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), Fade(bgColor, 0.8f));
            Vector2 menuPos = {GetScreenWidth() / 2.0f - 200, GetScreenHeight() / 2.0f - 150};
            DrawRectangle(menuPos.x, menuPos.y, 500, 300, gutterColor);
            DrawRectangleLines(menuPos.x, menuPos.y, 500, 300, gutterTextColor);
            DrawText("Open File (Enter to select, Esc to cancel)", menuPos.x + 10, menuPos.y + 10, 20, textColor);

            for (unsigned int i = 0; i < fileList.count; i++)
            {
                const char *filename = GetFileName(fileList.paths[i]);
                if (TextIsEqual(GetFileExtension(filename), ".pb"))
                {
                    DrawText(filename, menuPos.x + 20, menuPos.y + 40 + i * 30, 20, (i == fileSelection) ? (Color){255, 255, 0, 255} : textColor);
                }
            }
        }
        else if (mode == MODE_SAVE_AS) 
        {
            DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), Fade(bgColor, 0.8f));

            float boxWidth = 450;
            float boxHeight = 100;
            Vector2 boxPos = { GetScreenWidth()/2.0f - boxWidth/2.0f, GetScreenHeight()/2.0f - boxHeight/2.0f };

            DrawRectangle(boxPos.x, boxPos.y, boxWidth, boxHeight, gutterColor);
            DrawRectangleLines(boxPos.x, boxPos.y, boxWidth, boxHeight, gutterTextColor);

            DrawText("Save As (Enter to confirm, Esc to cancel)", boxPos.x + 10, boxPos.y + 10, 20, textColor);
            DrawText(saveAsBuffer, boxPos.x + 10, boxPos.y + 50, 20, textColor);

            // draw a blinking cursor
            if (fmod(GetTime(), 1.0) > 0.5) {
                int textWidth = MeasureText(saveAsBuffer, 20);
                DrawRectangle(boxPos.x + 10 + textWidth, boxPos.y + 50, 2, 20, cursorColor);
            }
        }

        // Draw Status Bar
        int screenHeight = GetScreenHeight();
        DrawRectangle(0, screenHeight - 20, GetScreenWidth(), 25, statusColor);
        DrawText(TextFormat("File: %s", currentFilename), 10, screenHeight - 15, 16, textColor);
        if (statusMessageTimer > 0)
        {
            int textWidth = MeasureText(statusMessage, 10);
            DrawText(statusMessage, GetScreenWidth() - textWidth - 10, screenHeight - 15, 10, textColor);
        }

        EndDrawing();
    }

    UnloadDirectoryFiles(fileList);
    FreeTextBuffer(&textBuffer);
    for (int i = 0; i <= undoTop; i++)
        free(undoStack[i].buffer);
    for (int i = 0; i <= redoTop; i++)
        free(redoStack[i].buffer);
    CloseWindow();

    return 0;
}

void EnsureFilesDirExists(void)
{
    if (!DirectoryExists("files"))
    {
        MKDIR("files");
        TraceLog(LOG_INFO, "Created 'files' directory.");
    }
}

void SaveFile(TextBuffer *tb, const char *filename)
{
    char path[MAX_FILENAME_LEN + 6];
    sprintf(path, "files/%s", filename);
    bool success = SaveFileText(path, tb->buffer);
    if (success)
    {
        SetStatusMessage(TextFormat("Saved to %s", filename));
    }
    else
    {
        SetStatusMessage("Error: Failed to save file.");
    }
}

void LoadFile(TextBuffer *tb, const char *filename)
{
    strncpy(currentFilename, filename, MAX_FILENAME_LEN - 1);
    char path[MAX_FILENAME_LEN + 6];
    sprintf(path, "files/%s", filename);

    if (FileExists(path) && strcmp(filename, "untitled.pb") != 0)
    {
        char *fileContent = LoadFileText(path);
        if (fileContent != NULL)
        {
            FreeTextBuffer(tb);
            InitTextBuffer(tb);
            InsertString(tb, fileContent);
            UnloadFileText(fileContent);
            SetStatusMessage(TextFormat("Loaded %s", filename));
        }
    }
    else
    {
        // File doesn't exist, start with a blank slate
        const char *initialText = "-- welcome to pogberry --\n\n"
                                  "-there is no auto-save and this file will be overwritten, so make sure to press ctrl+s before writing any code, and before quitting\n"
                                  "-basic shortcuts like ctrl+c, v, x, u, r, a and o work as you'd expect them to\n"
                                  "-you can run the code by pressing ctrl+i, and save your program as an executable by pressing ctrl + e\n"
                                  "-no mouse usage/buttons here, pls rememeber the shortcuts, there's not many";
        FreeTextBuffer(tb);
        InitTextBuffer(tb);
        InsertString(tb, initialText);
        SetStatusMessage(TextFormat("New file: %s", filename));
    }

    ClearSelection(tb);
    tb->cursor = 0;
    ClearUndoStack();
    ClearRedoStack();
    PushUndoState(tb);
}

void NewFile(TextBuffer *tb)
{
    LoadFile(tb, "untitled.pb");
}

void SetStatusMessage(const char *message)
{
    strncpy(statusMessage, message, 127);
    statusMessageTimer = 3.0f; // Show message for 3 seconds
}

void InitTextBuffer(TextBuffer *tb)
{
    tb->buffer = (char *)malloc(EDITOR_DEFAULT_BUFFER_CAPACITY);
    if (tb->buffer == NULL)
    {
        TraceLog(LOG_FATAL, "Failed to allocate memory for text buffer");
        return;
    }
    memset(tb->buffer, 0, EDITOR_DEFAULT_BUFFER_CAPACITY);
    tb->capacity = EDITOR_DEFAULT_BUFFER_CAPACITY;
    tb->length = 0;
    tb->cursor = 0;
    ClearSelection(tb);
}

void FreeTextBuffer(TextBuffer *tb)
{
    if (tb->buffer != NULL)
    {
        free(tb->buffer);
        tb->buffer = NULL;
    }
}

void InsertChar(TextBuffer *tb, char c)
{
    if (HasSelection(tb))
        DeleteSelection(tb);
    if (tb->length >= tb->capacity - 1)
    {
        int newCapacity = tb->capacity * EDITOR_TEXT_BUFFER_GROW_FACTOR;
        char *newBuffer = (char *)realloc(tb->buffer, newCapacity);
        if (newBuffer == NULL)
        {
            TraceLog(LOG_WARNING, "Failed to grow text buffer");
            return;
        }
        tb->buffer = newBuffer;
        tb->capacity = newCapacity;
    }
    if (tb->cursor < tb->length)
        memmove(&tb->buffer[tb->cursor + 1], &tb->buffer[tb->cursor], tb->length - tb->cursor);
    tb->buffer[tb->cursor] = c;
    tb->length++;
    tb->cursor++;
    tb->buffer[tb->length] = '\0';
}

void InsertString(TextBuffer *tb, const char *text)
{
    if (text == NULL)
        return;
    if (HasSelection(tb))
        DeleteSelection(tb);
    int textLen = strlen(text);
    if (textLen == 0)
        return;
    while (tb->length + textLen >= tb->capacity)
    {
        int newCapacity = tb->capacity * EDITOR_TEXT_BUFFER_GROW_FACTOR;
        char *newBuffer = (char *)realloc(tb->buffer, newCapacity);
        if (newBuffer == NULL)
        {
            TraceLog(LOG_WARNING, "Failed to grow text buffer");
            return;
        }
        tb->buffer = newBuffer;
        tb->capacity = newCapacity;
    }
    if (tb->cursor < tb->length)
        memmove(&tb->buffer[tb->cursor + textLen], &tb->buffer[tb->cursor], tb->length - tb->cursor);
    memcpy(&tb->buffer[tb->cursor], text, textLen);
    tb->length += textLen;
    tb->cursor += textLen;
    tb->buffer[tb->length] = '\0';
}

void DeleteChar(TextBuffer *tb)
{
    if (HasSelection(tb))
        DeleteSelection(tb);
    else if (tb->cursor > 0)
    {
        if (tb->cursor < tb->length)
            memmove(&tb->buffer[tb->cursor - 1], &tb->buffer[tb->cursor], tb->length - tb->cursor);
        tb->cursor--;
        tb->length--;
        tb->buffer[tb->length] = '\0';
    }
}

void DeleteSelection(TextBuffer *tb)
{
    if (!HasSelection(tb))
        return;
    int start = (tb->selectionStart < tb->selectionEnd) ? tb->selectionStart : tb->selectionEnd;
    int end = (tb->selectionStart > tb->selectionEnd) ? tb->selectionStart : tb->selectionEnd;
    int len = end - start;
    if (end < tb->length)
        memmove(&tb->buffer[start], &tb->buffer[end], tb->length - end);
    tb->length -= len;
    tb->cursor = start;
    tb->buffer[tb->length] = '\0';
    ClearSelection(tb);
}

void PushUndoState(TextBuffer *tb)
{
    if (undoTop >= 0 && undoStack[undoTop].length == tb->length && strcmp(undoStack[undoTop].buffer, tb->buffer) == 0)
        return;
    if (undoTop >= MAX_UNDO_LEVELS - 1)
    {
        free(undoStack[0].buffer);
        memmove(&undoStack[0], &undoStack[1], (MAX_UNDO_LEVELS - 1) * sizeof(HistoryState));
        undoTop--;
    }
    undoTop++;
    undoStack[undoTop].buffer = (char *)malloc(tb->capacity);
    if (undoStack[undoTop].buffer == NULL)
    {
        undoTop--;
        return;
    }
    memcpy(undoStack[undoTop].buffer, tb->buffer, tb->capacity);
    undoStack[undoTop].length = tb->length;
    undoStack[undoTop].cursor = tb->cursor;
    undoStack[undoTop].selectionStart = tb->selectionStart;
    undoStack[undoTop].selectionEnd = tb->selectionEnd;
}

void ClearRedoStack(void)
{
    for (int i = 0; i <= redoTop; i++)
        free(redoStack[i].buffer);
    redoTop = -1;
}

void ClearUndoStack(void)
{
    for (int i = 0; i <= undoTop; i++)
        free(undoStack[i].buffer);
    undoTop = -1;
}

void Undo(TextBuffer *tb)
{
    if (undoTop < 0)
        return;
    if (redoTop < MAX_UNDO_LEVELS - 1)
    {
        redoTop++;
        redoStack[redoTop].buffer = (char *)malloc(tb->capacity);
        memcpy(redoStack[redoTop].buffer, tb->buffer, tb->capacity);
        redoStack[redoTop].length = tb->length;
        redoStack[redoTop].cursor = tb->cursor;
        redoStack[redoTop].selectionStart = tb->selectionStart;
        redoStack[redoTop].selectionEnd = tb->selectionEnd;
    }
    HistoryState *state = &undoStack[undoTop];
    memcpy(tb->buffer, state->buffer, state->length + 1);
    tb->length = state->length;
    tb->cursor = state->cursor;
    tb->selectionStart = state->selectionStart;
    tb->selectionEnd = state->selectionEnd;
    free(undoStack[undoTop].buffer);
    undoTop--;
}

void Redo(TextBuffer *tb)
{
    if (redoTop < 0)
        return;
    PushUndoState(tb);
    HistoryState *state = &redoStack[redoTop];
    memcpy(tb->buffer, state->buffer, state->length + 1);
    tb->length = state->length;
    tb->cursor = state->cursor;
    tb->selectionStart = state->selectionStart;
    tb->selectionEnd = state->selectionEnd;
    free(redoStack[redoTop].buffer);
    redoTop--;
}

void MoveCursorUp(TextBuffer *tb)
{
    int currentLine = GetLineForIndex(tb->buffer, tb->cursor);
    if (currentLine == 0)
        return;
    int currentColumn = GetColumnForIndex(tb->buffer, tb->cursor);
    int prevLineStart = GetStartOfLine(tb->buffer, currentLine - 1);
    int prevLineEnd = GetStartOfLine(tb->buffer, currentLine) - 1;
    int prevLineLength = prevLineEnd - prevLineStart;
    tb->cursor = prevLineStart + ((currentColumn < prevLineLength) ? currentColumn : prevLineLength);
}

void MoveCursorDown(TextBuffer *tb)
{
    int currentLine = GetLineForIndex(tb->buffer, tb->cursor);
    int totalLines = CountLines(tb->buffer, tb->length);
    if (currentLine >= totalLines - 1)
        return;
    int currentColumn = GetColumnForIndex(tb->buffer, tb->cursor);
    int nextLineStart = GetStartOfLine(tb->buffer, currentLine + 1);
    int nextLineEnd = tb->length;
    for (int i = nextLineStart; i < tb->length; i++)
    {
        if (tb->buffer[i] == '\n')
        {
            nextLineEnd = i;
            break;
        }
    }
    int nextLineLength = nextLineEnd - nextLineStart;
    tb->cursor = nextLineStart + ((currentColumn < nextLineLength) ? currentColumn : nextLineLength);
}

void ClearSelection(TextBuffer *tb)
{
    tb->selectionStart = tb->cursor;
    tb->selectionEnd = tb->cursor;
}

bool HasSelection(TextBuffer *tb)
{
    return tb->selectionStart != tb->selectionEnd;
}

const char *GetSelection(TextBuffer *tb)
{
    if (!HasSelection(tb))
        return "";
    int start = (tb->selectionStart < tb->selectionEnd) ? tb->selectionStart : tb->selectionEnd;
    int end = (tb->selectionStart > tb->selectionEnd) ? tb->selectionStart : tb->selectionEnd;
    return TextSubtext(tb->buffer, start, end - start);
}

int CountLines(const char *text, int length)
{
    int count = 1;
    for (int i = 0; i < length; i++)
        if (text[i] == '\n')
            count++;
    return count;
}

Vector2 GetCursorScreenPos(const char *text, int cursorPosition, Font font, float lineSpacing)
{
    Vector2 pos = {0.0f, 0.0f};
    int currentLine = 0;
    int lineStartPos = 0;
    for (int i = 0; i < cursorPosition; i++)
    {
        if (text[i] == '\n')
        {
            currentLine++;
            lineStartPos = i + 1;
        }
    }
    pos.y = currentLine * EDITOR_FONT_SIZE * lineSpacing;
    const char *lineSubstring = TextSubtext(text, lineStartPos, cursorPosition - lineStartPos);
    pos.x = MeasureTextEx(font, lineSubstring, EDITOR_FONT_SIZE, 1).x;
    return pos;
}

int GetLineForIndex(const char *text, int index)
{
    int line = 0;
    for (int i = 0; i < index && text[i] != '\0'; i++)
        if (text[i] == '\n')
            line++;
    return line;
}

int GetStartOfLine(const char *text, int line)
{
    if (line == 0)
        return 0;
    int currentLine = 0;
    for (int i = 0; text[i] != '\0'; i++)
    {
        if (text[i] == '\n')
        {
            currentLine++;
            if (currentLine == line)
                return i + 1;
        }
    }
    return 0;
}

int GetColumnForIndex(const char *text, int index)
{
    int lineStart = GetStartOfLine(text, GetLineForIndex(text, index));
    return index - lineStart;
}
