use "pb_gui" as gui;
use "std.math" as math;
use "config";
use "assets";

export class UI
{
  init()
  {
    this.highScore = 0;
    this.blinkTimer = 0.0;
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
    let tw = gui.measureText(title, titleSize);
    let tx = (screenW - tw) / 2;

    // Shadow & glow
    gui.drawText(title, tx + 3, 113, titleSize, 20, 20, 40);
    gui.drawText(title, tx - 2, 108, titleSize, config.colorMagentaR, config.colorMagentaG, config.colorMagentaB);
    gui.drawText(title, tx, 110, titleSize, config.colorCyanR, config.colorCyanG, config.colorCyanB);

    let sub = "CHROME HORIZON // POGBERRY SHOWCASE";
    let subSize = 16;
    let sw = gui.measureText(sub, subSize);
    gui.drawText(sub, (screenW - sw) / 2, 170, subSize, 180, 200, 230);

    // Controls box
    let boxW = 360;
    let boxH = 135;
    let boxX = (screenW - boxW) / 2;
    let boxY = 210;
    gui.drawRectangleRounded(boxX, boxY, boxW, boxH, 0.15, 8, 16, 20, 32);
    gui.drawRectangleLines(boxX, boxY, boxW, boxH, 0, 180, 255);

    gui.drawText("MISSION DIRECTIVES:", boxX + 20, boxY + 14, 16, config.colorYellowR, config.colorYellowG, config.colorYellowB);
    gui.drawText("* SPACE / W : Jump & Double Jump", boxX + 24, boxY + 40, 15, config.colorWhiteR, config.colorWhiteG, config.colorWhiteB);
    gui.drawText("* S / DOWN  : Slide under drones", boxX + 24, boxY + 62, 15, config.colorWhiteR, config.colorWhiteG, config.colorWhiteB);
    gui.drawText("* LAND ON DRONES to stomp & bounce!", boxX + 24, boxY + 84, 15, config.colorMagentaR, config.colorMagentaG, config.colorMagentaB);
    gui.drawText("* P : Pause  |  M : Mute  |  F11 : Fullscreen", boxX + 24, boxY + 106, 14, 150, 170, 200);

    // Blinking start prompt
    if (this.blinkTimer < 0.65)
    {
      let prompt = ">> PRESS SPACE OR ENTER TO RUN <<";
      let psize = 20;
      let pw = gui.measureText(prompt, psize);
      gui.drawText(prompt, (screenW - pw) / 2, 380, psize, config.colorCyanR, config.colorCyanG, config.colorCyanB);
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
    gui.drawText("DIST: " + str(distMeters) + "m", 20, 13, 18, config.colorCyanR, config.colorCyanG, config.colorCyanB);

    // Score
    let scoreVal = math.floor(world.score);
    gui.drawText("SCORE: " + str(scoreVal), 190, 13, 18, config.colorWhiteR, config.colorWhiteG, config.colorWhiteB);

    // Coins
    gui.drawCircle(390, 22, 7.0, config.colorYellowR, config.colorYellowG, config.colorYellowB);
    gui.drawText("x " + str(world.coins), 405, 13, 18, config.colorYellowR, config.colorYellowG, config.colorYellowB);

    // Shield status
    if (player.shieldActive)
    {
      gui.drawText("[SHIELD ONLINE]", 510, 13, 16, config.colorGreenR, config.colorGreenG, config.colorGreenB);
    }
    else
    {
      gui.drawText("[SHIELD OFF]", 510, 13, 16, 120, 130, 150);
    }

    // Audio status
    if (assets.isMuted)
    {
      gui.drawText("MUTED (M)", screenW - 140, 13, 14, config.colorMagentaR, config.colorMagentaG, config.colorMagentaB);
    }
    else
    {
      gui.drawText("AUDIO ON (M)", screenW - 140, 13, 14, 130, 160, 190);
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
    let tw = gui.measureText(title, size);
    gui.drawText(title, (screenW - tw) / 2, 190, size, config.colorCyanR, config.colorCyanG, config.colorCyanB);

    let sub = "Press P or ESC to resume";
    let subSize = 18;
    let sw = gui.measureText(sub, subSize);
    gui.drawText(sub, (screenW - sw) / 2, 250, subSize, 200, 210, 230);
  }

  drawGameOver(world)
  {
    let screenW = gui.getScreenWidth();
    let screenH = gui.getScreenHeight();

    // Semi-transparent red/dark backdrop
    gui.drawRectangleAlpha(0, 0, screenW, screenH, 22, 8, 14, 210);

    let title = "SYSTEM CRASH";
    let size = 42;
    let tw = gui.measureText(title, size);
    let tx = (screenW - tw) / 2;
    gui.drawText(title, tx + 2, 102, size, 30, 10, 10);
    gui.drawText(title, tx, 100, size, config.colorMagentaR, config.colorMagentaG, config.colorMagentaB);

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

    gui.drawText("Distance Run: " + str(distMeters) + " m", bx + 30, by + 25, 18, config.colorWhiteR, config.colorWhiteG, config.colorWhiteB);
    gui.drawText("Data Orbs: " + str(world.coins), bx + 30, by + 55, 18, config.colorYellowR, config.colorYellowG, config.colorYellowB);
    gui.drawText("Final Score: " + str(finalScore), bx + 30, by + 85, 20, config.colorCyanR, config.colorCyanG, config.colorCyanB);
    gui.drawText("Best Score: " + str(this.highScore), bx + 30, by + 115, 18, 180, 190, 210);

    if (isNewHigh and finalScore > 0)
    {
      gui.drawText("NEW RECORD!", bx + 175, by + 87, 14, config.colorYellowR, config.colorYellowG, config.colorYellowB);
    }

    // Restart prompt
    if (this.blinkTimer < 0.65)
    {
      let prompt = ">> PRESS SPACE TO REBOOT <<";
      let psize = 20;
      let pw = gui.measureText(prompt, psize);
      gui.drawText(prompt, (screenW - pw) / 2, 375, psize, config.colorCyanR, config.colorCyanG, config.colorCyanB);
    }
  }
}
