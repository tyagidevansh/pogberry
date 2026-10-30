// TURBO CIRCUIT: OVERDRIVE — True World-Space Vehicle Dynamics & Physics
use "pb_gui" as gui;
use "std.math" as math;
use "math_util" as mu;
use "constants" as const;

export class Vehicle {
  init(carId, isPlayer, name, startZ) {
    this.carId = carId;
    this.spec = const.getCarSpec(carId);
    this.isPlayer = isPlayer;
    this.name = name;

    // World-Space Transform
    this.worldX = 0.0;
    this.worldY = 0.0;
    this.worldZ = startZ;
    this.worldHeading = 0.0; // World yaw angle in radians

    // Track Coordinates (for lap progression, radar minimap, and tests)
    this.trackDistance = 0.0;
    this.x = 0.0; // Signed lateral offset across track centerline in meters
    this.y = 0.0;
    this.z = startZ;
    this.heading = 0.0; // Relative heading to track tangent

    // Dynamics
    this.steer = 0.0;
    this.steerAngle = 0.0;
    this.yawRate = 0.0;
    this.lateralVelocity = 0.0;
    this.driftAngle = 0.0;
    this.isDrifting = false;
    this.driftPoints = 0;
    this.isReversing = false;
    this.completedLaps = 0;
    this.hasCrossedMidpoint = false;

    this.speed = 0.0;
    this.maxSpeed = this.spec["topSpeed"];
    this.boostSpeed = this.spec["boostSpeed"];
    this.accel = this.spec["accel"];
    this.handling = this.spec["handling"];

    // Health & Nitro
    this.maxHull = this.spec["maxHull"];
    this.hull = this.maxHull;
    this.maxNitro = this.spec["nitroCapacity"];
    this.nitro = this.maxNitro;
    this.isBoosting = false;
    this.isBraking = false;
    this.isOffTrack = false;
    this.onCurb = false;
    this.wallDamageCooldown = 0.0;
    this.impactCooldown = 0.0;
    this.spinTimer = 0.0;
    this.brakeWarning = 0;
    this.wallHitShake = 0.0;
    this.inputOverride = nil;
    this.isAutopilot = false;

    // AI parameters
    this.aiLane = 0.0;
    this.aiLaneTimer = 0.0;
    this.aiSkill = mu.randFloat(0.88, 1.12);

    // Visuals
    let col = this.spec["primaryColor"];
    this.colorR = col[0];
    this.colorG = col[1];
    this.colorB = col[2];
    this.scale = this.spec["scale"];
    this.hitFlash = 0.0;
    this.nearMissTimer = 0.0;
    this.nearMissCount = 0;
  }

  setTrackPosition(track, s, lateralOffset) {
    this.trackDistance = s;
    this.x = lateralOffset;
    let p = const.getTrackWorldPoint(track.trackId, s);
    let tan = const.getTrackTangent(track.trackId, s);
    let mag = math.sqrt(tan[0] * tan[0] + tan[1] * tan[1]);
    if (mag < 0.0001) mag = 1.0;
    let tx = tan[0] / mag;
    let tz = tan[1] / mag;
    let nx = -tz;
    let nz = tx;

    this.worldX = p[0] + nx * lateralOffset;
    this.worldZ = p[1] + nz * lateralOffset;
    this.worldY = track.getElevationAt(s) + 0.15;
    this.y = this.worldY;
    let trkHeading = math.atan2(tx, tz);
    this.worldHeading = trkHeading + this.heading;
  }

  updatePlayer(dt, track, particles, assets) {
    // Sync world position from track if uninitialized
    if (this.worldX == 0.0 and this.worldZ == 0.0 and track != nil) {
      this.setTrackPosition(track, this.trackDistance, this.x);
    }

    // 0. Spin-out recovery
    if (this.spinTimer > 0.0) {
      this.spinTimer = this.spinTimer - dt;
      this.speed = mu.approach(this.speed, 25.0, dt * 50.0);
      this.driftAngle = this.driftAngle + 680.0 * dt;
      let trkHead = const.getTrackHeading(track.trackId, this.trackDistance);
      this.worldHeading = trkHead + this.driftAngle * 0.0174533;
      let fwdX = math.sin(this.worldHeading);
      let fwdZ = math.cos(this.worldHeading);
      this.worldX = this.worldX + fwdX * this.speed * dt;
      this.worldZ = this.worldZ + fwdZ * this.speed * dt;
      if (particles != nil) particles.emitDriftSmoke(this.worldX, this.worldY, this.worldZ, 1.0);
      if (this.hitFlash > 0.0) this.hitFlash = this.hitFlash - dt;
      if (this.spinTimer <= 0.0) this.driftAngle = 0.0;
      return;
    }

    if (this.wallDamageCooldown > 0.0) this.wallDamageCooldown = this.wallDamageCooldown - dt;
    if (this.impactCooldown > 0.0) this.impactCooldown = this.impactCooldown - dt;

    let cruiseTop = this.maxSpeed;
    let boostTop = this.boostSpeed;

    // 1. Steering & Inputs
    let steerInput = 0.0;
    let throttleInput = false;
    let brakeInput = false;
    let boostKey = false;
    let shiftKey = false;

    if (this.inputOverride != nil) {
      if (this.inputOverride["steer"] != nil) steerInput = this.inputOverride["steer"];
      if (this.inputOverride["throttle"] != nil) throttleInput = this.inputOverride["throttle"];
      if (this.inputOverride["brake"] != nil) brakeInput = this.inputOverride["brake"];
      if (this.inputOverride["boost"] != nil) boostKey = this.inputOverride["boost"];
      if (this.inputOverride["drift"] != nil) shiftKey = this.inputOverride["drift"];
    } else {
      if (gui.isKeyDown("KEY_A") or gui.isKeyDown("KEY_LEFT")) steerInput = steerInput + 1.0;
      if (gui.isKeyDown("KEY_D") or gui.isKeyDown("KEY_RIGHT")) steerInput = steerInput - 1.0;
      throttleInput = gui.isKeyDown("KEY_W") or gui.isKeyDown("KEY_UP");
      brakeInput = gui.isKeyDown("KEY_S") or gui.isKeyDown("KEY_DOWN");
      boostKey = gui.isKeyDown("KEY_SPACE");
      shiftKey = gui.isKeyDown("KEY_LEFT_SHIFT");
    }

    let boostInput = boostKey and this.nitro > 4.0 and (throttleInput or this.speed > 25.0);
    this.isBraking = brakeInput;

    // Handbrake drift activation
    if (shiftKey and math.abs(steerInput) > 0.15 and this.speed > 20.0) {
      this.isDrifting = true;
    }

    if (this.isDrifting) {
      let targetDriftAngle = steerInput * 20.0;
      this.driftAngle = mu.approach(this.driftAngle, targetDriftAngle, dt * 45.0);
      this.driftPoints = this.driftPoints + math.floor(dt * 150.0);
      this.nitro = mu.clamp(this.nitro + this.spec["nitroRegen"] * 2.2 * dt, 0.0, this.maxNitro);

      let driftSign = 1.0;
      if (steerInput < 0.0) driftSign = -1.0;
      if (particles != nil) particles.emitDriftSmoke(this.worldX, this.worldY, this.worldZ, driftSign);
      if (rand(8) == 0 and assets != nil) assets.playSfx(assets.sndSkid);

      if (math.abs(steerInput) < 0.10 or this.speed < 16.0) {
        if (this.driftPoints > 60) {
          this.speed = mu.clamp(this.speed + 7.5, 0.0, this.boostSpeed);
          if (assets != nil) assets.playSfx(assets.sndNitro);
          if (particles != nil) particles.emitNitroFlames(this.worldX, this.worldY, this.worldZ, this.speed, 1.25);
        }
        this.driftPoints = 0;
        this.isDrifting = false;
        this.driftAngle = mu.approach(this.driftAngle, 0.0, dt * 60.0);
      }
    } else {
      this.driftPoints = 0;
      this.driftAngle = mu.approach(this.driftAngle, 0.0, dt * 60.0);
    }

    // 2. Throttle, Brakes, Reverse & Nitro Overdrive
    if (this.isOffTrack) {
      // Rolling gravel drag
      let gravelTop = 22.0;
      this.speed = mu.approach(this.speed, gravelTop, dt * 25.0);
      if (particles != nil) particles.emitDust(this.worldX, this.worldY, this.worldZ);
    }

    if (boostInput and !this.isOffTrack) {
      this.isBoosting = true;
      this.isReversing = false;
      this.speed = mu.approach(this.speed, boostTop, dt * (this.accel * 1.5));
      this.nitro = mu.clamp(this.nitro - this.spec["nitroBurn"] * dt, 0.0, this.maxNitro);

      let boostTier = 1.0;
      if (this.speed > 85.0) boostTier = 1.5;
      if (particles != nil) particles.emitNitroFlames(this.worldX, this.worldY, this.worldZ, this.speed, boostTier);
      if (rand(12) == 0 and assets != nil) assets.playSfx(assets.sndNitro);
    } else if (throttleInput) {
      this.isBoosting = false;
      if (this.speed < 0.0) {
        this.speed = mu.approach(this.speed, 0.0, dt * 50.0);
        this.isReversing = false;
      } else {
        let effAccel = this.accel;
        let effTop = cruiseTop;
        if (this.isOffTrack) {
          effAccel = this.accel * 0.30;
          effTop = 20.0;
        }
        this.speed = mu.approach(this.speed, effTop, dt * effAccel);
        this.isReversing = false;
      }
      this.nitro = mu.clamp(this.nitro + this.spec["nitroRegen"] * 0.3 * dt, 0.0, this.maxNitro);
    } else if (brakeInput and !this.isDrifting) {
      this.isBoosting = false;
      if (this.speed > 2.0) {
        // Active trail-braking deceleration
        this.speed = mu.approach(this.speed, 0.0, dt * 75.0);
        this.isReversing = false;
      } else {
        this.isReversing = true;
        this.speed = mu.approach(this.speed, -20.0, dt * 16.0);
      }
    } else if (this.isDrifting) {
      this.isBoosting = false;
      if (brakeInput) {
        this.speed = mu.approach(this.speed, 14.0, dt * 32.0);
      } else {
        let slideTarget = cruiseTop * 0.72;
        this.speed = mu.approach(this.speed, slideTarget, dt * 15.0);
      }
    } else {
      this.isBoosting = false;
      this.isReversing = false;
      this.speed = mu.approach(this.speed, 0.0, dt * 16.0);
      this.nitro = mu.clamp(this.nitro + this.spec["nitroRegen"] * 0.5 * dt, 0.0, this.maxNitro);
    }

    // 3. Responsive Steering & Yaw Dynamics
    let effectiveSteerInput = steerInput;
    if (this.isReversing) effectiveSteerInput = -effectiveSteerInput;

    let steerSpeed = 38.0;
    if (effectiveSteerInput * this.steer < 0.0) steerSpeed = 64.0;
    else if (effectiveSteerInput == 0.0 or math.abs(effectiveSteerInput) < math.abs(this.steer)) steerSpeed = 44.0;
    this.steer = mu.approach(this.steer, effectiveSteerInput, dt * steerSpeed);

    let speedRatio = math.abs(this.speed) / this.maxSpeed;
    if (speedRatio > 1.0) speedRatio = 1.0;

    let maxWheelLock = 0.40 - speedRatio * 0.12;
    if (this.isDrifting) maxWheelLock = 0.48;
    let targetWheel = this.steer * maxWheelLock;
    this.steerAngle = mu.approach(this.steerAngle, targetWheel, dt * 44.0);

    let speedFactor = 1.0;
    let absSpd = math.abs(this.speed);
    if (absSpd < 25.0) {
      let lowSpeedRatio = absSpd / 25.0;
      speedFactor = 1.0 + (1.0 - lowSpeedRatio) * 1.0;
    } else {
      speedFactor = 1.0 - (speedRatio - 0.3) * 0.08;
    }

    let turnAgility = (this.handling * 0.90) * speedFactor;
    if (this.isDrifting) {
      let driftMult = 1.45;
      if (this.spec["driftRate"] != nil) driftMult = 1.30 + this.spec["driftRate"] * 0.15;
      turnAgility = turnAgility * driftMult;
    }
    if (this.isOffTrack) turnAgility = turnAgility * 0.55;

    let yawTorque = this.steerAngle * turnAgility - this.yawRate * 11.5;
    this.yawRate = this.yawRate + yawTorque * dt;
    this.worldHeading = this.worldHeading + this.yawRate * dt;

    if (math.abs(steerInput) < 0.1) {
      this.yawRate = this.yawRate * (1.0 - 14.0 * dt);
    }

    // Wrap world heading to [-PI, +PI]
    let PI = 3.14159265;
    let TWO_PI = 6.2831853;
    while (this.worldHeading > PI) this.worldHeading = this.worldHeading - TWO_PI;
    while (this.worldHeading < -PI) this.worldHeading = this.worldHeading + TWO_PI;

    // 4. Newtonian Motion in 3D World Space
    let driftRad = this.driftAngle * 0.0174533 * 0.35;
    let effectiveHeading = this.worldHeading + driftRad;

    let fwdX = math.sin(effectiveHeading);
    let fwdZ = math.cos(effectiveHeading);
    let rgtX = -math.cos(effectiveHeading);
    let rgtZ = math.sin(effectiveHeading);

    // Tire lateral grip damping
    let targetLatVel = 0.0;
    if (this.isDrifting) {
      targetLatVel = this.speed * math.sin(this.steerAngle) * 0.65;
    }
    let latGripRate = 18.0;
    if (this.isBraking) latGripRate = 26.0;
    this.lateralVelocity = mu.approach(this.lateralVelocity, targetLatVel, dt * latGripRate);

    // Advance world coordinates
    this.worldX = this.worldX + (fwdX * this.speed + rgtX * this.lateralVelocity) * dt;
    this.worldZ = this.worldZ + (fwdZ * this.speed + rgtZ * this.lateralVelocity) * dt;

    // 5. Spline Projection: Update track distance, lateral offset, and elevation
    if (track != nil) {
      let proj = track.projectWorldPoint(this.worldX, this.worldZ, this.trackDistance);
      let prevDist = this.trackDistance;
      this.trackDistance = proj[0];
      this.x = proj[1];
      this.worldY = track.getElevationAt(this.trackDistance) + 0.15;
      this.y = this.worldY;

      // Track relative heading for HUD, AI, and test compatibility
      let trkHead = const.getTrackHeading(track.trackId, this.trackDistance);
      let relH = this.worldHeading - trkHead;
      while (relH > PI) relH = relH - TWO_PI;
      while (relH < -PI) relH = relH + TWO_PI;
      this.heading = relH;

      // Closed-circuit lap counting
      let lapLen = track.spec["length"];
      if (this.trackDistance > lapLen * 0.5) this.hasCrossedMidpoint = true;
      if (this.hasCrossedMidpoint and this.trackDistance < lapLen * 0.15) {
        this.completedLaps = this.completedLaps + 1;
        this.hasCrossedMidpoint = false;
      }

      // Look ahead 50m for upcoming sharp corners (Braking Zones)
      let lookAheadCurv = const.getTrackCurvature(track.trackId, this.trackDistance + 50.0);
      let absCurv = math.abs(lookAheadCurv);
      this.brakeWarning = 0;
      if (absCurv > 0.016 and this.speed > 50.0) {
        if (lookAheadCurv > 0.0) {
          this.brakeWarning = 1; // Sharp Left Turn Ahead!
        } else {
          this.brakeWarning = 2; // Sharp Right Turn Ahead!
        }
      }

      // Check curbs and off-track status
      let halfRoad = track.roadWidth * 0.5;
      let curbLimit = halfRoad + track.curbWidth;
      let wallLimit = halfRoad + track.curbWidth + track.runoffWidth;
      let absOffset = math.abs(this.x);
      let distFromCenter = proj[2];

      this.onCurb = (absOffset >= halfRoad and absOffset <= curbLimit);
      this.isOffTrack = (absOffset > curbLimit);

      // Perimeter concrete barrier bounce collision (Continuous Impenetrable Clamping)
      if (absOffset >= wallLimit or distFromCenter >= wallLimit) {
        let sign = 1.0;
        if (this.x < 0.0) sign = -1.0;

        // Strictly clamp vehicle inside barrier limit
        let safeWallX = sign * (wallLimit - 0.25);
        this.x = safeWallX;

        // Re-project clamped world coordinates onto barrier inner edge
        let stP = const.getTrackWorldPoint(track.trackId, this.trackDistance);
        let stTan = const.getTrackTangent(track.trackId, this.trackDistance);
        let tMag = math.sqrt(stTan[0] * stTan[0] + stTan[1] * stTan[1]);
        if (tMag < 0.0001) tMag = 1.0;
        let nx = -stTan[1] / tMag;
        let nz = stTan[0] / tMag;
        this.worldX = stP[0] + nx * this.x;
        this.worldZ = stP[1] + nz * this.x;

        // Check if car was moving outward into the wall
        let carVx = fwdX * this.speed + rgtX * this.lateralVelocity;
        let carVz = fwdZ * this.speed + rgtZ * this.lateralVelocity;
        let vOut = carVx * (sign * nx) + carVz * (sign * nz);

        // Solid elastic bounce inward away from wall
        let bounceImpulse = 6.5;
        if (vOut > 0.0) bounceImpulse = math.max(6.5, vOut * 0.50);
        this.lateralVelocity = -sign * bounceImpulse;
        this.speed = this.speed * 0.72;
        this.wallHitShake = 0.28;

        // Deflect heading so car glances along wall instead of driving through it
        let relH = this.worldHeading - trkHead;
        while (relH > PI) relH = relH - TWO_PI;
        while (relH < -PI) relH = relH + TWO_PI;

        if (sign > 0.0 and relH < 0.0) {
          // Pointing outward into right wall -> deflect counter-clockwise
          this.worldHeading = trkHead + 0.12;
          this.yawRate = 2.5;
        } else if (sign < 0.0 and relH > 0.0) {
          // Pointing outward into left wall -> deflect clockwise
          this.worldHeading = trkHead - 0.12;
          this.yawRate = -2.5;
        }

        if (this.impactCooldown <= 0.0) {
          this.impactCooldown = 0.35;
          if (particles != nil) particles.emitSparks(this.worldX, this.worldY + 0.3, this.worldZ, 8);
          if (assets != nil) assets.playSfx(assets.sndCrash);
        }
      }
    }
  }

  updateAi(dDist, playerSpeed, dt, track) {
    if (track == nil) return;

    let lapLen = track.spec["length"];
    let aiCurvature = track.getCurvature(0.0, this.trackDistance);
    let absCurv = math.abs(aiCurvature);
    let aiCornerLoad = mu.clamp(absCurv * 22.0, 0.0, 1.0);

    // AI speed calculation with rubberbanding
    let minAiCruise = 85.0 * this.aiSkill;
    let baseSpeed = this.maxSpeed * this.aiSkill;
    if (playerSpeed > 50.0) {
      baseSpeed = playerSpeed * (0.98 + (this.aiSkill - 1.0) * 0.06);
    } else {
      if (baseSpeed < minAiCruise) baseSpeed = minAiCruise;
    }

    if (dDist < -10.0) {
      let catchUp = 14.0 + (-dDist) * 0.40;
      let boostTarget = playerSpeed + catchUp;
      if (boostTarget > baseSpeed) baseSpeed = boostTarget;
    } else if (dDist > 28.0 and playerSpeed > 50.0) {
      let pullBack = (dDist - 25.0) * 0.30;
      let slowed = playerSpeed - pullBack;
      let minFloor = playerSpeed * 0.88;
      if (minFloor < minAiCruise) minFloor = minAiCruise;
      if (slowed < minFloor) slowed = minFloor;
      baseSpeed = slowed;
    }

    if (aiCornerLoad > 0.16) {
      let aiCornerSpeed = 135.0 - aiCornerLoad * 45.0;
      if (baseSpeed > aiCornerSpeed) baseSpeed = aiCornerSpeed;
    }
    this.speed = mu.approach(this.speed, baseSpeed, dt * 26.0);

    // AI progression along track
    this.trackDistance = this.trackDistance + this.speed * dt;
    if (this.trackDistance > lapLen * 0.5) this.hasCrossedMidpoint = true;
    if (this.trackDistance >= lapLen) {
      this.trackDistance = this.trackDistance - lapLen;
      if (this.hasCrossedMidpoint) {
        this.completedLaps = this.completedLaps + 1;
        this.hasCrossedMidpoint = false;
      }
    }
    while (this.trackDistance < 0.0) this.trackDistance = this.trackDistance + lapLen;

    // AI lateral lane management
    let aiRoadLimit = track.roadWidth * 0.5 - 2.0;
    this.x = mu.clamp(this.aiLane, -aiRoadLimit, aiRoadLimit);

    // Sync world coordinates from track station
    let p = const.getTrackWorldPoint(track.trackId, this.trackDistance);
    let tan = const.getTrackTangent(track.trackId, this.trackDistance);
    let mag = math.sqrt(tan[0] * tan[0] + tan[1] * tan[1]);
    if (mag < 0.0001) mag = 1.0;
    let tx = tan[0] / mag; let tz = tan[1] / mag;
    let nx = -tz; let nz = tx;

    this.worldX = p[0] + nx * this.x;
    this.worldZ = p[1] + nz * this.x;
    this.worldY = track.getElevationAt(this.trackDistance) + 0.15;
    this.y = this.worldY;
    this.worldHeading = math.atan2(tx, tz);
    this.heading = 0.0;
  }

  draw(assets, t) {
    let rotY = this.worldHeading * 57.29578 + 180.0 + this.driftAngle;
    let r = 255; let g = 255; let b = 255;
    if (this.hitFlash > 0.0) { r = 255; g = 120; b = 120; }

    // Ground contact shadow
    gui.drawPlane3D(this.worldX, this.worldY - 0.12, this.worldZ, 2.1 * this.scale, 3.4 * this.scale, 10, 12, 18);

    // Nitro boost underglow
    if (this.isBoosting) {
      let glow = this.spec["glowColor"];
      if (glow != nil) {
        gui.drawPlane3D(this.worldX, this.worldY - 0.10, this.worldZ, 1.6 * this.scale, 2.6 * this.scale,
                        math.floor(glow[0] * 0.18), math.floor(glow[1] * 0.18), math.floor(glow[2] * 0.18));
      }
    }

    // 3D Vehicle Model
    assets.playCarModel(this.carId, this.worldX, this.worldY, this.worldZ, rotY, this.scale, r, g, b);

    // Taillight flares during braking
    if (this.isBraking or this.speed < 0.0) {
      let cosH = math.cos(this.worldHeading);
      let sinH = math.sin(this.worldHeading);
      let hx = 0.50 * this.scale;
      let hz = 1.35 * this.scale;
      let rLeftX = this.worldX - hx * cosH - hz * sinH;
      let rLeftZ = this.worldZ - hz * cosH + hx * sinH;
      let rRightX = this.worldX + hx * cosH - hz * sinH;
      let rRightZ = this.worldZ - hz * cosH - hx * sinH;
      gui.drawSphere3D(rLeftX, this.worldY + 0.38 * this.scale, rLeftZ, 0.08, 255, 30, 30);
      gui.drawSphere3D(rRightX, this.worldY + 0.38 * this.scale, rRightZ, 0.08, 255, 30, 30);
    }
  }
}

// Civilian Traffic Car for Highway Slalom Mode
export class TrafficCar {
  init(startZ) {
    this.x = mu.randFloat(-3.2, 3.2);
    this.worldX = this.x;
    this.worldY = 0.0;
    this.worldZ = startZ;
    this.y = 0.0;
    this.z = startZ;
    this.type = rand(5);
    this.speed = mu.randFloat(35.0, 55.0);
    this.passed = false;
  }

  syncPosition(track, distance) {
    let roadCurve = track.getCurveOffset(this.z, distance);
    this.worldX = roadCurve + this.x;
  }

  update(playerSpeed, dt) {
    let relSpeed = this.speed - playerSpeed;
    this.z = this.z - relSpeed * dt;
  }

  draw(assets) {
    if (this.z < -260.0 or this.z > 18.0) return;
    let drawX = this.worldX;
    let scale = 1.45;
    gui.drawPlane3D(drawX, 0.02, this.z, 2.0 * scale, 3.2 * scale, 10, 12, 18);
    assets.playTrafficModel(this.type, drawX, this.y, this.z, 180.0, scale, 255, 255, 255);
  }
}
