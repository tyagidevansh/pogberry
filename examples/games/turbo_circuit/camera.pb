// TURBO CIRCUIT: OVERDRIVE — 3D Dynamic Camera
use "pb_gui" as gui;
use "std.math" as math;
use "math_util" as mu;

export class ChaseCamera {
  init() {
    this.x = 0.0;
    this.y = 5.6;
    this.z = 10.5;

    this.targetX = 0.0;
    this.targetY = 1.2;
    this.targetZ = -25.0;

    this.upX = 0.0;
    this.upY = 1.0;
    this.upZ = 0.0;

    this.baseFov = 64.0;
    this.fov = 64.0;
    this.shake = 0.0;
    this.orbitAngle = 0.0;
    this.lookCurve = 0.0;
    this.lookHill = 0.0;
  }

  setLookCurve(curve) {
    this.lookCurve = curve;
  }

  setLookAhead(curve, hill) {
    this.lookCurve = curve;
    this.lookHill = hill;
  }

  addShake(amount) {
    this.shake = this.shake + amount;
    if (this.shake > 1.2) this.shake = 1.2;
  }

  updateFollow(carX, carY, carZ, speed, steer, driftAngle, boosting, dt) {
    // 1. Calculate ideal camera position directly behind vehicle
    let targetCamX = carX * 0.72;
    let targetCamY = 4.8 + (speed / 140.0) * 0.6;
    let targetCamZ = carZ + 9.8 + (speed / 120.0) * 1.5;

    // Camera lag / smoothing
    let followSpeed = 12.0;
    this.x = mu.lerp(this.x, targetCamX, dt * followSpeed);
    this.y = mu.lerp(this.y, targetCamY, dt * followSpeed);
    this.z = mu.lerp(this.z, targetCamZ, dt * followSpeed);

    // 2. Camera target lookahead
    let lookDist = 32.0;
    let targetLookX = carX * 0.35 + (this.lookCurve * 0.45) - steer * 1.0;
    let targetLookY = 1.2 + (this.lookHill * 0.45);
    let targetLookZ = carZ - lookDist;

    this.targetX = mu.lerp(this.targetX, targetLookX, dt * 10.0);
    this.targetY = mu.lerp(this.targetY, targetLookY, dt * 10.0);
    this.targetZ = mu.lerp(this.targetZ, targetLookZ, dt * 10.0);

    // 3. Dynamic Roll (Bank into sharp turns)
    let rollAngle = (steer * 0.10) + (driftAngle * 0.05);
    this.upX = math.sin(rollAngle);
    this.upY = math.cos(rollAngle);
    this.upZ = 0.0;

    // 4. Dynamic FOV
    let targetFov = this.baseFov + (speed / 120.0) * 14.0;
    if (boosting) targetFov = targetFov + 12.0;
    this.fov = mu.lerp(this.fov, targetFov, dt * 5.0);

    // 5. Screen Shake decay
    if (this.shake > 0.0) {
      this.shake = this.shake - dt * 2.8;
      if (this.shake < 0.0) this.shake = 0.0;
    }
  }

  updateTurntable(centerX, centerY, centerZ, distance, height, dt) {
    this.orbitAngle = this.orbitAngle + dt * 0.7;
    this.x = centerX + math.sin(this.orbitAngle) * distance;
    this.y = centerY + height;
    this.z = centerZ + math.cos(this.orbitAngle) * distance;

    this.targetX = centerX;
    this.targetY = centerY + 0.6;
    this.targetZ = centerZ;

    this.upX = 0.0;
    this.upY = 1.0;
    this.upZ = 0.0;
    this.fov = 54.0;
    this.shake = 0.0;
  }

  updateCinematic(t) {
    this.x = math.sin(t * 0.3) * 6.0;
    this.y = 4.5 + math.sin(t * 0.5) * 1.2;
    this.z = 12.0;

    this.targetX = math.sin(t * 0.4) * 2.0;
    this.targetY = 1.0;
    this.targetZ = -40.0;

    this.upX = math.sin(t * 0.3) * 0.05;
    this.upY = 1.0;
    this.upZ = 0.0;
    this.fov = 62.0;
  }

  begin3DPass() {
    let sx = 0.0;
    let sy = 0.0;
    if (this.shake > 0.0) {
      sx = (rand(100) - 50) / 100.0 * this.shake * 0.45;
      sy = (rand(100) - 50) / 100.0 * this.shake * 0.35;
    }
    gui.begin3DEx(this.x + sx, this.y + sy, this.z,
                  this.targetX + sx, this.targetY + sy, this.targetZ,
                  this.upX, this.upY, this.upZ, this.fov);
  }

  end3DPass() {
    gui.end3D();
  }
}

