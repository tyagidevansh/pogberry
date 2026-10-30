// TURBO CIRCUIT: OVERDRIVE — Main Game Loop
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
use "agent_driver" as bot_mod;
use "std.math" as math;

// Initialize Window
gui.initWindow(const.SCREEN_WIDTH, const.SCREEN_HEIGHT, "TURBO // CIRCUIT : OVERDRIVE");
gui.setExitKey(0); // Disable default ESC window exit so ESC can trigger in-game pause
gui.setTargetFPS(const.TARGET_FPS);

let assets = assets_mod.AssetManager("examples/games/turbo_circuit");
assets.loadAll();

let cam = cam_mod.ChaseCamera();
let particles = part_mod.ParticleSystem();
let ui = ui_mod.UIRenderer();
let recordManager = rec_mod.RecordManager("records.txt");
let driverBot = bot_mod.DriverBot("HUMAN_ARCADE");

// Game State Variables
let state = const.STATE_TITLE;
let gameMode = const.MODE_GRAND_PRIX;
let selectedCar = const.CAR_PHANTOM;
let selectedTrack = const.TRACK_SHIBUYA;
let aiDifficulty = const.AI_DIFF_AMATEUR; // 0=Rookie, 1=Amateur, 2=Expert (Max Hard)

fun getAiDifficultyName(diff) {
  if (diff == const.AI_DIFF_ROOKIE) return "ROOKIE (EASY)";
  if (diff == const.AI_DIFF_AMATEUR) return "AMATEUR (MEDIUM)";
  return "EXPERT (MAX HARD)";
}

let track = track_mod.Track(selectedTrack);
let player = car_mod.Vehicle(selectedCar, true, "PLAYER", 0.0);

// AI Competitors for Grand Prix
let rivals = [];
let rivalNames = ["NEXUS", "CYBER-09", "RAZOR", "VORTEX", "APEX"];
let rivalCars = [const.CAR_SHINOBI, const.CAR_VALKYRIE, const.CAR_VANTA, const.CAR_PHANTOM, const.CAR_SHINOBI];

// Traffic Cars for Outrun Mode
let trafficCars = [];

// Timers & Metrics
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

// Outrun Mode Variables
let outrunTimer = 45.0;
let outrunStage = 1;
let nextGateDist = 600.0;
let totalNearMisses = 0;

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

  player = car_mod.Vehicle(selectedCar, true, "PLAYER", 0.0);
  player.speed = 0.0;
  player.trackDistance = 0.0;
  player.setTrackPosition(track, 0.0, 0.0);

  particles.clear();
  ui.setMode(gameMode);

  // Mode Specific Setups
  rivals = [];
  trafficCars = [];

  if (gameMode == const.MODE_GRAND_PRIX) {
    racePosition = 4;
    prevPosition = 4;
    // Staggered starting grid with equalized performance physics
    for (let i = 0; i < 5; i += 1) {
      let gridDist = 28.0 - i * 12.0; // P1 is at +28m, P2 at +16m, etc.
      let rCar = car_mod.Vehicle(rivalCars[i], false, rivalNames[i], -gridDist);
      // Strictly match acceleration, top speed, and performance specs to player for fair Grand Prix physics
      rCar.maxSpeed = player.maxSpeed;
      rCar.accel = player.accel;
      rCar.boostSpeed = player.boostSpeed;
      rCar.handling = player.handling;
      rCar.maxHull = player.maxHull;
      rCar.hull = player.hull;
      rCar.maxNitro = player.maxNitro;
      rCar.nitro = player.nitro;
      rCar.aiDifficulty = aiDifficulty;
      rCar.trackDistance = gridDist;
      rCar.aiLane = -2.6 + (i % 3) * 2.6;
      rCar.x = rCar.aiLane;
      rCar.speed = 0.0;
      rCar.setTrackPosition(track, gridDist, rCar.x);
      rivals.push(rCar);
    }
    ui.setBanner("OBJECTIVE: PODIUM FINISH (TOP 3)", "RACE 5 RIVALS // " + str(totalLaps) + " LAPS", 4.5, 255, 220, 40);
  } else if (gameMode == const.MODE_OUTRUN) {
    totalLaps = 999;
    outrunTimer = 45.0;
    outrunStage = 1;
    nextGateDist = 600.0;
    totalNearMisses = 0;
    racePosition = 1;
    prevPosition = 1;
    // Spawn highway traffic
    for (let i = 0; i < 10; i += 1) {
      let tf = car_mod.TrafficCar(-40.0 - i * 30.0);
      trafficCars.push(tf);
    }
    ui.setOutrunState(outrunTimer, outrunStage, nextGateDist, 0.0, 0);
    ui.setBanner("OBJECTIVE: BEAT THE CLOCK", "REACH CHECKPOINTS FOR +20s // WEAVE TRAFFIC", 4.5, 255, 80, 180);
  } else {
    // TIME ATTACK
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

// Main Game Loop
while (!gui.windowShouldClose()) {
  let dt = gui.getFrameTime();
  if (dt > 0.033) dt = 0.033; // Clamp dt to prevent tunneling
  let t = gui.getTime();
  ui.updateDimensions();

  // Fullscreen, Screenshot & Mute Hotkeys
  if (gui.isKeyPressed("KEY_F11")) gui.toggleFullscreen();
  if (gui.isKeyPressed("KEY_F12")) gui.takeScreenshot("screenshot.png");
  if (gui.isKeyPressed("KEY_M")) assets.toggleMute();

  // Music Streaming & Climax logic
  let wantClimax = (player.speed > 75.0 or player.isBoosting or state == const.STATE_FINISH);
  assets.updateAudio(wantClimax);

  // Dynamic Engine Pitch & Sound Loop
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

  // ---------------------------------------------------------------------------
  // STATE UPDATES
  // ---------------------------------------------------------------------------
  if (state == const.STATE_TITLE) {
    cam.updateCinematicTrack(track, t);
    track.update(24.0, dt);

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
    if (gui.isKeyPressed("KEY_ENTER") or gui.isKeyPressed("KEY_SPACE")) {
      assets.playSfx(assets.sndConfirm);
      state = const.STATE_GARAGE;
    }
  }
  else if (state == const.STATE_GARAGE) {
    cam.updateTurntable(0.0, 0.4, 0.0, 7.5, 3.2, dt);

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

    if (gui.isKeyPressed("KEY_W") or gui.isKeyPressed("KEY_UP")) {
      selectedTrack = selectedTrack - 1;
      if (selectedTrack < 0) selectedTrack = const.TOTAL_TRACKS - 1;
      track = track_mod.Track(selectedTrack);
      ui.setTrackId(selectedTrack);
      assets.playSfx(assets.sndSelect);
    }
    if (gui.isKeyPressed("KEY_S") or gui.isKeyPressed("KEY_DOWN")) {
      selectedTrack = selectedTrack + 1;
      if (selectedTrack >= const.TOTAL_TRACKS) selectedTrack = 0;
      track = track_mod.Track(selectedTrack);
      ui.setTrackId(selectedTrack);
      assets.playSfx(assets.sndSelect);
    }
    // AI Difficulty adjustment
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
  else if (state == const.STATE_COUNTDOWN) {
    let lookDist = 34.0;
    let lookCurve = track.getCurveOffset(-lookDist, distance);
    let lookHill = track.getYOffset(-lookDist, distance);
    cam.setLookAhead(lookCurve, lookHill);
    cam.updateFollow(player.worldX, player.worldY, player.worldZ, player.speed, player.worldHeading, player.steerAngle, player.driftAngle, false, dt);

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
    // Pause trigger
    if (gui.isKeyPressed("KEY_ESCAPE") or gui.isKeyPressed("KEY_P")) {
      pauseSelection = 0;
      state = const.STATE_PAUSED;
      assets.playSfx(assets.sndSelect);
    }

    // Camera POV Cycle (C or V key)
    if (gui.isKeyPressed("KEY_C") or gui.isKeyPressed("KEY_V")) {
      cam.cyclePov();
      ui.setBanner("CAMERA POV: " + cam.getPovName(), "VIEW " + str(cam.pov + 1) + " OF " + str(cam_mod.TOTAL_POVS) + " // [C] TO SWITCH", 2.0, 0, 240, 255);
      assets.playSfx(assets.sndSelect);
    }

    // Autopilot AI toggle
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

    // 1. Update Player Vehicle
    player.updatePlayer(dt, track, particles, assets);
    if (player.wallHitShake > 0.0) {
      cam.addShake(player.wallHitShake);
      player.wallHitShake = 0.0;
    }
    distance = player.trackDistance;

    // Track scroll
    roadScroll = roadScroll + player.speed * dt;
    while (roadScroll > track.segmentLength) {
      roadScroll = roadScroll - track.segmentLength;
    }
    while (roadScroll < 0.0) {
      roadScroll = roadScroll + track.segmentLength;
    }

    track.update(player.speed, dt);
    particles.update(dt);

    // Dynamic Camera lookahead following road curve & elevation crests in forward or reverse
    let lookDist = 34.0 + (player.speed / 100.0) * 16.0;
    let lookAheadDist = lookDist;
    if (math.cos(player.heading) < 0.0) lookAheadDist = -lookDist;
    let lookCurve = track.getCurveOffset(-lookAheadDist, distance);
    let lookHill = track.getYOffset(-lookAheadDist, distance);
    if (math.cos(player.heading) < 0.0) lookCurve = -lookCurve;
    cam.setLookAhead(lookCurve, lookHill);
    cam.updateFollow(player.worldX, player.worldY, player.worldZ, player.speed, player.worldHeading, player.steerAngle, player.driftAngle, player.isBoosting, dt);

    let tSpec = const.getTrackSpec(selectedTrack);
    let lapDist = tSpec["length"];

    // 2. Outrun Mode: Checkpoint Countdown & Stage Transitions
    if (gameMode == const.MODE_OUTRUN) {
      outrunTimer = outrunTimer - dt;

      // Pass Checkpoint Gate
      if (distance >= nextGateDist) {
        outrunTimer = outrunTimer + 20.0;
        nextGateDist = nextGateDist + 600.0;
        outrunStage = outrunStage + 1;
        ui.setBanner("CHECKPOINT! +20 SECONDS", "STAGE " + str(outrunStage) + ": SPEEDWAY WEAVE", 3.0, 0, 255, 230);
        assets.playSfx(assets.sndCheckpoint);
        cam.addShake(0.3);
      }

      if (outrunTimer <= 0.0) {
        state = const.STATE_TIMEOUT;
        assets.playSfx(assets.sndCrash);
      }

      ui.setOutrunState(outrunTimer, outrunStage, nextGateDist, distance, totalNearMisses);
    }

    // 3. Time Attack Mode: Delta Split Tracking
    if (gameMode == const.MODE_TIME_ATTACK and bestLapTime > 0.0) {
      let lapProg = (distance - math.floor(distance / lapDist) * lapDist) / lapDist;
      let expectedPace = bestLapTime * lapProg;
      let delta = currentLapTime - expectedPace;
      ui.setTimeAttackDelta(delta);
    }

    // 4. Lap & Stopwatch Tracking on Closed Circuit
    currentLapTime = currentLapTime + dt;

    if (player.trackDistance > lapDist * 0.5) {
      playerMidpointCrossed = true;
    }
    if (playerMidpointCrossed and player.trackDistance < lapDist * 0.15) {
      // Completed Lap!
      playerMidpointCrossed = false;
      player.completedLaps = player.completedLaps + 1;
      if (bestLapTime == 0.0 or currentLapTime < bestLapTime) {
        bestLapTime = currentLapTime;
      }
      if (recordManager.submitLapTime(selectedTrack, currentLapTime)) {
        isNewRecord = true;
      }
      currentLapTime = 0.0;
      currentLap = currentLap + 1;
      assets.playSfx(assets.sndCheckpoint);

      if (gameMode != const.MODE_OUTRUN) {
        if (currentLap > totalLaps) {
          state = const.STATE_FINISH;
          assets.playSfx(assets.sndWin);
        } else if (currentLap == totalLaps) {
          ui.setBanner("FINAL LAP!", "FULL OVERDRIVE // SPRINT TO THE LINE", 3.0, 255, 220, 40);
        } else {
          ui.setBanner("LAP " + str(currentLap) + " / " + str(totalLaps), "PREV LAP: " + str(bestLapTime) + "s", 2.5, 0, 240, 255);
        }
      }
    }

    // 5. Update AI Rivals (Grand Prix Pack Racing & Lapping)
    if (gameMode == const.MODE_GRAND_PRIX) {
      let aheadCount = 0;
      for (let i = 0; i < len(rivals); i += 1) {
        let rCar = rivals[i];

        // Closed-circuit along-track distance wrapped around lapDist
        let dDist = rCar.trackDistance - player.trackDistance;
        while (dDist > lapDist * 0.5) dDist = dDist - lapDist;
        while (dDist < -lapDist * 0.5) dDist = dDist + lapDist;

        // Dynamic pack racing update with relative distance
        rCar.updateAi(dDist, player.speed, dt, track);
        rCar.z = -dDist;

        // Overall race progression (completed laps * lapDist + trackDistance)
        let playerTotalProg = (player.completedLaps * lapDist) + player.trackDistance;
        let rivalTotalProg = (rCar.completedLaps * lapDist) + rCar.trackDistance;
        if (rivalTotalProg > playerTotalProg) aheadCount = aheadCount + 1;

        // Bumper & Head-on Collision between Player and Rival
        let dZ = math.abs(rCar.z);
        let dX = math.abs(player.x - rCar.x);
        if (dZ < 3.2 and dX < 1.8) {
          let pushX = (player.x - rCar.x) * 10.0 * dt;
          if (math.abs(pushX) < 0.01) {
            if (player.x >= rCar.x) pushX = 0.04;
            else pushX = -0.04;
          }
          player.x = player.x + pushX;
          rCar.x = rCar.x - pushX;

          if (player.impactCooldown <= 0.0) {
            player.speed = player.speed * 0.92;
            player.impactCooldown = 0.35;
            cam.addShake(0.20);
            particles.emitSparks(player.worldX, player.worldY + 0.4, player.worldZ, 6);
            assets.playSfx(assets.sndCrash);
          }
        }
      }
      racePosition = aheadCount + 1;
      if (racePosition < prevPosition) {
        let posSuffix = "TH";
        if (racePosition == 1) posSuffix = "ST";
        else if (racePosition == 2) posSuffix = "ND";
        else if (racePosition == 3) posSuffix = "RD";
        ui.setBanner("+1 OVERTAKE!", "NOW IN " + str(racePosition) + posSuffix + " PLACE", 2.0, 255, 230, 80);
        assets.playSfx(assets.sndConfirm);
      }
      prevPosition = racePosition;
    }

    // 8. Update Traffic (Outrun Slalom)
    if (gameMode == const.MODE_OUTRUN) {
      for (let i = 0; i < len(trafficCars); i += 1) {
        let tf = trafficCars[i];
        tf.update(player.speed, dt);
        tf.syncPosition(track, distance);

        // Near-Miss Bonus check (weave close to civilian traffic at high speed)
        if (!tf.passed and tf.z > -1.8 and tf.z < 2.0 and player.speed > 50.0) {
          let latDist = math.abs(player.x - tf.x);
          if (latDist >= 1.5 and latDist < 2.8) {
            tf.passed = true;
            player.nitro = mu.clamp(player.nitro + 15.0, 0.0, player.maxNitro);
            player.nearMissTimer = 1.0;
            player.nearMissCount = player.nearMissCount + 1;
            totalNearMisses = totalNearMisses + 1;
            assets.playSfx(assets.sndNitro);
          }
        }

        if (tf.z > 16.0) {
          tf.z = -220.0 - mu.randFloat(10.0, 50.0);
          tf.x = mu.randFloat(-3.5, 3.5);
          tf.passed = false;
        }

        // Collision with Traffic Car
        if (tf.z > -2.4 and tf.z < 2.4 and math.abs(player.x - tf.x) < 1.6 and player.impactCooldown <= 0.0) {
          player.impactCooldown = 0.42;
          player.speed = player.speed * 0.90;
          player.hitFlash = 0.25;
          cam.addShake(0.35);
          particles.emitSparks(player.worldX, 0.5, player.z, 5);
          assets.playSfx(assets.sndCrash);
        }
      }
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
    // Left/Right on Option 2 (Camera POV)
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
    // Left/Right on Option 3 (AI Difficulty)
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
        state = const.STATE_RACE;
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

  // ---------------------------------------------------------------------------
  // 3D SCENE & 2D HUD RENDERING (DIRECT PASS)
  // ---------------------------------------------------------------------------
  let tSpec = const.getTrackSpec(selectedTrack);
  let lapDist = tSpec["length"];
  let sky = tSpec["skyColor"];
  let ground = tSpec["groundColor"];
  if (ground == nil) ground = [10, 12, 18];

  let scrW = gui.getScreenWidth();
  let scrH = gui.getScreenHeight();

  gui.beginDrawing();

  if (state == const.STATE_GARAGE) {
    gui.clearBackground(4, 6, 18);
  } else {
    gui.clearBackground(sky[0], sky[1], sky[2]);

    let skyTop = tSpec["skyTop"];
    if (skyTop == nil) skyTop = [6, 12, 32];
    let skyBottom = tSpec["skyBottom"];
    if (skyBottom == nil) skyBottom = [32, 50, 92];
    let fogCol = tSpec["fogColor"];
    if (fogCol == nil) fogCol = [24, 38, 68];

    // 2D Atmospheric Horizon Sky Gradient (Dynamic screen fill)
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

  cam.begin3DPass();

  if (state == const.STATE_GARAGE) {
    // Cyber Showroom Turntable
    gui.drawPlane3D(0.0, -0.2, 0.0, 100.0, 100.0, 12, 16, 28);
    gui.drawGrid(12, 1.2);
    assets.playCarModel(selectedCar, 0.0, 0.0, 0.0, t * 45.0, 1.45, 255, 255, 255);
  } else {
    // Ground Horizon Plane (covers entire circuit area right beneath the track)
    let groundAnchorX = player.worldX;
    let groundAnchorZ = player.worldZ;
    if (state == const.STATE_TITLE or state == const.STATE_TRACK_SELECT) {
      let st0 = track.stations[0];
      groundAnchorX = st0["x"];
      groundAnchorZ = st0["z"];
    }
    gui.drawPlane3D(groundAnchorX, -0.2, groundAnchorZ, 6000.0, 6000.0, ground[0], ground[1], ground[2]);

    // Draw Persistent Entire Track & Roadside Props
    track.draw(0.0, player.trackDistance, t, assets, cam);

    // Draw AI Rivals in World Space
    if (gameMode == const.MODE_GRAND_PRIX) {
      for (let i = 0; i < len(rivals); i += 1) {
        let rCar = rivals[i];
        let dDist = math.abs(rCar.trackDistance - player.trackDistance);
        while (dDist > lapDist * 0.5) dDist = dDist - lapDist;
        if (math.abs(dDist) < 280.0) {
          rCar.draw(assets, t);
        }
      }
    }

    // Draw Civilian Traffic
    if (gameMode == const.MODE_OUTRUN) {
      for (let i = 0; i < len(trafficCars); i += 1) {
        trafficCars[i].draw(assets);
      }
    }

    // Draw Player (in Bumper POV, camera is mounted out on front nose cone)
    if (cam.pov != cam_mod.POV_BUMPER) {
      player.draw(assets, t);
    }
  }

  // Draw 3D Particles
  particles.draw();

  cam.end3DPass();

  // Speed Lines Effect in Nitro Boost
  if (player.isBoosting and state == const.STATE_RACE) {
    for (let i = 0; i < 48; i += 1) {
      let lx = (i * 127 + math.floor(t * player.speed * 20)) % scrW;
      let ly = (i * 79 + math.floor(t * player.speed * 12)) % scrH;
      gui.drawLine(lx, ly, lx - 18, ly + 36, 0, 240, 255);
    }
  }

  // UI State Overlays
  ui.setMode(gameMode);

  if (state == const.STATE_TITLE) {
    ui.drawTitleScreen(t, gameMode);
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
    ui.drawHUD(player, currentLap, totalLaps, currentLapTime, bestLapTime, racePosition, len(rivals) + 1, (gameMode == const.MODE_GRAND_PRIX), t, distance, lapDist, rivals);
    ui.drawCountdown(countdownTimer);
  }
  else if (state == const.STATE_RACE) {
    ui.drawHUD(player, currentLap, totalLaps, currentLapTime, bestLapTime, racePosition, len(rivals) + 1, (gameMode == const.MODE_GRAND_PRIX), t, distance, lapDist, rivals);
  }
  else if (state == const.STATE_PAUSED) {
    ui.drawHUD(player, currentLap, totalLaps, currentLapTime, bestLapTime, racePosition, len(rivals) + 1, (gameMode == const.MODE_GRAND_PRIX), t, distance, lapDist, rivals);
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

// Cleanup and Exit
assets.unloadAll();
gui.closeWindow();
print("TURBO CIRCUIT: OVERDRIVE session exited cleanly.");
