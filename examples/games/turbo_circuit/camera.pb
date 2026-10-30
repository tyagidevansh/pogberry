// TURBO CIRCUIT: OVERDRIVE — True World-Space 3D Chase Camera
use "pb_gui" as gui;
use "std.math" as math;
use "math_util" as mu;

export let POV_CLOSE_CHASE = 0;
export let POV_FAR_CHASE   = 1;
export let POV_COCKPIT     = 2;
export let POV_BUMPER      = 3;
export let POV_HELI        = 4;
export let TOTAL_POVS      = 5;

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
    this.pov = 0; // Default: POV_CLOSE_CHASE (closer to car)
  }

  cyclePov() {
    this.pov = (this.pov + 1) % 5;
    this.initialized = false;
    return this.pov;
  }

  setPov(newPov) {
    this.pov = newPov % 5;
    this.initialized = false;
  }

  getPovName() {
    if (this.pov == 0) return "CLOSE CHASE";
    if (this.pov == 1) return "FAR CHASE";
    if (this.pov == 2) return "COCKPIT";
    if (this.pov == 3) return "HOOD / BUMPER";
    return "HELI CAM";
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
    let fwdX = math.sin(heading);
    let fwdZ = math.cos(heading);
    let targetCamX = carX - fwdX * 5.4;
    let targetCamY = carY + 2.05;
    let targetCamZ = carZ - fwdZ * 5.4;
    let targetLookX = carX + fwdX * 20.0;
    let targetLookY = carY + 1.1;
    let targetLookZ = carZ + fwdZ * 20.0;

    if (this.pov == 1) {
      targetCamX = carX - fwdX * 8.5;
      targetCamY = carY + 3.4;
      targetCamZ = carZ - fwdZ * 8.5;
      targetLookX = carX + fwdX * 28.0;
      targetLookY = carY + 1.2;
      targetLookZ = carZ + fwdZ * 28.0;
    } else if (this.pov == 2) {
      targetCamX = carX + fwdX * 0.25;
      targetCamY = carY + 0.98;
      targetCamZ = carZ + fwdZ * 0.25;
      targetLookX = carX + fwdX * 35.0;
      targetLookY = carY + 0.85;
      targetLookZ = carZ + fwdZ * 35.0;
    } else if (this.pov == 3) {
      targetCamX = carX + fwdX * 2.3;
      targetCamY = carY + 0.52;
      targetCamZ = carZ + fwdZ * 2.3;
      targetLookX = carX + fwdX * 45.0;
      targetLookY = carY + 0.40;
      targetLookZ = carZ + fwdZ * 45.0;
    } else if (this.pov == 4) {
      targetCamX = carX - fwdX * 12.5;
      targetCamY = carY + 6.2;
      targetCamZ = carZ - fwdZ * 12.5;
      targetLookX = carX + fwdX * 18.0;
      targetLookY = carY + 0.8;
      targetLookZ = carZ + fwdZ * 18.0;
    }

    this.x = targetCamX;
    this.y = targetCamY;
    this.z = targetCamZ;
    this.targetX = targetLookX;
    this.targetY = targetLookY;
    this.targetZ = targetLookZ;
    this.initialized = true;
  }

  updateFollow(carX, carY, carZ, speed, heading, steerAngle, driftAngle, boosting, dt) {
    let normSpd = math.abs(speed) / 80.0;
    if (normSpd > 1.0) normSpd = 1.0;

    let fwdX = math.sin(heading);
    let fwdZ = math.cos(heading);

    let targetCamX = 0.0;
    let targetCamY = 0.0;
    let targetCamZ = 0.0;
    let targetLookX = 0.0;
    let targetLookY = 0.0;
    let targetLookZ = 0.0;
    let followSpeed = 14.0;
    let targetFov = this.baseFov;

    if (this.pov == 0) {
      // 0. CLOSE CHASE (New Default Closer Camera!)
      let camDist = 5.4 + normSpd * 1.2;
      let lookDist = 20.0 + normSpd * 4.0;
      targetCamX = carX - fwdX * camDist;
      targetCamY = carY + 2.05;
      targetCamZ = carZ - fwdZ * camDist;
      targetLookX = carX + fwdX * lookDist;
      targetLookY = carY + 1.1;
      targetLookZ = carZ + fwdZ * lookDist;
      followSpeed = 14.0;
      targetFov = 66.0 + normSpd * 6.0;
    } else if (this.pov == 1) {
      // 1. FAR CHASE (Classic Wide Arcade Perspective)
      let camDist = 8.5 + normSpd * 1.6;
      let lookDist = 28.0 + normSpd * 4.0;
      targetCamX = carX - fwdX * camDist;
      targetCamY = carY + 3.4;
      targetCamZ = carZ - fwdZ * camDist;
      targetLookX = carX + fwdX * lookDist;
      targetLookY = carY + 1.2;
      targetLookZ = carZ + fwdZ * lookDist;
      followSpeed = 12.0;
      targetFov = 64.0 + normSpd * 5.0;
    } else if (this.pov == 2) {
      // 2. COCKPIT / DRIVER EYE (In cockpit behind steering wheel looking past nose)
      targetCamX = carX + fwdX * 0.25;
      targetCamY = carY + 0.98;
      targetCamZ = carZ + fwdZ * 0.25;
      targetLookX = carX + fwdX * 35.0;
      targetLookY = carY + 0.85;
      targetLookZ = carZ + fwdZ * 35.0;
      followSpeed = 30.0;
      targetFov = 72.0 + normSpd * 6.0;
    } else if (this.pov == 3) {
      // 3. HOOD / BUMPER CAM (Low tarmac high-speed rush)
      targetCamX = carX + fwdX * 2.3;
      targetCamY = carY + 0.52;
      targetCamZ = carZ + fwdZ * 2.3;
      targetLookX = carX + fwdX * 45.0;
      targetLookY = carY + 0.40;
      targetLookZ = carZ + fwdZ * 45.0;
      followSpeed = 36.0;
      targetFov = 76.0 + normSpd * 7.0;
    } else {
      // 4. HELI / TV BROADCAST CAM (High sweeping vantage point)
      let camDist = 12.5;
      let lookDist = 18.0;
      targetCamX = carX - fwdX * camDist;
      targetCamY = carY + 6.2;
      targetCamZ = carZ - fwdZ * camDist;
      targetLookX = carX + fwdX * lookDist;
      targetLookY = carY + 0.8;
      targetLookZ = carZ + fwdZ * lookDist;
      followSpeed = 8.0;
      targetFov = 58.0;
    }

    if (boosting) targetFov = targetFov + 4.0;

    if (!this.initialized) {
      this.x = targetCamX;
      this.y = targetCamY;
      this.z = targetCamZ;
      this.targetX = targetLookX;
      this.targetY = targetLookY;
      this.targetZ = targetLookZ;
      this.fov = targetFov;
      this.initialized = true;
    } else {
      this.x = mu.lerp(this.x, targetCamX, dt * followSpeed);
      this.y = mu.lerp(this.y, targetCamY, dt * followSpeed);
      this.z = mu.lerp(this.z, targetCamZ, dt * followSpeed);

      this.targetX = mu.lerp(this.targetX, targetLookX, dt * (followSpeed * 1.2));
      this.targetY = mu.lerp(this.targetY, targetLookY, dt * (followSpeed * 1.2));
      this.targetZ = mu.lerp(this.targetZ, targetLookZ, dt * (followSpeed * 1.2));
      this.fov = mu.lerp(this.fov, targetFov, dt * 4.0);
    }

    // Level Horizon: Zero camera roll to guarantee comfort and eliminate nausea
    this.upX = 0.0;
    this.upY = 1.0;
    this.upZ = 0.0;

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
