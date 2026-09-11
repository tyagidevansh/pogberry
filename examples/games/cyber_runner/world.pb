use "pb_gui" as gui;
use "config";
use "assets";

export class World
{
  init()
  {
    this.reset();
  }

  reset()
  {
    this.distance = 0.0;
    this.scrollSpeed = config.baseRunSpeed;
    this.score = 0;
    this.coins = 0;

    this.skylineOffset = 0.0;
    this.buildingsOffset = 0.0;
    this.foregroundOffset = 0.0;

    this.platforms = [];
    this.coinsList = [];
    this.shieldsList = [];
    this.dronesList = [];

    // Starting runway
    this.platforms.push([0.0, 340.0, 500.0, 140.0]);
    this.platforms.push([560.0, 340.0, 380.0, 140.0]);
    this.platforms.push([1000.0, 320.0, 340.0, 160.0]);
    this.rightmostX = 1340.0;

    // Initial coins
    this.spawnCoinsOnPlatform(560.0, 340.0, 380.0);
    this.spawnCoinsOnPlatform(1000.0, 320.0, 340.0);
  }

  spawnCoinsOnPlatform(px, py, pw)
  {
    let count = 3 + rand(3);
    let startX = px + 40.0;
    let step = (pw - 80.0) / count;
    for (let i = 0; i < count; i = i + 1)
    {
      let cx = startX + i * step;
      let cy = py - 40.0 - (rand(20));
      this.coinsList.push([cx, cy, true, rand(100) / 10.0]);
    }
  }

  generateNextPlatform()
  {
    let gap = 90.0 + rand(80);
    let width = 240.0 + rand(180);
    let y = 300.0 + rand(50);
    let x = this.rightmostX + gap;

    this.platforms.push([x, y, width, gui.getScreenHeight() - y + 50.0]);
    this.rightmostX = x + width;

    // Chance to spawn coins
    if (rand(10) > 2)
    {
      this.spawnCoinsOnPlatform(x, y, width);
    }

    // Chance to spawn drone enemy
    if (rand(10) > 4)
    {
      let isHigh = rand(2) == 1;
      let droneY = y - 48.0;
      if (isHigh)
      {
        droneY = y - 85.0;
      }
      let droneX = x + width * 0.5;
      this.dronesList.push([droneX, droneY, droneY, 0.0, 36.0, 26.0, true, isHigh]);
    }

    // Rare chance to spawn shield orb
    if (rand(12) == 1)
    {
      this.shieldsList.push([x + width * 0.5, y - 60.0, true, 0.0]);
    }
  }

  update(dt, player, particles)
  {
    // Speed scaling over distance
    this.distance = this.distance + this.scrollSpeed * dt;
    this.score = this.score + (this.scrollSpeed * dt * 0.1);
    this.scrollSpeed = config.baseRunSpeed + (this.distance / 1000.0) * config.speedAcceleration;
    if (this.scrollSpeed > config.maxRunSpeed)
    {
      this.scrollSpeed = config.maxRunSpeed;
    }

    let dx = this.scrollSpeed * dt;

    // Parallax background offsets
    this.skylineOffset = this.skylineOffset + dx * 0.15;
    if (this.skylineOffset >= 1280.0) this.skylineOffset = this.skylineOffset - 1280.0;

    this.buildingsOffset = this.buildingsOffset + dx * 0.45;
    if (this.buildingsOffset >= 1280.0) this.buildingsOffset = this.buildingsOffset - 1280.0;

    this.foregroundOffset = this.foregroundOffset + dx * 0.85;
    if (this.foregroundOffset >= 1760.0) this.foregroundOffset = this.foregroundOffset - 1760.0;

    // Update platforms
    let activePlatforms = [];
    for (let i = 0; i < len(this.platforms); i = i + 1)
    {
      let plat = this.platforms[i];
      plat[0] = plat[0] - dx;
      if (plat[0] + plat[2] > -60.0)
      {
        activePlatforms.push(plat);
      }
    }
    this.platforms = activePlatforms;
    this.rightmostX = this.rightmostX - dx;

    // Ensure future platforms are generated ahead
    while (this.rightmostX < config.screenWidth + 500.0)
    while (this.rightmostX < gui.getScreenWidth() + 500.0)
    {
      this.generateNextPlatform();
    }

    // Update coins
    let activeCoins = [];
    for (let i = 0; i < len(this.coinsList); i = i + 1)
    {
      let coin = this.coinsList[i];
      coin[0] = coin[0] - dx;
      coin[3] = coin[3] + dt * 4.0; // bobbing
      if (coin[3] >= 2.0) coin[3] = coin[3] - 2.0;
      if (coin[0] > -30.0 and coin[2])
      {
        // Check collision with player
        let coinBob = 3.0;
        if (coin[3] < 1.0) coinBob = -3.0;
        let coinY = coin[1] + coinBob;
        let playerHb = player.getHitbox();
        if (gui.checkCollisionCircleRec(coin[0], coinY, 11.0,
                                       playerHb[0], playerHb[1], playerHb[2], playerHb[3]))
        {
          coin[2] = false;
          this.coins = this.coins + 1;
          this.score = this.score + 50;
          assets.playCoin();
          particles.addSparks(coin[0], coinY, 8, config.colorYellowR, config.colorYellowG, config.colorYellowB);
          particles.addPopup(coin[0] - 8, coinY - 14, "+50", config.colorYellowR, config.colorYellowG, config.colorYellowB);
        }
        else
        {
          activeCoins.push(coin);
        }
      }
    }
    this.coinsList = activeCoins;

    // Update shields
    let activeShields = [];
    for (let i = 0; i < len(this.shieldsList); i = i + 1)
    {
      let shd = this.shieldsList[i];
      shd[0] = shd[0] - dx;
      shd[3] = shd[3] + dt * 3.0;
      if (shd[3] >= 2.0) shd[3] = shd[3] - 2.0;
      if (shd[0] > -30.0 and shd[2])
      {
        let shdBob = 4.0;
        if (shd[3] < 1.0) shdBob = -4.0;
        let shdY = shd[1] + shdBob;
        let playerHb = player.getHitbox();
        if (gui.checkCollisionCircleRec(shd[0], shdY, 14.0,
                                       playerHb[0], playerHb[1], playerHb[2], playerHb[3]))
        {
          shd[2] = false;
          player.giveShield(particles);
          this.score = this.score + 100;
          assets.playCoin();
          particles.addSparks(shd[0], shdY, 14, config.colorCyanR, config.colorCyanG, config.colorCyanB);
        }
        else
        {
          activeShields.push(shd);
        }
      }
    }
    this.shieldsList = activeShields;

    // Update patrol drones
    let activeDrones = [];
    for (let i = 0; i < len(this.dronesList); i = i + 1)
    {
      let drone = this.dronesList[i];
      drone[0] = drone[0] - dx - 35.0 * dt; // flies slightly forward relative to platforms
      drone[3] = drone[3] + dt * 4.0;
      if (drone[3] >= 2.0) drone[3] = drone[3] - 2.0;
      let droneHover = 6.0;
      if (drone[3] < 1.0) droneHover = -6.0;
      drone[1] = drone[2] + droneHover; // hovering motion

      if (drone[0] > -60.0 and drone[6])
      {
        let playerHb = player.getHitbox();
        if (gui.checkCollisionRecs(playerHb[0], playerHb[1], playerHb[2], playerHb[3],
                                   drone[0], drone[1], drone[4], drone[5]))
        {
          // Stomp test: player moving downward and feet above center of drone
          let playerBottom = playerHb[1] + playerHb[3];
          if (player.vy > 30.0 and playerBottom <= drone[1] + drone[5] * 0.6)
          {
            // Stomp kill!
            drone[6] = false;
            player.bounce(particles);
            this.score = this.score + 250;
            assets.playStomp();
            particles.addExplosion(drone[0] + 18, drone[1] + 12);
            particles.addPopup(drone[0] - 10, drone[1] - 22, "+250 STOMP!", config.colorMagentaR, config.colorMagentaG, config.colorMagentaB);
          }
          else
          {
            // Player collision damage!
            player.hit(particles);
            activeDrones.push(drone);
          }
        }
        else
        {
          activeDrones.push(drone);
        }
      }
    }
    this.dronesList = activeDrones;

    // Player Platform Collisions
    let playerHb = player.getHitbox();
    let playerBottom = playerHb[1] + playerHb[3];
    let groundedThisFrame = false;

    for (let i = 0; i < len(this.platforms); i = i + 1)
    {
      let plat = this.platforms[i];
      // Check horizontal overlap
      if (playerHb[0] + playerHb[2] > plat[0] + 4.0 and playerHb[0] < plat[0] + plat[2] - 4.0)
      {
        // Check landing on top of platform
        if (player.vy >= 0.0 and playerBottom >= plat[1] and playerBottom <= plat[1] + 20.0)
        {
          player.y = plat[1] - playerHb[3];
          player.vy = 0.0;
          player.isGrounded = true;
          player.jumpsLeft = 2;
          groundedThisFrame = true;
          break;
        }
      }
    }

    if (!groundedThisFrame)
    {
      player.isGrounded = false;
    }

    // Check pit fall
    if (player.y > gui.getScreenHeight() + 10.0)
    {
      player.hit(particles);
    }
  }

  drawParallax()
  {
    let bgH = gui.getScreenHeight();
    // Layer 1: Skyline (Distant)
    if (assets.texBgSkyline != 0)
    {
      gui.drawTexturePro(assets.texBgSkyline,
                         0.0, 0.0, 512.0, 192.0,
                         -this.skylineOffset, 0.0, 1280.0, bgH,
                         0.0, 0.0, 0.0);
      gui.drawTexturePro(assets.texBgSkyline,
                         0.0, 0.0, 512.0, 192.0,
                         1280.0 - this.skylineOffset, 0.0, 1280.0, bgH,
                         0.0, 0.0, 0.0);
    }

    // Layer 2: Midground Buildings
    if (assets.texBgBuildings != 0)
    {
      gui.drawTexturePro(assets.texBgBuildings,
                         0.0, 0.0, 512.0, 192.0,
                         -this.buildingsOffset, 0.0, 1280.0, bgH,
                         0.0, 0.0, 0.0);
      gui.drawTexturePro(assets.texBgBuildings,
                         0.0, 0.0, 512.0, 192.0,
                         1280.0 - this.buildingsOffset, 0.0, 1280.0, bgH,
                         0.0, 0.0, 0.0);
    }

    // Layer 3: Foreground Street / Rooftops
    if (assets.texBgForeground != 0)
    {
      gui.drawTexturePro(assets.texBgForeground,
                         0.0, 0.0, 704.0, 192.0,
                         -this.foregroundOffset, 0.0, 1760.0, bgH,
                         0.0, 0.0, 0.0);
      gui.drawTexturePro(assets.texBgForeground,
                         0.0, 0.0, 704.0, 192.0,
                         1760.0 - this.foregroundOffset, 0.0, 1760.0, bgH,
                         0.0, 0.0, 0.0);
    }
  }

  draw()
  {
    // Draw platforms
    for (let i = 0; i < len(this.platforms); i = i + 1)
    {
      let plat = this.platforms[i];
      let px = plat[0];
      let py = plat[1];
      let pw = plat[2];
      let ph = plat[3];

      // Solid body
      gui.drawRectangle(px, py, pw, ph, config.colorDarkR, config.colorDarkG, config.colorDarkB);
      // Neon top edge
      gui.drawRectangle(px, py, pw, 3, config.colorPlatformEdgeR, config.colorPlatformEdgeG, config.colorPlatformEdgeB);
      // Subtle edge line
      gui.drawLine(px, py + 3, px + pw, py + 3, config.colorCyanR, config.colorCyanG, config.colorCyanB);
      // Decorative futuristic bolt rivets
      for (let bx = px + 15.0; bx < px + pw - 10.0; bx = bx + 50.0)
      {
        gui.drawCircle(bx, py + 12.0, 2.0, 60, 70, 90);
      }
    }

    // Draw coins
    for (let i = 0; i < len(this.coinsList); i = i + 1)
    {
      let coin = this.coinsList[i];
      let coinBob = 3.0;
      if (coin[3] < 1.0) coinBob = -3.0;
      let coinY = coin[1] + coinBob;
      gui.drawCircle(coin[0], coinY, 9.0, config.colorYellowR, config.colorYellowG, config.colorYellowB);
      gui.drawCircleLines(coin[0], coinY, 9.0, 255, 255, 220);
      gui.drawCircleLines(coin[0], coinY, 5.0, 200, 160, 0);
    }

    // Draw shields
    for (let i = 0; i < len(this.shieldsList); i = i + 1)
    {
      let shd = this.shieldsList[i];
      let shdBob = 4.0;
      if (shd[3] < 1.0) shdBob = -4.0;
      let shdY = shd[1] + shdBob;
      gui.drawCircleAlpha(shd[0], shdY, 14.0, config.colorCyanR, config.colorCyanG, config.colorCyanB, 90);
      gui.drawCircleLines(shd[0], shdY, 14.0, config.colorCyanR, config.colorCyanG, config.colorCyanB);
      gui.drawCircle(shd[0], shdY, 6.0, config.colorWhiteR, config.colorWhiteG, config.colorWhiteB);
    }

    // Draw patrol drones
    for (let i = 0; i < len(this.dronesList); i = i + 1)
    {
      let drone = this.dronesList[i];
      let dx = drone[0];
      let dy = drone[1];
      let dw = drone[4];
      let dh = drone[5];

      // Drone hull
      gui.drawRectangleRounded(dx, dy, dw, dh, 0.4, 6, 40, 44, 60);
      // Glowing red ocular sensor / visor
      gui.drawRectangle(dx + 6, dy + 8, dw - 12, 5, config.colorMagentaR, config.colorMagentaG, config.colorMagentaB);
      // Rotors
      gui.drawLine(dx - 4, dy - 2, dx + dw + 4, dy - 2, 160, 170, 190);
      // Bottom thruster spark
      gui.drawCircleAlpha(dx + dw * 0.5, dy + dh + 3, 4.0, config.colorCyanR, config.colorCyanG, config.colorCyanB, 180);
    }
  }
}
