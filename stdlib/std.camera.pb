export class Camera
{
  init(viewW, viewH)
  {
    if (viewW == nil or viewW <= 0) viewW = 800;
    if (viewH == nil or viewH <= 0) viewH = 450;
    this.viewW = viewW;
    this.viewH = viewH;
    this.x = 0;
    this.y = 0;
    this.zoom = 1;
    this.trauma = 0;
    this.shakeX = 0;
    this.shakeY = 0;
    this.maxShake = 20;
  }

  setZoom(z)
  {
    if (z == nil or z <= 0) return nil;
    if (z < 0.25) z = 0.25;
    if (z > 4) z = 4;
    this.zoom = z;
    return nil;
  }

  snapTo(wx, wy)
  {
    this.x = wx - this.viewW / (2 * this.zoom);
    this.y = wy - this.viewH / (2 * this.zoom);
    return nil;
  }

  follow(wx, wy, smoothing, dt)
  {
    let wantX = wx - this.viewW / (2 * this.zoom);
    let wantY = wy - this.viewH / (2 * this.zoom);
    if (smoothing == nil or smoothing <= 0 or dt == nil or dt <= 0)
    {
      this.x = wantX;
      this.y = wantY;
      return nil;
    }
    let t = smoothing * dt;
    if (t > 1) t = 1;
    this.x = this.x + (wantX - this.x) * t;
    this.y = this.y + (wantY - this.y) * t;
    return nil;
  }

  clampTo(minX, minY, maxX, maxY)
  {
    if (maxX < minX) this.x = (minX + maxX) / 2;
    else if (this.x < minX) this.x = minX;
    else if (this.x > maxX) this.x = maxX;
    if (maxY < minY) this.y = (minY + maxY) / 2;
    else if (this.y < minY) this.y = minY;
    else if (this.y > maxY) this.y = maxY;
    return nil;
  }

  addShake(amount)
  {
    if (amount == nil or amount <= 0) return nil;
    this.trauma = this.trauma + amount;
    if (this.trauma > 1) this.trauma = 1;
    return nil;
  }

  update(dt)
  {
    if (dt == nil or dt < 0) dt = 0;
    if (this.trauma > 0)
    {
      this.trauma = this.trauma - dt * 1.4;
      if (this.trauma < 0) this.trauma = 0;
    }
    if (this.trauma <= 0)
    {
      this.shakeX = 0;
      this.shakeY = 0;
      return nil;
    }
    let mag = this.maxShake * this.trauma * this.trauma;
    this.shakeX = (rand() * 2 - 1) * mag;
    this.shakeY = (rand() * 2 - 1) * mag;
    return nil;
  }

  applyX(wx)
  {
    return (wx - this.x) * this.zoom + this.shakeX;
  }

  applyY(wy)
  {
    return (wy - this.y) * this.zoom + this.shakeY;
  }

  worldX(sx)
  {
    return (sx - this.shakeX) / this.zoom + this.x;
  }

  worldY(sy)
  {
    return (sy - this.shakeY) / this.zoom + this.y;
  }

  isVisible(wx, wy, w, h, margin)
  {
    if (margin == nil or margin < 0) margin = 0;
    let sx = this.applyX(wx);
    let sy = this.applyY(wy);
    let sw = w * this.zoom;
    let sh = h * this.zoom;
    if (sx + sw < 0 - margin) return false;
    if (sy + sh < 0 - margin) return false;
    if (sx > this.viewW + margin) return false;
    if (sy > this.viewH + margin) return false;
    return true;
  }
}
