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
    this.targetLookCurve = 0.0;
    this.targetLookHill = 0.0;
    this.shakeTimer = 0.0;
  }

  setLookCurve(curve) {
    this.targetLookCurve = curve;
  }

  setLookAhead(curve, hill) {
    this.targetLookCurve = curve;
    this.targetLookHill = hill;
  }

  addShake(amount) {
    this.shake = this.shake + amount;
    if (this.shake > 0.40) this.shake = 0.40;
  }

  updateFollow(carX, carY, carZ, speed, heading, steerAngle, driftAngle, boosting, dt) {
    // 1. Camera position behind vehicle following car heading smoothly in full 360 degrees
    let normSpd = math.abs(speed) / 80.0;
    if (normSpd > 1.0) normSpd = 1.0;
    let camDist = 9.2 + normSpd * 1.5;
    let targetCamX = carX - math.sin(heading) * camDist;
    let targetCamY = carY + 4.2;
    let targetCamZ = carZ + math.cos(heading) * camDist;

    // Unified camera lag / smoothing rate prevents orientation twisting jitter
    let followSpeed = 12.0;
    this.x = mu.lerp(this.x, targetCamX, dt * followSpeed);
    this.y = mu.lerp(this.y, targetCamY, dt * followSpeed);
    this.z = mu.lerp(this.z, targetCamZ, dt * followSpeed);

    // 2. Camera target looks ahead along vehicle heading
    this.lookHill = mu.lerp(this.lookHill, this.targetLookHill, dt * 6.0);
    let lookDist = 28.0;
    let targetLookX = carX + math.sin(heading) * lookDist;
    let targetLookY = carY + 1.2 + (this.lookHill * 0.28);
    let targetLookZ = carZ - math.cos(heading) * lookDist;

    this.targetX = mu.lerp(this.targetX, targetLookX, dt * followSpeed);
    this.targetY = mu.lerp(this.targetY, targetLookY, dt * followSpeed);
    this.targetZ = mu.lerp(this.targetZ, targetLookZ, dt * followSpeed);

    // 3. Level Horizon: Zero roll to eliminate simulator sickness and visual nausea
    this.upX = 0.0;
    this.upY = 1.0;
    this.upZ = 0.0;

    // 4. Stable FOV: subtle, comfortable progression without nauseating fisheye distortion
    let targetFov = this.baseFov + normSpd * 4.0;
    if (boosting) targetFov = targetFov + 3.0;
    this.fov = mu.lerp(this.fov, targetFov, dt * 4.0);

    // 5. Screen Shake decay
    if (this.shake > 0.0) {
      this.shakeTimer = this.shakeTimer + dt * 24.0;
      this.shake = this.shake - dt * 2.2;
      if (this.shake < 0.0) {
        this.shake = 0.0;
        this.shakeTimer = 0.0;
      }
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
      sx = math.sin(this.shakeTimer) * this.shake * 0.14;
      sy = math.cos(this.shakeTimer * 1.2) * this.shake * 0.10;
    }
    gui.begin3DEx(this.x + sx, this.y + sy, this.z,
                  this.targetX + sx, this.targetY + sy, this.targetZ,
                  this.upX, this.upY, this.upZ, this.fov);
  }

  end3DPass() {
    gui.end3D();
  }
}

