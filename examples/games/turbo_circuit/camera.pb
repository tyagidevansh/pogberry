// TURBO CIRCUIT: OVERDRIVE — True World-Space 3D Chase Camera
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
    this.targetZ = 25.0;

    this.upX = 0.0;
    this.upY = 1.0;
    this.upZ = 0.0;

    this.baseFov = 65.0;
    this.fov = 65.0;
    this.shake = 0.0;
    this.orbitAngle = 0.0;
    this.lookCurve = 0.0;
    this.lookHill = 0.0;
    this.targetLookCurve = 0.0;
    this.targetLookHill = 0.0;
    this.shakeTimer = 0.0;
    this.initialized = false;
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

  snap(carX, carY, carZ, heading) {
    let camDist = 8.2;
    let lookDist = 24.0;
    this.x = carX - math.sin(heading) * camDist;
    this.y = carY + 3.2;
    this.z = carZ - math.cos(heading) * camDist;
    this.targetX = carX + math.sin(heading) * lookDist;
    this.targetY = carY + 1.2;
    this.targetZ = carZ + math.cos(heading) * lookDist;
    this.initialized = true;
  }

  updateFollow(carX, carY, carZ, speed, heading, steerAngle, driftAngle, boosting, dt) {
    let normSpd = math.abs(speed) / 80.0;
    if (normSpd > 1.0) normSpd = 1.0;
    let camDist = 8.2 + normSpd * 1.5;
    let lookDist = 24.0 + normSpd * 4.0;

    // 1. Camera eye position placed behind vehicle in 3D world space
    let targetCamX = carX - math.sin(heading) * camDist;
    let targetCamY = carY + 3.2;
    let targetCamZ = carZ - math.cos(heading) * camDist;

    // 2. Camera look target placed ahead along vehicle heading
    let targetLookX = carX + math.sin(heading) * lookDist;
    let targetLookY = carY + 1.2;
    let targetLookZ = carZ + math.cos(heading) * lookDist;

    if (!this.initialized) {
      this.x = targetCamX;
      this.y = targetCamY;
      this.z = targetCamZ;
      this.targetX = targetLookX;
      this.targetY = targetLookY;
      this.targetZ = targetLookZ;
      this.initialized = true;
    } else {
      let followSpeed = 12.0;
      this.x = mu.lerp(this.x, targetCamX, dt * followSpeed);
      this.y = mu.lerp(this.y, targetCamY, dt * followSpeed);
      this.z = mu.lerp(this.z, targetCamZ, dt * followSpeed);

      this.targetX = mu.lerp(this.targetX, targetLookX, dt * (followSpeed * 1.2));
      this.targetY = mu.lerp(this.targetY, targetLookY, dt * (followSpeed * 1.2));
      this.targetZ = mu.lerp(this.targetZ, targetLookZ, dt * (followSpeed * 1.2));
    }

    // 3. Level Horizon: Zero camera roll to guarantee comfort and eliminate nausea
    this.upX = 0.0;
    this.upY = 1.0;
    this.upZ = 0.0;

    // 4. Stable FOV with gentle speed progression
    let targetFov = this.baseFov + normSpd * 5.0;
    if (boosting) targetFov = targetFov + 4.0;
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

  updateCinematicTrack(track, t) {
    if (track == nil or len(track.stations) == 0) {
      this.updateCinematic(t);
      return;
    }
    let st0 = track.stations[0];
    let wx = st0["x"]; let wy = st0["y"]; let wz = st0["z"];
    let tx = st0["tx"]; let tz = st0["tz"];
    let nx = st0["nx"]; let nz = st0["nz"];

    // Dynamic sweeping cinematic tracking along start/finish straight
    let sideDist = -8.5 + math.sin(t * 0.28) * 3.0;
    let backDist = -22.0 + math.cos(t * 0.22) * 5.0;
    this.x = wx + nx * sideDist + tx * backDist;
    this.y = wy + 4.5 + math.sin(t * 0.35) * 0.9;
    this.z = wz + nz * sideDist + tz * backDist;

    let lookDist = 36.0 + math.sin(t * 0.25) * 8.0;
    this.targetX = wx + tx * lookDist + nx * (math.sin(t * 0.3) * 1.5);
    this.targetY = wy + 2.0;
    this.targetZ = wz + tz * lookDist + nz * (math.sin(t * 0.3) * 1.5);

    this.upX = 0.0;
    this.upY = 1.0;
    this.upZ = 0.0;
    this.fov = 58.0;
    this.shake = 0.0;
  }

  updateCinematic(t) {
    this.x = math.sin(t * 0.3) * 6.0;
    this.y = 4.5 + math.sin(t * 0.5) * 1.2;
    this.z = -12.0;

    this.targetX = math.sin(t * 0.4) * 2.0;
    this.targetY = 1.0;
    this.targetZ = 40.0;

    this.upX = 0.0;
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
