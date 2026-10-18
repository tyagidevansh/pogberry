// TURBO CIRCUIT: OVERDRIVE — User Interface & Menus
use "pb_gui" as gui;
use "std.math" as math;
use "constants" as const;

export class UIRenderer {
  init() {
    this.updateDimensions();
    this.bannerTitle = "";
    this.bannerSub = "";
    this.bannerTimer = 0.0;
    this.bannerR = 255;
    this.bannerG = 255;
    this.bannerB = 255;
    this.gameMode = const.MODE_GRAND_PRIX;
    this.outrunTimer = 45.0;
    this.outrunStage = 1;
    this.nextGateDist = 600.0;
    this.timeAttackDelta = 0.0;
    this.outrunDistance = 0.0;
    this.totalNearMisses = 0;
  }

  updateDimensions() {
    this.w = gui.getScreenWidth();
    this.h = gui.getScreenHeight();
    if (this.w < 800) this.w = 800;
    if (this.h < 600) this.h = 600;
  }

  setMode(mode) {
    this.gameMode = mode;
  }

  setBanner(title, sub, duration, r, g, b) {
    this.bannerTitle = title;
    this.bannerSub = sub;
    this.bannerTimer = duration;
    this.bannerR = r;
    this.bannerG = g;
    this.bannerB = b;
  }

  setOutrunState(timer, stage, nextGate, dist, nearMisses) {
    this.outrunTimer = timer;
    this.outrunStage = stage;
    this.nextGateDist = nextGate;
    this.outrunDistance = dist;
    this.totalNearMisses = nearMisses;
  }

  setTimeAttackDelta(delta) {
    this.timeAttackDelta = delta;
  }

  updateBanners(dt) {
    if (this.bannerTimer > 0.0) {
      this.bannerTimer = this.bannerTimer - dt;
    }
  }

  drawTitleScreen(t, selectedMode) {
    gui.drawRectangleAlpha(0, 0, this.w, this.h, 2, 4, 14, 180);

    // Glowing Header Logo
    let pulse = 220 + math.floor(math.sin(t * 4.0) * 35.0);
    gui.drawText("TURBO // CIRCUIT", 80, 50, 60, 0, 240, pulse);
    gui.drawRectangle(80, 120, 240, 32, 255, 30, 120);
    gui.drawText("OVERDRIVE", 92, 124, 24, 255, 255, 255);

    gui.drawText("HIGH-SPEED ARCADE RACING IN POGBERRY", 84, 168, 18, 160, 190, 220);

    // Mode Selector Panels
    let modes = [
      {"title": "GRAND PRIX", "desc": "Race 5 AI rivals. Finish TOP 3 on podium to win."},
      {"title": "OUTRUN SLALOM", "desc": "Race the clock! Hit checkpoints for +20s and weave traffic."},
      {"title": "TIME ATTACK", "desc": "Solo hotlap trial. Beat the circuit record in 3 laps."}
    ];

    for (let i = 0; i < len(modes); i += 1) {
      let mX = 80;
      let mY = 230 + i * 110;
      let isSel = (i == selectedMode);

      if (isSel) {
        gui.drawRectangleAlpha(mX, mY, 700, 90, 20, 40, 80, 230);
        gui.drawRectangleLines(mX, mY, 700, 90, 0, 240, 255);
        gui.drawText("> " + modes[i]["title"], mX + 24, mY + 16, 28, 255, 240, 90);
        gui.drawText(modes[i]["desc"], mX + 54, mY + 52, 18, 220, 235, 255);
      } else {
        gui.drawRectangleAlpha(mX, mY, 700, 90, 12, 16, 32, 160);
        gui.drawRectangleLines(mX, mY, 700, 90, 50, 70, 100);
        gui.drawText("  " + modes[i]["title"], mX + 24, mY + 16, 26, 170, 190, 210);
        gui.drawText(modes[i]["desc"], mX + 54, mY + 52, 18, 120, 140, 160);
      }
    }

    // Controls Legend
    gui.drawRectangleAlpha(820, 230, 400, 330, 10, 14, 28, 200);
    gui.drawRectangleLines(820, 230, 400, 330, 0, 180, 220);
    gui.drawText("CONTROLS & DRIVING", 845, 250, 22, 0, 240, 255);
    gui.drawText("W / UP                : ACCELERATE (GAS)", 845, 290, 16, 255, 240, 90);
    gui.drawText("S / DOWN              : BRAKE / REVERSE", 845, 325, 16, 255, 120, 120);
    gui.drawText("A / D or LEFT / RIGHT : STEER", 845, 360, 16, 220, 230, 255);
    gui.drawText("SPACE / SHIFT         : NITRO OVERDRIVE", 845, 395, 16, 255, 140, 200);
    gui.drawText("S in CORNER           : POWER DRIFT", 845, 430, 16, 0, 240, 255);
    gui.drawText("RELEASE DRIFT         : MINI-TURBO BOOST", 845, 465, 16, 255, 200, 60);
    gui.drawText("ESC / P               : PAUSE MENU", 845, 500, 16, 160, 180, 200);
    gui.drawText("F11                   : FULLSCREEN", 845, 525, 15, 140, 160, 180);

    // Start prompt
    let promptPulse = 200 + math.floor(math.sin(t * 6.0) * 55.0);
    gui.drawText("W / S  CHOOSE MODE      ENTER / SPACE  LAUNCH", 82, 630, 24, 255, promptPulse, 70);
  }

  drawGarageScreen(selectedCar, spec, t) {
    gui.drawRectangleAlpha(0, 0, this.w, this.h, 4, 6, 18, 140);

    gui.drawText("NIGHT GARAGE", 80, 60, 48, 240, 250, 255);
    gui.drawText("INSPECT & SELECT YOUR MACHINE", 84, 116, 20, 0, 220, 255);

    // Car Cards along bottom
    for (let i = 0; i < const.TOTAL_CARS; i += 1) {
      let carInfo = const.getCarSpec(i);
      let cardW = 270;
      let cardX = 65 + i * 290;
      let cardY = 510;
      let isSel = (i == selectedCar);

      if (isSel) {
        gui.drawRectangleAlpha(cardX, cardY, cardW, 140, 24, 38, 70, 230);
        gui.drawRectangleLines(cardX, cardY, cardW, 140, 0, 240, 255);
        gui.drawText(carInfo["name"], cardX + 16, cardY + 16, 20, 255, 235, 90);
        gui.drawText(carInfo["subtitle"], cardX + 16, cardY + 44, 14, 200, 230, 255);
        gui.drawText("SPEED: " + str(math.floor(carInfo["topSpeed"])) + " MPH", cardX + 16, cardY + 76, 15, 0, 240, 255);
        gui.drawText("HULL: " + str(math.floor(carInfo["maxHull"])) + " HP", cardX + 16, cardY + 102, 15, 255, 100, 180);
      } else {
        gui.drawRectangleAlpha(cardX, cardY, cardW, 140, 10, 16, 30, 170);
        gui.drawRectangleLines(cardX, cardY, cardW, 140, 50, 70, 95);
        gui.drawText(carInfo["name"], cardX + 16, cardY + 16, 18, 160, 180, 200);
        gui.drawText(carInfo["subtitle"], cardX + 16, cardY + 44, 13, 120, 140, 160);
        gui.drawText("SPEED: " + str(math.floor(carInfo["topSpeed"])), cardX + 16, cardY + 76, 14, 140, 160, 180);
        gui.drawText("HULL: " + str(math.floor(carInfo["maxHull"])), cardX + 16, cardY + 102, 14, 180, 120, 140);
      }
    }

    // Vehicle Spec Radar / Detail Box (Top Right)
    let specX = 860;
    let specY = 60;
    gui.drawRectangleAlpha(specX, specY, 350, 240, 12, 18, 36, 210);
    gui.drawRectangleLines(specX, specY, 350, 240, 0, 200, 240);

    gui.drawText(spec["name"], specX + 20, specY + 20, 24, 255, 240, 100);
    gui.drawText(spec["subtitle"], specX + 20, specY + 52, 15, 180, 210, 240);

    // Stat bars
    this.drawStatBar(specX + 20, specY + 85, "TOP SPEED", spec["topSpeed"] / 125.0, 0, 240, 255);
    this.drawStatBar(specX + 20, specY + 120, "ACCELERATION", spec["accel"] / 45.0, 255, 200, 50);
    this.drawStatBar(specX + 20, specY + 155, "HANDLING/DRIFT", spec["driftRate"] / 3.0, 255, 60, 180);
    this.drawStatBar(specX + 20, specY + 190, "ARMOR HULL", spec["maxHull"] / 180.0, 60, 255, 120);

    // Instructions
    gui.drawText("A / D  CHOOSE MACHINE     ENTER  SELECT TRACK     ESC  BACK", 80, 672, 20, 255, 240, 90);
  }

  drawTrackSelectScreen(selectedTrack, trackSpec, recordManager, t) {
    gui.drawRectangleAlpha(0, 0, this.w, this.h, 4, 6, 18, 150);

    gui.drawText("CHAMPIONSHIP CIRCUIT SELECT", 80, 50, 48, 240, 250, 255);
    gui.drawText("CHOOSE YOUR BATTLEGROUND", 84, 106, 20, 255, 80, 180);

    for (let i = 0; i < const.TOTAL_TRACKS; i += 1) {
      let tInfo = const.getTrackSpec(i);
      let tX = 80;
      let tY = 145 + i * 122;
      let isSel = (i == selectedTrack);
      let recTime = 99.99;
      if (recordManager != nil) recTime = recordManager.getRecord(i);

      if (isSel) {
        gui.drawRectangleAlpha(tX, tY, 860, 106, 24, 38, 70, 230);
        gui.drawRectangleLines(tX, tY, 860, 106, 255, 80, 180);
        gui.drawText(tInfo["name"], tX + 24, tY + 14, 28, 255, 240, 90);
        gui.drawText(tInfo["subtitle"], tX + 24, tY + 48, 16, 200, 230, 255);
        gui.drawText("DIFFICULTY: " + tInfo["difficulty"] + "  //  " + str(tInfo["laps"]) + " LAPS", tX + 460, tY + 18, 17, 0, 240, 255);
        gui.drawText("RECORD: " + str(recTime) + "s", tX + 460, tY + 48, 18, 255, 220, 60);
      } else {
        gui.drawRectangleAlpha(tX, tY, 860, 106, 12, 16, 32, 170);
        gui.drawRectangleLines(tX, tY, 860, 106, 60, 70, 90);
        gui.drawText(tInfo["name"], tX + 24, tY + 14, 24, 170, 190, 210);
        gui.drawText(tInfo["subtitle"], tX + 24, tY + 48, 16, 120, 140, 160);
        gui.drawText("DIFFICULTY: " + tInfo["difficulty"], tX + 460, tY + 18, 17, 140, 160, 180);
        gui.drawText("RECORD: " + str(recTime) + "s", tX + 460, tY + 48, 17, 180, 170, 100);
      }
    }

    gui.drawText("W / S  CHOOSE TRACK     ENTER  IGNITE ENGINES     ESC  BACK", 80, 655, 22, 255, 230, 90);
  }

  drawStatBar(x, y, label, ratio, r, g, b) {
    if (ratio > 1.0) ratio = 1.0;
    if (ratio < 0.0) ratio = 0.0;
    gui.drawText(label, x, y, 14, 180, 200, 220);
    let barX = x + 150;
    let barW = 160;
    let barH = 12;
    gui.drawRectangle(barX, y + 2, barW, barH, 20, 25, 40);
    gui.drawRectangle(barX, y + 2, math.floor(barW * ratio), barH, r, g, b);
    gui.drawRectangleLines(barX, y + 2, barW, barH, 70, 85, 110);
  }

  drawCountdown(countdownTimer) {
    let countNum = math.ceil(countdownTimer);
    let text = str(countNum);
    let r = 255; let g = 220; let b = 40;
    let size = 96;

    if (countdownTimer <= 0.8) {
      text = "OVERDRIVE!";
      r = 0; g = 255; b = 230;
      size = 80;
    }

    let tw = gui.measureText(text, size);
    let tx = math.floor((this.w - tw) * 0.5);
    let ty = 250;

    gui.drawRectangleAlpha(tx - 30, ty - 20, tw + 60, size + 40, 6, 10, 24, 210);
    gui.drawRectangleLines(tx - 30, ty - 20, tw + 60, size + 40, r, g, b);
    gui.drawText(text, tx, ty, size, r, g, b);
  }

  drawHUD(player, lap, totalLaps, lapTime, bestLap, pos, totalRacers, isGrandPrix, t, distance, lapLength, rivals) {
    // 1. Speedometer & Tachometer (Bottom Right)
    let gaugeX = this.w - 300;
    let gaugeY = this.h - 180;
    gui.drawRectangleAlpha(gaugeX, gaugeY, 275, 155, 8, 12, 26, 215);
    gui.drawRectangleLines(gaugeX, gaugeY, 275, 155, 0, 220, 255);

    let mph = math.floor(math.abs(player.speed) * 1.6);
    gui.drawText(str(mph), gaugeX + 20, gaugeY + 14, 56, 255, 255, 255);
    gui.drawText("MPH", gaugeX + 155, gaugeY + 46, 20, 0, 220, 255);

    // RPM Bar
    let rpmRatio = math.abs(player.speed) / player.maxSpeed;
    if (rpmRatio > 1.0) rpmRatio = 1.0;
    gui.drawRectangle(gaugeX + 20, gaugeY + 80, 235, 10, 30, 40, 60);
    let rpmColR = math.floor(rpmRatio * 255);
    let rpmColG = math.floor((1.0 - rpmRatio) * 255);
    gui.drawRectangle(gaugeX + 20, gaugeY + 80, math.floor(235 * rpmRatio), 10, rpmColR, rpmColG, 40);

    // Gear indicator & Reverse
    if (player.isReversing) {
      let rPulse = 180 + math.floor(math.sin(t * 12.0) * 75.0);
      gui.drawText("GEAR [R]", gaugeX + 20, gaugeY + 98, 18, 255, rPulse, 40);
    } else {
      let gear = 1;
      if (player.speed > 80.0) gear = 4;
      else if (player.speed > 55.0) gear = 3;
      else if (player.speed > 25.0) gear = 2;
      gui.drawText("GEAR " + str(gear), gaugeX + 20, gaugeY + 98, 16, 200, 220, 240);
    }

    if (player.isBoosting) {
      gui.drawText("// NITRO OVERDRIVE", gaugeX + 105, gaugeY + 98, 14, 255, 80, 200);
    } else if (player.isDrifting) {
      gui.drawText("// POWER DRIFT", gaugeX + 105, gaugeY + 98, 14, 0, 240, 255);
    }

    // Subtle controls reminder
    gui.drawText("W:GAS  S:BRAKE/REV  A/D:STEER", gaugeX + 20, gaugeY + 128, 13, 140, 165, 190);

    // 2. Nitro Overdrive Gauge (Bottom Center)
    let nitroX = math.floor(this.w * 0.5) - 170;
    let nitroY = this.h - 58;
    gui.drawRectangleAlpha(nitroX, nitroY, 340, 44, 8, 12, 26, 210);
    gui.drawRectangleLines(nitroX, nitroY, 340, 44, 255, 60, 180);

    let nitroRatio = player.nitro / player.maxNitro;
    gui.drawRectangle(nitroX + 10, nitroY + 10, math.floor(320 * nitroRatio), 24, 0, 240, 255);
    gui.drawText("NITRO [SPACE/SHIFT]", nitroX + 16, nitroY + 14, 15, 255, 255, 255);

    // 3. Hull Integrity (Bottom Left)
    let hullX = 30;
    let hullY = this.h - 58;
    gui.drawRectangleAlpha(hullX, hullY, 260, 44, 8, 12, 26, 210);
    gui.drawRectangleLines(hullX, hullY, 260, 44, 255, 60, 60);

    let hullRatio = player.hull / player.maxHull;
    if (hullRatio < 0.0) hullRatio = 0.0;
    let hullColR = 40; let hullColG = 255; let hullColB = 100;
    if (hullRatio < 0.35) { hullColR = 255; hullColG = 40; hullColB = 40; }
    gui.drawRectangle(hullX + 10, hullY + 10, math.floor(240 * hullRatio), 24, hullColR, hullColG, hullColB);
    gui.drawText("HULL: " + str(math.floor(player.hull)) + " HP", hullX + 16, hullY + 14, 16, 255, 255, 255);

    // 4. Position & Lap Info (Top Left)
    let infoX = 30;
    let infoY = 24;
    gui.drawRectangleAlpha(infoX, infoY, 310, 115, 8, 12, 26, 215);
    gui.drawRectangleLines(infoX, infoY, 310, 115, 0, 220, 255);

    if (this.gameMode == const.MODE_GRAND_PRIX) {
      let posSuffix = "TH";
      let posColor = [255, 255, 255];
      if (pos == 1) { posSuffix = "ST"; posColor = [255, 220, 40]; }
      else if (pos == 2) { posSuffix = "ND"; posColor = [220, 230, 255]; }
      else if (pos == 3) { posSuffix = "RD"; posColor = [240, 140, 60]; }

      gui.drawText(str(pos) + posSuffix, infoX + 18, infoY + 16, 44, posColor[0], posColor[1], posColor[2]);
      gui.drawText("/ " + str(totalRacers), infoX + 120, infoY + 34, 24, 180, 200, 220);
      gui.drawText("LAP " + str(lap) + " / " + str(totalLaps), infoX + 18, infoY + 76, 20, 0, 240, 255);
    } else if (this.gameMode == const.MODE_OUTRUN) {
      gui.drawText("OUTRUN HIGHWAY", infoX + 18, infoY + 16, 26, 255, 80, 180);
      gui.drawText("STAGE " + str(this.outrunStage), infoX + 18, infoY + 50, 22, 255, 220, 50);
      gui.drawText("DISTANCE: " + str(math.floor(distance)) + " M", infoX + 18, infoY + 80, 18, 0, 240, 255);
    } else {
      // Time Attack
      gui.drawText("TIME ATTACK", infoX + 18, infoY + 16, 28, 255, 220, 60);
      gui.drawText("LAP " + str(lap) + " / " + str(totalLaps), infoX + 18, infoY + 54, 20, 0, 240, 255);
      gui.drawText("SOLO RECORD TRIAL", infoX + 18, infoY + 82, 16, 180, 200, 220);
    }

    // 5. Stopwatch / Clock (Top Right)
    let timeX = this.w - 280;
    let timeY = 24;
    gui.drawRectangleAlpha(timeX, timeY, 250, 75, 8, 12, 26, 215);
    gui.drawRectangleLines(timeX, timeY, 250, 75, 255, 220, 60);

    let sec = math.floor(lapTime);
    let ms = math.floor((lapTime - sec) * 100);
    let secStr = str(sec);
    if (sec < 10) secStr = "0" + secStr;
    let msStr = str(ms);
    let timeLabel = "TIME: ";
    if (this.gameMode == const.MODE_OUTRUN) {
      timeLabel = "ELAPSED: ";
    }
    gui.drawText(timeLabel + secStr + "." + msStr, timeX + 16, timeY + 16, 21, 255, 255, 255);

    if (bestLap > 0.0) {
      let bSec = math.floor(bestLap);
      let bMs = math.floor((bestLap - bSec) * 100);
      gui.drawText("BEST: " + str(bSec) + "." + str(bMs), timeX + 16, timeY + 45, 17, 255, 220, 60);
    }

    // 6. Top-Center Mode Special Indicator
    if (this.gameMode == const.MODE_OUTRUN) {
      // Prominent Arcade Outrun Timer
      let oTimerW = 280;
      let oTimerH = 75;
      let oTimerX = math.floor((this.w - oTimerW) * 0.5);
      let oTimerY = 24;

      let timerR = 0; let timerG = 240; let timerB = 255;
      if (this.outrunTimer <= 10.0) {
        let tPulse = 180 + math.floor(math.sin(t * 14.0) * 75.0);
        timerR = 255; timerG = tPulse; timerB = 40;
      }

      gui.drawRectangleAlpha(oTimerX, oTimerY, oTimerW, oTimerH, 8, 12, 26, 230);
      gui.drawRectangleLines(oTimerX, oTimerY, oTimerW, oTimerH, timerR, timerG, timerB);

      let tSec = math.floor(this.outrunTimer);
      let tTenth = math.floor((this.outrunTimer - tSec) * 10);
      if (tTenth < 0) tTenth = 0;
      let tStr = "TIME " + str(tSec) + "." + str(tTenth) + "s";
      gui.drawText(tStr, oTimerX + 22, oTimerY + 14, 32, timerR, timerG, timerB);

      let toGate = math.floor(this.nextGateDist - distance);
      if (toGate < 0) toGate = 0;
      gui.drawText("NEXT GATE: " + str(toGate) + " M", oTimerX + 26, oTimerY + 50, 16, 220, 235, 255);
    } else if (this.gameMode == const.MODE_TIME_ATTACK and bestLap > 0.0) {
      // Time Attack Delta split indicator
      let dBoxW = 220;
      let dBoxX = math.floor((this.w - dBoxW) * 0.5);
      let dBoxY = 24;

      let delR = 40; let delG = 255; let delB = 120;
      let delPrefix = "-";
      let absDel = math.abs(this.timeAttackDelta);
      if (this.timeAttackDelta > 0.0) {
        delR = 255; delG = 80; delB = 80;
        delPrefix = "+";
      }

      gui.drawRectangleAlpha(dBoxX, dBoxY, dBoxW, 55, 8, 12, 26, 215);
      gui.drawRectangleLines(dBoxX, dBoxY, dBoxW, 55, delR, delG, delB);

      let dSec = math.floor(absDel);
      let dMs = math.floor((absDel - dSec) * 100);
      let dStr = "DELTA " + delPrefix + str(dSec) + "." + str(dMs) + "s";
      gui.drawText(dStr, dBoxX + 16, dBoxY + 16, 20, delR, delG, delB);
    }

    // 7. Dynamic Banner Notification (Center Top)
    if (this.bannerTimer > 0.0) {
      let bW = 680;
      let bH = 80;
      let bX = math.floor((this.w - bW) * 0.5);
      let bY = 160;

      gui.drawRectangleAlpha(bX, bY, bW, bH, 10, 14, 32, 235);
      gui.drawRectangleLines(bX, bY, bW, bH, this.bannerR, this.bannerG, this.bannerB);

      let tw = gui.measureText(this.bannerTitle, 30);
      gui.drawText(this.bannerTitle, math.floor((this.w - tw) * 0.5), bY + 12, 30, this.bannerR, this.bannerG, this.bannerB);

      let sw = gui.measureText(this.bannerSub, 18);
      gui.drawText(this.bannerSub, math.floor((this.w - sw) * 0.5), bY + 48, 18, 220, 235, 255);
    }

    // 8. Drift Combo Notification
    if (player.driftPoints > 0) {
      let dText = "DRIFT +" + str(player.driftPoints) + " PTS";
      gui.drawText(dText, math.floor(this.w * 0.5) - 80, this.h - 110, 24, 255, 220, 50);
    }

    // 9. Minimap Track Progress Rail (Left Edge)
    let mapX = 30;
    let mapY = 160;
    let mapH = 260;
    let mapW = 28;

    gui.drawRectangleAlpha(mapX - 6, mapY - 16, mapW + 12, mapH + 32, 8, 12, 26, 190);
    gui.drawRectangleLines(mapX - 6, mapY - 16, mapW + 12, mapH + 32, 40, 60, 90);

    let railCenterX = mapX + math.floor(mapW * 0.5);
    gui.drawLine(railCenterX, mapY, railCenterX, mapY + mapH, 0, 220, 255);

    // Finish Gate
    gui.drawRectangle(mapX, mapY - 4, mapW, 6, 255, 220, 40);
    gui.drawText("FIN", mapX + 3, mapY - 18, 11, 255, 220, 60);

    // Start Line
    gui.drawRectangle(mapX, mapY + mapH - 2, mapW, 6, 0, 240, 255);

    if (lapLength > 0.0) {
      // Draw AI Rivals
      if (this.gameMode == const.MODE_GRAND_PRIX and rivals != nil) {
        for (let i = 0; i < len(rivals); i += 1) {
          let rCar = rivals[i];
          let rProg = (rCar.trackDistance - math.floor(rCar.trackDistance / lapLength) * lapLength) / lapLength;
          if (rProg >= 0.0 and rProg <= 1.0) {
            let rDotY = mapY + mapH - math.floor(rProg * mapH);
            gui.drawCircle(railCenterX, rDotY, 4.0, 255, 90, 90);
          }
        }
      }

      // Draw Player Position
      let lapProg = (distance - math.floor(distance / lapLength) * lapLength) / lapLength;
      if (lapProg < 0.0) lapProg = 0.0;
      if (lapProg > 1.0) lapProg = 1.0;
      let pY = mapY + mapH - math.floor(lapProg * mapH);
      gui.drawCircle(railCenterX, pY, 7.0, 0, 240, 255);
      gui.drawCircle(railCenterX, pY, 4.0, 255, 255, 255);
    }

    // 10. Near Miss Alert
    if (player.nearMissTimer > 0.0) {
      let nmPulse = 200 + math.floor(math.sin(t * 15.0) * 55.0);
      gui.drawText("NEAR MISS! +15 NITRO", math.floor(this.w * 0.5) - 130, 260, 24, 255, nmPulse, 40);
    }
  }

  drawPauseMenu(selectedOption) {
    gui.drawRectangleAlpha(0, 0, this.w, this.h, 2, 4, 12, 200);

    let mX = math.floor(this.w * 0.5) - 200;
    let mY = 200;
    gui.drawRectangleAlpha(mX, mY, 400, 280, 16, 24, 48, 240);
    gui.drawRectangleLines(mX, mY, 400, 280, 0, 240, 255);

    gui.drawText("PAUSED", mX + 120, mY + 30, 42, 255, 255, 255);

    let options = ["RESUME RACE", "RESTART TRACK", "RETURN TO GARAGE"];
    for (let i = 0; i < len(options); i += 1) {
      let optY = mY + 110 + i * 50;
      if (i == selectedOption) {
        gui.drawText("> " + options[i], mX + 50, optY, 22, 255, 230, 80);
      } else {
        gui.drawText("  " + options[i], mX + 50, optY, 20, 170, 190, 210);
      }
    }
  }

  drawResultsScreen(position, totalRacers, bestLap, trackRecord, isNewRecord, t) {
    gui.drawRectangleAlpha(0, 0, this.w, this.h, 4, 6, 18, 200);

    let pX = math.floor(this.w * 0.5) - 300;
    let pY = 110;
    gui.drawRectangleAlpha(pX, pY, 600, 470, 16, 24, 48, 240);
    gui.drawRectangleLines(pX, pY, 600, 470, 255, 220, 60);

    if (this.gameMode == const.MODE_GRAND_PRIX) {
      let titleText = "GRAND PRIX COMPLETED";
      let titleColor = [255, 240, 90];
      if (position <= 3) {
        titleText = "PODIUM VICTORY!";
        titleColor = [255, 220, 40];
      }

      gui.drawText(titleText, pX + 50, pY + 36, 38, titleColor[0], titleColor[1], titleColor[2]);
      gui.drawText("FINAL PLACEMENT: " + str(position) + " / " + str(totalRacers), pX + 50, pY + 100, 28, 255, 255, 255);

      let medalStr = "ADVANCED // PODIUM FINISH";
      let medalCol = [255, 220, 40];
      if (position == 1) { medalStr = "1ST PLACE: GOLD CHAMPION"; medalCol = [255, 220, 40]; }
      else if (position == 2) { medalStr = "2ND PLACE: SILVER RUNNER-UP"; medalCol = [220, 230, 255]; }
      else if (position == 3) { medalStr = "3RD PLACE: BRONZE PODIUM"; medalCol = [240, 140, 60]; }
      else { medalStr = "UNRANKED // NEED TOP 3 TO ADVANCE"; medalCol = [255, 90, 90]; }

      gui.drawText(medalStr, pX + 50, pY + 150, 22, medalCol[0], medalCol[1], medalCol[2]);
    } else if (this.gameMode == const.MODE_OUTRUN) {
      gui.drawText("OUTRUN HIGHWAY SUMMARY", pX + 50, pY + 36, 36, 255, 80, 180);
      gui.drawText("STAGES CLEARED: " + str(this.outrunStage), pX + 50, pY + 100, 26, 255, 240, 90);
      gui.drawText("TOTAL DISTANCE: " + str(math.floor(this.outrunDistance)) + " M", pX + 50, pY + 145, 24, 0, 240, 255);
      gui.drawText("CIVILIAN NEAR MISSES: " + str(this.totalNearMisses), pX + 50, pY + 185, 22, 220, 235, 255);
    } else {
      // Time Attack
      gui.drawText("TIME ATTACK RECORD TRIAL", pX + 50, pY + 36, 36, 255, 220, 60);
      gui.drawText("3 LAPS COMPLETED", pX + 50, pY + 100, 26, 255, 255, 255);
    }

    let bSec = math.floor(bestLap);
    let bMs = math.floor((bestLap - bSec) * 100);
    gui.drawText("BEST LAP TIME: " + str(bSec) + "." + str(bMs) + "s", pX + 50, pY + 235, 22, 0, 240, 255);

    if (isNewRecord) {
      let recPulse = 200 + math.floor(math.sin(t * 12.0) * 55.0);
      gui.drawText(">> NEW TRACK RECORD! <<", pX + 50, pY + 285, 26, 255, recPulse, 40);
    } else if (trackRecord > 0.0) {
      gui.drawText("TRACK RECORD: " + str(trackRecord) + "s", pX + 50, pY + 285, 20, 180, 200, 220);
    }

    gui.drawText("ENTER  CONTINUE TO GARAGE", pX + 80, pY + 390, 24, 255, 230, 80);
  }

  drawTimeoutScreen(t) {
    gui.drawRectangleAlpha(0, 0, this.w, this.h, 24, 6, 12, 190);

    let pX = math.floor(this.w * 0.5) - 280;
    let pY = 140;
    gui.drawRectangleAlpha(pX, pY, 560, 380, 20, 12, 28, 240);
    gui.drawRectangleLines(pX, pY, 560, 380, 255, 60, 80);

    let tPulse = 200 + math.floor(math.sin(t * 8.0) * 55.0);
    gui.drawText("TIME OUT // GAME OVER", pX + 50, pY + 35, 36, 255, tPulse, 60);
    gui.drawText("FAILED TO REACH NEXT CHECKPOINT", pX + 50, pY + 85, 18, 220, 220, 230);

    gui.drawText("STAGES CLEARED: " + str(this.outrunStage), pX + 50, pY + 140, 24, 255, 240, 90);
    gui.drawText("DISTANCE REACHED: " + str(math.floor(this.outrunDistance)) + " M", pX + 50, pY + 185, 22, 0, 240, 255);
    gui.drawText("CIVILIAN NEAR MISSES: " + str(this.totalNearMisses), pX + 50, pY + 225, 22, 255, 140, 200);

    let prompt = "PRESS ENTER TO RETURN TO GARAGE";
    let pw = gui.measureText(prompt, 22);
    gui.drawText(prompt, math.floor((this.w - pw) * 0.5), pY + 310, 22, 255, 255, 255);
  }

  drawCrashedScreen(t) {
    gui.drawRectangleAlpha(0, 0, this.w, this.h, 25, 0, 0, 175);

    let pulse = 200 + math.floor(math.sin(t * 8.0) * 55.0);
    let text = "HULL CRITICAL // MACHINE TOTALED";
    let tw = gui.measureText(text, 44);
    gui.drawText(text, math.floor((this.w - tw) * 0.5), 280, 44, 255, pulse, pulse);

    let prompt = "PRESS ENTER TO RETURN TO GARAGE";
    let pw = gui.measureText(prompt, 24);
    gui.drawText(prompt, math.floor((this.w - pw) * 0.5), 370, 24, 255, 255, 255);
  }
}
