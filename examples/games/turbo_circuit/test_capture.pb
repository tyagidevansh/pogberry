// Automated visual capture script
use "pb_gui" as gui;
use "constants" as const;
use "math_util" as mu;
use "assets" as assets_mod;
use "camera" as cam_mod;
use "particles" as part_mod;
use "track" as track_mod;
use "car" as car_mod;
use "ui" as ui_mod;
use "std.math" as math;

gui.initWindow(const.SCREEN_WIDTH, const.SCREEN_HEIGHT, "TURBO // CIRCUIT : CAPTURE");
gui.setTargetFPS(const.TARGET_FPS);

let assets = assets_mod.AssetManager("examples/games/turbo_circuit");
assets.loadAll();

let cam = cam_mod.ChaseCamera();
let particles = part_mod.ParticleSystem();
let ui = ui_mod.UIRenderer();

let track = track_mod.Track(const.TRACK_SHIBUYA);
let player = car_mod.Vehicle(const.CAR_PHANTOM, true, "PLAYER", 0.0);
player.speed = 110.0;
player.isBoosting = true;

// 1. Capture Title
for (let i = 0; i < 15; i += 1) {
  let t = i * 0.016;
  cam.updateCinematic(t);
  track.update(24.0, 0.016);

  let tSpec = const.getTrackSpec(0);
  let sky = tSpec["skyColor"];
  gui.beginDrawing();
  gui.clearBackground(sky[0], sky[1], sky[2]);
  cam.begin3DPass();
  gui.drawPlane3D(0.0, -0.2, -140.0, 220.0, 460.0, sky[0], sky[1], sky[2]);
  track.draw(0.0, 0.0, t, assets);
  cam.end3DPass();

  ui.updateDimensions();
  ui.drawTitleScreen(t, 0);
  gui.endDrawing();
}
gui.takeScreenshot("title.png");
gui.takeScreenshot("test_assets/title.png");
print("Captured title.png");

// 2. Capture Garage
for (let i = 0; i < 20; i += 1) {
  let t = i * 0.016;
  cam.updateTurntable(0.0, 0.4, 0.0, 7.5, 3.2, 0.016);

  gui.beginDrawing();
  gui.clearBackground(4, 6, 18);
  cam.begin3DPass();
  gui.drawPlane3D(0.0, -0.2, 0.0, 100.0, 100.0, 12, 16, 28);
  assets.playCarModel(0, 0.0, 0.0, 0.0, t * 45.0, 1.45, 255, 255, 255);
  gui.drawGrid(12, 1.2);
  cam.end3DPass();

  ui.updateDimensions();
  let cSpec = const.getCarSpec(0);
  ui.drawGarageScreen(0, cSpec, t);
  gui.endDrawing();
}
gui.takeScreenshot("garage.png");
gui.takeScreenshot("test_assets/garage.png");
print("Captured garage.png");

// 2b. Capture Track Select
for (let i = 0; i < 15; i += 1) {
  let t = i * 0.016;
  cam.updateCinematic(t);
  let tSpec = const.getTrackSpec(0);
  let sky = tSpec["skyColor"];
  gui.beginDrawing();
  gui.clearBackground(sky[0], sky[1], sky[2]);
  cam.begin3DPass();
  gui.drawPlane3D(0.0, -0.2, -140.0, 220.0, 460.0, sky[0], sky[1], sky[2]);
  track.draw(0.0, 0.0, t, assets);
  cam.end3DPass();

  ui.updateDimensions();
  ui.drawTrackSelectScreen(0, tSpec, nil, t);
  gui.endDrawing();
}
gui.takeScreenshot("track_select.png");
gui.takeScreenshot("test_assets/track_select.png");
print("Captured track_select.png");

// 3. Capture Race with 3D Models, AI rivals, Minimap, and Nitro Flames
let rivals = [];
for (let i = 0; i < 4; i += 1) {
  let rCar = car_mod.Vehicle(i + 1, false, "RIVAL", -18.0 - i * 16.0);
  rCar.x = -2.2 + (i % 3) * 2.2;
  rivals.push(rCar);
}

for (let i = 0; i < 30; i += 1) {
  let dt = 0.016;
  let t = 1.0 + i * dt;
  particles.emitNitroFlames(player.x, 0.0, player.z, player.speed, 1.4);
  particles.update(dt);
  cam.updateFollow(player.x, player.y, player.z, player.speed, 0.2, 0.0, true, dt);
  track.update(player.speed, dt);

  let tSpec = const.getTrackSpec(0);
  let sky = tSpec["skyColor"];
  gui.beginDrawing();
  gui.clearBackground(sky[0], sky[1], sky[2]);

  cam.begin3DPass();
  gui.drawPlane3D(0.0, -0.2, -140.0, 220.0, 460.0, sky[0], sky[1], sky[2]);
  track.draw(0.0, 200.0, t, assets);
  for (let r = 0; r < len(rivals); r += 1) rivals[r].draw(assets, t);
  player.draw(assets, t);
  particles.draw();
  cam.end3DPass();

  ui.updateDimensions();
  ui.drawHUD(player, 1, 3, 14.5, 0.0, 2, 5, true, t, 200.0, 1800.0, rivals);
  gui.endDrawing();
}
gui.takeScreenshot("race.png");
gui.takeScreenshot("test_assets/race.png");
print("Captured race.png");

assets.unloadAll();
gui.closeWindow();
print("Visual capture complete!");
