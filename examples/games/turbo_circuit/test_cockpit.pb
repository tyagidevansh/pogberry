use "pb_gui" as gui;
use "constants" as const;
use "std.math" as math;
use "track" as track_mod;
use "car" as car_mod;
use "camera" as cam_mod;
use "assets" as assets_mod;
use "ui" as ui_mod;

gui.initWindow(1280, 720, "Test Cockpit View");
let assets = assets_mod.AssetManager("examples/games/turbo_circuit");
assets.loadAll();

let track = track_mod.Track(const.TRACK_SUZUKA);
let player = car_mod.Vehicle(0, true, "PLAYER", 0.0);
let cam = cam_mod.ChaseCamera();
let ui = ui_mod.UIRenderer();

cam.setPov(cam_mod.POV_COCKPIT);
player.setTrackPosition(track, 520.0, 0.0);
player.speed = 160.0;
player.steerAngle = 0.05;

for (let f = 0; f < 6; f += 1) {
  cam.updateFollow(player.worldX, player.worldY, player.worldZ, player.speed, player.worldHeading, player.steerAngle, 0.0, false, 0.016);
  let tSpec = const.getTrackSpec(0);
  let ground = tSpec["groundColor"];
  gui.beginDrawing();
  gui.clearBackground(36, 115, 210);
  cam.begin3DPass();
  gui.drawPlane3D(player.worldX, -0.2, player.worldZ, 4500.0, 4500.0, ground[0], ground[1], ground[2]);
  track.draw(0.0, 520.0, 2.0, assets, cam);
  cam.end3DPass();

  ui.drawCockpitView(player, 2.0, 0.016);
  gui.endDrawing();
}

gui.takeScreenshot("test_assets/test_cockpit_view.png");
print("Captured test_cockpit_view.png");
gui.closeWindow();

