use "pb_gui" as gui;
use "std.math";

// Run from the repo root: pb run examples/games/shaders
// SPACE = white hit-flash (forces the flash shader active).
// ENTER = toggle between the grayscale and flash shaders.
// D     = toggle Pogberry debug mode (Raylib trace logs on stderr).
let SHADER_DIR = "examples/games/shaders/assets/shaders/";

gui.initWindow(800, 450, "Pogberry Shaders");
gui.setTargetFPS(60);

let gray = gui.loadShader(nil, SHADER_DIR + "grayscale.fs");
let flash = gui.loadShader(nil, SHADER_DIR + "flash.fs");

let useGray = true;
let flashAmount = 0.0;
let debugOn = false;

while (!gui.windowShouldClose())
{
  if (gui.isKeyPressed("KEY_SPACE"))
  {
    // The flash only shows through the flash shader, so switch to it.
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
  if (gui.isKeyPressed("KEY_D"))
  {
    debugOn = !debugOn;
    gui.setDebugMode(debugOn);
  }

  let time = gui.getTime();
  gui.setShaderFloat(gray, "u_intensity", (math.sin(time * 2.0) + 1.0) / 2.0);
  gui.setShaderFloat(flash, "u_flash", flashAmount);

  let active = gray;
  let activeName = "grayscale (pulsing)";
  if (!useGray)
  {
    active = flash;
    activeName = "flash (SPACE to pop)";
  }

  gui.beginDrawing();
  gui.clearBackground(20, 20, 30);
  gui.beginShaderMode(active);
  gui.drawRectangle(100, 120, 220, 160, 90, 200, 120);
  gui.drawCircle(520, 200, 80, 220, 90, 90);
  gui.drawRectangle(360, 300, 160, 60, 90, 140, 230);
  gui.endShaderMode();
  // HUD is drawn unshaded so key handling stays verifiable even if a
  // shader fails visually.
  gui.drawText("shader: " + activeName, 20, 20, 20, 255, 255, 255);
  gui.drawText("flash: " + str(flashAmount), 20, 46, 20, 255, 255, 255);
  if (debugOn)
    gui.drawText("debug: ON", 20, 72, 20, 120, 255, 120);
  else
    gui.drawText("debug: OFF (D to enable)", 20, 72, 20, 160, 160, 160);
  gui.drawText("SPACE flash | ENTER swap | D debug", 20, 410, 20, 255, 255, 255);
  gui.endDrawing();
}

gui.unloadShader(gray);
gui.unloadShader(flash);
gui.closeWindow();
