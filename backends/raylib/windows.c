#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#ifndef NOMINMAX
#define NOMINMAX
#endif

#define CloseWindow WindowsCloseWindow
#define LoadImage WindowsLoadImage
#define DrawText WindowsDrawText
#define DrawTextEx WindowsDrawTextEx
#define PlaySound WindowsPlaySound

#include <windows.h>

#undef CloseWindow
#undef LoadImage
#undef DrawText
#undef DrawTextEx
#undef PlaySound

#define Rectangle RaylibRectangle
#define ShowCursor RaylibShowCursor

#include <raylib.h>

#undef Rectangle
#undef ShowCursor

#define MAX_TEXTURES 512
#define MAX_SOUNDS 256
#define MAX_MUSIC 64

static Texture2D textures[MAX_TEXTURES];
static bool textureActive[MAX_TEXTURES];

static Sound sounds[MAX_SOUNDS];
static bool soundActive[MAX_SOUNDS];

static Music musics[MAX_MUSIC];
static bool musicActive[MAX_MUSIC];
static bool audioInitialized = false;

__declspec(dllexport) void initWindow(int width, int height, const char *title) {
  SetConfigFlags(FLAG_WINDOW_RESIZABLE);
  SetTraceLogLevel(LOG_ERROR);
  InitWindow(width, height, title);
}

__declspec(dllexport) void initAudio(void) {
  if (!audioInitialized) {
    InitAudioDevice();
    audioInitialized = true;
  }
}

__declspec(dllexport) void closeAudio(void) {
  if (audioInitialized) {
    for (int i = 0; i < MAX_SOUNDS; i++) {
      if (soundActive[i]) {
        UnloadSound(sounds[i]);
        soundActive[i] = false;
      }
    }
    for (int i = 0; i < MAX_MUSIC; i++) {
      if (musicActive[i]) {
        UnloadMusicStream(musics[i]);
        musicActive[i] = false;
      }
    }
    CloseAudioDevice();
    audioInitialized = false;
  }
}

static int virtualWidth = 0;
static int virtualHeight = 0;
static float renderScale = 1.0f;
static float renderOffsetX = 0.0f;
static float renderOffsetY = 0.0f;
static bool virtualScalingActive = false;

__declspec(dllexport) void setVirtualResolution(int width, int height) {
  if (width <= 0 || height <= 0) {
    virtualScalingActive = false;
    virtualWidth = 0;
    virtualHeight = 0;
    renderScale = 1.0f;
    renderOffsetX = 0.0f;
    renderOffsetY = 0.0f;
  } else {
    virtualScalingActive = true;
    virtualWidth = width;
    virtualHeight = height;
  }
}

__declspec(dllexport) int getRenderWidth(void) { return GetScreenWidth(); }
__declspec(dllexport) int getRenderHeight(void) { return GetScreenHeight(); }

__declspec(dllexport) void closeWindow(void) {
  for (int i = 0; i < MAX_TEXTURES; i++) {
    if (textureActive[i]) {
      UnloadTexture(textures[i]);
      textureActive[i] = false;
    }
  }
  closeAudio();
  virtualScalingActive = false;
  virtualWidth = 0;
  virtualHeight = 0;
  renderScale = 1.0f;
  renderOffsetX = 0.0f;
  renderOffsetY = 0.0f;
  CloseWindow();
}

__declspec(dllexport) bool windowShouldClose(void) { return WindowShouldClose(); }
__declspec(dllexport) bool isWindowMinimized(void) { return IsWindowMinimized(); }
__declspec(dllexport) bool isWindowFocused(void) { return IsWindowFocused(); }
__declspec(dllexport) bool isWindowResized(void) { return IsWindowResized(); }
__declspec(dllexport) void toggleFullscreen(void) { ToggleFullscreen(); }
__declspec(dllexport) void toggleBorderlessWindowed(void) { ToggleBorderlessWindowed(); }
__declspec(dllexport) void setWindowTitle(const char *title) { SetWindowTitle(title); }
__declspec(dllexport) int getScreenWidth(void) {
  if (virtualScalingActive && virtualWidth > 0) return virtualWidth;
  return GetScreenWidth();
}
__declspec(dllexport) int getScreenHeight(void) {
  if (virtualScalingActive && virtualHeight > 0) return virtualHeight;
  return GetScreenHeight();
}
__declspec(dllexport) int getFPS(void) { return GetFPS(); }
__declspec(dllexport) float getFrameTime(void) { return GetFrameTime(); }
__declspec(dllexport) void setTargetFPS(int fps) { SetTargetFPS(fps); }

__declspec(dllexport) void clearBackground(int r, int g, int b) {
  if (virtualScalingActive && virtualWidth > 0 && virtualHeight > 0) {
    DrawRectangle(0, 0, virtualWidth, virtualHeight, (Color){r, g, b, 255});
  } else {
    ClearBackground((Color){r, g, b, 255});
  }
}

__declspec(dllexport) void beginDrawing(void) {
  BeginDrawing();
  if (virtualScalingActive && virtualWidth > 0 && virtualHeight > 0) {
    int winW = GetScreenWidth();
    int winH = GetScreenHeight();
    float scaleX = (float)winW / (float)virtualWidth;
    float scaleY = (float)winH / (float)virtualHeight;
    renderScale = (scaleX < scaleY) ? scaleX : scaleY;
    renderOffsetX = (winW - (float)virtualWidth * renderScale) * 0.5f;
    renderOffsetY = (winH - (float)virtualHeight * renderScale) * 0.5f;

    ClearBackground(BLACK);

    Camera2D camera = {0};
    camera.offset = (Vector2){renderOffsetX, renderOffsetY};
    camera.target = (Vector2){0.0f, 0.0f};
    camera.rotation = 0.0f;
    camera.zoom = renderScale;
    BeginMode2D(camera);
  }
}

__declspec(dllexport) void endDrawing(void) {
  if (virtualScalingActive && virtualWidth > 0 && virtualHeight > 0) {
    EndMode2D();
    int winW = GetScreenWidth();
    int winH = GetScreenHeight();
    if (renderOffsetX > 0.0f) {
      int barW = (int)(renderOffsetX + 0.99f);
      DrawRectangle(0, 0, barW, winH, BLACK);
      int rightX = (int)(renderOffsetX + (float)virtualWidth * renderScale);
      DrawRectangle(rightX, 0, winW - rightX + 1, winH, BLACK);
    }
    if (renderOffsetY > 0.0f) {
      int barH = (int)(renderOffsetY + 0.99f);
      DrawRectangle(0, 0, winW, barH, BLACK);
      int bottomY = (int)(renderOffsetY + (float)virtualHeight * renderScale);
      DrawRectangle(0, bottomY, winW, winH - bottomY + 1, BLACK);
    }
  }
  EndDrawing();
}

__declspec(dllexport) void drawPixel(int posX, int posY, int r, int g, int b) {
  DrawPixel(posX, posY, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawLine(int startPosX, int startPosY, int endPosX, int endPosY, int r, int g, int b) {
  DrawLine(startPosX, startPosY, endPosX, endPosY, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawCircle(int centerX, int centerY, float radius, int r, int g, int b) {
  DrawCircle(centerX, centerY, radius, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawCircleLines(int centerX, int centerY, float radius, int r, int g, int b) {
  DrawCircleLines(centerX, centerY, radius, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawCircleAlpha(int centerX, int centerY, float radius, int r, int g, int b, int a) {
  DrawCircle(centerX, centerY, radius, (Color){r, g, b, a});
}

__declspec(dllexport) void drawEllipse(int centerX, int centerY, float radiusH, float radiusV, int r, int g, int b) {
  DrawEllipse(centerX, centerY, radiusH, radiusV, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawRectangle(int posX, int posY, int width, int height, int r, int g, int b) {
  DrawRectangle(posX, posY, width, height, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawRectangleLines(int posX, int posY, int width, int height, int r, int g, int b) {
  DrawRectangleLines(posX, posY, width, height, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawRectangleAlpha(int posX, int posY, int width, int height, int r, int g, int b, int a) {
  DrawRectangle(posX, posY, width, height, (Color){r, g, b, a});
}

__declspec(dllexport) void drawRectangleRounded(float x, float y, float width, float height, float roundness,
                                                int segments, int r, int g, int b) {
  DrawRectangleRounded((RaylibRectangle){x, y, width, height}, roundness, segments, (Color){r, g, b, 255});
}

__declspec(dllexport) void drawText(const char *text, int posX, int posY, int fontSize, int r, int g, int b) {
  DrawText(text, posX, posY, fontSize, (Color){r, g, b, 255});
}

__declspec(dllexport) int measureText(const char *text, int fontSize) { return MeasureText(text, fontSize); }
__declspec(dllexport) void drawFPS(int posX, int posY) { DrawFPS(posX, posY); }
__declspec(dllexport) double getTime(void) { return GetTime(); }
__declspec(dllexport) void setWindowSize(int width, int height) { SetWindowSize(width, height); }
__declspec(dllexport) void setWindowPosition(int x, int y) { SetWindowPosition(x, y); }
__declspec(dllexport) bool isWindowFullscreen(void) { return IsWindowFullscreen(); }
__declspec(dllexport) bool isWindowMaximized(void) { return IsWindowMaximized(); }
__declspec(dllexport) void maximizeWindow(void) { MaximizeWindow(); }
__declspec(dllexport) void restoreWindow(void) { RestoreWindow(); }
__declspec(dllexport) void hideCursor(void) { HideCursor(); }
__declspec(dllexport) void showCursor(void) { RaylibShowCursor(); }

/* Input */
__declspec(dllexport) bool isKeyPressed(int key) { return IsKeyPressed(key); }
__declspec(dllexport) bool isKeyDown(int key) { return IsKeyDown(key); }
__declspec(dllexport) bool isKeyReleased(int key) { return IsKeyReleased(key); }
__declspec(dllexport) bool isKeyUp(int key) { return IsKeyUp(key); }
__declspec(dllexport) int getKeyPressed(void) { return GetKeyPressed(); }
__declspec(dllexport) int getCharPressed(void) { return GetCharPressed(); }
__declspec(dllexport) void setExitKey(int key) { SetExitKey(key); }

__declspec(dllexport) bool isMouseButtonPressed(int button) { return IsMouseButtonPressed(button); }
__declspec(dllexport) bool isMouseButtonDown(int button) { return IsMouseButtonDown(button); }
__declspec(dllexport) bool isMouseButtonReleased(int button) { return IsMouseButtonReleased(button); }
__declspec(dllexport) bool isMouseButtonUp(int button) { return IsMouseButtonUp(button); }
__declspec(dllexport) int getMouseX(void) {
  int mx = GetMouseX();
  if (virtualScalingActive && renderScale > 0.0f) {
    float vx = (mx - renderOffsetX) / renderScale;
    return (int)vx;
  }
  return mx;
}
__declspec(dllexport) int getMouseY(void) {
  int my = GetMouseY();
  if (virtualScalingActive && renderScale > 0.0f) {
    float vy = (my - renderOffsetY) / renderScale;
    return (int)vy;
  }
  return my;
}
__declspec(dllexport) float getMouseWheelMove(void) { return GetMouseWheelMove(); }

/* Collision */
__declspec(dllexport) bool checkCollisionRecs(float x1, float y1, float w1, float h1, float x2, float y2, float w2,
                                              float h2) {
  return CheckCollisionRecs((RaylibRectangle){x1, y1, w1, h1}, (RaylibRectangle){x2, y2, w2, h2});
}

__declspec(dllexport) bool checkCollisionCircles(float x1, float y1, float r1, float x2, float y2, float r2) {
  return CheckCollisionCircles((Vector2){x1, y1}, r1, (Vector2){x2, y2}, r2);
}

__declspec(dllexport) bool checkCollisionCircleRec(float cx, float cy, float radius, float rx, float ry, float rw,
                                                   float rh) {
  return CheckCollisionCircleRec((Vector2){cx, cy}, radius, (RaylibRectangle){rx, ry, rw, rh});
}

__declspec(dllexport) bool checkCollisionPointRec(float px, float py, float rx, float ry, float rw, float rh) {
  return CheckCollisionPointRec((Vector2){px, py}, (RaylibRectangle){rx, ry, rw, rh});
}

__declspec(dllexport) bool checkCollisionPointCircle(float px, float py, float cx, float cy, float radius) {
  return CheckCollisionPointCircle((Vector2){px, py}, (Vector2){cx, cy}, radius);
}

/* Sprites & Textures */
__declspec(dllexport) int loadTexture(const char *path) {
  if (!IsWindowReady()) return 0;
  for (int i = 0; i < MAX_TEXTURES; i++) {
    if (!textureActive[i]) {
      Texture2D tex = LoadTexture(path);
      if (tex.id == 0) return 0;
      textures[i] = tex;
      textureActive[i] = true;
      return i + 1;
    }
  }
  return 0;
}

__declspec(dllexport) void unloadTexture(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_TEXTURES && textureActive[index]) {
    UnloadTexture(textures[index]);
    textureActive[index] = false;
  }
}

__declspec(dllexport) void drawTexture(int id, int posX, int posY) {
  int index = id - 1;
  if (index >= 0 && index < MAX_TEXTURES && textureActive[index]) {
    DrawTexture(textures[index], posX, posY, WHITE);
  }
}

__declspec(dllexport) void drawTextureTint(int id, int posX, int posY, int r, int g, int b) {
  int index = id - 1;
  if (index >= 0 && index < MAX_TEXTURES && textureActive[index]) {
    DrawTexture(textures[index], posX, posY, (Color){r, g, b, 255});
  }
}

__declspec(dllexport) void drawTextureRec(int id, float sx, float sy, float sw, float sh, float dx, float dy) {
  int index = id - 1;
  if (index >= 0 && index < MAX_TEXTURES && textureActive[index]) {
    DrawTextureRec(textures[index], (RaylibRectangle){sx, sy, sw, sh}, (Vector2){dx, dy}, WHITE);
  }
}

__declspec(dllexport) void drawTexturePro(int id, float sx, float sy, float sw, float sh, float dx, float dy, float dw,
                                          float dh, float ox, float oy, float rot) {
  int index = id - 1;
  if (index >= 0 && index < MAX_TEXTURES && textureActive[index]) {
    DrawTexturePro(textures[index], (RaylibRectangle){sx, sy, sw, sh}, (RaylibRectangle){dx, dy, dw, dh},
                   (Vector2){ox, oy}, rot, WHITE);
  }
}

__declspec(dllexport) int getTextureWidth(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_TEXTURES && textureActive[index]) {
    return textures[index].width;
  }
  return 0;
}

__declspec(dllexport) int getTextureHeight(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_TEXTURES && textureActive[index]) {
    return textures[index].height;
  }
  return 0;
}

/* Sound Effects */
__declspec(dllexport) int loadSound(const char *path) {
  if (!audioInitialized) initAudio();
  if (!audioInitialized) return 0;
  for (int i = 0; i < MAX_SOUNDS; i++) {
    if (!soundActive[i]) {
      Sound snd = LoadSound(path);
      if (snd.frameCount == 0) return 0;
      sounds[i] = snd;
      soundActive[i] = true;
      return i + 1;
    }
  }
  return 0;
}

__declspec(dllexport) void unloadSound(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_SOUNDS && soundActive[index]) {
    UnloadSound(sounds[index]);
    soundActive[index] = false;
  }
}

__declspec(dllexport) void playSound(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_SOUNDS && soundActive[index]) {
    PlaySound(sounds[index]);
  }
}

__declspec(dllexport) void stopSound(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_SOUNDS && soundActive[index]) {
    StopSound(sounds[index]);
  }
}

__declspec(dllexport) void setSoundVolume(int id, float volume) {
  int index = id - 1;
  if (index >= 0 && index < MAX_SOUNDS && soundActive[index]) {
    SetSoundVolume(sounds[index], volume);
  }
}

__declspec(dllexport) void setSoundPitch(int id, float pitch) {
  int index = id - 1;
  if (index >= 0 && index < MAX_SOUNDS && soundActive[index]) {
    SetSoundPitch(sounds[index], pitch);
  }
}

__declspec(dllexport) bool isSoundPlaying(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_SOUNDS && soundActive[index]) {
    return IsSoundPlaying(sounds[index]);
  }
  return false;
}

__declspec(dllexport) void setMasterVolume(float volume) { SetMasterVolume(volume); }

/* Music Streams */
__declspec(dllexport) int loadMusic(const char *path) {
  if (!audioInitialized) initAudio();
  if (!audioInitialized) return 0;
  for (int i = 0; i < MAX_MUSIC; i++) {
    if (!musicActive[i]) {
      Music m = LoadMusicStream(path);
      if (m.frameCount == 0) return 0;
      musics[i] = m;
      musicActive[i] = true;
      return i + 1;
    }
  }
  return 0;
}

__declspec(dllexport) void unloadMusic(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    UnloadMusicStream(musics[index]);
    musicActive[index] = false;
  }
}

__declspec(dllexport) void playMusic(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    PlayMusicStream(musics[index]);
  }
}

__declspec(dllexport) void pauseMusic(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    PauseMusicStream(musics[index]);
  }
}

__declspec(dllexport) void resumeMusic(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    ResumeMusicStream(musics[index]);
  }
}

__declspec(dllexport) void stopMusic(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    StopMusicStream(musics[index]);
  }
}

__declspec(dllexport) void updateMusic(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    UpdateMusicStream(musics[index]);
  }
}

__declspec(dllexport) void setMusicVolume(int id, float volume) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    SetMusicVolume(musics[index], volume);
  }
}

__declspec(dllexport) bool isMusicStreamPlaying(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    return IsMusicStreamPlaying(musics[index]);
  }
  return false;
}
