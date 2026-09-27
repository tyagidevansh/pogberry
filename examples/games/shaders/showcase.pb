use "pb_gui" as gui;
use "std.math";

let SHADER_DIR = "examples/games/shaders/assets/shaders/";
let SPRITE = "examples/games/shaders/assets/sprite.png";

gui.initWindow(800, 450, "Pogberry Shader Showcase");
gui.setTargetFPS(60);

let tint = gui.loadShader(nil, SHADER_DIR + "tint.fs");
let dissolve = gui.loadShader(nil, SHADER_DIR + "dissolve.fs");
let sprite = gui.loadTexture(SPRITE);

while (!gui.windowShouldClose())
{
  let time = gui.getTime();
  let pulse = (math.sin(time * 2.0) + 1.0) / 2.0;

  gui.setShaderColor(tint, "u_tint", 255, 130 + 125 * pulse, 200, 255);
  gui.setShaderVec3(tint, "u_glow", pulse, 0.3 * pulse, 0.0);
  gui.setShaderVec4(tint, "u_rect", 0.25 + 0.2 * math.sin(time * 0.7), 0.2, 0.3, 0.6);
  gui.setShaderTexture(dissolve, "u_noise", sprite);
  gui.setShaderFloat(dissolve, "u_burn", pulse);

  gui.beginDrawing();
  gui.clearBackground(12, 12, 18);

  gui.beginShaderMode(tint);
  gui.drawTextureRec(sprite, 0, 0, 128, 128, 90, 120);
  gui.drawRectangle(90, 300, 180, 60, 90, 200, 120);
  gui.endShaderMode();

  gui.beginShaderMode(dissolve);
  gui.drawTextureRec(sprite, 0, 0, 128, 128, 540, 120);
  gui.endShaderMode();

  gui.drawText("tint: color + glow + rect", 80, 90, 20, 255, 255, 255);
  gui.drawText("dissolve: texture uniform", 500, 90, 20, 255, 255, 255);
  gui.drawText("vec3 vec4 color sampler showcase", 220, 400, 20, 255, 255, 255);
  gui.endDrawing();
}

gui.unloadShader(tint);
gui.unloadShader(dissolve);
gui.unloadTexture(sprite);
gui.closeWindow();
