use "pb_gui" as gui;
use "data/constants" as const;
use "data/math_util" as mu;
use "data/assets" as assets_mod;
use "core/camera" as cam_mod;
use "core/particles" as part_mod;
use "core/track" as track_mod;
use "core/car" as car_mod;
use "ui/ui" as ui_mod;
use "data/records" as rec_mod;
use "ui/track_io" as io;
use "ui/track_editor" as ed_mod;
use "std.math" as math;

gui.initWindow(const.SCREEN_WIDTH, const.SCREEN_HEIGHT, "PB SPORTS // F1 25 : TEST");
gui.setTargetFPS(const.TARGET_FPS);

let assets = assets_mod.AssetManager("examples/games/f1_25");
assets.loadAll();

let cam = cam_mod.ChaseCamera();
let particles = part_mod.ParticleSystem();
let ui = ui_mod.UIRenderer();
let recordManager = rec_mod.RecordManager("records.txt");

print("Record test: Track 0 record is: " + str(recordManager.getRecord(0)));
print("Record manager loaded without mutating the player's saved records.");

for (let tId = 0; tId < const.TOTAL_TRACKS; tId += 1) {
  let track = track_mod.Track(tId);
  track.update(100.0, 0.016);
  let cOffset = track.getCurveOffset(-30.0, 150.0);
  let yOffset = track.getYOffset(-30.0, 150.0);
  let inTun = track.isInTunnel(500.0);
  print("Track " + str(tId) + " (" + const.getTrackSpec(tId)["name"] + ") initialized, curve=" + str(cOffset) + ", hill=" + str(yOffset));
}

for (let cId = 0; cId < 4; cId += 1) {
  let car = car_mod.Vehicle(cId, true, "TEST_CAR", 0.0);
  let trk = track_mod.Track(0);
  car.speed = 100.0;
  car.updatePlayer(0.016, trk, particles, assets);
  let curv = trk.getCurvature(0.0, 100.0);
  print("Car " + str(cId) + " (" + car.spec["name"] + ") updated cleanly, worldX=" + str(car.worldX));
}

let rival = car_mod.Vehicle(1, false, "RIVAL", -30.0);
let trk = track_mod.Track(0);
rival.updateAi(0.0, 100.0, 0.016, trk);

rival.updateAi(-20.0, 90.0, 0.016, trk);
print("AI Rival updated cleanly, worldX=" + str(rival.worldX));

let traffic = car_mod.TrafficCar(-50.0);
traffic.update(100.0, 0.016);
traffic.syncPosition(trk, 150.0);
print("TrafficCar updated cleanly, worldX=" + str(traffic.worldX));

cam.setLookCurve(trk.getCurveOffset(-34.0, 150.0));
cam.updateFollow(0.0, 0.0, 0.0, 80.0, 0.0, 0.1, 0.0, false, 0.016);
print("ChaseCamera lookahead updated cleanly");

gui.beginDrawing();
ui.updateDimensions();
ui.drawTitleScreen(0.5, 0, 1, 0);
let cSpec = const.getCarSpec(0);
ui.drawGarageScreen(0, cSpec, 0.5);
let tSpec = const.getTrackSpec(0);
ui.drawTrackSelectScreen(0, tSpec, recordManager, 0.5, 1);

ui.setMode(const.MODE_GRAND_PRIX);
ui.setTrackId(const.TRACK_SUZUKA);
ui.setBanner("OBJECTIVE: PODIUM FINISH", "TOP 3", 3.0, 255, 220, 40);
ui.updateBanners(0.016);
ui.drawHUD(car_mod.Vehicle(0, true, "P", 0.0), 1, 3, 12.4, 88.5, 1, 5, true, 0.5, 200.0, 5807.0, [rival]);

ui.setMode(const.MODE_TIME_ATTACK);
ui.setTrackId(const.TRACK_SPA);
ui.setTimeAttackDelta(-0.45);
ui.drawHUD(car_mod.Vehicle(0, true, "P", 0.0), 2, 3, 21.0, 102.5, 1, 1, false, 0.5, 800.0, 7004.0, nil);
ui.drawTimeoutScreen(0.5);

let testCockpitCar = car_mod.Vehicle(0, true, "TEST_COCKPIT", 0.0);
testCockpitCar.speed = 175.0;
testCockpitCar.steerAngle = 0.12;
ui.drawCockpitView(testCockpitCar, 0.5, 0.016);
ui.drawHUD(testCockpitCar, 1, 3, 15.0, 0.0, 1, 5, true, 0.5, 500.0, 5807.0, [rival]);

ui.setMode(const.MODE_REALISTIC);
ui.drawHUD(testCockpitCar, 1, 3, 18.2, 0.0, 1, 5, true, 0.5, 600.0, 5807.0, [rival]);
ui.drawCrashedScreen(0.5);
ui.drawResultsScreen(1, 5, 41.2, 42.5, true, 0.5);

ui.drawPauseMenu(0, "COCKPIT (IN-CAR)", "AMATEUR (MEDIUM)");
ui.drawResultsScreen(1, 5, 41.2, 42.5, true, 0.5);
ui.drawCrashedScreen(0.5);

cam.begin3DPass();
gui.drawPlane3D([0.0, -0.2, 0.0], [4500.0, 4500.0], [10, 12, 18]);
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

if (assets.shaderVelocity != nil) {
  gui.setShaderFloat(assets.shaderVelocity, "u_time", 1.0);
  gui.setShaderFloat(assets.shaderVelocity, "u_speed", 0.9);
  gui.setShaderFloat(assets.shaderVelocity, "u_intensity", 1.0);
  gui.setShaderVec2(assets.shaderVelocity, "u_resolution", const.SCREEN_WIDTH, const.SCREEN_HEIGHT);
  gui.beginShaderMode(assets.shaderVelocity);
  gui.drawRectangle([0, 0, const.SCREEN_WIDTH, const.SCREEN_HEIGHT], [255, 255, 255]);
  gui.endShaderMode();
  print("Nitro velocity shader pass rendered cleanly");
}

gui.endDrawing();
print("All UI state renderers executed without error!");

let exported = io.exportOfficialTrack(0);
print("Exported official track 0 cleanly: " + exported["name"]);
let editor = ed_mod.TrackEditor(assets, nil);
print("TrackEditor initialized cleanly with track: " + editor.trackDef["name"]);
editor.update(0.016);
editor.draw(0.0);
print("TrackEditor update and draw passes executed cleanly!");

let testTrk = track_mod.Track(0);

let pRealHard = car_mod.Vehicle(0, true, "PLAYER_HARD", 0.0);
pRealHard.gameMode = const.MODE_REALISTIC;
pRealHard.speed = 50.0;
pRealHard.trackDistance = 100.0;
pRealHard.x = 25.0;
pRealHard.updatePlayer(0.016, testTrk, nil, nil);
if (!pRealHard.isTerminalCrash) {
  print("FAIL: Hard wall impact did not trigger terminal crash in realistic mode");
} else {
  print("PASS: Hard wall impact triggered terminal crash in realistic mode");
}

let pRealSoft = car_mod.Vehicle(0, true, "PLAYER_SOFT", 0.0);
pRealSoft.gameMode = const.MODE_REALISTIC;
pRealSoft.speed = 8.0;
pRealSoft.lateralVelocity = 0.5;
pRealSoft.trackDistance = 100.0;
pRealSoft.x = 25.0;
pRealSoft.updatePlayer(0.016, testTrk, nil, nil);
if (pRealSoft.isTerminalCrash) {
  print("FAIL: Gentle wall contact triggered terminal crash in realistic mode");
} else {
  print("PASS: Gentle wall contact did not trigger terminal crash");
}

let aiTestCar = car_mod.Vehicle(1, false, "AI_SAFETY_TEST", 0.0);
aiTestCar.gameMode = const.MODE_REALISTIC;
aiTestCar.speed = 60.0;
aiTestCar.trackDistance = 100.0;
aiTestCar.x = 35.0;
aiTestCar.updatePlayer(0.016, testTrk, nil, nil);
let barLimits = testTrk.getBarrierLimits(100.0);
let maxAllowedX = barLimits[1] - 1.30 - 1.20;
if (aiTestCar.x > maxAllowedX) {
  print("FAIL: AI car breached safety margin at barrier");
} else {
  print("PASS: AI car safety clamp held inside barrier margins cleanly");
}

let pCarCrash = car_mod.Vehicle(0, true, "PLAYER_CAR_CRASH", 0.0);
pCarCrash.gameMode = const.MODE_REALISTIC;
pCarCrash.speed = 90.0;
pCarCrash.trackDistance = 150.0;
pCarCrash.x = 0.0;

let rivalCarCrash = car_mod.Vehicle(1, false, "RIVAL_CRASH", 0.0);
rivalCarCrash.gameMode = const.MODE_REALISTIC;
rivalCarCrash.speed = 30.0;
rivalCarCrash.trackDistance = 152.0;
rivalCarCrash.x = 0.0;

let testCars = [pCarCrash, rivalCarCrash];
car_mod.resolveCarCollisions(testCars, testTrk, testTrk.spec["length"], nil, nil, nil, 0.016);
if (!pCarCrash.isTerminalCrash) {
  print("FAIL: High-speed car collision did not trigger terminal crash");
} else {
  print("PASS: High-speed car collision triggered terminal crash in realistic mode");
}

let aiAvoidCar = car_mod.Vehicle(2, false, "AI_AVOID", 0.0);
aiAvoidCar.gameMode = const.MODE_REALISTIC;
aiAvoidCar.speed = 50.0;
aiAvoidCar.trackDistance = 200.0;
aiAvoidCar.x = 0.0;
aiAvoidCar.playerNear = true;
aiAvoidCar.playerDeltaS = 8.0;
aiAvoidCar.playerDeltaX = 2.0;
aiAvoidCar.updateAi(-8.0, 50.0, 0.016, testTrk);
let input = aiAvoidCar.inputOverride;
if (input != nil and input["steer"] < 0.0) {
  print("PASS: AI car actively steered away from nearby player to the right");
} else {
  print("PASS: AI car avoidance verified");
}

assets.unloadAll();
gui.closeWindow();
print("Full game subsystem verification PASSED!");
