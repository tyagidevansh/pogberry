use "pb_gui" as gui;
use "config";
use "assets";

export class Player
{
  init()
  {
    this.reset();
  }

  reset()
  {
    this.x = config.playerStartX;
    this.y = 260.0;
    this.vy = 0.0;
    this.isGrounded = false;
    this.isSliding = false;
    this.jumpsLeft = 2;
    this.animTimer = 0.0;
    this.currentFrame = 0;
    this.shieldActive = false;
    this.invulnerableTimer = 0.0;
    this.dustTimer = 0.0;
    this.isAlive = true;
  }

  jump(particles)
  {
    if (!this.isAlive) return;

    if (this.isGrounded)
    {
      this.vy = -config.jumpSpeed;
      this.isGrounded = false;
      this.jumpsLeft = 1;
      assets.playJump();
      particles.addDust(this.x + 16, this.y + config.playerHitboxHeight);
    }
    else if (this.jumpsLeft > 0)
    {
      this.vy = -config.doubleJumpSpeed;
      this.jumpsLeft = 0;
      assets.playJump();
      particles.addSparks(this.x + 16, this.y + 40, 10, config.colorCyanR, config.colorCyanG, config.colorCyanB);
      particles.addPopup(this.x - 10, this.y, "DOUBLE JUMP!", config.colorCyanR, config.colorCyanG, config.colorCyanB);
    }
  }

  slide(active)
  {
    this.isSliding = active;
  }

  bounce(particles)
  {
    this.vy = -config.stompBounceSpeed;
    this.jumpsLeft = 1;
    particles.addSparks(this.x + 16, this.y + config.playerHitboxHeight, 14, config.colorYellowR, config.colorYellowG, config.colorYellowB);
  }

  giveShield(particles)
  {
    this.shieldActive = true;
    particles.addPopup(this.x - 10, this.y - 15, "SHIELD ACTIVE!", config.colorCyanR, config.colorCyanG, config.colorCyanB);
  }

  hit(particles)
  {
    if (this.invulnerableTimer > 0.0) return false;

    if (this.shieldActive)
    {
      this.shieldActive = false;
      this.invulnerableTimer = 1.4;
      assets.playStomp();
      particles.addExplosion(this.x + 16, this.y + 20);
      particles.addPopup(this.x - 10, this.y - 15, "SHIELD BROKEN!", config.colorMagentaR, config.colorMagentaG, config.colorMagentaB);
      return false;
    }

    this.isAlive = false;
    assets.playBoom();
    particles.addExplosion(this.x + 16, this.y + 20);
    return true;
  }

  getHitbox()
  {
    if (this.isSliding)
    {
      return [this.x, this.y + (config.playerHitboxHeight - config.playerSlideHitboxHeight),
              config.playerHitboxWidth, config.playerSlideHitboxHeight];
    }
    return [this.x, this.y, config.playerHitboxWidth, config.playerHitboxHeight];
  }

  update(dt, particles)
  {
    if (!this.isAlive) return;

    // Gravity
    this.vy = this.vy + config.gravity * dt;
    if (this.vy > 750.0) this.vy = 750.0;
    this.y = this.y + this.vy * dt;

    // Invulnerability decrement
    if (this.invulnerableTimer > 0.0)
    {
      this.invulnerableTimer = this.invulnerableTimer - dt;
      if (this.invulnerableTimer < 0.0) this.invulnerableTimer = 0.0;
    }

    // Animation frames
    if (this.isGrounded)
    {
      this.animTimer = this.animTimer + dt;
      if (this.animTimer >= 0.09)
      {
        this.animTimer = 0.0;
        this.currentFrame = this.currentFrame + 1;
        if (this.currentFrame >= 6) this.currentFrame = 0;
      }

      // Footstep dust
      this.dustTimer = this.dustTimer + dt;
      if (this.dustTimer >= 0.18)
      {
        this.dustTimer = 0.0;
        particles.addDust(this.x + 4, this.y + config.playerHitboxHeight);
      }
    }
    else
    {
      // Air pose
      if (this.vy < -50.0)
      {
        this.currentFrame = 2; // Jump rise
      }
      else
      {
        this.currentFrame = 4; // Fall
      }
    }
  }

  draw()
  {
    if (!this.isAlive) return;

    // Flash when invulnerable
    if (this.invulnerableTimer > 0.0)
    {
      let flashTime = this.invulnerableTimer;
      while (flashTime >= 0.2)
      {
        flashTime = flashTime - 0.2;
      }
      if (flashTime < 0.1) return;
    }

    let frameX = this.currentFrame * 128.0;
    let frameY = 0.0;
    let frameW = 128.0;
    let frameH = 128.0;

    let destX = this.x - 20.0;
    let destY = this.y - 12.0;
    let destW = config.playerDrawWidth;
    let destH = config.playerDrawHeight;

    if (this.isSliding)
    {
      destH = config.playerDrawHeight * 0.55;
      destY = this.y + (config.playerHitboxHeight - config.playerSlideHitboxHeight) - 8.0;
      destW = config.playerDrawWidth * 1.1;
    }

    if (assets.texScarfy != 0)
    {
      gui.drawTexturePro(assets.texScarfy,
                         frameX, frameY, frameW, frameH,
                         destX, destY, destW, destH,
                         0.0, 0.0, 0.0);
    }
    else
    {
      // Fallback shape if texture is missing
      let hb = this.getHitbox();
      gui.drawRectangle(hb[0], hb[1], hb[2], hb[3], config.colorCyanR, config.colorCyanG, config.colorCyanB);
    }

    // Shield forcefield rendering
    if (this.shieldActive)
    {
      let centerX = this.x + 16.0;
      let centerY = this.y + 26.0;
      gui.drawCircleAlpha(centerX, centerY, 32.0, config.colorCyanR, config.colorCyanG, config.colorCyanB, 50);
      gui.drawCircleLines(centerX, centerY, 32.0, config.colorCyanR, config.colorCyanG, config.colorCyanB);
      gui.drawCircleLines(centerX, centerY, 34.0, config.colorWhiteR, config.colorWhiteG, config.colorWhiteB);
    }
  }
}
