use "pb_gui" as gui;
use "std.math" as math;
use "data/constants" as const;

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
    this.timeAttackDelta = 0.0;
    this.trackId = 0;
    this.inCockpit = false;
  }

  setTrackId(trackId) {
    this.trackId = trackId;
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

  setTimeAttackDelta(delta) {
    this.timeAttackDelta = delta;
  }

  updateBanners(dt) {
    if (this.bannerTimer > 0.0) {
      this.bannerTimer = this.bannerTimer - dt;
    }
  }

  drawTitleScreen(t, selectedMode, aiDifficulty, pov) {
    if (aiDifficulty == nil) aiDifficulty = 1;
    if (pov == nil) pov = 0;

    gui.drawRectangleAlpha(0, 0, this.w, this.h, 2, 4, 14, 180);

    let pulse = 220 + math.floor(math.sin(t * 4.0) * 35.0);
    gui.drawText("PB SPORTS", 80, 42, 54, 0, 240, pulse);
    gui.drawRectangle(80, 104, 150, 28, 255, 30, 120);
    gui.drawText("F1 25", 90, 108, 21, 255, 255, 255);
    gui.drawText("IT'S IN THE BERRY // OFFICIAL FIA FORMULA 1 RACING", 82, 144, 16, 160, 190, 220);

    let modes = [
      {"title": "GRAND PRIX", "desc": "Race 5 F1 constructor rivals. Finish top 3 on podium to win."},
      {"title": "TIME ATTACK", "desc": "Solo hotlap trial. Beat the circuit record in 3 laps."},
      {"title": "REALISTIC GP", "desc": "High realism. Hard impact with walls or rivals ends race."}
    ];

    for (let i = 0; i < len(modes); i += 1) {
      let mX = 80;
      let mY = 174 + i * 58;
      let isSel = (i == selectedMode);

      if (isSel) {
        gui.drawRectangleAlpha(mX, mY, 710, 52, 20, 40, 80, 235);
        gui.drawRectangleLines(mX, mY, 710, 52, 0, 240, 255);
        gui.drawText("> " + modes[i]["title"], mX + 18, mY + 9, 20, 255, 240, 90);
        gui.drawText(modes[i]["desc"], mX + 42, mY + 31, 14, 220, 235, 255);
      } else {
        gui.drawRectangleAlpha(mX, mY, 710, 52, 12, 16, 32, 160);
        gui.drawRectangleLines(mX, mY, 710, 52, 50, 70, 100);
        gui.drawText("  " + modes[i]["title"], mX + 18, mY + 9, 19, 170, 190, 210);
        gui.drawText(modes[i]["desc"], mX + 42, mY + 31, 14, 120, 140, 160);
      }
    }

    let diffY = 360;
    gui.drawText("AI COMPETITION DIFFICULTY   [A / D OR CLICK]", 82, diffY, 15, 0, 240, 255);
    let diffs = [
      {"name": "ROOKIE", "sub": "EASY // 78% PACE"},
      {"name": "PRO RACER", "sub": "MEDIUM // 105% RACE PACE"},
      {"name": "WORLD CHAMPION", "sub": "HARD // 120% F1 PACE"}
    ];
    let pillW = 226;
    for (let d = 0; d < 3; d += 1) {
      let pX = 80 + d * 242;
      let pY = diffY + 22;
      let isD = (d == aiDifficulty);
      if (isD) {
        gui.drawRectangleAlpha(pX, pY, pillW, 46, 24, 48, 88, 235);
        gui.drawRectangleLines(pX, pY, pillW, 46, 255, 220, 40);
        gui.drawText("[ " + diffs[d]["name"] + " ]", pX + 16, pY + 8, 17, 255, 230, 80);
        gui.drawText(diffs[d]["sub"], pX + 20, pY + 28, 12, 200, 240, 255);
      } else {
        gui.drawRectangleAlpha(pX, pY, pillW, 46, 12, 16, 30, 170);
        gui.drawRectangleLines(pX, pY, pillW, 46, 60, 70, 90);
        gui.drawText("  " + diffs[d]["name"], pX + 16, pY + 8, 16, 160, 180, 200);
        gui.drawText(diffs[d]["sub"], pX + 20, pY + 28, 12, 110, 130, 150);
      }
    }

    let povY = 442;
    gui.drawText("CAMERA VIEW PERSPECTIVE   [C KEY OR CLICK]", 82, povY, 15, 0, 240, 255);
    let povNames = ["COCKPIT", "CHASE 1", "CHASE 2", "HOOD", "BUMPER"];
    let povSubs = ["IN-CAR", "CLOSE", "FAR", "FRONT", "LOW NOSE"];
    let povW = 136;
    for (let p = 0; p < 5; p += 1) {
      let pX = 80 + p * 143;
      let pY = povY + 22;
      let isP = (p == pov);
      if (isP) {
        gui.drawRectangleAlpha(pX, pY, povW, 46, 30, 52, 95, 235);
        gui.drawRectangleLines(pX, pY, povW, 46, 0, 240, 255);
        gui.drawText(povNames[p], pX + 10, pY + 8, 16, 255, 240, 90);
        gui.drawText(povSubs[p], pX + 12, pY + 28, 12, 180, 235, 255);
      } else {
        gui.drawRectangleAlpha(pX, pY, povW, 46, 12, 16, 30, 170);
        gui.drawRectangleLines(pX, pY, povW, 46, 60, 70, 90);
        gui.drawText(povNames[p], pX + 10, pY + 8, 15, 150, 170, 190);
        gui.drawText(povSubs[p], pX + 12, pY + 28, 12, 100, 120, 140);
      }
    }

    let btnY = 525;
    let btnPulse = 200 + math.floor(math.sin(t * 5.0) * 55.0);
    gui.drawRectangleAlpha(80, btnY, 440, 58, 20, 50, 90, 235);
    gui.drawRectangleLines(80, btnY, 440, 58, 0, btnPulse, 255);
    gui.drawText("[ ENTER GARAGE -> ]", 150, btnY + 16, 22, 255, 240, 90);

    gui.drawRectangleAlpha(535, btnY, 255, 58, 24, 40, 75, 235);
    gui.drawRectangleLines(535, btnY, 255, 58, 0, 240, 255);
    gui.drawText("TRACK EDITOR [E]", 560, btnY + 18, 18, 0, 240, 255);

    gui.drawText("CLICK ANY CARD TO SELECT      PRESS ENTER TO LAUNCH      E TRACK EDITOR", 84, 605, 16, 180, 210, 240);

    let cX = 815;
    let cY = 178;
    let cW = 395;
    let cH = 445;
    gui.drawRectangleAlpha(cX, cY, cW, cH, 10, 14, 28, 210);
    gui.drawRectangleLines(cX, cY, cW, cH, 0, 180, 220);
    gui.drawText("CONTROLS & SHORTCUTS", cX + 24, cY + 18, 20, 0, 240, 255);

    let ctrlList = [
      ["MOUSE CLICK", "SELECT OPTIONS & LAUNCH"],
      ["W / UP", "ACCELERATE (GAS)"],
      ["S / DOWN", "BRAKE / REVERSE"],
      ["A / D / ARROWS", "STEER LEFT / RIGHT"],
      ["SPACE", "BATTERY DEPLOY"],
      ["C / V", "CYCLE CAMERA PERSPECTIVE"],
      ["O", "TOGGLE AI AUTOPILOT DEMO"],
      ["ESC / P", "PAUSE MENU"],
      ["F11", "FULLSCREEN TOGGLE"]
    ];

    for (let c = 0; c < len(ctrlList); c += 1) {
      let rowY = cY + 54 + c * 33;
      gui.drawText(ctrlList[c][0], cX + 22, rowY, 15, 255, 230, 90);
      gui.drawText(ctrlList[c][1], cX + 165, rowY, 14, 220, 230, 245);
    }

    gui.drawRectangleAlpha(cX + 16, cY + 365, cW - 32, 60, 16, 22, 40, 200);
    gui.drawText("FORMULA 1 WORLD TOUR CIRCUITS", cX + 26, cY + 374, 13, 0, 240, 255);
    gui.drawText("SUZUKA // MONACO // SPA // MONZA", cX + 26, cY + 398, 14, 255, 255, 255);
  }

  drawGarageScreen(selectedCar, spec, t) {
    gui.drawRectangleAlpha(0, 0, this.w, this.h, 4, 6, 18, 140);

    gui.drawText("F1 PADDOCK GARAGE", 80, 60, 48, 240, 250, 255);
    gui.drawText("OFFICIAL CONSTRUCTOR LINEUP", 84, 116, 20, 0, 220, 255);

    for (let i = 0; i < const.TOTAL_CARS; i += 1) {
      let carInfo = const.getCarSpec(i);
      let cardW = 270;
      let cardX = 65 + i * 290;
      let cardY = 510;
      let isSel = (i == selectedCar);
      let pCol = carInfo["primaryColor"];
      let gCol = carInfo["glowColor"];
      let teamName = carInfo["team"];
      if (teamName == nil) teamName = "CONSTRUCTOR";

      if (isSel) {
        gui.drawRectangleAlpha(cardX, cardY, cardW, 140, 24, 38, 70, 230);
        gui.drawRectangleLines(cardX, cardY, cardW, 140, pCol[0], pCol[1], pCol[2]);
        gui.drawRectangle(cardX, cardY, cardW, 4, pCol[0], pCol[1], pCol[2]);
        gui.drawRectangle(cardX, cardY + 4, 4, 136, gCol[0], gCol[1], gCol[2]);
        gui.drawText(teamName, cardX + 16, cardY + 12, 11, gCol[0], gCol[1], gCol[2]);
        gui.drawText(carInfo["name"], cardX + 16, cardY + 28, 19, 255, 235, 90);
        gui.drawText(carInfo["subtitle"], cardX + 16, cardY + 54, 13, 200, 230, 255);
        gui.drawText("CRUISE: " + str(math.floor(carInfo["topSpeed"] * 1.60934)) + " KPH", cardX + 16, cardY + 82, 14, 0, 240, 255);
        gui.drawText("BATTERY: " + str(math.floor(carInfo["boostSpeed"] * 1.60934)) + " KPH", cardX + 16, cardY + 106, 14, 0, 240, 255);
      } else {
        gui.drawRectangleAlpha(cardX, cardY, cardW, 140, 10, 16, 30, 170);
        gui.drawRectangleLines(cardX, cardY, cardW, 140, 50, 70, 95);
        gui.drawRectangle(cardX, cardY, cardW, 3, pCol[0], pCol[1], pCol[2]);
        gui.drawText(teamName, cardX + 16, cardY + 12, 11, 140, 160, 180);
        gui.drawText(carInfo["name"], cardX + 16, cardY + 28, 17, 160, 180, 200);
        gui.drawText(carInfo["subtitle"], cardX + 16, cardY + 54, 12, 120, 140, 160);
        gui.drawText("CRUISE: " + str(math.floor(carInfo["topSpeed"] * 1.60934)) + " KPH", cardX + 16, cardY + 82, 14, 140, 160, 180);
        gui.drawText("BATTERY: " + str(math.floor(carInfo["boostSpeed"] * 1.60934)) + " KPH", cardX + 16, cardY + 106, 14, 140, 180, 200);
      }
    }

    let specX = 860;
    let specY = 60;
    let specPrimary = spec["primaryColor"];
    let specGlow = spec["glowColor"];
    let specTeam = spec["team"];
    if (specTeam == nil) specTeam = "CONSTRUCTOR SPECIFICATION";

    gui.drawRectangleAlpha(specX, specY, 350, 240, 12, 18, 36, 210);
    gui.drawRectangleLines(specX, specY, 350, 240, specPrimary[0], specPrimary[1], specPrimary[2]);
    gui.drawRectangle(specX, specY, 350, 4, specPrimary[0], specPrimary[1], specPrimary[2]);

    gui.drawText(specTeam, specX + 20, specY + 14, 12, specGlow[0], specGlow[1], specGlow[2]);
    gui.drawText(spec["name"], specX + 20, specY + 32, 24, 255, 240, 100);
    gui.drawText(spec["subtitle"], specX + 20, specY + 60, 14, 180, 210, 240);

    this.drawStatBar(specX + 20, specY + 88, "CRUISE SPEED", spec["topSpeed"] / 180.0, 0, 240, 255);
    this.drawStatBar(specX + 20, specY + 122, "ACCELERATION", spec["accel"] / 48.0, 255, 200, 50);
    this.drawStatBar(specX + 20, specY + 156, "HANDLING", spec["handling"] / 50.0, 255, 60, 180);
    this.drawStatBar(specX + 20, specY + 190, "BATTERY DEPLOY", spec["boostSpeed"] / 240.0, 0, 240, 255);

    gui.drawText("A / D  CHOOSE MACHINE     ENTER  SELECT TRACK     ESC  BACK", 80, 672, 20, 255, 240, 90);
  }

  drawTrackSelectScreen(selectedTrack, trackSpec, recordManager, t, aiDifficulty) {
    gui.drawRectangleAlpha(0, 0, this.w, this.h, 4, 6, 18, 150);

    gui.drawText("CHAMPIONSHIP CIRCUIT SELECT", 80, 50, 48, 240, 250, 255);
    gui.drawText("CHOOSE YOUR BATTLEGROUND", 84, 106, 20, 255, 80, 180);

    let totalT = const.getTotalTracks();
    let startIdx = 0;
    if (selectedTrack >= 4) {
      startIdx = selectedTrack - 3;
      if (startIdx + 4 > totalT) startIdx = totalT - 4;
      if (startIdx < 0) startIdx = 0;
    }

    for (let slot = 0; slot < 4 and (startIdx + slot) < totalT; slot += 1) {
      let i = startIdx + slot;
      let tInfo = const.getTrackSpec(i);
      let tX = 80;
      let tY = 145 + slot * 122;
      let isSel = (i == selectedTrack);
      let recTime = 99.99;
      if (recordManager != nil and i < 4) recTime = recordManager.getRecord(i);

      let isCustom = (i >= 4);
      let nameStr = tInfo["name"];
      if (isCustom) nameStr = "[CUSTOM] " + nameStr;

      if (isSel) {
        gui.drawRectangleAlpha(tX, tY, 810, 106, 24, 38, 70, 230);
        gui.drawRectangleLines(tX, tY, 810, 106, 255, 80, 180);
        let titleCol = [255, 240, 90];
        if (isCustom) titleCol = [0, 240, 255];
        gui.drawText(nameStr, tX + 24, tY + 14, 28, titleCol[0], titleCol[1], titleCol[2]);
        gui.drawText(tInfo["subtitle"], tX + 24, tY + 48, 16, 200, 230, 255);
        if (isCustom) {
          gui.drawText("USER CREATED CIRCUIT", tX + 430, tY + 48, 17, 0, 240, 255);
        } else {
          gui.drawText("RECORD: " + str(recTime) + "s", tX + 430, tY + 48, 18, 255, 220, 60);
        }
      } else {
        gui.drawRectangleAlpha(tX, tY, 810, 106, 12, 16, 32, 170);
        gui.drawRectangleLines(tX, tY, 810, 106, 60, 70, 90);
        gui.drawText(nameStr, tX + 24, tY + 14, 24, 170, 190, 210);
        gui.drawText(tInfo["subtitle"], tX + 24, tY + 48, 16, 120, 140, 160);
        if (isCustom) {
          gui.drawText("USER CIRCUIT", tX + 430, tY + 48, 16, 120, 180, 210);
        } else {
          gui.drawText("RECORD: " + str(recTime) + "s", tX + 430, tY + 48, 17, 180, 170, 100);
        }
      }
    }

    let curInfo = const.getTrackSpec(selectedTrack);
    let pX = 920;
    let pY = 145;
    let pW = 290;
    let pH = 472;
    let railCol = curInfo["railColorA"];
    if (railCol == nil) railCol = [255, 60, 80];

    gui.drawRectangleAlpha(pX, pY, pW, pH, 10, 16, 36, 235);
    gui.drawRectangleLines(pX, pY, pW, pH, railCol[0], railCol[1], railCol[2]);

    gui.drawText("// CIRCUIT TOPOLOGY", pX + 16, pY + 16, 13, 0, 240, 255);
    gui.drawText(curInfo["name"], pX + 16, pY + 38, 22, 255, 235, 90);
    gui.drawText(curInfo["shape"], pX + 16, pY + 66, 14, 200, 220, 245);

    let bnds = const.getTrackBounds(selectedTrack);
    let spanX = bnds[1] - bnds[0];
    let spanZ = bnds[3] - bnds[2];
    let maxSpan = spanX;
    if (spanZ > maxSpan) maxSpan = spanZ;
    let mScale = 170.0 / maxSpan;
    let midX = (bnds[0] + bnds[1]) * 0.5;
    let midZ = (bnds[2] + bnds[3]) * 0.5;
    let mapCX = pX + pW * 0.5;
    let mapCY = pY + 185.0;

    let numPts = 48;
    for (let k = 0; k < numPts; k += 1) {
      let sA = (k / numPts) * curInfo["length"];
      let sB = ((k + 1) / numPts) * curInfo["length"];
      let ptA = const.getTrackWorldPoint(selectedTrack, sA);
      let ptB = const.getTrackWorldPoint(selectedTrack, sB);
      let ax = mapCX + (ptA[0] - midX) * mScale;
      let ay = mapCY + (ptA[1] - midZ) * mScale;
      let bx = mapCX + (ptB[0] - midX) * mScale;
      let by = mapCY + (ptB[1] - midZ) * mScale;
      gui.drawLine(math.floor(ax), math.floor(ay), math.floor(bx), math.floor(by), railCol[0], railCol[1], railCol[2]);
    }

    let pt0 = const.getTrackWorldPoint(selectedTrack, 0.0);
    let p0x = mapCX + (pt0[0] - midX) * mScale;
    let p0y = mapCY + (pt0[1] - midZ) * mScale;
    gui.drawCircle(math.floor(p0x), math.floor(p0y), 4.0, 255, 220, 60);

    gui.drawText("CHICANES / TURNS: " + str(curInfo["turns"]), pX + 18, pY + 300, 14, 210, 230, 255);
    gui.drawText("CIRCUIT LENGTH: " + str(math.floor(curInfo["length"])) + " M", pX + 18, pY + 328, 14, 0, 240, 255);
    gui.drawText("ROAD WIDTH: " + str(math.floor(curInfo["roadWidth"])) + " METERS", pX + 18, pY + 356, 14, 210, 230, 255);
    gui.drawText("ELEVATION PROFILE:", pX + 18, pY + 384, 13, 255, 120, 180);
    gui.drawText(curInfo["elevationProfile"], pX + 18, pY + 406, 13, 240, 240, 255);
    gui.drawText("CHAMPIONSHIP CLASS: " + curInfo["difficulty"], pX + 18, pY + 434, 14, 255, 220, 60);

    let diffStr = "WORLD CHAMPION (HARD)";
    let diffR = 255; let diffG = 65; let diffB = 85;
    if (aiDifficulty == 0) {
      diffStr = "ROOKIE (EASY)";
      diffR = 80; diffG = 240; diffB = 140;
    } else if (aiDifficulty == 1) {
      diffStr = "PRO RACER (MEDIUM)";
      diffR = 255; diffG = 220; diffB = 60;
    }

    gui.drawText("AI DIFFICULTY: < " + diffStr + " >   [A / D TO CHANGE]", 80, 630, 18, diffR, diffG, diffB);
    gui.drawText("W / S CHOOSE TRACK     ENTER LAUNCH     ESC BACK", 80, 656, 17, 255, 230, 90);
    gui.drawText("F FORK TO EDITOR     E EDIT TRACK     N NEW CIRCUIT", 80, 680, 16, 0, 240, 255);
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
    let inCockpit = this.inCockpit;
    this.inCockpit = false;

    if (!inCockpit) {

      let gaugeX = this.w - 300;
      let gaugeY = this.h - 180;
      gui.drawRectangleAlpha(gaugeX, gaugeY, 275, 155, 8, 12, 26, 215);
      gui.drawRectangleLines(gaugeX, gaugeY, 275, 155, 0, 220, 255);

      let kph = math.floor(math.abs(player.speed) * 1.60934);
      gui.drawText(str(kph), gaugeX + 20, gaugeY + 14, 56, 255, 255, 255);
      gui.drawText("KPH", gaugeX + 155, gaugeY + 46, 20, 0, 220, 255);

      let rpmRatio = math.abs(player.speed) / player.maxSpeed;
      if (rpmRatio > 1.0) rpmRatio = 1.0;
      gui.drawRectangle(gaugeX + 20, gaugeY + 80, 235, 10, 30, 40, 60);
      let rpmColR = math.floor(rpmRatio * 255);
      let rpmColG = math.floor((1.0 - rpmRatio) * 255);
      gui.drawRectangle(gaugeX + 20, gaugeY + 80, math.floor(235 * rpmRatio), 10, rpmColR, rpmColG, 40);

      if (player.isReversing) {
        let rPulse = 180 + math.floor(math.sin(t * 12.0) * 75.0);
        gui.drawText("GEAR [R]", gaugeX + 20, gaugeY + 98, 18, 255, rPulse, 40);
      } else {
        let gear = 1;
        if (player.speed > 195.0) gear = 6;
        else if (player.speed > 150.0) gear = 5;
        else if (player.speed > 110.0) gear = 4;
        else if (player.speed > 70.0) gear = 3;
        else if (player.speed > 30.0) gear = 2;
        gui.drawText("GEAR " + str(gear), gaugeX + 20, gaugeY + 98, 16, 200, 220, 240);
      }

      if (player.isBoosting) {
        gui.drawText("// BATTERY DEPLOY", gaugeX + 105, gaugeY + 98, 14, 0, 240, 255);
      }

      if (player.isAutopilot) {
        let aiPulse = 180 + math.floor(math.sin(t * 10.0) * 75.0);
        gui.drawText("[AI PILOT ACTIVE: PRESS O]", gaugeX + 16, gaugeY + 128, 13, 0, 240, aiPulse);
      } else {
        gui.drawText("W:GAS S:BRAKE A/D:STEER [O]:AI", gaugeX + 16, gaugeY + 128, 12, 140, 165, 190);
      }

      let nitroX = math.floor(this.w * 0.5) - 170;
      let nitroY = this.h - 58;
      gui.drawRectangleAlpha(nitroX, nitroY, 340, 44, 8, 12, 26, 210);
      gui.drawRectangleLines(nitroX, nitroY, 340, 44, 0, 240, 255);

      let nitroRatio = player.nitro / player.maxNitro;
      gui.drawRectangle(nitroX + 10, nitroY + 10, math.floor(320 * nitroRatio), 24, 0, 240, 255);
      gui.drawText("BATTERY DEPLOY [SPACE]", nitroX + 16, nitroY + 14, 15, 255, 255, 255);

      let meterX = 30;
      let meterY = this.h - 58;
      gui.drawRectangleAlpha(meterX, meterY, 260, 44, 8, 12, 26, 210);
      gui.drawRectangleLines(meterX, meterY, 260, 44, 0, 240, 255);

      let lapProgRatio = 0.0;
      if (player != nil and player.raceDistance != nil and player.raceDistance > 0.0) {
        let curDist = player.raceDistance;
        lapProgRatio = (curDist - math.floor(curDist / lapLength) * lapLength) / lapLength;
      } else if (distance > 0.0) {
        lapProgRatio = (distance - math.floor(distance / lapLength) * lapLength) / lapLength;
      }
      if (lapProgRatio < 0.0) lapProgRatio = 0.0;
      if (lapProgRatio > 1.0) lapProgRatio = 1.0;
      gui.drawRectangle(meterX + 10, meterY + 10, math.floor(240 * lapProgRatio), 24, 0, 220, 180);
      let lapPct = math.floor(lapProgRatio * 100.0);
      gui.drawText("CIRCUIT LAP: " + str(lapPct) + "%", meterX + 16, meterY + 14, 15, 255, 255, 255);
    }

    let infoX = 30;
    let infoY = 24;
    gui.drawRectangleAlpha(infoX, infoY, 310, 115, 8, 12, 26, 215);
    gui.drawRectangleLines(infoX, infoY, 310, 115, 0, 220, 255);

    if (this.gameMode == const.MODE_GRAND_PRIX or this.gameMode == const.MODE_REALISTIC) {
      let posSuffix = "TH";
      let posColor = [255, 255, 255];
      if (pos == 1) { posSuffix = "ST"; posColor = [255, 220, 40]; }
      else if (pos == 2) { posSuffix = "ND"; posColor = [220, 230, 255]; }
      else if (pos == 3) { posSuffix = "RD"; posColor = [240, 140, 60]; }

      gui.drawText(str(pos) + posSuffix, infoX + 18, infoY + 16, 44, posColor[0], posColor[1], posColor[2]);
      gui.drawText("/ " + str(totalRacers), infoX + 120, infoY + 34, 24, 180, 200, 220);
      gui.drawText("LAP " + str(lap) + " / " + str(totalLaps), infoX + 18, infoY + 76, 20, 0, 240, 255);
      if (this.gameMode == const.MODE_REALISTIC) {
        gui.drawText("// REALISTIC DNF ACTIVE", infoX + 130, infoY + 80, 12, 255, 75, 75);
      }
    } else {

      gui.drawText("TIME ATTACK", infoX + 18, infoY + 16, 28, 255, 220, 60);
      gui.drawText("LAP " + str(lap) + " / " + str(totalLaps), infoX + 18, infoY + 54, 20, 0, 240, 255);
      gui.drawText("SOLO RECORD TRIAL", infoX + 18, infoY + 82, 16, 180, 200, 220);
    }

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
    gui.drawText(timeLabel + secStr + "." + msStr, timeX + 16, timeY + 16, 21, 255, 255, 255);

    if (bestLap > 0.0) {
      let bSec = math.floor(bestLap);
      let bMs = math.floor((bestLap - bSec) * 100);
      gui.drawText("BEST: " + str(bSec) + "." + str(bMs), timeX + 16, timeY + 45, 17, 255, 220, 60);
    }

    if (this.gameMode == const.MODE_TIME_ATTACK and bestLap > 0.0) {

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

    if (player.brakeWarning != 0 and this.bannerTimer <= 0.0) {
      let warnW = 440;
      let warnH = 68;
      let warnX = math.floor((this.w - warnW) * 0.5);
      let warnY = 160;

      let pulse = 180 + math.floor(math.sin(t * 16.0) * 75.0);
      gui.drawRectangleAlpha(warnX, warnY, warnW, warnH, 20, 10, 16, 235);
      gui.drawRectangleLines(warnX, warnY, warnW, warnH, 255, 40, pulse);

      let warnText = "<<< BRAKE! <<<";
      let subText = "SHARP LEFT CORNER // HEAVY BRAKING ZONE";
      if (player.brakeWarning == 2) {
        warnText = ">>> BRAKE! >>>";
        subText = "SHARP RIGHT CORNER // HEAVY BRAKING ZONE";
      }

      let tw = gui.measureText(warnText, 30);
      gui.drawText(warnText, math.floor((this.w - tw) * 0.5), warnY + 10, 30, 255, 40, pulse);
      let sw = gui.measureText(subText, 14);
      gui.drawText(subText, math.floor((this.w - sw) * 0.5), warnY + 44, 14, 255, 230, 80);
    }

    if (player.spinTimer > 0.0) {
      let spPulse = 200 + math.floor(math.sin(t * 18.0) * 55.0);
      let spText = "CRASH! VEHICLE SPIN-OUT!";
      let spSub = "LOSS OF TRACTION // RECOVERING HEADING";
      let spW = 460;
      let spH = 68;
      let spX = math.floor((this.w - spW) * 0.5);
      let spY = 160;
      gui.drawRectangleAlpha(spX, spY, spW, spH, 40, 8, 12, 240);
      gui.drawRectangleLines(spX, spY, spW, spH, 255, spPulse, 40);
      let tw = gui.measureText(spText, 28);
      gui.drawText(spText, math.floor((this.w - tw) * 0.5), spY + 12, 28, 255, spPulse, 40);
      let sw = gui.measureText(spSub, 14);
      gui.drawText(spSub, math.floor((this.w - sw) * 0.5), spY + 44, 14, 255, 220, 200);
    } else if (player.isOffTrack) {
      let otPulse = 180 + math.floor(math.sin(t * 12.0) * 75.0);
      let otText = "OFF TRACK // GRAVEL TRAP";
      let otSub = "SEVERE ROLLING DRAG // RETURN TO TARMAC";
      let otW = 440;
      let otH = 66;
      let otX = math.floor((this.w - otW) * 0.5);
      let otY = 160;
      gui.drawRectangleAlpha(otX, otY, otW, otH, 35, 20, 8, 235);
      gui.drawRectangleLines(otX, otY, otW, otH, 255, otPulse, 30);
      let tw = gui.measureText(otText, 26);
      gui.drawText(otText, math.floor((this.w - tw) * 0.5), otY + 10, 26, 255, otPulse, 40);
      let sw = gui.measureText(otSub, 13);
      gui.drawText(otSub, math.floor((this.w - sw) * 0.5), otY + 42, 13, 255, 230, 90);
    }

    let mapX = this.w - 280;
    let mapY = 112;
    let mapW = 250;
    let mapH = 175;

    let curTrackId = this.trackId;

    let tSpec = const.getTrackSpec(curTrackId);
    let railCol = tSpec["railColorA"];
    if (railCol == nil) railCol = [255, 60, 80];

    gui.drawRectangleAlpha(mapX, mapY, mapW, mapH, 8, 12, 26, 220);
    gui.drawRectangleLines(mapX, mapY, mapW, mapH, railCol[0], railCol[1], railCol[2]);
    gui.drawText("// " + tSpec["name"] + " RADAR", mapX + 14, mapY + 10, 13, 0, 240, 255);

    let bnds = const.getTrackBounds(curTrackId);
    let spanX = bnds[1] - bnds[0];
    let spanZ = bnds[3] - bnds[2];
    let maxSpan = spanX;
    if (spanZ > maxSpan) maxSpan = spanZ;

    let drawW = mapW - 36.0;
    let drawH = mapH - 42.0;
    let rScale = drawW / maxSpan;
    if (drawH / maxSpan < rScale) rScale = drawH / maxSpan;

    let midX = (bnds[0] + bnds[1]) * 0.5;
    let midZ = (bnds[2] + bnds[3]) * 0.5;
    let cx = mapX + mapW * 0.5;
    let cy = mapY + 22.0 + drawH * 0.5;

    let numPts = 48;
    for (let k = 0; k < numPts; k += 1) {
      let sA = (k / numPts) * lapLength;
      let sB = ((k + 1) / numPts) * lapLength;
      let ptA = const.getTrackWorldPoint(curTrackId, sA);
      let ptB = const.getTrackWorldPoint(curTrackId, sB);
      let ax = cx + (ptA[0] - midX) * rScale;
      let ay = cy + (ptA[1] - midZ) * rScale;
      let bx = cx + (ptB[0] - midX) * rScale;
      let by = cy + (ptB[1] - midZ) * rScale;
      gui.drawLine(math.floor(ax), math.floor(ay), math.floor(bx), math.floor(by), 120, 140, 175);
    }

    let pt0 = const.getTrackWorldPoint(curTrackId, 0.0);
    let p0x = cx + (pt0[0] - midX) * rScale;
    let p0y = cy + (pt0[1] - midZ) * rScale;
    gui.drawCircle(math.floor(p0x), math.floor(p0y), 3.5, 255, 220, 60);

    if ((this.gameMode == const.MODE_GRAND_PRIX or this.gameMode == const.MODE_REALISTIC) and rivals != nil) {
      for (let i = 0; i < len(rivals); i += 1) {
        let rCar = rivals[i];
        let rPt = const.getTrackWorldPoint(curTrackId, rCar.trackDistance);
        let rx = cx + (rPt[0] - midX) * rScale;
        let ry = cy + (rPt[1] - midZ) * rScale;
        gui.drawCircle(math.floor(rx), math.floor(ry), 3.0, 255, 90, 80);
      }
    }

    let pPt = const.getTrackWorldPoint(curTrackId, distance);
    let px = cx + (pPt[0] - midX) * rScale;
    let py = cy + (pPt[1] - midZ) * rScale;
    let pTan = const.getTrackTangent(curTrackId, distance);
    let tLen = math.sqrt(pTan[0] * pTan[0] + pTan[1] * pTan[1]);
    if (tLen < 0.001) tLen = 1.0;
    let dirX = (pTan[0] / tLen) * 7.0;
    let dirY = (pTan[1] / tLen) * 7.0;

    let pPulse = 4.5 + math.sin(t * 8.0) * 1.0;
    gui.drawCircle(math.floor(px), math.floor(py), pPulse, 0, 240, 255);
    gui.drawCircle(math.floor(px), math.floor(py), 2.0, 255, 255, 255);
    gui.drawLine(math.floor(px), math.floor(py), math.floor(px + dirX), math.floor(py + dirY), 255, 255, 255);

    if (player.nearMissTimer > 0.0) {
      let nmPulse = 200 + math.floor(math.sin(t * 15.0) * 55.0);
      gui.drawText("NEAR MISS! +15% BATTERY", math.floor(this.w * 0.5) - 150, 260, 24, 0, 240, 255);
    }
  }

  drawPauseMenu(selectedOption, currentPovName, currentDiffName) {
    this.updateDimensions();
    gui.drawRectangleAlpha(0, 0, this.w, this.h, 2, 4, 12, 210);

    let mW = 520;
    let mH = 390;
    let mX = math.floor(this.w * 0.5) - math.floor(mW * 0.5);
    let mY = math.floor(this.h * 0.5) - math.floor(mH * 0.5);

    gui.drawRectangleAlpha(mX, mY, mW, mH, 12, 18, 34, 248);
    gui.drawRectangleLines(mX, mY, mW, mH, 0, 240, 255);
    gui.drawRectangleLines(mX + 2, mY + 2, mW - 4, mH - 4, 0, 110, 160);

    gui.drawText("SYSTEM PAUSED", mX + 145, mY + 26, 32, 255, 255, 255);
    gui.drawRectangle(mX + 35, mY + 68, mW - 70, 2, 0, 240, 255);

    let povStr = "CAMERA POV: CLOSE CHASE";
    if (currentPovName != nil) povStr = "CAMERA POV: " + currentPovName;

    let diffStr = "AI DIFFICULTY: EXPERT";
    if (currentDiffName != nil) diffStr = "AI DIFFICULTY: " + currentDiffName;

    let options = [
      "RESUME RACE",
      "RESTART TRACK",
      povStr,
      diffStr,
      "RETURN TO GARAGE"
    ];

    for (let i = 0; i < len(options); i += 1) {
      let optY = mY + 92 + i * 46;
      if (i == selectedOption) {
        gui.drawRectangleAlpha(mX + 25, optY - 5, mW - 50, 38, 0, 200, 255, 55);
        gui.drawRectangleLines(mX + 25, optY - 5, mW - 50, 38, 0, 240, 255);
        gui.drawText(">>  " + options[i], mX + 45, optY + 2, 21, 255, 230, 80);
      } else {
        gui.drawText("    " + options[i], mX + 45, optY + 2, 19, 170, 190, 210);
      }
    }

    gui.drawRectangle(mX + 35, mY + mH - 46, mW - 70, 1, 60, 80, 110);
    gui.drawText("[W/S] NAVIGATE   [A/D] ADJUST   [ENTER] SELECT   [ESC] RESUME", mX + 40, mY + mH - 32, 14, 130, 160, 190);
  }

  drawResultsScreen(position, totalRacers, bestLap, trackRecord, isNewRecord, t) {
    gui.drawRectangleAlpha(0, 0, this.w, this.h, 4, 6, 18, 200);

    let pX = math.floor(this.w * 0.5) - 300;
    let pY = 110;
    gui.drawRectangleAlpha(pX, pY, 600, 470, 16, 24, 48, 240);
    gui.drawRectangleLines(pX, pY, 600, 470, 255, 220, 60);

    if (this.gameMode == const.MODE_GRAND_PRIX or this.gameMode == const.MODE_REALISTIC) {
      let titleText = "GRAND PRIX COMPLETED";
      if (this.gameMode == const.MODE_REALISTIC) {
        titleText = "REALISTIC GP COMPLETED";
      }
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
    } else {

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
    gui.drawText("SESSION TIME EXPIRED", pX + 50, pY + 85, 18, 220, 220, 230);

    let prompt = "PRESS ENTER TO RETURN TO GARAGE";
    let pw = gui.measureText(prompt, 22);
    gui.drawText(prompt, math.floor((this.w - pw) * 0.5), pY + 310, 22, 255, 255, 255);
  }

  drawCrashedScreen(t) {
    gui.drawRectangleAlpha(0, 0, this.w, this.h, 25, 0, 0, 175);

    let pulse = 200 + math.floor(math.sin(t * 8.0) * 55.0);
    let text = "HULL CRITICAL // MACHINE TOTALED";
    if (this.gameMode == const.MODE_REALISTIC) {
      text = "TERMINAL DAMAGE // DNF";
    }
    let tw = gui.measureText(text, 44);
    gui.drawText(text, math.floor((this.w - tw) * 0.5), 260, 44, 255, pulse, pulse);

    if (this.gameMode == const.MODE_REALISTIC) {
      let sub = "CRITICAL IMPACT IN REALISTIC MODE";
      let sw = gui.measureText(sub, 20);
      gui.drawText(sub, math.floor((this.w - sw) * 0.5), 320, 20, 255, 180, 180);
    }

    let prompt = "PRESS ENTER TO RETURN TO GARAGE";
    let pw = gui.measureText(prompt, 24);
    gui.drawText(prompt, math.floor((this.w - pw) * 0.5), 380, 24, 255, 255, 255);
  }

  rotPtX(cx, cy, lx, ly, cosA, sinA) {
    return cx + lx * cosA - ly * sinA;
  }

  rotPtY(cx, cy, lx, ly, cosA, sinA) {
    return cy + lx * sinA + ly * cosA;
  }

  drawRotBox(cx, cy, w, h, ang, r, g, b) {
    let hw = w * 0.5;
    let hh = h * 0.5;
    let cosA = math.cos(ang);
    let sinA = math.sin(ang);
    let step = 1.5;
    let ly = -hh;
    while (ly <= hh) {
      let px = -ly * sinA;
      let py = ly * cosA;
      let lx = cx - hw * cosA + px;
      let lyP = cy - hw * sinA + py;
      let rx = cx + hw * cosA + px;
      let ryP = cy + hw * sinA + py;
      gui.drawLine(math.floor(lx), math.floor(lyP), math.floor(rx), math.floor(ryP), r, g, b);
      ly = ly + step;
    }
  }

  drawRotBoxLines(cx, cy, w, h, ang, r, g, b) {
    let hw = w * 0.5;
    let hh = h * 0.5;
    let cosA = math.cos(ang);
    let sinA = math.sin(ang);
    let p1x = cx - hw * cosA + hh * sinA;
    let p1y = cy - hw * sinA - hh * cosA;
    let p2x = cx + hw * cosA + hh * sinA;
    let p2y = cy + hw * sinA - hh * cosA;
    let p3x = cx + hw * cosA - hh * sinA;
    let p3y = cy + hw * sinA + hh * cosA;
    let p4x = cx - hw * cosA - hh * sinA;
    let p4y = cy - hw * sinA + hh * cosA;
    gui.drawLine(math.floor(p1x), math.floor(p1y), math.floor(p2x), math.floor(p2y), r, g, b);
    gui.drawLine(math.floor(p2x), math.floor(p2y), math.floor(p3x), math.floor(p3y), r, g, b);
    gui.drawLine(math.floor(p3x), math.floor(p3y), math.floor(p4x), math.floor(p4y), r, g, b);
    gui.drawLine(math.floor(p4x), math.floor(p4y), math.floor(p1x), math.floor(p1y), r, g, b);
  }

  drawCockpitView(player, t, dt) {
    this.updateDimensions();
    this.inCockpit = true;
    let scrW = 1280;
    let scrH = 720;
    let cx = scrW * 0.5;

    let cId = player.carId;
    let teamCol = [14, 35, 82];
    let teamTrim = [235, 30, 45];
    let suitCol = [18, 42, 95];
    let suitTrim = [255, 215, 25];
    let gloveCol = [22, 50, 110];

    if (cId == 1) {
      teamCol = [0, 162, 155];
      teamTrim = [230, 235, 245];
      suitCol = [240, 242, 248];
      suitTrim = [0, 162, 155];
      gloveCol = [245, 248, 252];
    } else if (cId == 2) {
      teamCol = [225, 25, 35];
      teamTrim = [255, 215, 30];
      suitCol = [215, 20, 30];
      suitTrim = [255, 255, 255];
      gloveCol = [245, 245, 250];
    } else if (cId == 3) {
      teamCol = [255, 128, 0];
      teamTrim = [0, 210, 225];
      suitCol = [255, 120, 0];
      suitTrim = [20, 24, 30];
      gloveCol = [255, 135, 15];
    }

    let carbonDark = [14, 16, 20];
    let carbonMid = [28, 30, 38];
    let carbonLight = [48, 52, 64];

    let normSpd = math.abs(player.speed) / player.maxSpeed;
    if (normSpd > 1.0) normSpd = 1.0;
    let vibY = math.sin(t * 85.0) * (normSpd * 1.5);
    let vibX = math.cos(t * 70.0) * (normSpd * 1.0);
    let pitch = vibY;
    if (player.isBraking) pitch = pitch + 3.5;
    else if (player.isBoosting) pitch = pitch - 2.5;

    let steer = player.steerAngle;

    let wyWheels = 552.0 + pitch * 0.4;
    let wxL = cx - 380.0 + steer * 18.0;
    let wxR = cx + 380.0 + steer * 18.0;

    let wishNoseY = wyWheels + 12.0;

    gui.drawLine(math.floor(cx - 52.0), math.floor(wyWheels - 36), math.floor(wxL + 34.0), math.floor(wyWheels - 22), 32, 35, 42);
    gui.drawLine(math.floor(cx - 52.0), math.floor(wyWheels - 35), math.floor(wxL + 34.0), math.floor(wyWheels - 21), 75, 82, 95);
    gui.drawLine(math.floor(cx - 62.0), math.floor(wyWheels + 22), math.floor(wxL + 34.0), math.floor(wyWheels + 16), 32, 35, 42);
    gui.drawLine(math.floor(cx - 46.0), math.floor(wishNoseY), math.floor(wxL + 30.0), math.floor(wyWheels + 2), 95, 105, 120);

    gui.drawLine(math.floor(cx + 52.0), math.floor(wyWheels - 36), math.floor(wxR - 34.0), math.floor(wyWheels - 22), 32, 35, 42);
    gui.drawLine(math.floor(cx + 52.0), math.floor(wyWheels - 35), math.floor(wxR - 34.0), math.floor(wyWheels - 21), 75, 82, 95);
    gui.drawLine(math.floor(cx + 62.0), math.floor(wyWheels + 22), math.floor(wxR - 34.0), math.floor(wyWheels + 16), 32, 35, 42);
    gui.drawLine(math.floor(cx + 46.0), math.floor(wishNoseY), math.floor(wxR - 30.0), math.floor(wyWheels + 2), 95, 105, 120);

    gui.drawRectangle(math.floor(wxL + 20.0), math.floor(wyWheels - 32.0), 16, 70, 24, 26, 32);
    gui.drawRectangleLines(math.floor(wxL + 20.0), math.floor(wyWheels - 32.0), 16, 70, 55, 60, 72);
    gui.drawRectangle(math.floor(wxR - 36.0), math.floor(wyWheels - 32.0), 16, 70, 24, 26, 32);
    gui.drawRectangleLines(math.floor(wxR - 36.0), math.floor(wyWheels - 32.0), 16, 70, 55, 60, 72);

    let tW = 80.0;
    let tH = 132.0;
    let steerTiltPx = steer * 40.0;

    for (let side = -1; side <= 1; side += 2) {
      let curWx = wxR;
      if (side < 0) curWx = wxL;

      let topX = curWx + steerTiltPx;
      let botX = curWx - steerTiltPx * 0.45;

      let numSteps = 24;
      for (let k = 0; k < numSteps; k += 1) {
        let frac = k / (numSteps - 1.0);
        let yP = wyWheels - tH * 0.5 + frac * tH;
        let xC = topX + frac * (botX - topX);

        let widthFactor = 1.0;
        if (frac < 0.20) widthFactor = 0.72 + (frac / 0.20) * 0.28;
        else if (frac > 0.82) widthFactor = 0.75 + ((1.0 - frac) / 0.18) * 0.25;
        let curW = tW * widthFactor;

        let xLeft = math.floor(xC - curW * 0.5);
        let curH = math.ceil(tH / numSteps) + 1;

        let rShade = 20; let gShade = 22; let bShade = 26;
        if (frac < 0.15) { rShade = 38; gShade = 42; bShade = 50; }
        else if (frac > 0.85) { rShade = 14; gShade = 15; bShade = 18; }

        gui.drawRectangle(xLeft, math.floor(yP), math.floor(curW), curH, rShade, gShade, bShade);
        gui.drawRectangle(xLeft, math.floor(yP), 4, curH, 12, 13, 16);
        gui.drawRectangle(xLeft + math.floor(curW) - 4, math.floor(yP), 4, curH, 12, 13, 16);

        if (frac > 0.25 and frac < 0.55) {
          gui.drawRectangle(xLeft + 8, math.floor(yP), math.floor(curW - 16), curH, 30, 32, 38);
        }
      }

      let defW = tW + 12.0;
      let defX = math.floor(topX - defW * 0.5);
      let defY = math.floor(wyWheels - tH * 0.5 - 8.0);
      gui.drawRectangle(defX, defY, math.floor(defW), 8, carbonDark[0], carbonDark[1], carbonDark[2]);
      gui.drawRectangle(defX + 2, defY + 1, math.floor(defW - 4), 3, teamCol[0], teamCol[1], teamCol[2]);
      gui.drawRectangleLines(defX, defY, math.floor(defW), 8, 60, 65, 78);

      let stripeY = math.floor(wyWheels - tH * 0.15);
      let stripeX = math.floor(curWx - tW * 0.5 + 4);
      if (side > 0) stripeX = math.floor(curWx + tW * 0.5 - 10);
      gui.drawRectangle(stripeX, stripeY, 6, 28, 235, 30, 40);
    }

    let yTip = 530.0 + pitch;
    let yBase = 625.0 + pitch;
    let wTip = 36.0;
    let wBase = 120.0;

    let fwW = 340.0;
    let fwLeft = math.floor(cx - fwW * 0.5);
    gui.drawRectangle(fwLeft, math.floor(yTip) - 5, math.floor(fwW), 10, 18, 20, 24);
    gui.drawRectangle(fwLeft + 6, math.floor(yTip) - 2, math.floor(fwW - 12), 5, teamCol[0], teamCol[1], teamCol[2]);
    gui.drawRectangle(fwLeft + 22, math.floor(yTip) - 6, math.floor(fwW - 44), 2, 235, 238, 245);

    gui.drawRectangle(fwLeft - 8, math.floor(yTip) - 24, 8, 30, 24, 26, 32);
    gui.drawRectangle(fwLeft - 8, math.floor(yTip) - 24, 8, 10, teamCol[0], teamCol[1], teamCol[2]);

    gui.drawRectangle(fwLeft + math.floor(fwW), math.floor(yTip) - 24, 8, 30, 24, 26, 32);
    gui.drawRectangle(fwLeft + math.floor(fwW), math.floor(yTip) - 24, 8, 10, teamCol[0], teamCol[1], teamCol[2]);

    gui.drawLine(math.floor(cx), math.floor(yTip - 3), math.floor(cx), math.floor(yTip - 32), 210, 220, 235);

    let nSlices = 28;
    for (let s = 0; s < nSlices; s += 1) {
      let factor = s / (nSlices - 1.0);
      let yS = math.floor(yTip + factor * (yBase - yTip));
      let hS = math.ceil((yBase - yTip) / nSlices) + 1;
      let curW = wTip + (wBase - wTip) * factor;
      let xLeft = math.floor(cx - curW * 0.5);

      gui.drawRectangle(xLeft, yS, math.floor(curW), hS, carbonDark[0], carbonDark[1], carbonDark[2]);
      gui.drawRectangle(xLeft, yS, 5, hS, 10, 11, 14);
      gui.drawRectangle(xLeft + math.floor(curW) - 5, yS, 5, hS, 10, 11, 14);

      let bodyW = math.floor(curW * 0.82);
      let bLeft = math.floor(cx - bodyW * 0.5);
      gui.drawRectangle(bLeft, yS, bodyW, hS, teamCol[0], teamCol[1], teamCol[2]);

      let hiW = math.floor(curW * 0.38);
      let hiR = math.min(255, teamCol[0] + 38);
      let hiG = math.min(255, teamCol[1] + 38);
      let hiB = math.min(255, teamCol[2] + 38);
      gui.drawRectangle(math.floor(cx - hiW * 0.5), yS, hiW, hS, hiR, hiG, hiB);

      gui.drawRectangle(math.floor(cx - 2), yS, 4, hS, 255, 255, 255);
      if (s > 14 and s < 22) {
        gui.drawRectangle(math.floor(cx - 2), yS, 4, hS, teamTrim[0], teamTrim[1], teamTrim[2]);
      }
    }

    gui.drawText("16", math.floor(cx - 11), math.floor(yTip + 44.0), 20, 255, 255, 255);

    let flankTopY = 415 + math.floor(pitch * 0.3);

    for (let y = flankTopY; y < scrH; y += 2) {
      let f = (y - flankTopY) / (scrH - flankTopY + 0.0);
      let wallW = math.floor(130.0 + f * 150.0);

      gui.drawRectangle(0, y, wallW, 2, carbonDark[0], carbonDark[1], carbonDark[2]);
      if ((math.floor(y / 4)) % 2 == 1) {
        gui.drawRectangle(0, y, wallW, 2, carbonMid[0], carbonMid[1], carbonMid[2]);
      }

      gui.drawRectangle(wallW - 14, y, 14, 2, carbonLight[0], carbonLight[1], carbonLight[2]);
      gui.drawRectangle(wallW - 4, y, 4, 2, teamCol[0], teamCol[1], teamCol[2]);
    }

    for (let y = flankTopY; y < scrH; y += 2) {
      let f = (y - flankTopY) / (scrH - flankTopY + 0.0);
      let wallW = math.floor(130.0 + f * 150.0);
      let rX = scrW - wallW;

      gui.drawRectangle(rX, y, wallW, 2, carbonDark[0], carbonDark[1], carbonDark[2]);
      if ((math.floor(y / 4)) % 2 == 1) {
        gui.drawRectangle(rX, y, wallW, 2, carbonMid[0], carbonMid[1], carbonMid[2]);
      }
      gui.drawRectangle(rX, y, 14, 2, carbonLight[0], carbonLight[1], carbonLight[2]);
      gui.drawRectangle(rX, y, 4, 2, teamCol[0], teamCol[1], teamCol[2]);
    }

    let mW = 124; let mH = 62;
    let mY = 380 + math.floor(pitch * 0.35);
    let mLX = 60;
    let mRX = scrW - 60 - mW;

    gui.drawRectangle(mLX + mW - 8, mY + mH - 12, 34, 18, carbonDark[0], carbonDark[1], carbonDark[2]);
    gui.drawRectangleLines(mLX + mW - 8, mY + mH - 12, 34, 18, 55, 60, 72);
    gui.drawRectangle(mLX, mY, mW, mH, carbonDark[0], carbonDark[1], carbonDark[2]);
    gui.drawRectangle(mLX, mY, mW, 6, teamCol[0], teamCol[1], teamCol[2]);
    gui.drawRectangleLines(mLX, mY, mW, mH, 65, 72, 85);

    let gLX = mLX + 5; let gLY = mY + 8; let gW = mW - 10; let gH = mH - 12;
    gui.drawRectangle(gLX, gLY, gW, math.floor(gH * 0.48), 95, 150, 215);
    gui.drawRectangle(gLX, gLY + math.floor(gH * 0.48), gW, math.ceil(gH * 0.52), 52, 56, 65);
    gui.drawLine(gLX, gLY + math.floor(gH * 0.48), gLX + gW, gLY + math.floor(gH * 0.48), 140, 180, 230);
    gui.drawRectangle(gLX + math.floor(gW * 0.5) - 10, gLY + math.floor(gH * 0.48) - 3, 20, 8, 22, 24, 28);
    gui.drawRectangle(gLX + math.floor(gW * 0.5) - 6, gLY + math.floor(gH * 0.48) - 1, 12, 4, 225, 25, 35);

    gui.drawRectangle(mRX - 26, mY + mH - 12, 34, 18, carbonDark[0], carbonDark[1], carbonDark[2]);
    gui.drawRectangleLines(mRX - 26, mY + mH - 12, 34, 18, 55, 60, 72);
    gui.drawRectangle(mRX, mY, mW, mH, carbonDark[0], carbonDark[1], carbonDark[2]);
    gui.drawRectangle(mRX, mY, mW, 6, teamCol[0], teamCol[1], teamCol[2]);
    gui.drawRectangleLines(mRX, mY, mW, mH, 65, 72, 85);
    let gRX = mRX + 5;
    gui.drawRectangle(gRX, gLY, gW, math.floor(gH * 0.48), 95, 150, 215);
    gui.drawRectangle(gRX, gLY + math.floor(gH * 0.48), gW, math.ceil(gH * 0.52), 52, 56, 65);
    gui.drawLine(gRX, gLY + math.floor(gH * 0.48), gRX + gW, gLY + math.floor(gH * 0.48), 140, 180, 230);
    gui.drawRectangle(gRX + math.floor(gW * 0.5) - 10, gLY + math.floor(gH * 0.48) - 3, 20, 8, 22, 24, 28);
    gui.drawRectangle(gRX + math.floor(gW * 0.5) - 6, gLY + math.floor(gH * 0.48) - 1, 12, 4, 30, 110, 220);

    let steerPx = steer * 55.0;
    let steerTilt = steer * 34.0;
    let wcX = cx + vibX + steerPx;
    let wcY = 582.0 + pitch * 0.35;
    let hubW = 240.0;
    let hubH = 140.0;

    let leftGripY = wcY - steerTilt;
    let rightGripY = wcY + steerTilt;

    let wingSpan = 440.0;
    gui.drawRectangle(math.floor(wcX - wingSpan * 0.5), math.floor(wcY - 48.0), math.floor(wingSpan), 96, carbonDark[0], carbonDark[1], carbonDark[2]);
    gui.drawRectangleLines(math.floor(wcX - wingSpan * 0.5), math.floor(wcY - 48.0), math.floor(wingSpan), 96, 60, 65, 78);

    gui.drawRectangle(math.floor(wcX - hubW * 0.5), math.floor(wcY - hubH * 0.5), math.floor(hubW), math.floor(hubH), carbonMid[0], carbonMid[1], carbonMid[2]);
    gui.drawRectangleLines(math.floor(wcX - hubW * 0.5), math.floor(wcY - hubH * 0.5), math.floor(hubW), math.floor(hubH), 72, 78, 92);
    gui.drawRectangle(math.floor(wcX - hubW * 0.5 + 4), math.floor(wcY - hubH * 0.5 + 2), math.floor(hubW - 8), 4, teamCol[0], teamCol[1], teamCol[2]);

    let gripW = 56.0;
    let gripH = 175.0;
    let lGripX = math.floor(wcX - wingSpan * 0.5 - gripW * 0.5 + 10.0);
    let rGripX = math.floor(wcX + wingSpan * 0.5 - gripW * 0.5 - 10.0);
    let lGripY = math.floor(leftGripY - gripH * 0.5);
    let rGripY = math.floor(rightGripY - gripH * 0.5);

    gui.drawRectangle(lGripX, lGripY, math.floor(gripW), math.floor(gripH), 42, 45, 54);
    gui.drawRectangleLines(lGripX, lGripY, math.floor(gripW), math.floor(gripH), 65, 70, 82);
    gui.drawRectangle(rGripX, rGripY, math.floor(gripW), math.floor(gripH), 42, 45, 54);
    gui.drawRectangleLines(rGripX, rGripY, math.floor(gripW), math.floor(gripH), 65, 70, 82);

    let armBaseLY = lGripY + 85;
    for (let yA = armBaseLY; yA < scrH; yA += 2) {
      let fA = (yA - armBaseLY) / (scrH - armBaseLY + 0.0);
      let aW = gripW + 24.0 + fA * 150.0;
      let aX = lGripX - fA * 210.0;

      gui.drawRectangle(math.floor(aX), yA, math.floor(aW), 2, suitCol[0], suitCol[1], suitCol[2]);

      gui.drawRectangle(math.floor(aX), yA, 8, 2, math.floor(suitCol[0] * 0.7), math.floor(suitCol[1] * 0.7), math.floor(suitCol[2] * 0.7));

      gui.drawRectangle(math.floor(aX + aW * 0.45), yA, 10, 2, suitTrim[0], suitTrim[1], suitTrim[2]);
      gui.drawRectangle(math.floor(aX + aW * 0.45 + 10), yA, 5, 2, teamTrim[0], teamTrim[1], teamTrim[2]);
    }

    let armBaseRY = rGripY + 85;
    for (let yA = armBaseRY; yA < scrH; yA += 2) {
      let fA = (yA - armBaseRY) / (scrH - armBaseRY + 0.0);
      let aW = gripW + 24.0 + fA * 150.0;
      let aX = rGripX + fA * 90.0;

      gui.drawRectangle(math.floor(aX), yA, math.floor(aW), 2, suitCol[0], suitCol[1], suitCol[2]);

      gui.drawRectangle(math.floor(aX + aW - 8), yA, 8, 2, math.floor(suitCol[0] * 0.7), math.floor(suitCol[1] * 0.7), math.floor(suitCol[2] * 0.7));

      gui.drawRectangle(math.floor(aX + aW * 0.45), yA, 10, 2, suitTrim[0], suitTrim[1], suitTrim[2]);
      gui.drawRectangle(math.floor(aX + aW * 0.45 + 10), yA, 5, 2, teamTrim[0], teamTrim[1], teamTrim[2]);
    }

    gui.drawRectangle(lGripX - 8, lGripY + 42, math.floor(gripW + 10), 68, gloveCol[0], gloveCol[1], gloveCol[2]);
    gui.drawRectangle(lGripX - 10, lGripY + 48, 14, 52, teamCol[0], teamCol[1], teamCol[2]);
    gui.drawRectangle(lGripX + 6, lGripY + 50, math.floor(gripW - 14), 28, 28, 30, 36);
    gui.drawRectangle(lGripX + 8, lGripY + 52, math.floor(gripW - 18), 4, 255, 255, 255);
    for (let fj = 0; fj < 4; fj += 1) {
      let fY = lGripY + 48 + fj * 14;
      gui.drawRectangle(lGripX - 12, fY, 8, 10, 24, 26, 32);
      gui.drawRectangle(lGripX - 12, fY + 2, 8, 2, 235, 235, 240);
    }
    gui.drawCircle(math.floor(lGripX + gripW - 2), math.floor(lGripY + 58), 11.0, gloveCol[0], gloveCol[1], gloveCol[2]);
    gui.drawCircle(math.floor(lGripX + gripW - 2), math.floor(lGripY + 58), 7.0, teamCol[0], teamCol[1], teamCol[2]);
    gui.drawCircle(math.floor(lGripX + gripW - 2), math.floor(lGripY + 58), 3.5, 255, 255, 255);

    gui.drawRectangle(rGripX - 2, rGripY + 42, math.floor(gripW + 10), 68, gloveCol[0], gloveCol[1], gloveCol[2]);
    gui.drawRectangle(rGripX + math.floor(gripW - 4), rGripY + 48, 14, 52, teamCol[0], teamCol[1], teamCol[2]);
    gui.drawRectangle(rGripX + 8, rGripY + 50, math.floor(gripW - 14), 28, 28, 30, 36);
    gui.drawRectangle(rGripX + 10, rGripY + 52, math.floor(gripW - 18), 4, 255, 255, 255);
    for (let fj = 0; fj < 4; fj += 1) {
      let fY = rGripY + 48 + fj * 14;
      gui.drawRectangle(rGripX + math.floor(gripW + 4), fY, 8, 10, 24, 26, 32);
      gui.drawRectangle(rGripX + math.floor(gripW + 4), fY + 2, 8, 2, 235, 235, 240);
    }
    gui.drawCircle(math.floor(rGripX + 2), math.floor(rGripY + 58), 11.0, gloveCol[0], gloveCol[1], gloveCol[2]);
    gui.drawCircle(math.floor(rGripX + 2), math.floor(rGripY + 58), 7.0, teamCol[0], teamCol[1], teamCol[2]);
    gui.drawCircle(math.floor(rGripX + 2), math.floor(rGripY + 58), 3.5, 255, 255, 255);

    gui.drawCircle(math.floor(wcX - 160), math.floor(wcY - 24), 8.0, 255, 215, 30);
    gui.drawCircle(math.floor(wcX - 160), math.floor(wcY + 4), 8.0, 0, 230, 255);
    gui.drawCircle(math.floor(wcX - 160), math.floor(wcY + 32), 8.0, 40, 240, 90);

    gui.drawCircle(math.floor(wcX + 160), math.floor(wcY - 24), 8.0, 255, 40, 180);
    gui.drawCircle(math.floor(wcX + 160), math.floor(wcY + 4), 8.0, 235, 35, 45);
    gui.drawCircle(math.floor(wcX + 160), math.floor(wcY + 32), 8.0, 255, 140, 30);

    gui.drawCircle(math.floor(wcX - 60), math.floor(wcY + 50), 10.0, 34, 38, 48);
    gui.drawCircleLines(math.floor(wcX - 60), math.floor(wcY + 50), 10.0, 180, 195, 220);
    gui.drawLine(math.floor(wcX - 60), math.floor(wcY + 50), math.floor(wcX - 60), math.floor(wcY + 41), 255, 255, 255);

    gui.drawCircle(math.floor(wcX + 60), math.floor(wcY + 50), 10.0, 34, 38, 48);
    gui.drawCircleLines(math.floor(wcX + 60), math.floor(wcY + 50), 10.0, 180, 195, 220);
    gui.drawLine(math.floor(wcX + 60), math.floor(wcY + 50), math.floor(wcX + 60), math.floor(wcY + 41), 255, 255, 255);

    let curRpmRatio = math.abs(player.speed) / player.maxSpeed;
    if (curRpmRatio > 1.0) curRpmRatio = 1.0;
    let isRedline = (curRpmRatio >= 0.94 or player.isBoosting);
    let flashOn = (math.sin(t * 32.0) > 0.0);

    let ledStartX = wcX - 98.0;
    let ledY = wcY - 56.0;
    for (let i = 0; i < 15; i += 1) {
      let ledX = ledStartX + i * 14.0;
      let active = false;
      let lR = 24; let lG = 26; let lB = 34;

      if (i < 5) {
        if (curRpmRatio >= (0.38 + i * 0.055)) { active = true; lR = 30; lG = 240; lB = 60; }
      } else if (i < 10) {
        if (curRpmRatio >= (0.65 + (i - 5) * 0.055)) { active = true; lR = 245; lG = 30; lB = 40; }
      } else {
        if (curRpmRatio >= (0.92 + (i - 10) * 0.02)) { active = true; lR = 60; lG = 140; lB = 255; }
      }

      if (isRedline and flashOn) {
        lR = 255; lG = 255; lB = 255;
        active = true;
      }

      gui.drawCircle(math.floor(ledX), math.floor(ledY), 4.5, lR, lG, lB);
      if (active) {
        gui.drawCircle(math.floor(ledX), math.floor(ledY), 2.0, 255, 255, 255);
      }
    }

    let oledW = 160.0;
    let oledH = 82.0;
    let oledX = math.floor(wcX - oledW * 0.5);
    let oledY = math.floor(wcY - 42.0);

    gui.drawRectangle(oledX, oledY, math.floor(oledW), math.floor(oledH), 8, 12, 18);
    gui.drawRectangleLines(oledX, oledY, math.floor(oledW), math.floor(oledH), 45, 90, 110);

    let gStr = "1";
    if (player.isReversing or player.speed < -0.5) {
      gStr = "R";
    } else if (math.abs(player.speed) < 1.0 and (!player.isAccelerating or player.isBraking)) {
      gStr = "N";
    } else {
      let gVal = 1;
      if (player.speed > 195.0) gVal = 6;
      else if (player.speed > 150.0) gVal = 5;
      else if (player.speed > 110.0) gVal = 4;
      else if (player.speed > 70.0) gVal = 3;
      else if (player.speed > 30.0) gVal = 2;
      gStr = str(gVal);
    }
    gui.drawText(gStr, math.floor(wcX - 9), math.floor(oledY + 12), 38, 255, 255, 255);

    let kphSpd = math.floor(math.abs(player.speed) * 1.85);
    let spdText = str(kphSpd);
    gui.drawText(spdText, math.floor(wcX - 68), math.floor(oledY + 16), 24, 0, 245, 255);
    gui.drawText("KPH", math.floor(wcX - 68), math.floor(oledY + 44), 11, 140, 180, 205);

    let curRPM = math.floor(4000.0 + curRpmRatio * 8500.0);
    gui.drawText(str(curRPM), math.floor(wcX + 22), math.floor(oledY + 16), 16, 255, 215, 30);
    gui.drawText("RPM", math.floor(wcX + 22), math.floor(oledY + 36), 11, 180, 190, 200);

    let ersFrac = player.nitro / player.maxNitro;
    gui.drawRectangle(math.floor(wcX - 65), math.floor(oledY + 62), 130, 8, 18, 26, 36);
    let ersW = math.floor(130.0 * ersFrac);
    let ersR = 0; let ersG = 220; let ersB = 255;
    if (player.isBoosting) { ersR = 255; ersG = 140; ersB = 20; }
    gui.drawRectangle(math.floor(wcX - 65), math.floor(oledY + 62), ersW, 8, ersR, ersG, ersB);
    gui.drawText("ERS", math.floor(wcX - 65), math.floor(oledY + 52), 10, 0, 240, 255);
    gui.drawText(str(math.floor(ersFrac * 100)) + "%", math.floor(wcX + 38), math.floor(oledY + 52), 10, 235, 240, 250);
  }

}
