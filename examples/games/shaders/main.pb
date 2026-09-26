use "pb_gui" as gui;
use "std.math";

let SHADER_DIR = "examples/games/shaders/assets/shaders/";

gui.initWindow(800, 450, "Pogberry Shaders");
gui.setTargetFPS(60);

let gray = gui.loadShader(nil, SHADER_DIR + "grayscale.fs");
let flash = gui.loadShader(nil, SHADER_DIR + "flash.fs");
let crt = gui.loadShader(nil, SHADER_DIR + "crt.fs");
let screen = gui.loadRenderTexture(800, 450);

let useGray = true;
let flashAmount = 0.0;
let debugOn = false;
let crtOn = false;

fun drawScene(active)
{
  gui.clearBackground(20, 20, 30);
  gui.beginShaderMode(active);
  gui.drawRectangle(100, 120, 220, 160, 90, 200, 120);
  gui.drawCircle(520, 200, 80, 220, 90, 90);
  gui.drawRectangle(360, 300, 160, 60, 90, 140, 230);
  gui.endShaderMode();
}

fun drawHud(modeLabel)
{
  gui.drawText("mode: " + modeLabel, 20, 20, 20, 255, 255, 255);
  gui.drawText("flash: " + str(flashAmount), 20, 46, 20, 255, 255, 255);
  if (debugOn)
    gui.drawText("debug: ON", 20, 72, 20, 120, 255, 120);
  else
    gui.drawText("debug: OFF (D to enable)", 20, 72, 20, 160, 160, 160);
  gui.drawText("SPACE flash | ENTER swap | C CRT | D debug", 20, 410, 20, 255, 255, 255);
}

while (!gui.windowShouldClose())
{
  if (gui.isKeyPressed("KEY_SPACE"))
  {
    useGray = false;
    flashAmount = 1.0;
  }
  if (flashAmount > 0.0)
  {
    flashAmount = flashAmount - gui.getFrameTime() * 2.0;
    if (flashAmount < 0.0) flashAmount = 0.0;
  }
  if (gui.isKeyPressed("KEY_ENTER"))
  {
    useGray = !useGray;
  }
  if (gui.isKeyPressed("KEY_C"))
  {
    crtOn = !crtOn;
  }
  if (gui.isKeyPressed("KEY_D"))
  {
    debugOn = !debugOn;
    gui.setDebugMode(debugOn);
  }

  let time = gui.getTime();
  gui.setShaderFloat(gray, "u_intensity", (math.sin(time * 2.0) + 1.0) / 2.0);
  gui.setShaderFloat(flash, "u_flash", flashAmount);
  gui.setShaderFloat(crt, "u_time", time);

  let active = gray;
  let activeName = "grayscale (pulsing)";
  if (!useGray)
  {
    active = flash;
    activeName = "flash (SPACE to pop)";
  }
  let modeLabel = activeName;
  if (crtOn)
  {
    modeLabel = activeName + " + CRT";
  }

  if (crtOn)
  {
    gui.beginTextureMode(screen);
    drawScene(active);
    gui.endTextureMode();
    gui.beginDrawing();
    gui.beginShaderMode(crt);
    gui.drawRenderTexture(screen, 0, 0);
    gui.endShaderMode();
    drawHud(modeLabel);
    gui.endDrawing();
  }
  else
  {
    gui.beginDrawing();
    drawScene(active);
    drawHud(modeLabel);
    gui.endDrawing();
  }
}

gui.unloadShader(gray);
gui.unloadShader(flash);
gui.unloadShader(crt);
gui.unloadRenderTexture(screen);
gui.closeWindow();
