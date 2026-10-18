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
let isNew = recordManager.submitLapTime(0, 41.20);
print("Submitted 41.20s: isNewRecord = " + str(isNew));
print("New Track 0 record is: " + str(recordManager.getRecord(0)));

// Test all 3 tracks
for (let tId = 0; tId < 3; tId += 1) {
  let track = track_mod.Track(tId);
  track.update(100.0, 0.016);
  print("Track " + str(tId) + " (" + const.getTrackSpec(tId)["name"] + ") initialized and updated cleanly");
}

// Test all 4 cars
for (let cId = 0; cId < 4; cId += 1) {
  let car = car_mod.Vehicle(cId, true, "TEST_CAR", 0.0);
  let trk = track_mod.Track(0);
  car.speed = 100.0;
  car.updatePlayer(0.016, trk, particles, assets);
  print("Car " + str(cId) + " (" + car.spec["name"] + ") updated cleanly");
}

// Test AI Rivals and Traffic
let rival = car_mod.Vehicle(1, false, "RIVAL", -30.0);
let trk = track_mod.Track(0);
rival.updateAi(0.0, 100.0, 0.016, trk);
print("AI Rival updated cleanly");

let traffic = car_mod.TrafficCar(-50.0);
traffic.update(100.0, 0.016);
print("TrafficCar updated cleanly");

// Test UI screen rendering calls
gui.beginDrawing();
ui.updateDimensions();
ui.drawTitleScreen(0.5, 0);
let cSpec = const.getCarSpec(0);
ui.drawGarageScreen(0, cSpec, 0.5);
let tSpec = const.getTrackSpec(0);
ui.drawTrackSelectScreen(0, tSpec, recordManager, 0.5);
ui.drawHUD(car_mod.Vehicle(0, true, "P", 0.0), 1, 3, 12.4, 41.2, 1, 5, true, 0.5, 200.0, 1800.0, [rival]);
ui.drawPauseMenu(0);
ui.drawResultsScreen(1, 5, 41.2, 42.5, true, 0.5);
ui.drawCrashedScreen(0.5);
gui.endDrawing();
print("All UI state renderers executed without error!");

assets.unloadAll();
gui.closeWindow();
print("Full game subsystem verification PASSED!");
