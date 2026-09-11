use "pb_gui" as gui;
use "config";
use "assets";
use "particles";
use "player";
use "world";
use "ui";

let STATE_TITLE = 0;
let STATE_PLAYING = 1;
let STATE_PAUSED = 2;
let STATE_GAMEOVER = 3;

gui.initWindow(config.windowWidth, config.windowHeight, "Cyber Runner - Pogberry 2D Showcase");
gui.setVirtualResolution(config.virtualWidth, config.virtualHeight);
gui.setTargetFPS(config.targetFPS);
gui.setExitKey(0); // Disable default ESC so game can use ESC for pause

assets.init();

let playerObj = player.Player();
let worldObj = world.World();
let particleSys = particles.ParticleSystem();
let uiObj = ui.UI();

let gameState = STATE_TITLE;

while (!gui.windowShouldClose())
{
  let dt = gui.getFrameTime();
  if (dt > 0.05) dt = 0.05; // clamp delta time for stability

  // Keep background music streaming
  assets.updateMusic();

  // Global hotkeys
  if (gui.isKeyPressed("KEY_M"))
  {
    assets.toggleMute();
  }
  if (gui.isKeyPressed("KEY_F11"))
  {
    gui.toggleFullscreen();
  }

  if (gameState == STATE_TITLE)
  {
    uiObj.update(dt);
    // Slow ambient parallax movement on title screen
    worldObj.skylineOffset = worldObj.skylineOffset + 25.0 * dt;
    if (worldObj.skylineOffset >= 1280.0) worldObj.skylineOffset = worldObj.skylineOffset - 1280.0;

    worldObj.buildingsOffset = worldObj.buildingsOffset + 60.0 * dt;
    if (worldObj.buildingsOffset >= 1280.0) worldObj.buildingsOffset = worldObj.buildingsOffset - 1280.0;

    worldObj.foregroundOffset = worldObj.foregroundOffset + 110.0 * dt;
    if (worldObj.foregroundOffset >= 1760.0) worldObj.foregroundOffset = worldObj.foregroundOffset - 1760.0;

    if (gui.isKeyPressed("KEY_SPACE") or gui.isKeyPressed("KEY_ENTER"))
    {
      gameState = STATE_PLAYING;
      playerObj.reset();
      worldObj.reset();
      particleSys.clear();
      assets.playJump();
    }
  }
  else if (gameState == STATE_PLAYING)
  {
    // Pause toggle
    if (gui.isKeyPressed("KEY_P") or gui.isKeyPressed("KEY_ESCAPE"))
    {
      gameState = STATE_PAUSED;
      assets.pauseMusic();
    }
    else
    {
      // Controls
      if (gui.isKeyPressed("KEY_SPACE") or gui.isKeyPressed("KEY_UP") or gui.isKeyPressed("KEY_W"))
      {
        playerObj.jump(particleSys);
      }

      let isSliding = gui.isKeyDown("KEY_DOWN") or gui.isKeyDown("KEY_S");
      playerObj.slide(isSliding);

      // Updates
      worldObj.update(dt, playerObj, particleSys);
      playerObj.update(dt, particleSys);
      particleSys.update(dt);
      uiObj.update(dt);

      if (!playerObj.isAlive)
      {
        gameState = STATE_GAMEOVER;
      }
    }
  }
  else if (gameState == STATE_PAUSED)
  {
    if (gui.isKeyPressed("KEY_P") or gui.isKeyPressed("KEY_ESCAPE"))
    {
      gameState = STATE_PLAYING;
      assets.resumeMusic();
    }
  }
  else if (gameState == STATE_GAMEOVER)
  {
    particleSys.update(dt);
    uiObj.update(dt);

    if (gui.isKeyPressed("KEY_SPACE") or gui.isKeyPressed("KEY_ENTER"))
    {
      gameState = STATE_PLAYING;
      playerObj.reset();
      worldObj.reset();
      particleSys.clear();
      assets.playJump();
    }
  }

  gui.beginDrawing();
  gui.clearBackground(config.colorBgR, config.colorBgG, config.colorBgB);

  if (gameState == STATE_TITLE)
  {
    worldObj.drawParallax();
    uiObj.drawTitleScreen();
  }
  else if (gameState == STATE_PLAYING)
  {
    worldObj.drawParallax();
    worldObj.draw();
    playerObj.draw();
    particleSys.draw();
    uiObj.drawHUD(playerObj, worldObj);
  }
  else if (gameState == STATE_PAUSED)
  {
    worldObj.drawParallax();
    worldObj.draw();
    playerObj.draw();
    particleSys.draw();
    uiObj.drawHUD(playerObj, worldObj);
    uiObj.drawPauseOverlay();
  }
  else if (gameState == STATE_GAMEOVER)
  {
    worldObj.drawParallax();
    worldObj.draw();
    particleSys.draw();
    uiObj.drawGameOver(worldObj);
  }

  gui.endDrawing();
}

assets.cleanup();
gui.closeWindow();
