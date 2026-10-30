// TURBO CIRCUIT: OVERDRIVE — Complete Subsystem Test & Verification
use "pb_gui" as gui;
use "constants" as const;
use "math_util" as mu;
use "assets" as assets_mod;
use "camera" as cam_mod;
use "particles" as part_mod;
use "track" as track_mod;
use "car" as car_mod;
use "ui" as ui_mod;
use "records" as rec_mod;
use "std.math" as math;

gui.initWindow(const.SCREEN_WIDTH, const.SCREEN_HEIGHT, "TURBO // CIRCUIT : TEST");
gui.setTargetFPS(const.TARGET_FPS);

let assets = assets_mod.AssetManager("examples/games/turbo_circuit");
assets.loadAll();

let cam = cam_mod.ChaseCamera();
let particles = part_mod.ParticleSystem();
let ui = ui_mod.UIRenderer();
let recordManager = rec_mod.RecordManager("records.txt");

print("Record test: Track 0 record is: " + str(recordManager.getRecord(0)));
print("Record manager loaded without mutating the player's saved records.");

// Test all 4 tracks
for (let tId = 0; tId < const.TOTAL_TRACKS; tId += 1) {
  let track = track_mod.Track(tId);
  track.update(100.0, 0.016);
  let cOffset = track.getCurveOffset(-30.0, 150.0);
  let yOffset = track.getYOffset(-30.0, 150.0);
  let inTun = track.isInTunnel(500.0);
  print("Track " + str(tId) + " (" + const.getTrackSpec(tId)["name"] + ") initialized, curve=" + str(cOffset) + ", hill=" + str(yOffset));
}

// Test all 4 cars
for (let cId = 0; cId < 4; cId += 1) {
  let car = car_mod.Vehicle(cId, true, "TEST_CAR", 0.0);
  let trk = track_mod.Track(0);
  car.speed = 100.0;
  car.updatePlayer(0.016, trk, particles, assets);
  let curv = trk.getCurvature(0.0, 100.0);
  print("Car " + str(cId) + " (" + car.spec["name"] + ") updated cleanly, worldX=" + str(car.worldX));
}

// Test AI Rivals and Traffic
let rival = car_mod.Vehicle(1, false, "RIVAL", -30.0);
let trk = track_mod.Track(0);
rival.updateAi(0.0, 100.0, 0.016, trk);
print("AI Rival updated cleanly, worldX=" + str(rival.worldX));

let traffic = car_mod.TrafficCar(-50.0);
traffic.update(100.0, 0.016);
traffic.syncPosition(trk, 150.0);
print("TrafficCar updated cleanly, worldX=" + str(traffic.worldX));

// Test Camera lookahead
cam.setLookCurve(trk.getCurveOffset(-34.0, 150.0));
cam.updateFollow(0.0, 0.0, 0.0, 80.0, 0.0, 0.1, 0.0, false, 0.016);
print("ChaseCamera lookahead updated cleanly");

// Test UI screen rendering calls
gui.beginDrawing();
ui.updateDimensions();
ui.drawTitleScreen(0.5, 0);
let cSpec = const.getCarSpec(0);
ui.drawGarageScreen(0, cSpec, 0.5);
let tSpec = const.getTrackSpec(0);
ui.drawTrackSelectScreen(0, tSpec, recordManager, 0.5);

// Test Grand Prix HUD
ui.setMode(const.MODE_GRAND_PRIX);
ui.setTrackId(const.TRACK_SUZUKA);
ui.setBanner("OBJECTIVE: PODIUM FINISH", "TOP 3", 3.0, 255, 220, 40);
ui.updateBanners(0.016);
ui.drawHUD(car_mod.Vehicle(0, true, "P", 0.0), 1, 3, 12.4, 88.5, 1, 5, true, 0.5, 200.0, 5807.0, [rival]);

// Test Outrun HUD & Timeout
ui.setMode(const.MODE_OUTRUN);
ui.setTrackId(const.TRACK_MONACO);
ui.setOutrunState(38.5, 2, 600.0, 450.0, 3);
ui.drawHUD(car_mod.Vehicle(0, true, "P", 0.0), 1, 3, 12.4, 54.2, 1, 5, false, 0.5, 450.0, 3337.0, nil);
ui.drawTimeoutScreen(0.5);

// Test Time Attack HUD
ui.setMode(const.MODE_TIME_ATTACK);
ui.setTrackId(const.TRACK_SPA);
ui.setTimeAttackDelta(-0.45);
ui.drawHUD(car_mod.Vehicle(0, true, "P", 0.0), 2, 3, 21.0, 102.5, 1, 1, false, 0.5, 800.0, 7004.0, nil);

ui.drawPauseMenu(0);
ui.drawResultsScreen(1, 5, 41.2, 42.5, true, 0.5);
ui.drawCrashedScreen(0.5);

// Test 3D rendering pass with rivals and track
cam.begin3DPass();
gui.drawPlane3D(0.0, -0.2, 0.0, 4500.0, 4500.0, 10, 12, 18);
let trkTest = track_mod.Track(0);
trkTest.draw(0.0, 100.0, 0.5, assets, cam);
let rCarTest = car_mod.Vehicle(1, false, "RIVAL", -10.0);
let dDistTest = math.abs(rCarTest.trackDistance - 100.0);
let lapDistTest = trkTest.spec["length"];
while (dDistTest > lapDistTest * 0.5) dDistTest = dDistTest - lapDistTest;
if (math.abs(dDistTest) < 280.0) {
  rCarTest.draw(assets, 0.5);
}
cam.end3DPass();

gui.endDrawing();
print("All UI state renderers executed without error!");

assets.unloadAll();
gui.closeWindow();
print("Full game subsystem verification PASSED!");
