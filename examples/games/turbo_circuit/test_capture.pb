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
  let ground = tSpec["groundColor"];
  gui.beginDrawing();
  gui.clearBackground(sky[0], sky[1], sky[2]);
  cam.begin3DPass();
  gui.drawPlane3D(0.0, -0.2, -140.0, 260.0, 480.0, ground[0], ground[1], ground[2]);
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
  let ground = tSpec["groundColor"];
  gui.beginDrawing();
  gui.clearBackground(sky[0], sky[1], sky[2]);
  cam.begin3DPass();
  gui.drawPlane3D(0.0, -0.2, -140.0, 260.0, 480.0, ground[0], ground[1], ground[2]);
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

// 3. Capture Track 0: Neo Shibuya
let track0 = track_mod.Track(const.TRACK_SHIBUYA);
ui.setTrackId(const.TRACK_SHIBUYA);
for (let i = 0; i < 20; i += 1) {
  let dt = 0.016;
  let t = 1.0 + i * dt;
  let dist = 140.0;
  player.trackDistance = dist;
  player.worldX = player.x;

  cam.setLookAhead(track0.getCurveOffset(-34.0, dist), track0.getYOffset(-34.0, dist));
  cam.updateFollow(player.worldX, player.y, player.z, player.speed, 0.1, 0.0, true, dt);

  let tSpec = const.getTrackSpec(0);
  let sky = tSpec["skyColor"];
  let ground = tSpec["groundColor"];
  gui.beginDrawing();
  gui.clearBackground(sky[0], sky[1], sky[2]);

  cam.begin3DPass();
  gui.drawPlane3D(0.0, -0.2, -140.0, 260.0, 480.0, ground[0], ground[1], ground[2]);
  track0.draw(0.0, dist, t, assets);
  for (let r = 0; r < len(rivals); r += 1) {
    rivals[r].worldX = track0.getCurveOffset(rivals[r].z, dist) + rivals[r].x;
    rivals[r].draw(assets, t);
  }
  player.draw(assets, t);
  cam.end3DPass();

  ui.updateDimensions();
  ui.setMode(const.MODE_GRAND_PRIX);
  ui.setBanner("NEO SHIBUYA // DOWNTOWN FLYOVER", "CIRCUIT 1 OF 4", 3.0, 0, 240, 255);
  ui.drawHUD(player, 1, 3, 14.5, 0.0, 2, 5, true, t, dist, 1800.0, rivals);
  gui.endDrawing();
}
gui.takeScreenshot("track_shibuya.png");
gui.takeScreenshot("test_assets/track_shibuya.png");
print("Captured track_shibuya.png");

// 4. Capture Track 1: Sunset Horizon (Coastal Ocean Highway)
let track1 = track_mod.Track(const.TRACK_SUNSET);
ui.setTrackId(const.TRACK_SUNSET);
for (let i = 0; i < 20; i += 1) {
  let dt = 0.016;
  let t = 2.0 + i * dt;
  let dist = 180.0;
  player.trackDistance = dist;
  player.worldX = player.x;

  cam.setLookAhead(track1.getCurveOffset(-34.0, dist), track1.getYOffset(-34.0, dist));
  cam.updateFollow(player.worldX, player.y, player.z, player.speed, 0.0, 0.0, false, dt);

  let tSpec = const.getTrackSpec(1);
  let sky = tSpec["skyColor"];
  let ground = tSpec["groundColor"];
  gui.beginDrawing();
  gui.clearBackground(sky[0], sky[1], sky[2]);

  cam.begin3DPass();
  gui.drawPlane3D(0.0, -0.2, -140.0, 260.0, 480.0, ground[0], ground[1], ground[2]);
  track1.draw(0.0, dist, t, assets);
  player.draw(assets, t);
  cam.end3DPass();

  ui.updateDimensions();
  ui.setMode(const.MODE_OUTRUN);
  ui.setOutrunState(44.0, 1, 600.0, dist, 0);
  ui.setBanner("SUNSET HORIZON // PACIFIC COAST", "CIRCUIT 2 OF 4", 3.0, 255, 140, 40);
  ui.drawHUD(player, 1, 999, 22.0, 0.0, 1, 1, false, t, dist, 2200.0, nil);
  gui.endDrawing();
}
gui.takeScreenshot("track_sunset.png");
gui.takeScreenshot("test_assets/track_sunset.png");
print("Captured track_sunset.png");

// 5. Capture Track 2: Nebula Canyon (Titan Badlands)
let track2 = track_mod.Track(const.TRACK_CANYON);
ui.setTrackId(const.TRACK_CANYON);
for (let i = 0; i < 20; i += 1) {
  let dt = 0.016;
  let t = 3.0 + i * dt;
  let dist = 220.0;
  player.trackDistance = dist;
  player.worldX = player.x;

  cam.setLookAhead(track2.getCurveOffset(-34.0, dist), track2.getYOffset(-34.0, dist));
  cam.updateFollow(player.worldX, player.y, player.z, player.speed, -0.15, 0.0, false, dt);

  let tSpec = const.getTrackSpec(2);
  let sky = tSpec["skyColor"];
  let ground = tSpec["groundColor"];
  gui.beginDrawing();
  gui.clearBackground(sky[0], sky[1], sky[2]);

  cam.begin3DPass();
  gui.drawPlane3D(0.0, -0.2, -140.0, 260.0, 480.0, ground[0], ground[1], ground[2]);
  track2.draw(0.0, dist, t, assets);
  player.draw(assets, t);
  cam.end3DPass();

  ui.updateDimensions();
  ui.setMode(const.MODE_TIME_ATTACK);
  ui.setTimeAttackDelta(-0.62);
  ui.setBanner("NEBULA CANYON // TITAN RIFT", "CIRCUIT 3 OF 4", 3.0, 255, 200, 40);
  ui.drawHUD(player, 2, 4, 38.0, 63.4, 1, 1, false, t, dist, 2600.0, nil);
  gui.endDrawing();
}
gui.takeScreenshot("track_canyon.png");
gui.takeScreenshot("test_assets/track_canyon.png");
print("Captured track_canyon.png");

// 6. Capture Track 3: Hyperion Speedway (Orbital Superspeedway)
let track3 = track_mod.Track(const.TRACK_HYPERION);
ui.setTrackId(const.TRACK_HYPERION);
for (let i = 0; i < 20; i += 1) {
  let dt = 0.016;
  let t = 4.0 + i * dt;
  let dist = 360.0;
  player.trackDistance = dist;
  player.worldX = player.x;

  cam.setLookAhead(track3.getCurveOffset(-34.0, dist), track3.getYOffset(-34.0, dist));
  cam.updateFollow(player.worldX, player.y, player.z, player.speed, 0.0, 0.0, true, dt);

  let tSpec = const.getTrackSpec(3);
  let sky = tSpec["skyColor"];
  let ground = tSpec["groundColor"];
  gui.beginDrawing();
  gui.clearBackground(sky[0], sky[1], sky[2]);

  cam.begin3DPass();
  gui.drawPlane3D(0.0, -0.2, -140.0, 260.0, 480.0, ground[0], ground[1], ground[2]);
  track3.draw(0.0, dist, t, assets);
  player.draw(assets, t);
  cam.end3DPass();

  ui.updateDimensions();
  ui.setMode(const.MODE_GRAND_PRIX);
  ui.setBanner("HYPERION SPEEDWAY // ORBITAL RING", "CIRCUIT 4 OF 4", 3.0, 0, 255, 170);
  ui.drawHUD(player, 1, 4, 18.0, 0.0, 1, 5, true, t, dist, 2400.0, nil);
  gui.endDrawing();
}
gui.takeScreenshot("track_hyperion.png");
gui.takeScreenshot("test_assets/track_hyperion.png");
print("Captured track_hyperion.png");

assets.unloadAll();
gui.closeWindow();
print("Visual capture complete!");
