use "pb_gui" as gui;
use "std.camera";

let VIEW_W = 800;
let VIEW_H = 450;
let LEVEL_W = 2000;
let LEVEL_H = 1200;

gui.initWindow(800, 600, "Camera Demo - Arrows/WASD move, SPACE shake, Z/X zoom");
gui.setVirtualResolution(VIEW_W, VIEW_H);
gui.setTargetFPS(60);

let cam = camera.Camera(VIEW_W, VIEW_H);
let px = 400;
let py = 300;
let speed = 320;

let coins = [];
seed(99);
for (let i = 0; i < 120; i = i + 1)
{
  coins.push([rand(LEVEL_W), rand(LEVEL_H)]);
}

cam.snapTo(px, py);

while (!gui.windowShouldClose())
{
  let dt = gui.getFrameTime();
  if (dt > 0.05) dt = 0.05;

  if (gui.isKeyDown("KEY_LEFT") or gui.isKeyDown("KEY_A")) px = px - speed * dt;
  if (gui.isKeyDown("KEY_RIGHT") or gui.isKeyDown("KEY_D")) px = px + speed * dt;
  if (gui.isKeyDown("KEY_UP") or gui.isKeyDown("KEY_W")) py = py - speed * dt;
  if (gui.isKeyDown("KEY_DOWN") or gui.isKeyDown("KEY_S")) py = py + speed * dt;
  if (px < 0) px = 0;
  if (py < 0) py = 0;
  if (px > LEVEL_W) px = LEVEL_W;
  if (py > LEVEL_H) py = LEVEL_H;

  if (gui.isKeyPressed("KEY_SPACE")) cam.addShake(0.6);
  if (gui.isKeyPressed("KEY_Z")) cam.setZoom(cam.zoom + 0.25);
  if (gui.isKeyPressed("KEY_X")) cam.setZoom(cam.zoom - 0.25);

  cam.follow(px, py, 4.0, dt);
  cam.clampTo(0, 0, LEVEL_W - VIEW_W / cam.zoom, LEVEL_H - VIEW_H / cam.zoom);
  cam.update(dt);

  let mx = cam.worldX(gui.getMouseX());
  let my = cam.worldY(gui.getMouseY());

  gui.beginDrawing();
  gui.clearBackground(12, 14, 24);

  for (let gy = 0; gy <= LEVEL_H; gy = gy + 200)
  {
    if (cam.isVisible(0, gy, LEVEL_W, 2, 50))
      gui.drawRectangle(cam.applyX(0), cam.applyY(gy), LEVEL_W * cam.zoom, 2, 30, 40, 60);
  }
  for (let gx = 0; gx <= LEVEL_W; gx = gx + 200)
  {
    if (cam.isVisible(gx, 0, 2, LEVEL_H, 50))
      gui.drawRectangle(cam.applyX(gx), cam.applyY(0), 2, LEVEL_H * cam.zoom, 30, 40, 60);
  }

  for (let i = 0; i < len(coins); i = i + 1)
  {
    let c = coins[i];
    if (cam.isVisible(c[0] - 6, c[1] - 6, 12, 12, 10))
      gui.drawCircle(cam.applyX(c[0]), cam.applyY(c[1]), 6 * cam.zoom, 255, 210, 0);
  }

  gui.drawCircle(cam.applyX(mx), cam.applyY(my), 5, 0, 235, 255);
  gui.drawRectangle(cam.applyX(px) - 12 * cam.zoom, cam.applyY(py) - 12 * cam.zoom, 24 * cam.zoom, 24 * cam.zoom, 0, 235, 255);

  gui.drawText("WASD/arrows move  SPACE shake  Z/X zoom", 12, 12, 16, 200, 210, 230);
  gui.drawText("world: " + str(px) + ", " + str(py), 12, 34, 16, 0, 235, 255);
  gui.drawText("cam: " + str(cam.x) + ", " + str(cam.y) + " z" + str(cam.zoom), 12, 56, 16, 180, 190, 210);
  gui.endDrawing();
}

gui.closeWindow();
