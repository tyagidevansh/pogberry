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
use "core/agent_driver" as bot_mod;
use "ui/track_io" as io;
use "ui/track_editor" as ed_mod;
use "data/f1_data" as f1;
use "std.math" as math;

gui.initWindow(const.SCREEN_WIDTH, const.SCREEN_HEIGHT, "PB SPORTS // F1 25");
gui.setExitKey(0);
gui.setTargetFPS(const.TARGET_FPS);

let assets = assets_mod.AssetManager("examples/games/f1_25");
assets.loadAll();

let cam = cam_mod.ChaseCamera();
let particles = part_mod.ParticleSystem();
let ui = ui_mod.UIRenderer();
let recordManager = rec_mod.RecordManager("records.txt");
let driverBot = bot_mod.DriverBot("HUMAN_ARCADE");
let editor = ed_mod.TrackEditor(assets, nil);

let discoveredTracks = io.listCustomTracks();
for (let dtIdx = 0; dtIdx < len(discoveredTracks); dtIdx += 1) {
  let cItem = discoveredTracks[dtIdx];
  const.registerCustomTrack(cItem["trackDef"]);
}

let state = const.STATE_TITLE;
let gameMode = const.MODE_GRAND_PRIX;
let selectedCar = const.CAR_VALKYRIE;
let selectedTrack = const.TRACK_SHIBUYA;
let aiDifficulty = const.AI_DIFF_PRO;

fun getAiDifficultyName(diff) {
  if (diff == const.AI_DIFF_ROOKIE) return "ROOKIE (EASY)";
  if (diff == const.AI_DIFF_PRO) return "PRO RACER (MEDIUM)";
  return "WORLD CHAMPION (HARD)";
}

let track = track_mod.Track(selectedTrack);
let player = car_mod.Vehicle(selectedCar, true, "PLAYER", 0.0);

let rivals = [];
let rivalNames = ["BULL GP", "SILVER ARROW", "SCUDERIA", "PAPAYA GP", "BRITISH GP"];
let rivalCars = [const.CAR_VALKYRIE, const.CAR_SHINOBI, const.CAR_PHANTOM, const.CAR_VANTA, const.CAR_BRITISH];

let countdownTimer = 3.8;
let roadScroll = 0.0;
let distance = 0.0;
let currentLap = 1;
let totalLaps = 3;
let currentLapTime = 0.0;
let bestLapTime = 0.0;
let isNewRecord = false;
let pauseSelection = 0;
let racePosition = 4;
let prevPosition = 4;
let playerMidpointCrossed = false;
let nitroFxIntensity = 0.0;

fun startRace() {
  track = track_mod.Track(selectedTrack);
  ui.setTrackId(selectedTrack);
  let tSpec = const.getTrackSpec(selectedTrack);
  totalLaps = tSpec["laps"];
  currentLap = 1;
  currentLapTime = 0.0;
  distance = 0.0;
  roadScroll = 0.0;
  countdownTimer = 3.8;
  isNewRecord = false;
  playerMidpointCrossed = false;

  let lapLen = track.spec["length"];
  let hw = track.roadWidth * 0.5;
  let pDist = lapLen - 47.5;
  let pLane = hw * 0.40;
  let pRaceDist = -47.5;
  if (gameMode == const.MODE_TIME_ATTACK) {
    pDist = lapLen - 16.0;
    pLane = -hw * 0.40;
    pRaceDist = -16.0;
  }

  player = car_mod.Vehicle(selectedCar, true, "PLAYER", 0.0);
  player.speed = 0.0;
  player.trackDistance = pDist;
  player.raceDistance = pRaceDist;
  player.x = pLane;
  player.gameMode = gameMode;
  player.setTrackPosition(track, pDist, pLane);

  particles.clear();
  ui.setMode(gameMode);

  rivals = [];

  if (gameMode == const.MODE_GRAND_PRIX or gameMode == const.MODE_REALISTIC) {
    racePosition = 4;
    prevPosition = 4;

    let slotConfigs = [
      [-16.0, -hw * 0.40],
      [-26.5, hw * 0.40],
      [-37.0, -hw * 0.40],
      [-58.0, -hw * 0.40],
      [-68.5, hw * 0.40]
    ];

    for (let i = 0; i < 5; i += 1) {
      let cfg = slotConfigs[i];
      let slotOffset = cfg[0];
      let gridDist = lapLen + slotOffset;
      let gridLane = cfg[1];
      let rCar = car_mod.Vehicle(rivalCars[i], false, rivalNames[i], 0.0);

      rCar.maxSpeed = player.maxSpeed;
      rCar.accel = player.accel;
      rCar.boostSpeed = player.boostSpeed;
      rCar.handling = player.handling;
      rCar.maxHull = player.maxHull;
      rCar.hull = player.hull;
      rCar.maxNitro = player.maxNitro;
      rCar.nitro = player.nitro;
      rCar.aiDifficulty = aiDifficulty;
      rCar.gameMode = gameMode;
      rCar.trackDistance = gridDist;
      rCar.raceDistance = slotOffset;
      rCar.aiLane = gridLane;
      rCar.x = gridLane;
      rCar.speed = 0.0;
      rCar.setTrackPosition(track, gridDist, gridLane);
      rivals.push(rCar);
    }
    if (gameMode == const.MODE_REALISTIC) {
      ui.setBanner("REALISTIC MODE // TERMINAL DAMAGE", "WALL & CAR IMPACTS END RACE", 4.5, 255, 60, 60);
    } else {
      ui.setBanner("OBJECTIVE: PODIUM FINISH (TOP 3)", "RACE 5 RIVALS // " + str(totalLaps) + " LAPS", 4.5, 255, 220, 40);
    }
  } else {

    totalLaps = 3;
    racePosition = 1;
    prevPosition = 1;
    let recTime = recordManager.getRecord(selectedTrack);
    ui.setBanner("OBJECTIVE: BEAT THE RECORD", "3 LAPS SOLO // TARGET: " + str(recTime) + "s", 4.5, 0, 240, 255);
  }

  cam.snap(player.worldX, player.worldY, player.worldZ, player.worldHeading);
  assets.playSfx(assets.sndEngineStart);
  state = const.STATE_COUNTDOWN;
}

while (!gui.windowShouldClose()) {
  let dt = gui.getFrameTime();
  if (dt > 0.033) dt = 0.033;
  let t = gui.getTime();
  ui.updateDimensions();

  if (gui.isKeyPressed("KEY_F11")) gui.toggleFullscreen();
  if (gui.isKeyPressed("KEY_F12")) gui.takeScreenshot("screenshot.png");
  if (gui.isKeyPressed("KEY_M")) assets.toggleMute();

  let wantClimax = (player.speed > 75.0 or player.isBoosting or state == const.STATE_FINISH);
  assets.updateAudio(wantClimax);

  let targetNitroFx = 0.0;
  if (player.isBoosting and state == const.STATE_RACE) {
    targetNitroFx = 1.0;
  }
  nitroFxIntensity = mu.approach(nitroFxIntensity, targetNitroFx, dt * 7.5);

  if (state == const.STATE_RACE or state == const.STATE_COUNTDOWN) {
    if (!gui.isSoundPlaying(assets.sndEngineStart)) {
      assets.playSfx(assets.sndEngineStart);
    }
    let normSpd = math.abs(player.speed) / player.maxSpeed;
    if (normSpd < 0.0) normSpd = 0.0;
    let enginePitch = 0.70 + normSpd * 0.90;
    if (player.isBoosting) enginePitch = 1.80;
    gui.setSoundPitch(assets.sndEngineStart, enginePitch);
  } else {
    if (gui.isSoundPlaying(assets.sndEngineStart)) {
      gui.stopSound(assets.sndEngineStart);
    }
  }

  if (state == const.STATE_TITLE) {
    cam.updateCinematicTrack(track, t);
    track.update(24.0, dt);

    let mouseX = gui.getMouseX();
    let mouseY = gui.getMouseY();
    let mouseClick = gui.isMouseButtonPressed("LEFT");

    if (mouseClick) {

      if (mouseX >= 80 and mouseX <= 790 and mouseY >= 174 and mouseY < 228) {
        gameMode = 0;
        assets.playSfx(assets.sndSelect);
      } else if (mouseX >= 80 and mouseX <= 790 and mouseY >= 232 and mouseY < 286) {
        gameMode = 1;
        assets.playSfx(assets.sndSelect);
      } else if (mouseX >= 80 and mouseX <= 790 and mouseY >= 290 and mouseY < 344) {
        gameMode = 2;
        assets.playSfx(assets.sndSelect);
      }

      else if (mouseY >= 382 and mouseY <= 428) {
        for (let d = 0; d < 3; d += 1) {
          let pX = 80 + d * 242;
          if (mouseX >= pX and mouseX <= pX + 226) {
            aiDifficulty = d;
            assets.playSfx(assets.sndSelect);
          }
        }
      }

      else if (mouseY >= 464 and mouseY <= 510) {
        for (let p = 0; p < 5; p += 1) {
          let pX = 80 + p * 143;
          if (mouseX >= pX and mouseX <= pX + 136) {
            cam.setPov(p);
            assets.playSfx(assets.sndSelect);
          }
        }
      }

      else if (mouseX >= 80 and mouseX <= 520 and mouseY >= 525 and mouseY <= 583) {
        assets.playSfx(assets.sndConfirm);
        state = const.STATE_GARAGE;
      }

      else if (mouseX >= 535 and mouseX <= 790 and mouseY >= 525 and mouseY <= 583) {
        assets.playSfx(assets.sndConfirm);
        state = const.STATE_TRACK_EDITOR;
      }
    }

    if (gui.isKeyPressed("KEY_E")) {
      assets.playSfx(assets.sndConfirm);
      state = const.STATE_TRACK_EDITOR;
    }
    if (gui.isKeyPressed("KEY_W") or gui.isKeyPressed("KEY_UP")) {
      gameMode = gameMode - 1;
      if (gameMode < 0) gameMode = 2;
      assets.playSfx(assets.sndSelect);
    }
    if (gui.isKeyPressed("KEY_S") or gui.isKeyPressed("KEY_DOWN")) {
      gameMode = gameMode + 1;
      if (gameMode > 2) gameMode = 0;
      assets.playSfx(assets.sndSelect);
    }

    if (gui.isKeyPressed("KEY_A") or gui.isKeyPressed("KEY_LEFT")) {
      aiDifficulty = (aiDifficulty + const.TOTAL_AI_DIFFS - 1) % const.TOTAL_AI_DIFFS;
      assets.playSfx(assets.sndSelect);
    }
    if (gui.isKeyPressed("KEY_D") or gui.isKeyPressed("KEY_RIGHT")) {
      aiDifficulty = (aiDifficulty + 1) % const.TOTAL_AI_DIFFS;
      assets.playSfx(assets.sndSelect);
    }

    if (gui.isKeyPressed("KEY_C") or gui.isKeyPressed("KEY_V")) {
      cam.cyclePov();
      assets.playSfx(assets.sndSelect);
    }
    if (gui.isKeyPressed("KEY_ENTER") or gui.isKeyPressed("KEY_SPACE")) {
      assets.playSfx(assets.sndConfirm);
      state = const.STATE_GARAGE;
    }
  }
  else if (state == const.STATE_GARAGE) {
    cam.updateTurntable(0.0, 0.4, 0.0, 7.5, 3.2, dt);

    let mouseX = gui.getMouseX();
    let mouseY = gui.getMouseY();
    let mouseClick = gui.isMouseButtonPressed("LEFT");

    if (mouseClick) {

      for (let i = 0; i < const.TOTAL_CARS; i += 1) {
        let cardX = 65 + i * 290;
        if (mouseX >= cardX and mouseX <= cardX + 270 and mouseY >= 510 and mouseY <= 650) {
          if (selectedCar == i) {
            assets.playSfx(assets.sndConfirm);
            state = const.STATE_TRACK_SELECT;
          } else {
            selectedCar = i;
            assets.playSfx(assets.sndSelect);
          }
        }
      }
    }

    if (gui.isKeyPressed("KEY_A") or gui.isKeyPressed("KEY_LEFT")) {
      selectedCar = selectedCar - 1;
      if (selectedCar < 0) selectedCar = const.TOTAL_CARS - 1;
      assets.playSfx(assets.sndSelect);
    }
    if (gui.isKeyPressed("KEY_D") or gui.isKeyPressed("KEY_RIGHT")) {
      selectedCar = selectedCar + 1;
      if (selectedCar >= const.TOTAL_CARS) selectedCar = 0;
      assets.playSfx(assets.sndSelect);
    }
    if (gui.isKeyPressed("KEY_ESCAPE")) {
      state = const.STATE_TITLE;
    }
    if (gui.isKeyPressed("KEY_ENTER") or gui.isKeyPressed("KEY_SPACE")) {
      assets.playSfx(assets.sndConfirm);
      state = const.STATE_TRACK_SELECT;
    }
  }
  else if (state == const.STATE_TRACK_SELECT) {
    cam.updateCinematicTrack(track, t);

    let mouseX = gui.getMouseX();
    let mouseY = gui.getMouseY();
    let mouseClick = gui.isMouseButtonPressed("LEFT");
    let totalT = const.getTotalTracks();
    let startIdx = 0;
    if (selectedTrack >= 4) {
      startIdx = selectedTrack - 3;
      if (startIdx + 4 > totalT) startIdx = totalT - 4;
      if (startIdx < 0) startIdx = 0;
    }

    if (mouseClick) {

      for (let slot = 0; slot < 4 and (startIdx + slot) < totalT; slot += 1) {
        let i = startIdx + slot;
        let tY = 145 + slot * 122;
        if (mouseX >= 80 and mouseX <= 890 and mouseY >= tY and mouseY <= tY + 106) {
          if (selectedTrack == i) {
            startRace();
          } else {
            selectedTrack = i;
            track = track_mod.Track(selectedTrack);
            ui.setTrackId(selectedTrack);
            assets.playSfx(assets.sndSelect);
          }
        }
      }

      if (mouseX >= 920 and mouseX <= 1210 and mouseY >= 145 and mouseY <= 617) {
        startRace();
      }
    }

    if (gui.isKeyPressed("KEY_W") or gui.isKeyPressed("KEY_UP")) {
      selectedTrack = selectedTrack - 1;
      if (selectedTrack < 0) selectedTrack = totalT - 1;
      track = track_mod.Track(selectedTrack);
      ui.setTrackId(selectedTrack);
      assets.playSfx(assets.sndSelect);
    }
    if (gui.isKeyPressed("KEY_S") or gui.isKeyPressed("KEY_DOWN")) {
      selectedTrack = selectedTrack + 1;
      if (selectedTrack >= totalT) selectedTrack = 0;
      track = track_mod.Track(selectedTrack);
      ui.setTrackId(selectedTrack);
      assets.playSfx(assets.sndSelect);
    }

    if (gui.isKeyPressed("KEY_F")) {
      let tSpec = const.getTrackSpec(selectedTrack);
      let forked = io.forkTrack(selectedTrack, tSpec["name"] + " CUSTOM");
      if (forked != nil) {
        editor.loadTrack(forked["trackDef"], forked["filename"]);
        state = const.STATE_TRACK_EDITOR;
        assets.playSfx(assets.sndConfirm);
      }
    }

    if (gui.isKeyPressed("KEY_E")) {
      if (selectedTrack >= 4) {
        let cDef = f1.getCustomTrack(selectedTrack);
        if (cDef != nil) {
          editor.loadTrack(cDef, nil);
          state = const.STATE_TRACK_EDITOR;
          assets.playSfx(assets.sndConfirm);
        }
      } else {
        let tSpec = const.getTrackSpec(selectedTrack);
        let forked = io.forkTrack(selectedTrack, tSpec["name"] + " CUSTOM");
        if (forked != nil) {
          editor.loadTrack(forked["trackDef"], forked["filename"]);
          state = const.STATE_TRACK_EDITOR;
          assets.playSfx(assets.sndConfirm);
        }
      }
    }

    if (gui.isKeyPressed("KEY_N")) {
      editor.createNewTrack("NEW CIRCUIT");
      state = const.STATE_TRACK_EDITOR;
      assets.playSfx(assets.sndConfirm);
    }

    if (gui.isKeyPressed("KEY_A") or gui.isKeyPressed("KEY_LEFT")) {
      aiDifficulty = (aiDifficulty + const.TOTAL_AI_DIFFS - 1) % const.TOTAL_AI_DIFFS;
      assets.playSfx(assets.sndSelect);
    }
    if (gui.isKeyPressed("KEY_D") or gui.isKeyPressed("KEY_RIGHT")) {
      aiDifficulty = (aiDifficulty + 1) % const.TOTAL_AI_DIFFS;
      assets.playSfx(assets.sndSelect);
    }
    if (gui.isKeyPressed("KEY_ESCAPE")) {
      state = const.STATE_GARAGE;
    }
    if (gui.isKeyPressed("KEY_ENTER") or gui.isKeyPressed("KEY_SPACE")) {
      startRace();
    }
  }
  else if (state == const.STATE_TRACK_EDITOR) {
    let edRes = editor.update(dt);
    if (edRes == "EXIT") {
      state = const.STATE_TITLE;
      selectedTrack = 0;
      track = track_mod.Track(selectedTrack);
      ui.setTrackId(selectedTrack);
    }
  }
  else if (state == const.STATE_COUNTDOWN) {
    player.speed = 0.0;
    for (let rIdx = 0; rIdx < len(rivals); rIdx += 1) {
      rivals[rIdx].speed = 0.0;
    }
    let lookDist = 34.0;
    let lookCurve = track.getCurveOffset(-lookDist, distance);
    let lookHill = track.getYOffset(-lookDist, distance);
    cam.setLookAhead(lookCurve, lookHill);
    cam.updateFollow(player.worldX, player.worldY, player.worldZ, player.speed, player.worldHeading, player.steerAngle, 0.0, false, dt);

    let oldSec = math.ceil(countdownTimer);
    countdownTimer = countdownTimer - dt;
    let newSec = math.ceil(countdownTimer);

    if (oldSec != newSec and newSec > 0 and newSec <= 3) {
      assets.playSfx(assets.sndCountdownLow);
    }

    if (countdownTimer <= 0.0) {
      assets.playSfx(assets.sndCountdownHigh);
      state = const.STATE_RACE;
    }
  }
  else if (state == const.STATE_RACE) {

    if (gui.isKeyPressed("KEY_ESCAPE") or gui.isKeyPressed("KEY_P")) {
      pauseSelection = 0;
      state = const.STATE_PAUSED;
      assets.playSfx(assets.sndSelect);
    }

    if (gui.isKeyPressed("KEY_C") or gui.isKeyPressed("KEY_V")) {
      cam.cyclePov();
      ui.setBanner("CAMERA POV: " + cam.getPovName(), "VIEW " + str(cam.pov + 1) + " OF " + str(cam_mod.TOTAL_POVS) + " // [C] TO SWITCH", 2.0, 0, 240, 255);
      assets.playSfx(assets.sndSelect);
    }

    if (gui.isKeyPressed("KEY_O")) {
      player.isAutopilot = !player.isAutopilot;
      if (player.isAutopilot) {
        ui.setBanner("AUTOPILOT ENGAGED", "AI DRIVER TAKING THE WHEEL // PRESS O TO CANCEL", 2.2, 0, 240, 255);
        assets.playSfx(assets.sndConfirm);
      } else {
        player.inputOverride = nil;
        ui.setBanner("MANUAL CONTROL RESTORED", "YOU HAVE THE WHEEL", 2.0, 255, 220, 40);
        assets.playSfx(assets.sndSelect);
      }
    }

    if (player.isAutopilot) {
      if (gui.isKeyDown("KEY_A") or gui.isKeyDown("KEY_D") or gui.isKeyDown("KEY_LEFT") or gui.isKeyDown("KEY_RIGHT")) {
        player.isAutopilot = false;
        player.inputOverride = nil;
        ui.setBanner("MANUAL OVERRIDE", "YOU HAVE THE WHEEL", 1.8, 255, 220, 40);
      } else {
        player.inputOverride = driverBot.computeInput(player, track);
      }
    }

    ui.updateBanners(dt);

    player.updatePlayer(dt, track, particles, assets);
    if (player.wallHitShake > 0.0) {
      cam.addShake(player.wallHitShake);
      player.wallHitShake = 0.0;
    }

    if (player.isTerminalCrash or player.hull <= 0.0) {
      state = const.STATE_CRASHED;
      assets.playSfx(assets.sndCrash);
      cam.addShake(1.2);
    }
    distance = player.trackDistance;

    roadScroll = roadScroll + player.speed * dt;
    while (roadScroll > track.segmentLength) {
      roadScroll = roadScroll - track.segmentLength;
    }
    while (roadScroll < 0.0) {
      roadScroll = roadScroll + track.segmentLength;
    }

    track.update(player.speed, dt);
    particles.update(dt);

    let lookDist = 34.0 + (player.speed / 100.0) * 16.0;
    let lookAheadDist = lookDist;
    if (math.cos(player.heading) < 0.0) lookAheadDist = -lookDist;
    let lookCurve = track.getCurveOffset(-lookAheadDist, distance);
    let lookHill = track.getYOffset(-lookAheadDist, distance);
    if (math.cos(player.heading) < 0.0) lookCurve = -lookCurve;
    cam.setLookAhead(lookCurve, lookHill);
    cam.updateFollow(player.worldX, player.worldY, player.worldZ, player.speed, player.worldHeading, player.steerAngle, 0.0, player.isBoosting, dt);

    let tSpec = const.getTrackSpec(selectedTrack);
    let lapDist = tSpec["length"];

    if (gameMode == const.MODE_TIME_ATTACK and bestLapTime > 0.0) {
      let lapProg = (distance - math.floor(distance / lapDist) * lapDist) / lapDist;
      let expectedPace = bestLapTime * lapProg;
      let delta = currentLapTime - expectedPace;
      ui.setTimeAttackDelta(delta);
    }

    currentLapTime = currentLapTime + dt;

    let targetLap = 0;
    if (player.raceDistance >= 0.0) {
      targetLap = math.floor(player.raceDistance / lapDist);
    }
    if (targetLap > (currentLap - 1)) {

      if (bestLapTime == 0.0 or currentLapTime < bestLapTime) {
        bestLapTime = currentLapTime;
      }
      if (recordManager.submitLapTime(selectedTrack, currentLapTime)) {
        isNewRecord = true;
      }
      currentLapTime = 0.0;
      currentLap = targetLap + 1;
      assets.playSfx(assets.sndCheckpoint);

      if (currentLap > totalLaps) {
        state = const.STATE_FINISH;
        assets.playSfx(assets.sndWin);
      } else if (currentLap == totalLaps) {
        ui.setBanner("FINAL LAP!", "FULL OVERDRIVE // SPRINT TO THE LINE", 3.0, 255, 220, 40);
      } else {
        ui.setBanner("LAP " + str(currentLap) + " / " + str(totalLaps), "PREV LAP: " + str(bestLapTime) + "s", 2.5, 0, 240, 255);
      }
    }

    if (gameMode == const.MODE_GRAND_PRIX or gameMode == const.MODE_REALISTIC) {
      let allCars = [player];
      for (let i = 0; i < len(rivals); i += 1) allCars.push(rivals[i]);

      for (let i = 0; i < len(rivals); i += 1) {
        let rCar = rivals[i];

        let closestAheadDist = 999.0;
        let closestBehindDist = -999.0;
        let leadCarSpd = player.speed;
        let leadCarX = nil;

        let threatLeft = false;
        let threatRight = false;

        for (let j = 0; j < len(allCars); j += 1) {
          let other = allCars[j];
          if (other != rCar) {
            let deltaS = other.trackDistance - rCar.trackDistance;
            while (deltaS > lapDist * 0.5) deltaS = deltaS - lapDist;
            while (deltaS < -lapDist * 0.5) deltaS = deltaS + lapDist;

            if (deltaS > 0.0 and deltaS < closestAheadDist) {
              closestAheadDist = deltaS;
              leadCarSpd = other.speed;
              leadCarX = other.x;
            } else if (deltaS < 0.0 and deltaS > closestBehindDist) {
              closestBehindDist = deltaS;
            }

            if (math.abs(deltaS) < 6.5) {
              let dX = other.x - rCar.x;
              if (dX > 0.0 and dX < 3.2) {
                threatRight = true;
              } else if (dX < 0.0 and dX > -3.2) {
                threatLeft = true;
              }
            }
          }
        }

        rCar.rivalAheadX = leadCarX;
        rCar.closestAheadDist = closestAheadDist;
        rCar.leadCarSpd = leadCarSpd;
        rCar.threatLeft = threatLeft;
        rCar.threatRight = threatRight;

        let pDeltaS = player.trackDistance - rCar.trackDistance;
        while (pDeltaS > lapDist * 0.5) pDeltaS = pDeltaS - lapDist;
        while (pDeltaS < -lapDist * 0.5) pDeltaS = pDeltaS + lapDist;
        rCar.playerDeltaS = pDeltaS;
        rCar.playerDeltaX = player.x - rCar.x;
        rCar.playerNear = (math.abs(pDeltaS) < 35.0);

        let packDDist = 999.0;
        if (closestAheadDist < 55.0) {
          packDDist = -closestAheadDist;
        } else if (closestBehindDist > -30.0) {
          packDDist = -closestBehindDist;
        }

        rCar.updateAi(packDDist, leadCarSpd, dt, track);

        let dDistPlayer = rCar.trackDistance - player.trackDistance;
        while (dDistPlayer > lapDist * 0.5) dDistPlayer = dDistPlayer - lapDist;
        while (dDistPlayer < -lapDist * 0.5) dDistPlayer = dDistPlayer + lapDist;
        rCar.z = -dDistPlayer;
      }

      car_mod.resolveCarCollisions(allCars, track, lapDist, particles, assets, cam, dt);

      if (player.isTerminalCrash or player.hull <= 0.0) {
        state = const.STATE_CRASHED;
        assets.playSfx(assets.sndCrash);
        cam.addShake(1.2);
      }

      distance = player.trackDistance;
      let aheadCount = 0;
      for (let i = 0; i < len(rivals); i += 1) {
        let rCar = rivals[i];
        let dDist = rCar.trackDistance - player.trackDistance;
        while (dDist > lapDist * 0.5) dDist = dDist - lapDist;
        while (dDist < -lapDist * 0.5) dDist = dDist + lapDist;
        rCar.z = -dDist;

        if (rCar.raceDistance > player.raceDistance) {
          aheadCount = aheadCount + 1;
        }
      }

      racePosition = aheadCount + 1;
      prevPosition = racePosition;
    }

  }
  else if (state == const.STATE_PAUSED) {
    if (gui.isKeyPressed("KEY_ESCAPE") or gui.isKeyPressed("KEY_P")) {
      state = const.STATE_RACE;
      assets.playSfx(assets.sndConfirm);
    }
    if (gui.isKeyPressed("KEY_W") or gui.isKeyPressed("KEY_UP")) {
      pauseSelection = pauseSelection - 1;
      if (pauseSelection < 0) pauseSelection = 4;
      assets.playSfx(assets.sndSelect);
    }
    if (gui.isKeyPressed("KEY_S") or gui.isKeyPressed("KEY_DOWN")) {
      pauseSelection = pauseSelection + 1;
      if (pauseSelection > 4) pauseSelection = 0;
      assets.playSfx(assets.sndSelect);
    }

    if (pauseSelection == 2) {
      if (gui.isKeyPressed("KEY_A") or gui.isKeyPressed("KEY_LEFT")) {
        cam.setPov((cam.pov + cam_mod.TOTAL_POVS - 1) % cam_mod.TOTAL_POVS);
        assets.playSfx(assets.sndSelect);
      }
      if (gui.isKeyPressed("KEY_D") or gui.isKeyPressed("KEY_RIGHT")) {
        cam.cyclePov();
        assets.playSfx(assets.sndSelect);
      }
    }

    if (pauseSelection == 3) {
      if (gui.isKeyPressed("KEY_A") or gui.isKeyPressed("KEY_LEFT")) {
        aiDifficulty = (aiDifficulty + const.TOTAL_AI_DIFFS - 1) % const.TOTAL_AI_DIFFS;
        for (let i = 0; i < len(rivals); i += 1) rivals[i].aiDifficulty = aiDifficulty;
        assets.playSfx(assets.sndSelect);
      }
      if (gui.isKeyPressed("KEY_D") or gui.isKeyPressed("KEY_RIGHT")) {
        aiDifficulty = (aiDifficulty + 1) % const.TOTAL_AI_DIFFS;
        for (let i = 0; i < len(rivals); i += 1) rivals[i].aiDifficulty = aiDifficulty;
        assets.playSfx(assets.sndSelect);
      }
    }
    if (gui.isKeyPressed("KEY_ENTER") or gui.isKeyPressed("KEY_SPACE")) {
      assets.playSfx(assets.sndConfirm);
      if (pauseSelection == 0) {
        state = const.STATE_RACE;
      } else if (pauseSelection == 1) {
        startRace();
      } else if (pauseSelection == 2) {
        cam.cyclePov();
      } else if (pauseSelection == 3) {
        aiDifficulty = (aiDifficulty + 1) % const.TOTAL_AI_DIFFS;
        for (let i = 0; i < len(rivals); i += 1) rivals[i].aiDifficulty = aiDifficulty;
      } else {
        state = const.STATE_GARAGE;
      }
    }
  }
  else if (state == const.STATE_FINISH or state == const.STATE_CRASHED or state == const.STATE_TIMEOUT) {
    cam.updateCinematic(t);
    if (gui.isKeyPressed("KEY_ENTER") or gui.isKeyPressed("KEY_SPACE")) {
      assets.playSfx(assets.sndConfirm);
      state = const.STATE_GARAGE;
    }
  }

  let tSpec = const.getTrackSpec(selectedTrack);
  let lapDist = tSpec["length"];
  let sky = tSpec["skyColor"];
  let ground = tSpec["groundColor"];
  if (ground == nil) ground = [10, 12, 18];

  let scrW = gui.getScreenWidth();
  let scrH = gui.getScreenHeight();

  gui.beginDrawing();

  if (state == const.STATE_TRACK_EDITOR) {
    editor.draw(t);
    gui.endDrawing();
    continue;
  }

  if (state == const.STATE_GARAGE) {
    gui.clearBackground(4, 6, 18);
  } else {
    gui.clearBackground(sky[0], sky[1], sky[2]);

    let skyTop = tSpec["skyTop"];
    if (skyTop == nil) skyTop = [24, 88, 180];
    let skyBottom = tSpec["skyBottom"];
    if (skyBottom == nil) skyBottom = [145, 192, 238];
    let fogCol = tSpec["fogColor"];
    if (fogCol == nil) fogCol = [145, 192, 238];

    let skyBands = 36;
    let bandH = scrH / skyBands;
    for (let b = 0; b < skyBands; b += 1) {
      let factor = b / (skyBands - 1.0);
      let r = math.floor(skyTop[0] + (skyBottom[0] - skyTop[0]) * factor);
      let g = math.floor(skyTop[1] + (skyBottom[1] - skyTop[1]) * factor);
      let bCol = math.floor(skyTop[2] + (skyBottom[2] - skyTop[2]) * factor);
      gui.drawRectangle(0, math.floor(b * bandH), scrW, math.ceil(bandH + 1.0), r, g, bCol);
    }
  }

  cam.begin3DPass();

  if (state == const.STATE_GARAGE) {

    gui.drawPlane3D(0.0, -0.2, 0.0, 100.0, 100.0, 12, 16, 28);
    gui.drawGrid(12, 1.2);
    let carSpec = const.getCarSpec(selectedCar);
    let pCol = carSpec["primaryColor"];
    assets.playCarModel(selectedCar, 0.0, 0.0, 0.0, t * 45.0, 1.45, 255, 255, 255);
  } else {

    let groundAnchorX = player.worldX;
    let groundAnchorZ = player.worldZ;
    if (state == const.STATE_TITLE or state == const.STATE_TRACK_SELECT) {
      let st0 = track.stations[0];
      groundAnchorX = st0["x"];
      groundAnchorZ = st0["z"];
    }
    gui.drawPlane3D(groundAnchorX, -0.2, groundAnchorZ, 8000.0, 8000.0, ground[0], ground[1], ground[2]);

    track.draw(0.0, player.trackDistance, t, assets, cam);

    if (gameMode == const.MODE_GRAND_PRIX or gameMode == const.MODE_REALISTIC) {
      for (let i = 0; i < len(rivals); i += 1) {
        let rCar = rivals[i];
        let dDist = math.abs(rCar.trackDistance - player.trackDistance);
        while (dDist > lapDist * 0.5) dDist = dDist - lapDist;
        if (math.abs(dDist) < 280.0) {
          rCar.draw(assets, t);
        }
      }
    }

    if (cam.pov != cam_mod.POV_BUMPER and cam.pov != cam_mod.POV_HOOD and cam.pov != cam_mod.POV_COCKPIT) {
      player.draw(assets, t);
    }
  }

  particles.draw();

  cam.end3DPass();

  if (nitroFxIntensity > 0.005) {
    if (assets.shaderVelocity != nil) {
      gui.setShaderFloat(assets.shaderVelocity, "u_time", t);
      let normSpd = math.abs(player.speed) / player.maxSpeed;
      if (normSpd < 0.0) normSpd = 0.0;
      gui.setShaderFloat(assets.shaderVelocity, "u_speed", normSpd);
      gui.setShaderFloat(assets.shaderVelocity, "u_intensity", nitroFxIntensity * 0.75);
      gui.setShaderVec2(assets.shaderVelocity, "u_resolution", scrW, scrH);
      gui.beginShaderMode(assets.shaderVelocity);
      gui.drawRectangle(0, 0, scrW, scrH, 255, 255, 255);
      gui.endShaderMode();
    }
  }

  if (player.hitFlash > 0.0) {
    let flashAlpha = math.floor((player.hitFlash / 0.35) * 140);
    gui.drawRectangleAlpha(0, 0, scrW, scrH, 220, 24, 32, flashAlpha);
  }

  ui.setMode(gameMode);

  if (state == const.STATE_TITLE) {
    ui.drawTitleScreen(t, gameMode, aiDifficulty, cam.pov);
  }
  else if (state == const.STATE_GARAGE) {
    let cSpec = const.getCarSpec(selectedCar);
    ui.drawGarageScreen(selectedCar, cSpec, t);
  }
  else if (state == const.STATE_TRACK_SELECT) {
    let trkSpec = const.getTrackSpec(selectedTrack);
    ui.drawTrackSelectScreen(selectedTrack, trkSpec, recordManager, t, aiDifficulty);
  }
  else if (state == const.STATE_COUNTDOWN) {
    if (cam.pov == cam_mod.POV_COCKPIT) {
      ui.drawCockpitView(player, t, dt);
    }
    ui.drawHUD(player, currentLap, totalLaps, currentLapTime, bestLapTime, racePosition, len(rivals) + 1, (gameMode == const.MODE_GRAND_PRIX or gameMode == const.MODE_REALISTIC), t, distance, lapDist, rivals);
    ui.drawCountdown(countdownTimer);
  }
  else if (state == const.STATE_RACE) {
    if (cam.pov == cam_mod.POV_COCKPIT) {
      ui.drawCockpitView(player, t, dt);
    }
    ui.drawHUD(player, currentLap, totalLaps, currentLapTime, bestLapTime, racePosition, len(rivals) + 1, (gameMode == const.MODE_GRAND_PRIX or gameMode == const.MODE_REALISTIC), t, distance, lapDist, rivals);
  }
  else if (state == const.STATE_PAUSED) {
    if (cam.pov == cam_mod.POV_COCKPIT) {
      ui.drawCockpitView(player, t, dt);
    }
    ui.drawHUD(player, currentLap, totalLaps, currentLapTime, bestLapTime, racePosition, len(rivals) + 1, (gameMode == const.MODE_GRAND_PRIX or gameMode == const.MODE_REALISTIC), t, distance, lapDist, rivals);
    ui.drawPauseMenu(pauseSelection, cam.getPovName(), getAiDifficultyName(aiDifficulty));
  }
  else if (state == const.STATE_FINISH) {
    ui.drawResultsScreen(racePosition, len(rivals) + 1, bestLapTime, recordManager.getRecord(selectedTrack), isNewRecord, t);
  }
  else if (state == const.STATE_TIMEOUT) {
    ui.drawTimeoutScreen(t);
  }
  else if (state == const.STATE_CRASHED) {
    ui.drawCrashedScreen(t);
  }

  gui.endDrawing();
}

assets.unloadAll();
gui.closeWindow();
print("PB SPORTS F1 25 session exited cleanly.");
