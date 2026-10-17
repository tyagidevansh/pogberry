// TURBO//CIRCUIT — native 3D arcade racer for Pogberry.
use "pb_gui" as gui;
use "std.math" as math;

let W = 1280;
let H = 720;
let TITLE = 0;
let RACE = 1;
let CRASHED = 2;

fun clamp(v, lo, hi)
{
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

fun makeTraffic(z)
{
  return {"x": rand(4) - 2.0, "z": z, "color": rand(3), "passed": false};
}

fun carColor(kind)
{
  if (kind == 0) return [255, 62, 112];
  if (kind == 1) return [65, 230, 255];
  return [255, 192, 56];
}

fun drawCar(x, z, kind, steer, player)
{
  let c = carColor(kind);
  let y = 0.55;
  // Chassis, glass canopy, front splitter and four wheel volumes.
  gui.drawCube3D(x, y, z, 1.75, 0.42, 3.35, c[0], c[1], c[2]);
  gui.drawCube3D(x + steer * 0.12, y + 0.35, z + 0.15, 1.22, 0.45, 1.45, 25, 36, 62);
  gui.drawCube3D(x, y + 0.08, z - 1.82, 1.88, 0.12, 0.38, 235, 245, 255);
  gui.drawCube3D(x - 0.94, 0.36, z - 1.05, 0.30, 0.48, 0.70, 8, 10, 18);
  gui.drawCube3D(x + 0.94, 0.36, z - 1.05, 0.30, 0.48, 0.70, 8, 10, 18);
  gui.drawCube3D(x - 0.94, 0.36, z + 1.05, 0.30, 0.48, 0.70, 8, 10, 18);
  gui.drawCube3D(x + 0.94, 0.36, z + 1.05, 0.30, 0.48, 0.70, 8, 10, 18);
  if (player)
  {
    gui.drawSphere3D(x - 0.48, y + 0.08, z - 1.72, 0.12, 130, 240, 255);
    gui.drawSphere3D(x + 0.48, y + 0.08, z - 1.72, 0.12, 130, 240, 255);
  }
}

fun drawRoad(scroll, t)
{
  // Repeating road, rails, lane markers and a moving neon horizon.
  for (let i = 0; i < 18; i += 1)
  {
    let z = 14 - i * 18 + scroll;
    gui.drawPlane3D(0, 0, z, 9.5, 17.9, 19, 22, 38);
    gui.drawCube3D(-5.0, 0.30, z, 0.16, 0.60, 17.8, 255, 52, 150);
    gui.drawCube3D(5.0, 0.30, z, 0.16, 0.60, 17.8, 52, 220, 255);
    for (let lane = -1; lane <= 1; lane += 1)
      gui.drawCube3D(lane * 2.35, 0.025, z - 5.0, 0.08, 0.04, 4.2, 200, 226, 255);
  }
  for (let i = 0; i < 20; i += 1)
  {
    let z = -30 - i * 20 + scroll;
    let h = 5 + ((i * 17) % 8);
    let pulse = 90 + math.sin(t * 2 + i) * 40;
    gui.drawCube3D(-10.5, h / 2, z, 4.0, h, 5.0, 18, 20, 42);
    gui.drawCube3D(10.5, h / 2, z - 8, 4.0, h, 5.0, 18, 20, 42);
    gui.drawCube3D(-8.45, h * 0.7, z, 0.08, h * 0.22, 4.4, 70, pulse, 255);
    gui.drawCube3D(8.45, h * 0.7, z - 8, 0.08, h * 0.22, 4.4, 255, 70, 195);
  }
}

fun drawGate(z, phase)
{
  let glow = 180 + math.sin(phase) * 60;
  gui.drawCube3D(-4.0, 3.1, z, 0.28, 6.2, 0.28, 255, glow, 78);
  gui.drawCube3D(4.0, 3.1, z, 0.28, 6.2, 0.28, 255, glow, 78);
  gui.drawCube3D(0, 6.1, z, 8.2, 0.28, 0.28, 255, glow, 78);
  gui.drawSphere3D(0, 4.3, z, 0.42, 255, 240, 160);
}

let shaderPath = "examples/games/turbo_circuit/assets/velocity.fs";
gui.initWindow(W, H, "TURBO//CIRCUIT");
gui.setTargetFPS(60);
gui.setExitKey(0);
let post = gui.loadShader(nil, shaderPath);
let frame = gui.loadRenderTexture(W, H);

let state = TITLE;
let playerX = 0.0;
let playerVX = 0.0;
let speed = 58.0;
let nitro = 100.0;
let health = 100.0;
let distance = 0.0;
let roadScroll = 0.0;
let traffic = [];
let pickupZ = -85.0;
let pickupX = 0.0;
let gateZ = -180.0;
let hitFlash = 0.0;
let best = 0;
for (let i = 0; i < 9; i += 1) traffic.push(makeTraffic(-35 - i * 30));

while (!gui.windowShouldClose())
{
  let dt = gui.getFrameTime();
  if (dt > 0.04) dt = 0.04;
  let t = gui.getTime();
  if (gui.isKeyPressed("KEY_F11")) gui.toggleFullscreen();
  if (state == TITLE and (gui.isKeyPressed("KEY_ENTER") or gui.isKeyPressed("KEY_SPACE")))
  {
    state = RACE;
    playerX = 0; playerVX = 0; speed = 58; nitro = 100; health = 100; distance = 0; roadScroll = 0;
    traffic = [];
    for (let i = 0; i < 9; i += 1) traffic.push(makeTraffic(-35 - i * 30));
    pickupZ = -85; pickupX = rand(4) - 2; gateZ = -180;
  }
  else if (state == CRASHED and (gui.isKeyPressed("KEY_ENTER") or gui.isKeyPressed("KEY_SPACE"))) state = TITLE;

  if (state == RACE)
  {
    let input = 0;
    if (gui.isKeyDown("KEY_A") or gui.isKeyDown("KEY_LEFT")) input -= 1;
    if (gui.isKeyDown("KEY_D") or gui.isKeyDown("KEY_RIGHT")) input += 1;
    playerVX += input * 22 * dt;
    playerVX *= 1 - 5 * dt;
    playerX += playerVX * dt;
    playerX = clamp(playerX, -3.75, 3.75);
    let boosting = (gui.isKeyDown("KEY_SPACE") or gui.isKeyDown("KEY_LEFT_SHIFT")) and nitro > 0;
    if (boosting) { speed += (108 - speed) * 4 * dt; nitro -= 28 * dt; }
    else { speed += (58 - speed) * 2.5 * dt; nitro += 8 * dt; }
    nitro = clamp(nitro, 0, 100);
    distance += speed * dt;
    roadScroll += speed * dt;
    while (roadScroll > 18) roadScroll -= 18;
    for (let i = 0; i < len(traffic); i += 1)
    {
      let car = traffic[i];
      car["z"] += speed * dt;
      if (car["z"] > 18) traffic[i] = makeTraffic(-240 - rand(130));
      else if (car["z"] > -2.2 and car["z"] < 2.5 and math.abs(playerX - car["x"]) < 1.55)
      {
        health -= 44 * dt;
        hitFlash = 0.5;
        playerVX += (playerX - car["x"]) * 25 * dt;
      }
    }
    pickupZ += speed * dt;
    if (pickupZ > 8) { pickupZ = -190 - rand(120); pickupX = rand(4) - 2; }
    if (pickupZ > -2 and pickupZ < 2 and math.abs(playerX - pickupX) < 1.1)
    { nitro = clamp(nitro + 40, 0, 100); pickupZ = -260; }
    gateZ += speed * dt;
    if (gateZ > 12) { gateZ = -300; health = clamp(health + 16, 0, 100); nitro = clamp(nitro + 20, 0, 100); }
    if (health <= 0) { state = CRASHED; if (distance > best) best = distance; }
  }
  hitFlash -= dt;
  if (hitFlash < 0) hitFlash = 0;

  gui.beginTextureMode(frame);
  gui.clearBackground(4, 5, 18);
  gui.begin3D(playerX * 0.38, 5.7, 10.8, playerX * 0.16, 0.65, -29, 64);
  gui.drawPlane3D(0, -0.16, -160, 120, 420, 4, 5, 18);
  drawRoad(roadScroll, t);
  drawGate(gateZ, t * 4);
  // Collectible energy core.
  gui.drawSphere3D(pickupX, 1.1, pickupZ, 0.45 + math.sin(t * 8) * 0.08, 75, 255, 218);
  gui.drawSphere3D(pickupX, 1.1, pickupZ, 0.22, 235, 255, 255);
  for (let i = 0; i < len(traffic); i += 1) drawCar(traffic[i]["x"], traffic[i]["z"], traffic[i]["color"], 0, false);
  drawCar(playerX, 1.4, 1, playerVX * 0.08, true);
  gui.end3D();
  gui.endTextureMode();

  gui.beginDrawing();
  gui.setShaderFloat(post, "u_time", t);
  gui.setShaderFloat(post, "u_speed", speed / 108);
  gui.setShaderFloat(post, "u_hit", hitFlash * 2);
  gui.beginShaderMode(post);
  gui.drawRenderTexture(frame, 0, 0);
  gui.endShaderMode();
  if (state == TITLE)
  {
    gui.drawRectangleAlpha(0, 0, W, H, 3, 4, 16, 145);
    gui.drawText("TURBO//CIRCUIT", 80, 82, 70, 240, 247, 255);
    gui.drawText("NEON HIGHWAY // NO BRAKES // ONE MORE RUN", 86, 162, 22, 83, 231, 255);
    gui.drawText("A / D   STEER", 88, 332, 24, 220, 232, 255);
    gui.drawText("SPACE   NITRO", 88, 372, 24, 220, 232, 255);
    gui.drawText("DODGE TRAFFIC. THREAD THE GATES. STEAL THE ENERGY.", 88, 466, 21, 255, 112, 192);
    gui.drawText("PRESS ENTER TO IGNITE", 88, 542, 29, 255, 232, 92);
  }
  else
  {
    gui.drawText("DISTANCE  " + str(math.floor(distance)) + "m", 34, 28, 25, 235, 244, 255);
    gui.drawText("NITRO", 34, 62, 14, 100, 230, 255);
    gui.drawRectangleAlpha(34, 82, 210, 13, 8, 12, 28, 220);
    gui.drawRectangle(34, 82, nitro * 2.1, 13, 65, 225, 255);
    gui.drawText("HULL", 34, 112, 14, 255, 126, 179);
    gui.drawRectangleAlpha(34, 132, 210, 13, 8, 12, 28, 220);
    gui.drawRectangle(34, 132, health * 2.1, 13, 255, 82, 150);
    gui.drawText("x" + str(math.floor(speed / 58 * 10) / 10), 1145, 32, 29, 255, 215, 94);
    if (state == CRASHED)
    {
      gui.drawRectangleAlpha(0, 0, W, H, 22, 0, 18, 165);
      gui.drawText("WRECKED", 474, 258, 66, 255, 72, 148);
      gui.drawText("BEST RUN  " + str(math.floor(best)) + "m", 500, 342, 24, 235, 244, 255);
      gui.drawText("ENTER  //  REBOOT", 498, 390, 22, 255, 220, 98);
    }
  }
  gui.endDrawing();
}

gui.unloadRenderTexture(frame);
gui.unloadShader(post);
gui.closeWindow();
