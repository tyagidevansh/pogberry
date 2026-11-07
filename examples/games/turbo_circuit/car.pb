// TURBO CIRCUIT: OVERDRIVE — True World-Space Vehicle Dynamics & Physics
use "pb_gui" as gui;
use "std.math" as math;
use "math_util" as mu;
use "constants" as const;

fun getCornerTargetSpeed(k, maxLat, topSpeed) {
  if (k <= 0.0030) return topSpeed;
  let effLat = maxLat;
  if (k > 0.015) {
    let t = (k - 0.015) / 0.035;
    if (t > 1.0) t = 1.0;
    effLat = maxLat * (1.0 - t * 0.15);
  }
  return math.sqrt(effLat / k);
}

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
    this.raceDistance = 0.0;
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
    this.isAccelerating = false;
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
    this.aiDifficulty = 1; // 0=Rookie, 1=Amateur, 2=Pro/Expert
    this.rivalAheadX = nil;

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

  update(dt, track, particles, assets) {
    this.updatePlayer(dt, track, particles, assets);
  }

  updatePlayer(dt, track, particles, assets) {
    // Sync world position from track if uninitialized
    if (this.worldX == 0.0 and this.worldZ == 0.0 and track != nil) {
      this.setTrackPosition(track, this.trackDistance, this.x);
    } else if (track != nil) {
      let curTrkHead = const.getTrackHeading(track.trackId, this.trackDistance);
      let expRelH = this.worldHeading - curTrkHead;
      while (expRelH > 3.14159265) expRelH = expRelH - 6.2831853;
      while (expRelH < -3.14159265) expRelH = expRelH + 6.2831853;
      if (math.abs(this.heading - expRelH) > 0.05) {
        this.worldHeading = curTrkHead + this.heading;
      }
    }

    // 0. Spin-out recovery
    if (this.spinTimer > 0.0) {
      this.spinTimer = this.spinTimer - dt;
      this.speed = mu.approach(this.speed, 25.0, dt * 50.0);
      this.driftAngle = 0.0;
      this.worldHeading = this.worldHeading + 11.868 * dt;
      let fwdX = math.sin(this.worldHeading);
      let fwdZ = math.cos(this.worldHeading);
      this.worldX = this.worldX + fwdX * this.speed * dt;
      this.worldZ = this.worldZ + fwdZ * this.speed * dt;
      if (particles != nil) particles.emitDust(this.worldX, this.worldY, this.worldZ);
      if (this.hitFlash > 0.0) this.hitFlash = this.hitFlash - dt;
      if (this.spinTimer <= 0.0) {
        this.driftAngle = 0.0;
        let trkHead = const.getTrackHeading(track.trackId, this.trackDistance);
        this.worldHeading = trkHead;
      }
      return;
    }

    if (this.wallDamageCooldown > 0.0) this.wallDamageCooldown = this.wallDamageCooldown - dt;
    if (this.impactCooldown > 0.0) this.impactCooldown = this.impactCooldown - dt;
    if (this.hitFlash > 0.0) this.hitFlash = this.hitFlash - dt;
    if (this.wallHitShake > 0.0) this.wallHitShake = mu.approach(this.wallHitShake, 0.0, dt * 12.0);

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
    this.isAccelerating = throttleInput or boostInput;

    this.isDrifting = false;
    this.driftAngle = 0.0;
    this.driftPoints = 0;

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
    } else if (brakeInput) {
      this.isBoosting = false;
      if (this.speed > 2.0) {
        // Active trail-braking deceleration and authentic F1 MGU-K battery energy recovery
        this.speed = mu.approach(this.speed, 0.0, dt * 75.0);
        this.isReversing = false;
        this.nitro = mu.clamp(this.nitro + this.spec["nitroRegen"] * 2.8 * dt, 0.0, this.maxNitro);
      } else {
        this.isReversing = true;
        this.speed = mu.approach(this.speed, -20.0, dt * 16.0);
      }
    } else {
      this.isBoosting = false;
      this.isReversing = false;
      this.speed = mu.approach(this.speed, 0.0, dt * 16.0);
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
    this.driftAngle = 0.0;
    let effectiveHeading = this.worldHeading;

    let fwdX = math.sin(effectiveHeading);
    let fwdZ = math.cos(effectiveHeading);
    let rgtX = -math.cos(effectiveHeading);
    let rgtZ = math.sin(effectiveHeading);

    // Tire lateral grip damping
    let targetLatVel = 0.0;
    let latGripRate = 18.0;
    if (this.isBraking) latGripRate = 26.0;
    this.lateralVelocity = mu.approach(this.lateralVelocity, targetLatVel, dt * latGripRate);

    // Advance world coordinates
    this.worldX = this.worldX + (fwdX * this.speed + rgtX * this.lateralVelocity) * dt;
    this.worldZ = this.worldZ + (fwdZ * this.speed + rgtZ * this.lateralVelocity) * dt;

    // 5. Spline Projection: Update track distance, lateral offset, and elevation
    if (track != nil) {
      let proj = track.projectWorldPoint(this.worldX, this.worldZ, this.trackDistance, this.worldHeading);
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

      // Closed-circuit lap & monotonic race distance tracking
      let lapLen = track.spec["length"];
      if (this.raceDistance == 0.0 and this.completedLaps == 0 and prevDist > 0.0 and prevDist < lapLen * 0.5) {
        this.raceDistance = prevDist;
      }
      let ds = this.trackDistance - prevDist;
      while (ds > lapLen * 0.5) ds = ds - lapLen;
      while (ds < -lapLen * 0.5) ds = ds + lapLen;
      this.raceDistance = this.raceDistance + ds;

      if (this.raceDistance >= 0.0) {
        this.completedLaps = math.floor(this.raceDistance / lapLen);
      } else {
        this.completedLaps = 0;
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
      let absOffset = math.abs(this.x);
      this.onCurb = (absOffset >= halfRoad and absOffset <= curbLimit);
      this.isOffTrack = (absOffset > curbLimit);

      // Exact physical barrier limits at this station on track
      let barLims = track.getBarrierLimits(this.trackDistance);
      let limL = barLims[0];
      let limR = barLims[1];
      let hasWallL = barLims[2];
      let hasWallR = barLims[3];
      let carHalfW = 1.30 * (this.scale / 1.45); // Physical half-width of car body (1.30m)
      let maxRight = limR - carHalfW;
      let maxLeft = -(limL - carHalfW);

      let hitWall = false;
      let sign = 0.0;

      if (this.x >= maxRight) {
        if (hasWallR) hitWall = true;
        sign = 1.0;
        this.x = maxRight;
      } else if (this.x <= maxLeft) {
        if (hasWallL) hitWall = true;
        sign = -1.0;
        this.x = maxLeft;
      }

      // Re-project clamped world coordinates onto track perimeter edge to prevent floating/levitation
      if (sign != 0.0) {
        if (hitWall) {
          // Displace vehicle cleanly inward away from barrier threshold to prevent sticky collision lock
          this.x = this.x - sign * 0.25;
        }
        let stP = const.getTrackWorldPoint(track.trackId, this.trackDistance);
        let stTan = const.getTrackTangent(track.trackId, this.trackDistance);
        let tMag = math.sqrt(stTan[0] * stTan[0] + stTan[1] * stTan[1]);
        if (tMag < 0.0001) tMag = 1.0;
        let nx = -stTan[1] / tMag;
        let nz = stTan[0] / tMag;
        this.worldX = stP[0] + nx * this.x;
        this.worldZ = stP[1] + nz * this.x;
      }

      // Perimeter concrete barrier collision (Impenetrable, momentum killing)
      if (hitWall) {
        // TOTALLY KILL MOMENTUM: Concrete barrier absorbs kinetic energy cold
        this.speed = 0.0;
        this.isBoosting = false;
        this.isDrifting = false;
        this.driftAngle = 0.0;

        // Firm rebound impulse pushing vehicle cleanly inward away from barrier
        this.lateralVelocity = -sign * 5.5;
        this.wallHitShake = 0.85;

        // Deflect heading away from wall if car was angling outward
        let curRelH = this.worldHeading - trkHead;
        while (curRelH > 3.14159) curRelH = curRelH - 6.28318;
        while (curRelH < -3.14159) curRelH = curRelH + 6.28318;
        if (sign > 0.0 and curRelH < 0.0 and curRelH > -1.7) {
          this.worldHeading = trkHead + 0.12;
          this.yawRate = 2.5;
        } else if (sign < 0.0 and curRelH > 0.0 and curRelH < 1.7) {
          this.worldHeading = trkHead - 0.12;
          this.yawRate = -2.5;
        }

        if (this.impactCooldown <= 0.0) {
          this.impactCooldown = 0.35;
          this.hitFlash = 0.35;
          this.hull = math.max(0.0, this.hull - 12.0);
          if (particles != nil) particles.emitSparks(this.worldX, this.worldY + 0.3, this.worldZ, 16);
          if (assets != nil) assets.playSfx(assets.sndCrash);
        }
      }
    }
  }

  updateAi(dDist, playerSpeed, dt, track) {
    if (track == nil) return;

    let dist = this.trackDistance;
    let spd = this.speed;
    let absSpd = math.abs(spd);
    let diff = this.aiDifficulty;
    if (diff == nil) diff = 1;

    let isNarrowTrack = (track.roadWidth < 27.0);

    let curCurv = const.getTrackCurvature(track.trackId, dist);

    // Peak curvature across immediate turn zone (-16m exit to +32m entry)
    let maxImmCurv = math.abs(curCurv);
    for (let d = -16.0; d <= 32.0; d += 8.0) {
      let k = math.abs(const.getTrackCurvature(track.trackId, dist + d));
      if (k > maxImmCurv) maxImmCurv = k;
    }

    // Authentic cornering grip limits based on Newtonian centripetal physics (v = sqrt(a_lat / k))
    let maxLatAccel = 54.0;
    if (isNarrowTrack) maxLatAccel = 44.0;
    let aBrake = 68.0;
    let safeMargin = 2.0;
    if (isNarrowTrack) safeMargin = 1.8;
    let rxBuffer = 0.08;
    let steerGain = 4.6;
    let tcThresh = 0.60;
    let tcSpeedRatio = 0.96;
    let overtakeOffset = 2.4;
    if (isNarrowTrack) overtakeOffset = 1.5;

    if (diff == 0) {
      // Rookie: clean pace, steady lines, measured braking
      maxLatAccel = 42.0;
      if (isNarrowTrack) maxLatAccel = 34.0;
      aBrake = 62.0;
      safeMargin = 2.4;
      rxBuffer = 0.14;
      steerGain = 4.0;
      tcThresh = 0.50;
      tcSpeedRatio = 0.92;
      overtakeOffset = 1.8;
    } else if (diff == 1) {
      // Pro Racer: fast competitive pace, authentic F1 racing lines, late braking
      maxLatAccel = 56.0;
      if (isNarrowTrack) maxLatAccel = 46.0;
      aBrake = 68.0;
      safeMargin = 1.9;
      rxBuffer = 0.08;
      steerGain = 4.8;
      tcThresh = 0.60;
      tcSpeedRatio = 0.96;
      overtakeOffset = 2.4;
      if (isNarrowTrack) overtakeOffset = 1.6;
    } else {
      // World Champion: elite aggressive championship lines, extreme late braking, fierce racecraft
      maxLatAccel = 68.0;
      if (isNarrowTrack) maxLatAccel = 56.0;
      aBrake = 74.0;
      safeMargin = 1.6;
      if (isNarrowTrack) safeMargin = 1.4;
      rxBuffer = 0.04;
      steerGain = 5.4;
      tcThresh = 0.75;
      tcSpeedRatio = 0.99;
      overtakeOffset = 2.8;
      if (isNarrowTrack) overtakeOffset = 1.8;
    }

    let vImmediateLimit = getCornerTargetSpeed(maxImmCurv, maxLatAccel, this.maxSpeed);

    let brakeInput = false;
    let throttleInput = true;

    // Scan ahead up to 260m for upcoming corner braking points with steering reaction buffer
    for (let aheadDist = 12.0; aheadDist <= 260.0; aheadDist += 10.0) {
      let kAhead = math.abs(const.getTrackCurvature(track.trackId, dist + aheadDist));
      if (kAhead > 0.0035) {
        let vCornerTarget = getCornerTargetSpeed(kAhead, maxLatAccel, this.maxSpeed);
        if (spd > vCornerTarget) {
          let reqDist = (spd * spd - vCornerTarget * vCornerTarget) / (2.0 * aBrake) + spd * rxBuffer;
          if (reqDist >= (aheadDist - 4.0)) {
            brakeInput = true;
            throttleInput = false;
          }
        }
      }
    }

    // In-turn speed control: accelerate cleanly up to the tire limit, lift at limit, brake if over limit
    if (spd > vImmediateLimit * 1.06) {
      brakeInput = true;
      throttleInput = false;
    } else if (spd > vImmediateLimit * 1.01) {
      throttleInput = false;
    }

    // Barrier limits lookahead to anticipate narrowing walls
    let carW = 1.4;
    let barLimsNow = track.getBarrierLimits(dist);
    let barLimsMid = track.getBarrierLimits(dist + 25.0);
    let barLimsFar = track.getBarrierLimits(dist + 50.0);
    let limL = math.min(barLimsNow[0], math.min(barLimsMid[0], barLimsFar[0]));
    let limR = math.min(barLimsNow[1], math.min(barLimsMid[1], barLimsFar[1]));
    let hw = track.roadWidth * 0.5;

    let maxR = math.min(hw - 1.4, limR - safeMargin - carW);
    let maxL = -math.min(hw - 1.4, limL - safeMargin - carW);

    let apexCurv = const.getTrackCurvature(track.trackId, dist + 24.0);
    let entryCurv = const.getTrackCurvature(track.trackId, dist + 70.0);

    // True Formula 1 Geometric Racing Line (Out - In - Out):
    // Curvature > 0 is Right turn (inside is +x Right, outside is -x Left)
    // Curvature < 0 is Left turn (inside is -x Left, outside is +x Right)
    let racingLineOffset = 0.0;
    let maxLineOffset = 5.2;
    if (isNarrowTrack) maxLineOffset = 2.2;

    if (diff == 2) {
      if (math.abs(curCurv) > 0.008) {
        racingLineOffset = curCurv * 160.0; // In corner: clip inside curb apex (Right turn > 0 -> +x, Left turn < 0 -> -x)
      } else if (math.abs(apexCurv) > 0.007) {
        racingLineOffset = -apexCurv * 140.0; // Corner entry: setup wide on outside (Right turn ahead > 0 -> -x Left)
      } else if (math.abs(entryCurv) > 0.007) {
        racingLineOffset = -entryCurv * 100.0; // Long approach: drift to outside
      }
    } else if (diff == 1) {
      if (math.abs(curCurv) > 0.009) {
        racingLineOffset = curCurv * 130.0;
      } else if (math.abs(apexCurv) > 0.008) {
        racingLineOffset = -apexCurv * 110.0;
      }
    } else {
      racingLineOffset = curCurv * 60.0;
    }
    racingLineOffset = mu.clamp(racingLineOffset, -maxLineOffset, maxLineOffset);

    // Dynamic Overtaking & Defensive Lateral Tactics
    let attackOffset = 0.0;
    if (diff >= 1) {
      if (dDist < -3.5 and dDist > -40.0) {
        // Only pull out alongside if track is wide or on straightaway
        let canOvertakeHere = (!isNarrowTrack or maxImmCurv < 0.008);
        if (canOvertakeHere) {
          let leadX = 0.0;
          if (this.rivalAheadX != nil) leadX = this.rivalAheadX;
          else if (this.aiLane < 0.0) leadX = -2.0;
          else leadX = 2.0;

          // Pull into open lane opposite of lead car
          if (leadX > 0.0) {
            attackOffset = -overtakeOffset; // Pass on left
          } else {
            attackOffset = overtakeOffset;  // Pass on right
          }

          // Verify barrier clearance in chosen passing lane
          if (attackOffset > 0.0 and (this.x + attackOffset) > maxR) {
            attackOffset = -overtakeOffset; // Switch to left if right barrier is too close
          } else if (attackOffset < 0.0 and (this.x + attackOffset) < maxL) {
            attackOffset = overtakeOffset;  // Switch to right if left barrier is too close
          }
        }
      } else if (dDist > 2.0 and dDist < 25.0) {
        // Leading car with chaser right behind: Defend the inside apex into the braking zone
        if (apexCurv > 0.004) attackOffset = overtakeOffset * 0.75;
        else if (apexCurv < -0.004) attackOffset = -overtakeOffset * 0.75;
      }
    }

    let laneBlend = this.aiLane * 0.35;
    let targetLane = mu.clamp(racingLineOffset * 0.70 + laneBlend + attackOffset, maxL, maxR);

    // Pure Pursuit Steering Target along Track Spline with curvature-adaptive lookahead
    let lookDist = 14.0 + (absSpd / 50.0) * 16.0;
    if (maxImmCurv > 0.012) {
      let tightLook = 24.0 - maxImmCurv * 300.0;
      if (tightLook < 8.0) tightLook = 8.0;
      if (tightLook < lookDist) lookDist = tightLook;
    }
    let targetS = dist + lookDist;

    let tPt = const.getTrackWorldPoint(track.trackId, targetS);
    let tTan = const.getTrackTangent(track.trackId, targetS);
    let tMag = math.sqrt(tTan[0] * tTan[0] + tTan[1] * tTan[1]);
    if (tMag < 0.0001) tMag = 1.0;
    let tNx = -tTan[1] / tMag;
    let tNz = tTan[0] / tMag;

    let targetX = tPt[0] + tNx * targetLane;
    let targetZ = tPt[1] + tNz * targetLane;

    let toTgtX = targetX - this.worldX;
    let toTgtZ = targetZ - this.worldZ;
    let desiredHeading = math.atan2(toTgtX, toTgtZ);
    let headingErr = desiredHeading - this.worldHeading;
    while (headingErr > 3.14159) headingErr = headingErr - 6.28318;
    while (headingErr < -3.14159) headingErr = headingErr + 6.28318;

    let steerInput = mu.clamp(headingErr * steerGain, -1.0, 1.0);

    // Active Barrier Proximity Deflection & Emergency Scrub
    let wallDistR = limR - this.x - carW;
    let wallDistL = limL + this.x - carW;
    let hasWallL = barLimsNow[2] or barLimsMid[2];
    let hasWallR = barLimsNow[3] or barLimsMid[3];

    let trkHead = const.getTrackHeading(track.trackId, dist);
    let relHead = this.worldHeading - trkHead;
    while (relHead > 3.14159) relHead = relHead - 6.28318;
    while (relHead < -3.14159) relHead = relHead + 6.28318;

    if (hasWallR and wallDistR < 2.0) {
      if (spd > 20.0) brakeInput = true;
      let awayTargetX = tPt[0] - tNx * 1.5;
      let awayTargetZ = tPt[1] - tNz * 1.5;
      let toAwayX = awayTargetX - this.worldX;
      let toAwayZ = awayTargetZ - this.worldZ;
      let awayHeading = math.atan2(toAwayX, toAwayZ);
      let awayErr = awayHeading - this.worldHeading;
      while (awayErr > 3.14159) awayErr = awayErr - 6.28318;
      while (awayErr < -3.14159) awayErr = awayErr + 6.28318;
      steerInput = mu.clamp(awayErr * steerGain, -1.0, 1.0);
    } else if (hasWallL and wallDistL < 2.0) {
      if (spd > 20.0) brakeInput = true;
      let awayTargetX = tPt[0] + tNx * 1.5;
      let awayTargetZ = tPt[1] + tNz * 1.5;
      let toAwayX = awayTargetX - this.worldX;
      let toAwayZ = awayTargetZ - this.worldZ;
      let awayHeading = math.atan2(toAwayX, toAwayZ);
      let awayErr = awayHeading - this.worldHeading;
      while (awayErr > 3.14159) awayErr = awayErr - 6.28318;
      while (awayErr < -3.14159) awayErr = awayErr + 6.28318;
      steerInput = mu.clamp(awayErr * steerGain, -1.0, 1.0);
    }

    // Traction Control: prevent excessive power slide only when heavily loaded and well beyond speed limit
    let steerAbs = math.abs(this.steer);
    let absRelHead = math.abs(relHead);

    if ((steerAbs > 0.65 or absRelHead > 0.35) and spd > vImmediateLimit * 1.05) {
      throttleInput = false;
    }

    // Tactical Battery Deployment (ERS / Overdrive)
    let boostInput = false;
    let slipstreamBoost = (diff >= 1 and dDist < -4.0 and dDist > -70.0 and math.abs(curCurv) < 0.007);
    let straightBoost = (diff >= 1 and maxImmCurv < 0.0065 and math.abs(entryCurv) < 0.008);
    let exitBoost = (diff >= 2 and maxImmCurv < 0.008 and spd > 50.0);
    if (!brakeInput and throttleInput and (straightBoost or slipstreamBoost or exitBoost) and spd > 35.0 and this.nitro > 8.0) {
      boostInput = true;
    }

    this.inputOverride = {
      "steer": steerInput,
      "throttle": throttleInput,
      "brake": brakeInput,
      "boost": boostInput,
      "drift": false
    };
    this.updatePlayer(dt, track, nil, nil);
  }

  draw(assets, t) {
    let yawRad = this.worldHeading;
    let rotY = yawRad * 57.29578;
    let r = 255; let g = 255; let b = 255;

    // Authentic Rotated Aerodynamic Ground Contact Shadow
    this.drawShadow(this.scale, yawRad);

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

  drawShadow(sc, yawRad) {
    let fwdX = math.sin(yawRad);
    let fwdZ = math.cos(yawRad);
    let rgtX = -math.cos(yawRad);
    let rgtZ = math.sin(yawRad);
    let y0 = this.worldY - 0.12;

    // 1. Soft Outer Ambient Penumbra (feathered aerodynamic falloff)
    let wRearOut = 1.15 * sc;
    let wFrontOut = 0.85 * sc;
    let lBackOut = -2.1 * sc;
    let lFrontOut = 2.1 * sc;

    let p1x = this.worldX - rgtX * wRearOut + fwdX * lBackOut;
    let p1z = this.worldZ - rgtZ * wRearOut + fwdZ * lBackOut;
    let p2x = this.worldX + rgtX * wRearOut + fwdX * lBackOut;
    let p2z = this.worldZ + rgtZ * wRearOut + fwdZ * lBackOut;
    let p3x = this.worldX + rgtX * wFrontOut + fwdX * lFrontOut;
    let p3z = this.worldZ + rgtZ * wFrontOut + fwdZ * lFrontOut;
    let p4x = this.worldX - rgtX * wFrontOut + fwdX * lFrontOut;
    let p4z = this.worldZ - rgtZ * wFrontOut + fwdZ * lFrontOut;
    gui.drawQuad3D(p1x, y0, p1z, p2x, y0, p2z, p3x, y0, p3z, p4x, y0, p4z, 26, 30, 38);

    // 2. Dense Inner Chassis Contact Core
    let y1 = this.worldY - 0.11;
    let wRearIn = 0.90 * sc;
    let wFrontIn = 0.65 * sc;
    let lBackIn = -1.6 * sc;
    let lFrontIn = 1.6 * sc;

    let c1x = this.worldX - rgtX * wRearIn + fwdX * lBackIn;
    let c1z = this.worldZ - rgtZ * wRearIn + fwdZ * lBackIn;
    let c2x = this.worldX + rgtX * wRearIn + fwdX * lBackIn;
    let c2z = this.worldZ + rgtZ * wRearIn + fwdZ * lBackIn;
    let c3x = this.worldX + rgtX * wFrontIn + fwdX * lFrontIn;
    let c3z = this.worldZ + rgtZ * wFrontIn + fwdZ * lFrontIn;
    let c4x = this.worldX - rgtX * wFrontIn + fwdX * lFrontIn;
    let c4z = this.worldZ - rgtZ * wFrontIn + fwdZ * lFrontIn;
    gui.drawQuad3D(c1x, y1, c1z, c2x, y1, c2z, c3x, y1, c3z, c4x, y1, c4z, 8, 10, 14);

    // 3. Wheel Contact Patches (4 distinct tire ground contact spots)
    let y2 = this.worldY - 0.10;
    let tw = 0.22 * sc;
    let tl = 0.40 * sc;

    // Front Left Tire
    let flX = this.worldX - rgtX * (0.92 * sc) + fwdX * (1.20 * sc);
    let flZ = this.worldZ - rgtZ * (0.92 * sc) + fwdZ * (1.20 * sc);
    gui.drawQuad3D(
      flX - rgtX * tw - fwdX * tl, y2, flZ - rgtZ * tw - fwdZ * tl,
      flX + rgtX * tw - fwdX * tl, y2, flZ + rgtZ * tw - fwdZ * tl,
      flX + rgtX * tw + fwdX * tl, y2, flZ + rgtZ * tw + fwdZ * tl,
      flX - rgtX * tw + fwdX * tl, y2, flZ - rgtZ * tw + fwdZ * tl,
      4, 5, 8
    );

    // Front Right Tire
    let frX = this.worldX + rgtX * (0.92 * sc) + fwdX * (1.20 * sc);
    let frZ = this.worldZ + rgtZ * (0.92 * sc) + fwdZ * (1.20 * sc);
    gui.drawQuad3D(
      frX - rgtX * tw - fwdX * tl, y2, frZ - rgtZ * tw - fwdZ * tl,
      frX + rgtX * tw - fwdX * tl, y2, frZ + rgtZ * tw - fwdZ * tl,
      frX + rgtX * tw + fwdX * tl, y2, frZ + rgtZ * tw + fwdZ * tl,
      frX - rgtX * tw + fwdX * tl, y2, frZ - rgtZ * tw + fwdZ * tl,
      4, 5, 8
    );

    // Rear Left Tire
    let rlX = this.worldX - rgtX * (0.98 * sc) - fwdX * (1.20 * sc);
    let rlZ = this.worldZ - rgtZ * (0.98 * sc) - fwdZ * (1.20 * sc);
    gui.drawQuad3D(
      rlX - rgtX * (tw * 1.2) - fwdX * (tl * 1.1), y2, rlZ - rgtZ * (tw * 1.2) - fwdZ * (tl * 1.1),
      rlX + rgtX * (tw * 1.2) - fwdX * (tl * 1.1), y2, rlZ + rgtZ * (tw * 1.2) - fwdZ * (tl * 1.1),
      rlX + rgtX * (tw * 1.2) + fwdX * (tl * 1.1), y2, rlZ + rgtZ * (tw * 1.2) + fwdZ * (tl * 1.1),
      rlX - rgtX * (tw * 1.2) + fwdX * (tl * 1.1), y2, rlZ - rgtZ * (tw * 1.2) + fwdZ * (tl * 1.1),
      4, 5, 8
    );

    // Rear Right Tire
    let rrX = this.worldX + rgtX * (0.98 * sc) - fwdX * (1.20 * sc);
    let rrZ = this.worldZ + rgtZ * (0.98 * sc) - fwdZ * (1.20 * sc);
    gui.drawQuad3D(
      rrX - rgtX * (tw * 1.2) - fwdX * (tl * 1.1), y2, rrZ - rgtZ * (tw * 1.2) - fwdZ * (tl * 1.1),
      rrX + rgtX * (tw * 1.2) - fwdX * (tl * 1.1), y2, rrZ + rgtZ * (tw * 1.2) - fwdZ * (tl * 1.1),
      rrX + rgtX * (tw * 1.2) + fwdX * (tl * 1.1), y2, rrZ + rgtZ * (tw * 1.2) + fwdZ * (tl * 1.1),
      rrX - rgtX * (tw * 1.2) + fwdX * (tl * 1.1), y2, rrZ - rgtZ * (tw * 1.2) + fwdZ * (tl * 1.1),
      4, 5, 8
    );
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

// -----------------------------------------------------------------------------
// SOLID IMPENETRABLE VEHICLE-TO-VEHICLE COLLISION RESOLUTION
// Cars cannot phase through each other under any condition.
// Touching a car in front blocks the trailing vehicle directly behind its rear bumper.
// No momentum reset: the trailing vehicle matches lead vehicle speed without stopping.
// Lateral collisions separate vehicles so they never interpenetrate door-to-door.
// -----------------------------------------------------------------------------
export fun resolveCarCollisions(cars, track, lapLen, particles, assets, cam, dt) {
  let numCars = len(cars);
  if (numCars < 2 or track == nil) return;

  let L_col = 3.5;  // Minimum bumper-to-bumper longitudinal distance (meters)
  let W_col = 1.75; // Minimum door-to-door lateral distance (meters)

  for (let iter = 0; iter < 2; iter += 1) {
    for (let i = 0; i < numCars; i += 1) {
      for (let j = i + 1; j < numCars; j += 1) {
        let carA = cars[i];
        let carB = cars[j];

        // Closed-circuit distance along track from carA to carB
        let ds = carB.trackDistance - carA.trackDistance;
        while (ds > lapLen * 0.5) ds = ds - lapLen;
        while (ds < -lapLen * 0.5) ds = ds + lapLen;

        let absDs = math.abs(ds);
        let dx = carB.x - carA.x;
        let absDx = math.abs(dx);

        if (absDs < L_col and absDx < W_col) {
          let penS = (L_col - absDs) / L_col;
          let penX = (W_col - absDx) / W_col;

          if (penS < penX) {
            // Longitudinal / Bumper collision:
            // Leading vehicle blocks trailing vehicle cleanly behind rear bumper.
            if (ds >= 0.0) {
              // carB is ahead, carA is behind
              let clampedDist = carB.trackDistance - L_col;
              while (clampedDist < 0.0) clampedDist = clampedDist + lapLen;
              while (clampedDist >= lapLen) clampedDist = clampedDist - lapLen;
              carA.trackDistance = clampedDist;
              if (carA.raceDistance > carB.raceDistance - L_col) {
                carA.raceDistance = carB.raceDistance - L_col;
              }
              carA.setTrackPosition(track, carA.trackDistance, carA.x);

              if (carA.speed > carB.speed) {
                carA.speed = carB.speed;
              }
              if (carB.speed < 0.0) {
                carB.speed = 0.0;
              }
            } else {
              // carA is ahead, carB is behind
              let clampedDist = carA.trackDistance - L_col;
              while (clampedDist < 0.0) clampedDist = clampedDist + lapLen;
              while (clampedDist >= lapLen) clampedDist = clampedDist - lapLen;
              carB.trackDistance = clampedDist;
              if (carB.raceDistance > carA.raceDistance - L_col) {
                carB.raceDistance = carA.raceDistance - L_col;
              }
              carB.setTrackPosition(track, carB.trackDistance, carB.x);

              if (carB.speed > carA.speed) {
                carB.speed = carA.speed;
              }
              if (carA.speed < 0.0) {
                carA.speed = 0.0;
              }
            }
          } else {
            // Lateral / Side-by-Side collision:
            // Separate cars along lateral track axis so they do not overlap.
            let overlap = W_col - absDx;
            let barLimsA = track.getBarrierLimits(carA.trackDistance);
            let barLimsB = track.getBarrierLimits(carB.trackDistance);
            let halfW = 1.30;
            let barClearance = 1.0;
            let minXA = -(barLimsA[0] - halfW - barClearance);
            let maxXA = barLimsA[1] - halfW - barClearance;
            let minXB = -(barLimsB[0] - halfW - barClearance);
            let maxXB = barLimsB[1] - halfW - barClearance;

            let tanA = const.getTrackTangent(track.trackId, carA.trackDistance);
            let magA = math.sqrt(tanA[0] * tanA[0] + tanA[1] * tanA[1]);
            if (magA < 0.0001) magA = 1.0;
            let nxA = -tanA[1] / magA;
            let nzA = tanA[0] / magA;

            let tanB = const.getTrackTangent(track.trackId, carB.trackDistance);
            let magB = math.sqrt(tanB[0] * tanB[0] + tanB[1] * tanB[1]);
            if (magB < 0.0001) magB = 1.0;
            let nxB = -tanB[1] / magB;
            let nzB = tanB[0] / magB;

            if (dx >= 0.0) {
              // carA is on left, carB is on right
              let shiftA = overlap * 0.5;
              let shiftB = overlap * 0.5;

              let roomA = carA.x - minXA;
              let roomB = maxXB - carB.x;
              if (roomA < shiftA and roomB >= shiftA) {
                shiftB = shiftB + (shiftA - roomA);
                shiftA = roomA;
              } else if (roomB < shiftB and roomA >= shiftB) {
                shiftA = shiftA + (shiftB - roomB);
                shiftB = roomB;
              }

              carA.x = mu.clamp(carA.x - shiftA, minXA, maxXA);
              carB.x = mu.clamp(carB.x + shiftB, minXB, maxXB);
              carA.worldX = carA.worldX - nxA * shiftA;
              carA.worldZ = carA.worldZ - nzA * shiftA;
              carB.worldX = carB.worldX + nxB * shiftB;
              carB.worldZ = carB.worldZ + nzB * shiftB;

              if (carA.lateralVelocity > 0.0) carA.lateralVelocity = 0.0;
              if (carB.lateralVelocity < 0.0) carB.lateralVelocity = 0.0;
            } else {
              // carB is on left, carA is on right
              let shiftA = overlap * 0.5;
              let shiftB = overlap * 0.5;

              let roomB = carB.x - minXB;
              let roomA = maxXA - carA.x;
              if (roomB < shiftB and roomA >= shiftB) {
                shiftA = shiftA + (shiftB - roomB);
                shiftB = roomB;
              } else if (roomA < shiftA and roomB >= shiftA) {
                shiftB = shiftB + (shiftA - roomA);
                shiftA = roomA;
              }

              carB.x = mu.clamp(carB.x - shiftB, minXB, maxXB);
              carA.x = mu.clamp(carA.x + shiftA, minXA, maxXA);
              carB.worldX = carB.worldX - nxB * shiftB;
              carB.worldZ = carB.worldZ - nzB * shiftB;
              carA.worldX = carA.worldX + nxA * shiftA;
              carA.worldZ = carA.worldZ + nzA * shiftA;

              if (carB.lateralVelocity > 0.0) carB.lateralVelocity = 0.0;
              if (carA.lateralVelocity < 0.0) carA.lateralVelocity = 0.0;
            }
          }

          if (carA.isPlayer or carB.isPlayer) {
            let pCar = carA;
            if (carB.isPlayer) pCar = carB;
            if (pCar.impactCooldown <= 0.0) {
              pCar.impactCooldown = 0.25;
              if (cam != nil) cam.addShake(0.18);
              if (particles != nil) particles.emitSparks(pCar.worldX, pCar.worldY + 0.35, pCar.worldZ, 8);
              if (assets != nil) assets.playSfx(assets.sndCrash);
            }
          }
        }
      }
    }
  }
}
