use "pb_gui" as gui;
use "std.math" as math;
use "data/math_util" as mu;

export let POV_COCKPIT     = 0;
export let POV_CLOSE_CHASE = 1;
export let POV_FAR_CHASE   = 2;
export let POV_HOOD        = 3;
export let POV_BUMPER      = 4;
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
    this.pov = 1;
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
    if (this.pov == 0) return "COCKPIT (IN-CAR)";
    if (this.pov == 1) return "CLOSE CHASE";
    if (this.pov == 2) return "FAR CHASE";
    if (this.pov == 3) return "HOOD";
    return "LOW BUMPER";
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

    let targetCamX = carX + fwdX * 0.18;
    let targetCamY = carY + 0.84;
    let targetCamZ = carZ + fwdZ * 0.18;
    let targetLookX = carX + fwdX * 45.0;
    let targetLookY = carY + 0.72;
    let targetLookZ = carZ + fwdZ * 45.0;

    if (this.pov == 1) {

      targetCamX = carX - fwdX * 5.4;
      targetCamY = carY + 2.05;
      targetCamZ = carZ - fwdZ * 5.4;
      targetLookX = carX + fwdX * 20.0;
      targetLookY = carY + 1.1;
      targetLookZ = carZ + fwdZ * 20.0;
    } else if (this.pov == 2) {

      targetCamX = carX - fwdX * 8.5;
      targetCamY = carY + 3.4;
      targetCamZ = carZ - fwdZ * 8.5;
      targetLookX = carX + fwdX * 28.0;
      targetLookY = carY + 1.2;
      targetLookZ = carZ + fwdZ * 28.0;
    } else if (this.pov == 3) {

      targetCamX = carX + fwdX * 1.35;
      targetCamY = carY + 0.85;
      targetCamZ = carZ + fwdZ * 1.35;
      targetLookX = carX + fwdX * 45.0;
      targetLookY = carY + 0.65;
      targetLookZ = carZ + fwdZ * 45.0;
    } else if (this.pov == 4) {

      targetCamX = carX + fwdX * 2.3;
      targetCamY = carY + 0.52;
      targetCamZ = carZ + fwdZ * 2.3;
      targetLookX = carX + fwdX * 45.0;
      targetLookY = carY + 0.40;
      targetLookZ = carZ + fwdZ * 45.0;
    }

    this.x = targetCamX;
    this.y = targetCamY;
    this.z = targetCamZ;
    this.targetX = targetLookX;
    this.targetY = targetLookY;
    this.targetZ = targetLookZ;
    this.initialized = true;
  }

  update(car, track, dt) {
    if (car == nil) return;
    let lookCurve = 0.0;
    let lookHill = 0.0;
    if (track != nil) {
      lookCurve = track.getCurveOffset(-30.0, car.trackDistance);
      lookHill = track.getYOffset(-30.0, car.trackDistance);
    }
    this.setLookAhead(lookCurve, lookHill);
    let isBoost = false;
    if (car.isBoosting != nil) isBoost = car.isBoosting;
    let dAngle = 0.0;
    if (car.driftAngle != nil) dAngle = car.driftAngle;
    this.updateFollow(car.worldX, car.worldY, car.worldZ, car.speed, car.worldHeading, car.steerAngle, dAngle, isBoost, dt);
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

      targetCamX = carX + fwdX * 0.18;
      targetCamY = carY + 0.78;
      targetCamZ = carZ + fwdZ * 0.18;
      targetLookX = carX + fwdX * 45.0;
      targetLookY = carY + 0.76;
      targetLookZ = carZ + fwdZ * 45.0;
      followSpeed = 34.0;
      targetFov = 74.0 + normSpd * 5.0;
    } else if (this.pov == 1) {

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
    } else if (this.pov == 2) {

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
    } else if (this.pov == 3) {

      targetCamX = carX + fwdX * 1.35;
      targetCamY = carY + 0.85;
      targetCamZ = carZ + fwdZ * 1.35;
      targetLookX = carX + fwdX * 45.0;
      targetLookY = carY + 0.65;
      targetLookZ = carZ + fwdZ * 45.0;
      followSpeed = 36.0;
      targetFov = 72.0 + normSpd * 6.0;
    } else {

      targetCamX = carX + fwdX * 2.3;
      targetCamY = carY + 0.52;
      targetCamZ = carZ + fwdZ * 2.3;
      targetLookX = carX + fwdX * 45.0;
      targetLookY = carY + 0.40;
      targetLookZ = carZ + fwdZ * 45.0;
      followSpeed = 38.0;
      targetFov = 78.0 + normSpd * 8.0;
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

    this.upX = 0.0;
    this.upY = 1.0;
    this.upZ = 0.0;

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
    gui.begin3DEx([this.x + sx, this.y + sy, this.z],
                  [this.targetX + sx, this.targetY + sy, this.targetZ],
                  [this.upX, this.upY, this.upZ], this.fov);
  }

  end3DPass() {
    gui.end3D();
  }
}
