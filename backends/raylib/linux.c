#include <stdbool.h>
#include <stddef.h>
#include <raylib.h>

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

static int traceLevel = LOG_ERROR;

#define MAX_SHADERS 64
static Shader shaders[MAX_SHADERS];
static bool shaderActive[MAX_SHADERS];

#define MAX_RENDER_TEXTURES 32
static RenderTexture2D renderTargets[MAX_RENDER_TEXTURES];
static bool renderTargetActive[MAX_RENDER_TEXTURES];
static bool inTextureMode = false;

void initWindow(int width, int height, const char *title) {
  SetConfigFlags(FLAG_WINDOW_RESIZABLE);
  SetTraceLogLevel(traceLevel);
  InitWindow(width, height, title);
}

void setTraceLogLevel(int level) {
  if (level < LOG_ALL) level = LOG_ALL;
  if (level > LOG_NONE) level = LOG_NONE;
  traceLevel = level;
  SetTraceLogLevel(level);
}

void setDebugMode(int level) { setTraceLogLevel(level); }

void initAudio(void) {
  if (!audioInitialized) {
    InitAudioDevice();
    audioInitialized = IsAudioDeviceReady();
  }
}

void closeAudio(void) {
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
  if (audioInitialized) {
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

void setVirtualResolution(int width, int height) {
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

int getRenderWidth(void) { return GetScreenWidth(); }
int getRenderHeight(void) { return GetScreenHeight(); }

void closeWindow(void) {
  closeAudio();
  for (int i = 0; i < MAX_TEXTURES; i++) {
    if (textureActive[i]) {
      UnloadTexture(textures[i]);
      textureActive[i] = false;
    }
  }
  for (int i = 0; i < MAX_SHADERS; i++) {
    if (shaderActive[i]) {
      UnloadShader(shaders[i]);
      shaderActive[i] = false;
    }
  }
  for (int i = 0; i < MAX_RENDER_TEXTURES; i++) {
    if (renderTargetActive[i]) {
      UnloadRenderTexture(renderTargets[i]);
      renderTargetActive[i] = false;
    }
  }
  inTextureMode = false;
  virtualScalingActive = false;
  virtualWidth = 0;
  virtualHeight = 0;
  renderScale = 1.0f;
  renderOffsetX = 0.0f;
  renderOffsetY = 0.0f;
  CloseWindow();
}

bool windowShouldClose(void) { return WindowShouldClose(); }
bool isWindowMinimized(void) { return IsWindowMinimized(); }
bool isWindowFocused(void) { return IsWindowFocused(); }
bool isWindowResized(void) { return IsWindowResized(); }
void toggleFullscreen(void) { ToggleFullscreen(); }
void toggleBorderlessWindowed(void) { ToggleBorderlessWindowed(); }
void setWindowTitle(const char *title) { SetWindowTitle(title); }
int getScreenWidth(void) {
  if (virtualScalingActive && virtualWidth > 0) return virtualWidth;
  return GetScreenWidth();
}
int getScreenHeight(void) {
  if (virtualScalingActive && virtualHeight > 0) return virtualHeight;
  return GetScreenHeight();
}
int getFPS(void) { return GetFPS(); }
float getFrameTime(void) { return GetFrameTime(); }
void clearBackground(int r, int g, int b) {
  if (virtualScalingActive && virtualWidth > 0 && virtualHeight > 0) {
    DrawRectangle(0, 0, virtualWidth, virtualHeight, (Color){r, g, b, 255});
  } else {
    ClearBackground((Color){r, g, b, 255});
  }
}
void beginDrawing(void) {
  BeginDrawing();
  if (!inTextureMode && virtualScalingActive && virtualWidth > 0 && virtualHeight > 0) {
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
void endDrawing(void) {
  if (!inTextureMode && virtualScalingActive && virtualWidth > 0 && virtualHeight > 0) {
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
void setTargetFPS(int fps) { SetTargetFPS(fps); }

void drawPixel(int posX, int posY, int r, int g, int b) { DrawPixel(posX, posY, (Color){r, g, b, 255}); }

void drawLine(int startPosX, int startPosY, int endPosX, int endPosY, int r, int g, int b) {
  DrawLine(startPosX, startPosY, endPosX, endPosY, (Color){r, g, b, 255});
}

void drawCircle(int centerX, int centerY, float radius, int r, int g, int b) {
  DrawCircle(centerX, centerY, radius, (Color){r, g, b, 255});
}

void drawCircleLines(int centerX, int centerY, float radius, int r, int g, int b) {
  DrawCircleLines(centerX, centerY, radius, (Color){r, g, b, 255});
}

void drawEllipse(int centerX, int centerY, float radiusH, float radiusV, int r, int g, int b) {
  DrawEllipse(centerX, centerY, radiusH, radiusV, (Color){r, g, b, 255});
}

void drawRectangle(int posX, int posY, int width, int height, int r, int g, int b) {
  DrawRectangle(posX, posY, width, height, (Color){r, g, b, 255});
}

void drawRectangleLines(int posX, int posY, int width, int height, int r, int g, int b) {
  DrawRectangleLines(posX, posY, width, height, (Color){r, g, b, 255});
}

void drawRectangleAlpha(int posX, int posY, int width, int height, int r, int g, int b, int a) {
  DrawRectangle(posX, posY, width, height, (Color){r, g, b, a});
}

void drawCircleAlpha(int centerX, int centerY, float radius, int r, int g, int b, int a) {
  DrawCircle(centerX, centerY, radius, (Color){r, g, b, a});
}

void drawRectangleRounded(float x, float y, float width, float height, float roundness, int segments, int r, int g,
                          int b) {
  DrawRectangleRounded((Rectangle){x, y, width, height}, roundness, segments, (Color){r, g, b, 255});
}

void drawText(const char *text, int posX, int posY, int fontSize, int r, int g, int b) {
  DrawText(text, posX, posY, fontSize, (Color){r, g, b, 255});
}

int measureText(const char *text, int fontSize) { return MeasureText(text, fontSize); }
void drawFPS(int posX, int posY) { DrawFPS(posX, posY); }
double getTime(void) { return GetTime(); }
void setWindowSize(int width, int height) { SetWindowSize(width, height); }
void setWindowPosition(int x, int y) { SetWindowPosition(x, y); }
bool isWindowFullscreen(void) { return IsWindowFullscreen(); }
bool isWindowMaximized(void) { return IsWindowMaximized(); }
void maximizeWindow(void) { MaximizeWindow(); }
void restoreWindow(void) { RestoreWindow(); }
void hideCursor(void) { HideCursor(); }
void showCursor(void) { ShowCursor(); }

/* Input */
bool isKeyPressed(int key) { return IsKeyPressed(key); }
bool isKeyDown(int key) { return IsKeyDown(key); }
bool isKeyReleased(int key) { return IsKeyReleased(key); }
bool isKeyUp(int key) { return IsKeyUp(key); }
int getKeyPressed(void) { return GetKeyPressed(); }
int getCharPressed(void) { return GetCharPressed(); }
void setExitKey(int key) { SetExitKey(key); }
bool isMouseButtonPressed(int button) { return IsMouseButtonPressed(button); }
bool isMouseButtonDown(int button) { return IsMouseButtonDown(button); }
bool isMouseButtonReleased(int button) { return IsMouseButtonReleased(button); }
bool isMouseButtonUp(int button) { return IsMouseButtonUp(button); }
int getMouseX(void) {
  int mx = GetMouseX();
  if (virtualScalingActive && renderScale > 0.0f) {
    float vx = (mx - renderOffsetX) / renderScale;
    return (int)vx;
  }
  return mx;
}
int getMouseY(void) {
  int my = GetMouseY();
  if (virtualScalingActive && renderScale > 0.0f) {
    float vy = (my - renderOffsetY) / renderScale;
    return (int)vy;
  }
  return my;
}
float getMouseWheelMove(void) { return GetMouseWheelMove(); }

/* Collision */
bool checkCollisionRecs(float x1, float y1, float w1, float h1, float x2, float y2, float w2, float h2) {
  return CheckCollisionRecs((Rectangle){x1, y1, w1, h1}, (Rectangle){x2, y2, w2, h2});
}

bool checkCollisionCircles(float x1, float y1, float r1, float x2, float y2, float r2) {
  return CheckCollisionCircles((Vector2){x1, y1}, r1, (Vector2){x2, y2}, r2);
}

bool checkCollisionCircleRec(float cx, float cy, float radius, float rx, float ry, float rw, float rh) {
  return CheckCollisionCircleRec((Vector2){cx, cy}, radius, (Rectangle){rx, ry, rw, rh});
}

bool checkCollisionPointRec(float px, float py, float rx, float ry, float rw, float rh) {
  return CheckCollisionPointRec((Vector2){px, py}, (Rectangle){rx, ry, rw, rh});
}

bool checkCollisionPointCircle(float px, float py, float cx, float cy, float radius) {
  return CheckCollisionPointCircle((Vector2){px, py}, (Vector2){cx, cy}, radius);
}

/* Sprites & Textures */
int loadTexture(const char *path) {
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

void unloadTexture(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_TEXTURES && textureActive[index]) {
    UnloadTexture(textures[index]);
    textureActive[index] = false;
  }
}

void drawTexture(int id, int posX, int posY) {
  int index = id - 1;
  if (index >= 0 && index < MAX_TEXTURES && textureActive[index]) {
    DrawTexture(textures[index], posX, posY, WHITE);
  }
}

void drawTextureTint(int id, int posX, int posY, int r, int g, int b) {
  int index = id - 1;
  if (index >= 0 && index < MAX_TEXTURES && textureActive[index]) {
    DrawTexture(textures[index], posX, posY, (Color){r, g, b, 255});
  }
}

void drawTextureRec(int id, float sx, float sy, float sw, float sh, float dx, float dy) {
  int index = id - 1;
  if (index >= 0 && index < MAX_TEXTURES && textureActive[index]) {
    DrawTextureRec(textures[index], (Rectangle){sx, sy, sw, sh}, (Vector2){dx, dy}, WHITE);
  }
}

void drawTexturePro(int id, float sx, float sy, float sw, float sh, float dx, float dy, float dw, float dh, float ox,
                    float oy, float rot) {
  int index = id - 1;
  if (index >= 0 && index < MAX_TEXTURES && textureActive[index]) {
    DrawTexturePro(textures[index], (Rectangle){sx, sy, sw, sh}, (Rectangle){dx, dy, dw, dh}, (Vector2){ox, oy}, rot,
                   WHITE);
  }
}

int getTextureWidth(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_TEXTURES && textureActive[index]) {
    return textures[index].width;
  }
  return 0;
}

int getTextureHeight(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_TEXTURES && textureActive[index]) {
    return textures[index].height;
  }
  return 0;
}

/* Sound Effects */
int loadSound(const char *path) {
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

void unloadSound(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_SOUNDS && soundActive[index]) {
    UnloadSound(sounds[index]);
    soundActive[index] = false;
  }
}

void playSound(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_SOUNDS && soundActive[index]) {
    PlaySound(sounds[index]);
  }
}

void stopSound(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_SOUNDS && soundActive[index]) {
    StopSound(sounds[index]);
  }
}

void setSoundVolume(int id, float volume) {
  int index = id - 1;
  if (index >= 0 && index < MAX_SOUNDS && soundActive[index]) {
    SetSoundVolume(sounds[index], volume);
  }
}

void setSoundPitch(int id, float pitch) {
  int index = id - 1;
  if (index >= 0 && index < MAX_SOUNDS && soundActive[index]) {
    SetSoundPitch(sounds[index], pitch);
  }
}

bool isSoundPlaying(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_SOUNDS && soundActive[index]) {
    return IsSoundPlaying(sounds[index]);
  }
  return false;
}

void setMasterVolume(float volume) { SetMasterVolume(volume); }

/* Music Streams */
int loadMusic(const char *path) {
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

void unloadMusic(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    UnloadMusicStream(musics[index]);
    musicActive[index] = false;
  }
}

void playMusic(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    PlayMusicStream(musics[index]);
  }
}

void pauseMusic(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    PauseMusicStream(musics[index]);
  }
}

void resumeMusic(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    ResumeMusicStream(musics[index]);
  }
}

void stopMusic(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    StopMusicStream(musics[index]);
  }
}

void updateMusic(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    UpdateMusicStream(musics[index]);
  }
}

void setMusicVolume(int id, float volume) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    SetMusicVolume(musics[index], volume);
  }
}

bool isMusicStreamPlaying(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_MUSIC && musicActive[index]) {
    return IsMusicStreamPlaying(musics[index]);
  }
  return false;
}

int loadShader(const char *vsPath, const char *fsPath) {
  if (!IsWindowReady()) return 0;
  const char *vs = (vsPath != NULL && vsPath[0] != '\0') ? vsPath : NULL;
  const char *fs = (fsPath != NULL && fsPath[0] != '\0') ? fsPath : NULL;
  if (vs == NULL && fs == NULL) return 0;
  for (int i = 0; i < MAX_SHADERS; i++) {
    if (!shaderActive[i]) {
      Shader shader = LoadShader(vs, fs);
      if (!IsShaderValid(shader)) return 0;
      shaders[i] = shader;
      shaderActive[i] = true;
      return i + 1;
    }
  }
  return 0;
}

void unloadShader(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_SHADERS && shaderActive[index]) {
    UnloadShader(shaders[index]);
    shaderActive[index] = false;
  }
}

void beginShaderMode(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_SHADERS && shaderActive[index]) {
    BeginShaderMode(shaders[index]);
  } else {
    TraceLog(LOG_WARNING, "PBGUI: beginShaderMode(%d) with invalid shader id.", id);
  }
}

void endShaderMode(void) { EndShaderMode(); }

void setShaderFloat(int id, const char *uniformName, float value) {
  int index = id - 1;
  if (index < 0 || index >= MAX_SHADERS || !shaderActive[index] || uniformName == NULL) return;
  int loc = GetShaderLocation(shaders[index], uniformName);
  if (loc == -1) {
    TraceLog(LOG_WARNING, "PBGUI: shader uniform '%s' not found.", uniformName);
    return;
  }
  SetShaderValue(shaders[index], loc, &value, SHADER_UNIFORM_FLOAT);
}

void setShaderVec2(int id, const char *uniformName, float x, float y) {
  int index = id - 1;
  if (index < 0 || index >= MAX_SHADERS || !shaderActive[index] || uniformName == NULL) return;
  int loc = GetShaderLocation(shaders[index], uniformName);
  if (loc == -1) {
    TraceLog(LOG_WARNING, "PBGUI: shader uniform '%s' not found.", uniformName);
    return;
  }
  float vec[2] = {x, y};
  SetShaderValue(shaders[index], loc, vec, SHADER_UNIFORM_VEC2);
}

int loadRenderTexture(int width, int height) {
  if (!IsWindowReady()) return 0;
  for (int i = 0; i < MAX_RENDER_TEXTURES; i++) {
    if (!renderTargetActive[i]) {
      RenderTexture2D target = LoadRenderTexture(width, height);
      if (!IsRenderTextureValid(target)) return 0;
      renderTargets[i] = target;
      renderTargetActive[i] = true;
      return i + 1;
    }
  }
  return 0;
}

void unloadRenderTexture(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_RENDER_TEXTURES && renderTargetActive[index]) {
    UnloadRenderTexture(renderTargets[index]);
    renderTargetActive[index] = false;
  }
}

void beginTextureMode(int id) {
  int index = id - 1;
  if (index >= 0 && index < MAX_RENDER_TEXTURES && renderTargetActive[index]) {
    inTextureMode = true;
    BeginTextureMode(renderTargets[index]);
  } else {
    TraceLog(LOG_WARNING, "PBGUI: beginTextureMode(%d) with invalid render texture id.", id);
  }
}

void endTextureMode(void) {
  EndTextureMode();
  inTextureMode = false;
}

void drawRenderTexture(int id, int x, int y) {
  int index = id - 1;
  if (index < 0 || index >= MAX_RENDER_TEXTURES || !renderTargetActive[index]) return;
  Texture2D texture = renderTargets[index].texture;
  DrawTextureRec(texture, (Rectangle){0, 0, (float)texture.width, -(float)texture.height},
                 (Vector2){(float)x, (float)y}, WHITE);
}

void drawRenderTextureRec(int id, float sx, float sy, float sw, float sh, float dx, float dy) {
  int index = id - 1;
  if (index < 0 || index >= MAX_RENDER_TEXTURES || !renderTargetActive[index]) return;
  float textureHeight = (float)renderTargets[index].texture.height;
  DrawTextureRec(renderTargets[index].texture, (Rectangle){sx, textureHeight - sy - sh, sw, -sh},
                 (Vector2){dx, dy}, WHITE);
}
