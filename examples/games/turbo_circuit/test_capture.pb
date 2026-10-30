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

fun drawSkyBackdrop(tSpec) {
  let scrW = gui.getScreenWidth();
  let scrH = gui.getScreenHeight();
  let sky = tSpec["skyColor"];
  gui.clearBackground(sky[0], sky[1], sky[2]);
  let skyTop = tSpec["skyTop"];
  if (skyTop == nil) skyTop = [6, 12, 32];
  let skyBottom = tSpec["skyBottom"];
  if (skyBottom == nil) skyBottom = [32, 50, 92];
  let skyBands = 24;
  let bandH = scrH / skyBands;
  for (let b = 0; b < skyBands; b += 1) {
    let factor = b / (skyBands - 1.0);
    let r = math.floor(skyTop[0] + (skyBottom[0] - skyTop[0]) * factor);
    let g = math.floor(skyTop[1] + (skyBottom[1] - skyTop[1]) * factor);
    let bCol = math.floor(skyTop[2] + (skyBottom[2] - skyTop[2]) * factor);
    gui.drawRectangle(0, math.floor(b * bandH), scrW, math.ceil(bandH + 1.0), r, g, bCol);
  }
}

// 1. Capture Title
for (let i = 0; i < 15; i += 1) {
  let t = i * 0.016;
  cam.updateCinematicTrack(track, t);
  track.update(24.0, 0.016);

  let tSpec = const.getTrackSpec(0);
  let ground = tSpec["groundColor"];
  gui.beginDrawing();
  drawSkyBackdrop(tSpec);
  cam.begin3DPass();
  let st0 = track.stations[0];
  gui.drawPlane3D(st0["x"], -0.2, st0["z"], 4500.0, 4500.0, ground[0], ground[1], ground[2]);
  track.draw(0.0, 0.0, t, assets, cam);
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
  cam.updateCinematicTrack(track, t);
  let tSpec = const.getTrackSpec(0);
  let ground = tSpec["groundColor"];
  gui.beginDrawing();
  drawSkyBackdrop(tSpec);
  cam.begin3DPass();
  let st0 = track.stations[0];
  gui.drawPlane3D(st0["x"], -0.2, st0["z"], 4500.0, 4500.0, ground[0], ground[1], ground[2]);
  track.draw(0.0, 0.0, t, assets, cam);
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

// 3. Capture Track 0: Suzuka GP (Casio Triangle Chicane Braking Zone)
let track0 = track_mod.Track(const.TRACK_SUZUKA);
ui.setTrackId(const.TRACK_SUZUKA);
player.setTrackPosition(track0, 5130.0, 0.0);
cam.snap(player.worldX, player.worldY, player.worldZ, player.worldHeading);
for (let i = 0; i < 20; i += 1) {
  let dt = 0.016;
  let t = 1.0 + i * dt;
  let dist = 5130.0;
  player.setTrackPosition(track0, dist, 0.0);
  player.speed = 88.0;
  player.brakeWarning = 2; // Right turn brake warning

  cam.updateFollow(player.worldX, player.worldY, player.worldZ, player.speed, player.worldHeading, 0.05, 0.0, true, dt);

  let tSpec = const.getTrackSpec(0);
  let ground = tSpec["groundColor"];
  gui.beginDrawing();
  drawSkyBackdrop(tSpec);

  cam.begin3DPass();
  gui.drawPlane3D(player.worldX, -0.2, player.worldZ, 4500.0, 4500.0, ground[0], ground[1], ground[2]);
  track0.draw(0.0, dist, t, assets, cam);
  for (let r = 0; r < len(rivals); r += 1) {
    rivals[r].setTrackPosition(track0, dist - 12.0 - r * 14.0, rivals[r].x);
    rivals[r].draw(assets, t);
  }
  player.draw(assets, t);
  particles.emitNitroFlames(player.worldX, player.worldY, player.worldZ, player.speed, 1.4);
  particles.update(0.016);
  particles.draw();
  cam.end3DPass();

  ui.updateDimensions();
  ui.setMode(const.MODE_GRAND_PRIX);
  ui.drawHUD(player, 1, 3, 14.5, 0.0, 2, 5, true, t, dist, 5807.0, rivals);
  gui.endDrawing();
}
gui.takeScreenshot("track_shibuya.png");
gui.takeScreenshot("test_assets/track_shibuya.png");
print("Captured track_shibuya.png (Suzuka GP)");

// 4. Capture Track 1: Monaco GP (Sainte Dévote Braking Zone)
let track1 = track_mod.Track(const.TRACK_MONACO);
ui.setTrackId(const.TRACK_MONACO);
player.setTrackPosition(track1, 330.0, 0.0);
cam.snap(player.worldX, player.worldY, player.worldZ, player.worldHeading);
for (let i = 0; i < 20; i += 1) {
  let dt = 0.016;
  let t = 2.0 + i * dt;
  let dist = 330.0;
  player.setTrackPosition(track1, dist, 0.0);
  player.speed = 82.0;
  player.brakeWarning = 1; // Left turn brake warning

  cam.updateFollow(player.worldX, player.worldY, player.worldZ, player.speed, player.worldHeading, 0.0, 0.0, false, dt);

  let tSpec = const.getTrackSpec(1);
  let ground = tSpec["groundColor"];
  gui.beginDrawing();
  drawSkyBackdrop(tSpec);

  cam.begin3DPass();
  gui.drawPlane3D(player.worldX, -0.2, player.worldZ, 4500.0, 4500.0, ground[0], ground[1], ground[2]);
  track1.draw(0.0, dist, t, assets, cam);
  player.draw(assets, t);
  particles.emitNitroFlames(player.worldX, player.worldY, player.worldZ, player.speed, 1.4);
  particles.update(0.016);
  particles.draw();
  cam.end3DPass();

  ui.updateDimensions();
  ui.setMode(const.MODE_OUTRUN);
  ui.setOutrunState(44.0, 1, 600.0, dist, 0);
  ui.drawHUD(player, 1, 999, 22.0, 0.0, 1, 1, false, t, dist, 3337.0, nil);
  gui.endDrawing();
}
gui.takeScreenshot("track_sunset.png");
gui.takeScreenshot("test_assets/track_sunset.png");
print("Captured track_sunset.png (Monaco GP)");

// 5. Capture Track 2: Spa-Francorchamps (La Source Hairpin Braking Zone)
let track2 = track_mod.Track(const.TRACK_SPA);
ui.setTrackId(const.TRACK_SPA);
player.setTrackPosition(track2, 190.0, 0.0);
cam.snap(player.worldX, player.worldY, player.worldZ, player.worldHeading);
for (let i = 0; i < 20; i += 1) {
  let dt = 0.016;
  let t = 3.0 + i * dt;
  let dist = 190.0;
  player.setTrackPosition(track2, dist, 0.0);
  player.speed = 78.0;
  player.brakeWarning = 2;

  cam.updateFollow(player.worldX, player.worldY, player.worldZ, player.speed, player.worldHeading, -0.1, 0.0, false, dt);

  let tSpec = const.getTrackSpec(2);
  let ground = tSpec["groundColor"];
  gui.beginDrawing();
  drawSkyBackdrop(tSpec);

  cam.begin3DPass();
  gui.drawPlane3D(player.worldX, -0.2, player.worldZ, 4500.0, 4500.0, ground[0], ground[1], ground[2]);
  track2.draw(0.0, dist, t, assets, cam);
  player.draw(assets, t);
  particles.emitNitroFlames(player.worldX, player.worldY, player.worldZ, player.speed, 1.4);
  particles.update(0.016);
  particles.draw();
  cam.end3DPass();

  ui.updateDimensions();
  ui.setMode(const.MODE_TIME_ATTACK);
  ui.setTimeAttackDelta(-0.62);
  ui.drawHUD(player, 2, 3, 38.0, 102.5, 1, 1, false, t, dist, 7004.0, nil);
  gui.endDrawing();
}
gui.takeScreenshot("track_canyon.png");
gui.takeScreenshot("test_assets/track_canyon.png");
print("Captured track_canyon.png (Spa GP)");

// 6. Capture Track 3: Monza GP (Variante del Rettifilo Chicane Braking Zone)
let track3 = track_mod.Track(const.TRACK_MONZA);
ui.setTrackId(const.TRACK_MONZA);
player.setTrackPosition(track3, 850.0, 0.0);
cam.snap(player.worldX, player.worldY, player.worldZ, player.worldHeading);
for (let i = 0; i < 20; i += 1) {
  let dt = 0.016;
  let t = 4.0 + i * dt;
  let dist = 850.0;
  player.setTrackPosition(track3, dist, 0.0);
  player.speed = 85.0;
  player.brakeWarning = 1;

  cam.updateFollow(player.worldX, player.worldY, player.worldZ, player.speed, player.worldHeading, 0.0, 0.0, true, dt);

  let tSpec = const.getTrackSpec(3);
  let ground = tSpec["groundColor"];
  gui.beginDrawing();
  drawSkyBackdrop(tSpec);

  cam.begin3DPass();
  gui.drawPlane3D(player.worldX, -0.2, player.worldZ, 4500.0, 4500.0, ground[0], ground[1], ground[2]);
  track3.draw(0.0, dist, t, assets, cam);
  player.draw(assets, t);
  particles.emitNitroFlames(player.worldX, player.worldY, player.worldZ, player.speed, 1.4);
  particles.update(0.016);
  particles.draw();
  cam.end3DPass();

  ui.updateDimensions();
  ui.setMode(const.MODE_GRAND_PRIX);
  ui.setBanner("AUTODROMO NAZIONALE MONZA", "CIRCUIT 4 OF 4 // TEMPLE OF SPEED", 3.0, 0, 255, 170);
  ui.drawHUD(player, 1, 3, 18.0, 0.0, 1, 5, true, t, dist, 5793.0, nil);
  gui.endDrawing();
}
gui.takeScreenshot("track_hyperion.png");
gui.takeScreenshot("test_assets/track_hyperion.png");
print("Captured track_hyperion.png (Monza GP)");

assets.unloadAll();
gui.closeWindow();
print("Visual capture complete!");
