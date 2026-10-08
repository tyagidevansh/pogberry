use "pb_gui" as gui;
use "std.math" as math;
use "std.ui" as widgets;
use "config";
use "assets";

export class UI
{
  init()
  {
    this.highScore = 0;
    this.blinkTimer = 0.0;
    this.playerName = "";
    this.nameField = nil;
    this.naming = false;
  }

  update(dt)
  {
    this.blinkTimer = this.blinkTimer + dt;
    if (this.blinkTimer >= 1.0)
    {
      this.blinkTimer = this.blinkTimer - 1.0;
    }
  }

  drawTitleScreen()
  {
    let screenW = gui.getScreenWidth();
    let screenH = gui.getScreenHeight();

    // Dark cyber backdrop
    gui.drawRectangleAlpha(0, 0, screenW, screenH, 8, 10, 18, 220);

    // Glowing main title
    let title = "CYBER RUNNER";
    let titleSize = 48;
    let tw = assets.fontWidth(title, titleSize, 2);
    let tx = (screenW - tw) / 2;

    // Shadow & glow
    assets.fontText(title, tx + 3, 113, titleSize, 2, 20, 20, 40);
    assets.fontText(title, tx - 2, 108, titleSize, 2, config.colorMagentaR, config.colorMagentaG, config.colorMagentaB);
    assets.fontText(title, tx, 110, titleSize, 2, config.colorCyanR, config.colorCyanG, config.colorCyanB);

    let sub = "CHROME HORIZON // POGBERRY SHOWCASE";
    let subSize = 16;
    let sw = assets.fontWidth(sub, subSize, 1);
    assets.fontText(sub, (screenW - sw) / 2, 170, subSize, 1, 180, 200, 230);

    // Controls box
    let boxW = 360;
    let boxH = 135;
    let boxX = (screenW - boxW) / 2;
    let boxY = 210;
    gui.drawRectangleRounded(boxX, boxY, boxW, boxH, 0.15, 8, 16, 20, 32);
    gui.drawRectangleLines(boxX, boxY, boxW, boxH, 0, 180, 255);

    assets.fontText("MISSION DIRECTIVES:", boxX + 20, boxY + 14, 16, 1, config.colorYellowR, config.colorYellowG, config.colorYellowB);
    assets.fontText("* SPACE / W : Jump & Double Jump", boxX + 24, boxY + 40, 15, 1, config.colorWhiteR, config.colorWhiteG, config.colorWhiteB);
    assets.fontText("* S / DOWN  : Slide under drones", boxX + 24, boxY + 62, 15, 1, config.colorWhiteR, config.colorWhiteG, config.colorWhiteB);
    assets.fontText("* LAND ON DRONES to stomp & bounce!", boxX + 24, boxY + 84, 15, 1, config.colorMagentaR, config.colorMagentaG, config.colorMagentaB);
    assets.fontText("* P : Pause  |  M : Mute  |  F11 : Fullscreen", boxX + 24, boxY + 106, 14, 1, 150, 170, 200);

    // Blinking start prompt
    if (this.blinkTimer < 0.65)
    {
      let prompt = ">> PRESS SPACE OR ENTER TO RUN <<";
      let psize = 20;
      let pw = assets.fontWidth(prompt, psize, 1);
      assets.fontText(prompt, (screenW - pw) / 2, 380, psize, 1, config.colorCyanR, config.colorCyanG, config.colorCyanB);
    }
  }

  drawHUD(player, world)
  {
    let screenW = gui.getScreenWidth();
    let screenH = gui.getScreenHeight();

    // Top banner bar
    gui.drawRectangleAlpha(0, 0, screenW, 44, 10, 12, 20, 190);
    gui.drawRectangle(0, 43, screenW, 1, 0, 160, 220);

    // Distance
    let distMeters = math.floor(world.distance / 20.0);
    assets.fontText("DIST: " + str(distMeters) + "m", 20, 13, 18, 1, config.colorCyanR, config.colorCyanG, config.colorCyanB);

    // Score
    let scoreVal = math.floor(world.score);
    assets.fontText("SCORE: " + str(scoreVal), 190, 13, 18, 1, config.colorWhiteR, config.colorWhiteG, config.colorWhiteB);

    // Coins
    gui.drawCircle(390, 22, 7.0, config.colorYellowR, config.colorYellowG, config.colorYellowB);
    assets.fontText("x " + str(world.coins), 405, 13, 18, 1, config.colorYellowR, config.colorYellowG, config.colorYellowB);

    // Shield status
    if (player.shieldActive)
    {
      assets.fontText("[SHIELD ONLINE]", 510, 13, 16, 1, config.colorGreenR, config.colorGreenG, config.colorGreenB);
    }
    else
    {
      assets.fontText("[SHIELD OFF]", 510, 13, 16, 1, 120, 130, 150);
    }

    // Audio status
    if (assets.isMuted)
    {
      assets.fontText("MUTED (M)", screenW - 140, 13, 14, 1, config.colorMagentaR, config.colorMagentaG, config.colorMagentaB);
    }
    else
    {
      assets.fontText("AUDIO ON (M)", screenW - 140, 13, 14, 1, 130, 160, 190);
    }

    // FPS in corner
    gui.drawFPS(screenW - 70, 52);
  }

  drawPauseOverlay()
  {
    let screenW = gui.getScreenWidth();
    let screenH = gui.getScreenHeight();

    // Semi-transparent backdrop
    gui.drawRectangleAlpha(0, 0, screenW, screenH, 10, 12, 22, 180);

    let title = "PAUSED";
    let size = 44;
    let tw = assets.fontWidth(title, size, 2);
    assets.fontText(title, (screenW - tw) / 2, 190, size, 2, config.colorCyanR, config.colorCyanG, config.colorCyanB);

    let sub = "Press P or ESC to resume";
    let subSize = 18;
    let sw = assets.fontWidth(sub, subSize, 1);
    assets.fontText(sub, (screenW - sw) / 2, 250, subSize, 1, 200, 210, 230);
  }

  beginGameOver(world)
  {
    let finalScore = math.floor(world.score);
    if (finalScore > this.highScore and finalScore > 0)
    {
      this.nameField = widgets.TextField(12);
      this.nameField.focused = true;
      this.naming = true;
    }
    else
    {
      this.naming = false;
    }
  }

  drawGameOver(world)
  {
    let screenW = gui.getScreenWidth();
    let screenH = gui.getScreenHeight();

    // Semi-transparent red/dark backdrop
    gui.drawRectangleAlpha(0, 0, screenW, screenH, 22, 8, 14, 210);

    let title = "SYSTEM CRASH";
    let size = 42;
    let tw = assets.fontWidth(title, size, 2);
    let tx = (screenW - tw) / 2;
    assets.fontText(title, tx + 2, 102, size, 2, 30, 10, 10);
    assets.fontText(title, tx, 100, size, 2, config.colorMagentaR, config.colorMagentaG, config.colorMagentaB);

    if (this.naming)
    {
      let bw = 420;
      let bh = 150;
      let bx = (screenW - bw) / 2;
      let by = 180;
      gui.drawRectangleRounded(bx, by, bw, bh, 0.15, 8, 16, 18, 28);
      gui.drawRectangleLines(bx, by, bw, bh, 255, 40, 100);
      assets.fontText("NEW RECORD! ENTER PILOT NAME:", bx + 30, by + 16, 18, 1, config.colorYellowR, config.colorYellowG, config.colorYellowB);
      gui.drawRectangleLines(bx + 30, by + 48, bw - 60, 30, 0, 180, 255);
      assets.fontText(this.nameField.text, bx + 38, by + 52, 18, 1, config.colorWhiteR, config.colorWhiteG, config.colorWhiteB);
      if (this.blinkTimer < 0.5)
      {
        let before = this.nameField.text.substr(0, this.nameField.cursor);
        let cx = bx + 38 + assets.fontWidth(before, 18, 1);
        gui.drawRectangle(cx, by + 52, 2, 24, config.colorCyanR, config.colorCyanG, config.colorCyanB);
      }
      assets.fontText("ENTER ok   ESC skip", bx + 30, by + 96, 14, 1, 150, 170, 200);
      return;
    }

    let distMeters = math.floor(world.distance / 20.0);
    let finalScore = math.floor(world.score);
    let isNewHigh = false;

    if (finalScore > this.highScore)
    {
      this.highScore = finalScore;
      isNewHigh = true;
    }

    // Stats modal box
    let bw = 320;
    let bh = 175;
    let bx = (screenW - bw) / 2;
    let by = 165;
    gui.drawRectangleRounded(bx, by, bw, bh, 0.15, 8, 16, 18, 28);
    gui.drawRectangleLines(bx, by, bw, bh, 255, 40, 100);

    assets.fontText("Distance Run: " + str(distMeters) + " m", bx + 30, by + 25, 18, 1, config.colorWhiteR, config.colorWhiteG, config.colorWhiteB);
    assets.fontText("Data Orbs: " + str(world.coins), bx + 30, by + 55, 18, 1, config.colorYellowR, config.colorYellowG, config.colorYellowB);
    assets.fontText("Final Score: " + str(finalScore), bx + 30, by + 85, 20, 1, config.colorCyanR, config.colorCyanG, config.colorCyanB);
    assets.fontText("Best Score: " + str(this.highScore), bx + 30, by + 115, 18, 1, 180, 190, 210);
    if (this.playerName != "")
    {
      assets.fontText("Pilot: " + this.playerName, bx + 30, by + 145, 18, 1, config.colorGreenR, config.colorGreenG, config.colorGreenB);
    }

    if (isNewHigh and finalScore > 0)
    {
      assets.fontText("NEW RECORD!", bx + 175, by + 87, 14, 1, config.colorYellowR, config.colorYellowG, config.colorYellowB);
    }

    // Restart prompt
    if (this.blinkTimer < 0.65)
    {
      let prompt = ">> PRESS SPACE TO REBOOT <<";
      let psize = 20;
      let pw = assets.fontWidth(prompt, psize, 1);
      assets.fontText(prompt, (screenW - pw) / 2, 375, psize, 1, config.colorCyanR, config.colorCyanG, config.colorCyanB);
    }
  }
}
