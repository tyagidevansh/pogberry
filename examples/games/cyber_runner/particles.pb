use "pb_gui" as gui;
use "config";

export class Particle
{
  init(x, y, vx, vy, size, life, r, g, b)
  {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.size = size;
    this.life = life;
    this.maxLife = life;
    this.r = r;
    this.g = g;
    this.b = b;
  }

  update(dt)
  {
    this.x = this.x + this.vx * dt;
    this.y = this.y + this.vy * dt;
    this.vy = this.vy + 200.0 * dt; // slight gravity
    this.life = this.life - dt;
    return this.life > 0;
  }

  draw()
  {
    if (this.life <= 0) return;
    let alpha = (this.life / this.maxLife) * 220.0;
    if (alpha > 255.0) alpha = 255.0;
    if (alpha < 0.0) alpha = 0.0;
    gui.drawCircleAlpha(this.x, this.y, this.size, this.r, this.g, this.b, alpha);
  }
}

export class PopupText
{
  init(x, y, text, r, g, b)
  {
    this.x = x;
    this.y = y;
    this.text = text;
    this.vy = -65.0;
    this.life = 0.85;
    this.maxLife = 0.85;
    this.r = r;
    this.g = g;
    this.b = b;
  }

  update(dt)
  {
    this.y = this.y + this.vy * dt;
    this.life = this.life - dt;
    return this.life > 0;
  }

  draw()
  {
    if (this.life <= 0) return;
    gui.drawText(this.text, this.x, this.y, 16, this.r, this.g, this.b);
  }
}

export class ParticleSystem
{
  init()
  {
    this.particles = [];
    this.popups = [];
  }

  addDust(x, y)
  {
    for (let i = 0; i < 3; i = i + 1)
    {
      let vx = -60.0 - rand(40);
      let vy = -20.0 - rand(30);
      let p = Particle(x + rand(10) - 5, y + rand(4), vx, vy, 2.5 + rand(3), 0.35, 180, 190, 210);
      this.particles.push(p);
    }
  }

  addSparks(x, y, count, r, g, b)
  {
    for (let i = 0; i < count; i = i + 1)
    {
      let angle = (rand(360) / 180.0) * 3.14159;
      let speed = 70.0 + rand(160);
      let vx = speed * (rand(200) - 100) / 100.0;
      let vy = speed * (rand(200) - 100) / 100.0;
      let p = Particle(x, y, vx, vy, 2.0 + rand(3), 0.45, r, g, b);
      this.particles.push(p);
    }
  }

  addExplosion(x, y)
  {
    this.addSparks(x, y, 18, config.colorMagentaR, config.colorMagentaG, config.colorMagentaB);
    this.addSparks(x, y, 12, config.colorYellowR, config.colorYellowG, config.colorYellowB);
  }

  addPopup(x, y, text, r, g, b)
  {
    let pop = PopupText(x, y, text, r, g, b);
    this.popups.push(pop);
  }

  update(dt)
  {
    let nextP = [];
    for (let i = 0; i < len(this.particles); i = i + 1)
    {
      let p = this.particles[i];
      if (p.update(dt))
      {
        nextP.push(p);
      }
    }
    this.particles = nextP;

    let nextPop = [];
    for (let i = 0; i < len(this.popups); i = i + 1)
    {
      let pop = this.popups[i];
      if (pop.update(dt))
      {
        nextPop.push(pop);
      }
    }
    this.popups = nextPop;
  }

  draw()
  {
    for (let i = 0; i < len(this.particles); i = i + 1)
    {
      this.particles[i].draw();
    }
    for (let i = 0; i < len(this.popups); i = i + 1)
    {
      this.popups[i].draw();
    }
  }

  clear()
  {
    this.particles = [];
    this.popups = [];
  }
}

