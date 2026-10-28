// TURBO CIRCUIT: OVERDRIVE — Vehicles & Physics
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

    // Transform
    this.x = 0.0;
    this.worldX = 0.0;
    this.y = 0.0;
    this.z = startZ;
    this.trackDistance = 0.0;
    this.steer = 0.0;
    this.steerAngle = 0.0;
    this.heading = 0.0;
    this.yawRate = 0.0;
    this.lateralVelocity = 0.0;
    this.cornerLoad = 0.0;
    this.turnCommitment = 0.0;
    this.driftAngle = 0.0;
    this.isDrifting = false;
    this.driftPoints = 0;
    this.isReversing = false;
    this.completedLaps = 0;
    this.hasCrossedMidpoint = false;

    // Dynamics
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
    this.wallDamageCooldown = 0.0;
    // Short global impact grace prevents one contact from draining the hull every frame.
    this.impactCooldown = 0.0;
    this.boostPadCooldown = 0.0;
    this.shieldRegenDelay = 0.0;
    this.spinTimer = 0.0;
    this.brakeWarning = 0;
    this.wallHitShake = 0.0;
    this.inputOverride = nil;
    this.isAutopilot = false;
    this.isOffTrack = false;
    this.onCurb = false;

    // AI parameters
    this.aiLane = 0.0;
    this.aiLaneTimer = 0.0;
    this.aiSkill = mu.randFloat(0.85, 1.15);

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

  updatePlayer(dt, track, particles, assets) {
    // 0. Spin-out handling (when shield is depleted or during severe impact)
    if (this.spinTimer > 0.0) {
      this.spinTimer = this.spinTimer - dt;
      this.speed = mu.approach(this.speed, 20.0, dt * 50.0);
      this.driftAngle = this.driftAngle + 680.0 * dt;
      this.trackDistance = this.trackDistance + this.speed * dt;
      this.worldX = this.x;
      if (particles != nil) particles.emitDriftSmoke(this.worldX, 0.0, this.z, 1.0);
      if (this.hitFlash > 0.0) this.hitFlash = this.hitFlash - dt;
      if (this.spinTimer <= 0.0) {
        this.driftAngle = 0.0;
      }
      return;
    }

    // Shield auto-repair when out of combat / damage cooldown
    if (this.shieldRegenDelay > 0.0) {
      this.shieldRegenDelay = this.shieldRegenDelay - dt;
    } else {
      if (this.hull < this.maxHull) {
        this.hull = mu.clamp(this.hull + 10.0 * dt, 0.0, this.maxHull);
      }
    }

    if (this.wallDamageCooldown > 0.0) {
      this.wallDamageCooldown = this.wallDamageCooldown - dt;
    }
    if (this.impactCooldown > 0.0) this.impactCooldown = this.impactCooldown - dt;
    if (this.boostPadCooldown > 0.0) this.boostPadCooldown = this.boostPadCooldown - dt;

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
      if (gui.isKeyDown("KEY_A") or gui.isKeyDown("KEY_LEFT")) steerInput = steerInput - 1.0;
      if (gui.isKeyDown("KEY_D") or gui.isKeyDown("KEY_RIGHT")) steerInput = steerInput + 1.0;
      throttleInput = gui.isKeyDown("KEY_W") or gui.isKeyDown("KEY_UP");
      brakeInput = gui.isKeyDown("KEY_S") or gui.isKeyDown("KEY_DOWN");
      boostKey = gui.isKeyDown("KEY_SPACE");
      shiftKey = gui.isKeyDown("KEY_LEFT_SHIFT");
    }

    let boostInput = boostKey and this.nitro > 4.0 and (throttleInput or this.speed > 25.0);

    // Drift activation: brake while steering, or use Shift as a deliberate handbrake.
    let wantDrift = (brakeInput or shiftKey) and math.abs(steerInput) > 0.1 and this.speed > 24.0;
    if (wantDrift) {
      this.isDrifting = true;
      let targetDriftAngle = steerInput * 18.0;
      this.driftAngle = mu.approach(this.driftAngle, targetDriftAngle, dt * 54.0);
      this.driftPoints = this.driftPoints + math.floor(dt * 140.0);

      // Drifting refills nitro!
      this.nitro = mu.clamp(this.nitro + this.spec["nitroRegen"] * 2.2 * dt, 0.0, this.maxNitro);

      // Emit tire smoke and skid sfx
      let driftSign = 1.0;
      if (steerInput < 0.0) driftSign = -1.0;
      if (particles != nil) particles.emitDriftSmoke(this.worldX, 0.0, this.z, driftSign);
      if (rand(8) == 0 and assets != nil) assets.playSfx(assets.sndSkid);
    } else {
      // If we just finished a high-value drift, reward with mini-turbo boost!
      if (this.isDrifting and this.driftPoints > 75) {
        this.speed = mu.clamp(this.speed + 6.0, 0.0, this.boostSpeed);
        if (assets != nil) assets.playSfx(assets.sndNitro);
        if (particles != nil) particles.emitNitroFlames(this.worldX, 0.0, this.z, this.speed, 1.2);
      }
      this.driftPoints = 0;
      this.isDrifting = false;
      this.driftAngle = mu.approach(this.driftAngle, 0.0, dt * 60.0);
    }

    // 2. Throttle, Brakes, Reverse & Nitro Overdrive
    if (this.isOffTrack) {
      // Gravel Trap Drag Penalty: Rolling resistance drags car down hard towards ~22 MPH
      let gravelTop = 22.0;
      this.speed = mu.approach(this.speed, gravelTop, dt * 25.0);
      if (particles != nil) particles.emitDust(this.worldX, 0.0, this.z);
    }

    if (boostInput and !this.isOffTrack) {
      this.isBoosting = true;
      this.isReversing = false;
      this.speed = mu.approach(this.speed, boostTop, dt * (this.accel * 1.5));
      this.nitro = mu.clamp(this.nitro - this.spec["nitroBurn"] * dt, 0.0, this.maxNitro);

      // Nitro exhaust particles
      let boostTier = 1.0;
      if (this.speed > 85.0) boostTier = 1.5;
      if (particles != nil) particles.emitNitroFlames(this.worldX, 0.0, this.z, this.speed, boostTier);
      if (rand(12) == 0 and assets != nil) assets.playSfx(assets.sndNitro);
    } else if (throttleInput) {
      this.isBoosting = false;
      if (this.speed < 0.0) {
        // Accelerating out of reverse
        this.speed = mu.approach(this.speed, 0.0, dt * 50.0);
        this.isReversing = false;
      } else {
        let effAccel = this.accel;
        let effTop = cruiseTop;
        if (this.isOffTrack) {
          effAccel = this.accel * 0.30; // 70% throttle power loss in gravel!
          effTop = 20.0;
        }
        this.speed = mu.approach(this.speed, effTop, dt * effAccel);
        this.isReversing = false;
      }
      // Trickle nitro refill when not boosting
      this.nitro = mu.clamp(this.nitro + this.spec["nitroRegen"] * 0.3 * dt, 0.0, this.maxNitro);
    } else if (brakeInput and !this.isDrifting) {
      this.isBoosting = false;
      if (this.speed > 2.0) {
        // Active braking (snappy, responsive deceleration)
        this.speed = mu.approach(this.speed, 0.0, dt * 70.0);
        this.isReversing = false;
      } else {
        // Reverse gear
        this.isReversing = true;
        this.speed = mu.approach(this.speed, -20.0, dt * 16.0);
      }
    } else if (this.isDrifting) {
      this.isBoosting = false;
      if (brakeInput) {
        // Handbrake turn / braking drift: scrub speed down to tighten the turn radius
        this.speed = mu.approach(this.speed, 12.0, dt * 28.0);
      } else {
        // Controlled power slide speed retention
        let slideTarget = cruiseTop * 0.72;
        this.speed = mu.approach(this.speed, slideTarget, dt * 15.0);
      }
    } else {
      // Coasting (no throttle, no brake)
      this.isBoosting = false;
      this.isReversing = false;
      this.speed = mu.approach(this.speed, 0.0, dt * 16.0);
      this.nitro = mu.clamp(this.nitro + this.spec["nitroRegen"] * 0.5 * dt, 0.0, this.maxNitro);
    }

    // 3. Front-First Steering & Vehicle Heading Dynamics
    let effectiveSteerInput = steerInput;
    if (this.isReversing) effectiveSteerInput = -effectiveSteerInput;

    this.steer = mu.approach(this.steer, effectiveSteerInput, dt * 14.0);

    // Front wheels turn first!
    let maxWheelLock = 0.50; // ~29 degrees max steer
    let targetWheel = this.steer * maxWheelLock;
    this.steerAngle = mu.approach(this.steerAngle, targetWheel, dt * 10.0);

    let speedRatio = math.abs(this.speed) / this.maxSpeed;
    if (speedRatio > 1.0) speedRatio = 1.0;

    // Yaw agility: responsive at slow speeds for turning around / U-turns, stable at high speeds
    let turnAgility = (this.handling * 0.65) * (1.4 - speedRatio * 0.4);
    if (this.isDrifting) {
      let driftMult = 1.6;
      if (this.spec["driftRate"] != nil) driftMult = 1.2 + this.spec["driftRate"] * 0.25;
      turnAgility = turnAgility * driftMult;
    }
    if (this.isOffTrack) {
      turnAgility = turnAgility * 0.5; // Traction loss in gravel
    }

    let yawTorque = this.steerAngle * turnAgility - this.yawRate * 5.5;
    this.yawRate = this.yawRate + yawTorque * dt;
    this.heading = this.heading + this.yawRate * dt;

    // Road Curvature effect on relative heading:
    // As the road turns, relative to the road the vehicle heading rotates
    let fwdSpeed = this.speed * math.cos(this.heading);
    let curv = track.getCurvature(0.0, this.trackDistance);
    let dRoadTheta = curv * fwdSpeed * dt;
    this.heading = this.heading - dRoadTheta;

    // Gentle straight-line caster stabilization ONLY when driving forward and unsteered
    if (math.abs(this.heading) < 0.40 and math.abs(steerInput) < 0.1) {
      this.heading = this.heading * (1.0 - 2.0 * dt);
    }

    // Wrap heading cleanly to [-PI, +PI] for full 360-degree freedom
    let PI = 3.14159265;
    let TWO_PI = 6.2831853;
    while (this.heading > PI) this.heading = this.heading - TWO_PI;
    while (this.heading < -PI) this.heading = this.heading + TWO_PI;

    // Velocity projection: motion follows heading in full 360 degrees
    let effectiveHeading = this.heading + (this.driftAngle * 0.0174533 * 0.5);
    let forwardProgress = this.speed * math.cos(effectiveHeading);
    this.lateralVelocity = this.speed * math.sin(effectiveHeading);

    // Track Distance accumulation on closed-loop circuit
    this.trackDistance = this.trackDistance + forwardProgress * dt;
    let lapLen = track.spec["length"];
    if (this.trackDistance > lapLen * 0.5) this.hasCrossedMidpoint = true;
    if (this.trackDistance >= lapLen) {
      this.trackDistance = this.trackDistance - lapLen;
      if (this.hasCrossedMidpoint) {
        this.completedLaps = this.completedLaps + 1;
        this.hasCrossedMidpoint = false;
      }
    }
    while (this.trackDistance < 0.0) this.trackDistance = this.trackDistance + lapLen;

    this.x = this.x + this.lateralVelocity * dt;
    this.worldX = this.x;

    let cornerPreview = track.getCurveOffset(-36.0, this.trackDistance);
    let absCurv = math.abs(curv);
    this.cornerLoad = mu.clamp((math.abs(cornerPreview) * 0.08 + absCurv * 18.0), 0.0, 1.0);

    // Look ahead 54m for upcoming sharp corners (Braking Zones alert)
    let lookAheadCurv = track.getCurvature(-54.0, this.trackDistance);
    let lookAheadOffset = track.getCurveOffset(-54.0, this.trackDistance);
    let absCurvAhead = math.abs(lookAheadCurv);
    this.brakeWarning = 0;
    if ((absCurvAhead > 0.012 or math.abs(lookAheadOffset) > 6.0) and this.speed > 50.0) {
      if (lookAheadOffset > 0.0) {
        this.brakeWarning = 2; // Sharp Right Turn Ahead!
      } else {
        this.brakeWarning = 1; // Sharp Left Turn Ahead!
      }
    }

    // 4. Track Surface Zones & Barrier Collisions
    let halfRoad = track.roadWidth * 0.5;
    let curbW = track.curbWidth;
    let runoffW = track.runoffWidth;
    let wallLimit = halfRoad + curbW + runoffW - 0.45;
    let absX = math.abs(this.x);

    this.isOffTrack = false;
    this.onCurb = false;

    if (absX > halfRoad + curbW) {
      this.isOffTrack = true;
    } else if (absX > halfRoad) {
      this.onCurb = true;
    }

    if (absX >= wallLimit) {
      let sign = 1.0;
      if (this.x < 0.0) sign = -1.0;
      this.x = sign * (wallLimit - 0.45); // Keep inside track
      this.lateralVelocity = 0.0; // Stop outward lateral drift

      // Barrier prevents rotating deeper into the wall, but freely allows turning away
      if (sign * this.heading > 0.0) {
        this.heading = mu.approach(this.heading, 0.0, dt * 10.0);
        if (sign * this.yawRate > 0.0) this.yawRate = 0.0;
      }

      if (this.wallDamageCooldown <= 0.0) {
        if (this.speed > 68.0) {
          this.speed = this.speed * 0.74;
          this.hull = this.hull - 10.0;
          this.shieldRegenDelay = 3.5;
          this.wallHitShake = 0.30;
          this.hitFlash = 0.25;
          if (particles != nil) particles.emitSparks(this.worldX + sign * 0.6, 0.5, this.z, 12);
          if (assets != nil) assets.playSfx(assets.sndCrash);
        } else if (this.speed > 35.0) {
          this.speed = this.speed * 0.82;
          this.hull = this.hull - 5.0;
          this.shieldRegenDelay = 2.2;
          this.wallHitShake = 0.18;
          this.hitFlash = 0.15;
          if (particles != nil) particles.emitSparks(this.worldX + sign * 0.6, 0.4, this.z, 8);
          if (assets != nil) assets.playSfx(assets.sndCrash);
        } else {
          this.speed = this.speed * 0.88;
          this.hull = this.hull - 2.0;
          this.shieldRegenDelay = 1.2;
          this.wallHitShake = 0.10;
          this.hitFlash = 0.10;
          if (particles != nil) particles.emitSparks(this.worldX + sign * 0.6, 0.3, this.z, 4);
          if (assets != nil) assets.playSfx(assets.sndCrash);
        }
        if (this.hull < 0.0) this.hull = 0.0;
        this.wallDamageCooldown = 0.40;
      }
    }

    if (this.hitFlash > 0.0) this.hitFlash = this.hitFlash - dt;
    if (this.nearMissTimer > 0.0) this.nearMissTimer = this.nearMissTimer - dt;
  }

  updateAi(playerZ, playerSpeed, dt, track) {
    // AI Lane logic
    this.aiLaneTimer = this.aiLaneTimer - dt;
    if (this.aiLaneTimer <= 0.0) {
      this.aiLane = mu.randFloat(-2.8, 2.8);
      this.aiLaneTimer = mu.randFloat(2.5, 6.0);
    }

    let aiCurvature = track.getCurvature(0.0, this.trackDistance);
    let absAiCurvature = math.abs(aiCurvature);
    let aiCornerLoad = mu.clamp(absAiCurvature * 22.0, 0.0, 1.0);

    // Steer front-first towards target lane
    let aiLatError = this.aiLane - this.x;
    let aiSteer = mu.clamp(aiLatError * 0.22 + (aiCurvature * 24.0), -1.0, 1.0);
    this.steerAngle = mu.approach(this.steerAngle, aiSteer * 0.45, dt * 8.0);
    let aiYawTorque = this.steerAngle * 14.0 - this.yawRate * 5.5;
    this.yawRate = this.yawRate + aiYawTorque * dt;
    this.heading = this.heading + this.yawRate * dt;
    let aiDs = this.speed * dt;
    this.heading = this.heading - aiCurvature * aiDs * 1.2;
    this.heading = this.heading * (1.0 - 2.5 * dt);
    this.x = this.x + (this.speed * 0.50) * math.sin(this.heading) * dt;
    let aiRoadLimit = track.roadWidth * 0.5 - 0.9;
    this.x = mu.clamp(this.x, -aiRoadLimit, aiRoadLimit);

    // AI speed & rubberbanding
    let targetSpeed = this.maxSpeed * this.aiSkill;
    let distToPlayer = this.z - playerZ;

    if (aiCornerLoad > 0.18) {
      let aiCornerSpeed = 64.0 - aiCornerLoad * 24.0;
      if (targetSpeed > aiCornerSpeed) targetSpeed = aiCornerSpeed;
    }

    if (distToPlayer > 60.0) {
      targetSpeed = targetSpeed * 0.92;
    } else if (distToPlayer < -30.0) {
      targetSpeed = targetSpeed * 1.12;
    }

    this.speed = mu.approach(this.speed, targetSpeed, dt * 20.0);

    // AI track distance on closed circuit
    this.trackDistance = this.trackDistance + this.speed * dt;
    let lapLen = track.spec["length"];
    if (this.trackDistance > lapLen * 0.5) this.hasCrossedMidpoint = true;
    if (this.trackDistance >= lapLen) {
      this.trackDistance = this.trackDistance - lapLen;
      if (this.hasCrossedMidpoint) {
        this.completedLaps = this.completedLaps + 1;
        this.hasCrossedMidpoint = false;
      }
    }
    while (this.trackDistance < 0.0) this.trackDistance = this.trackDistance + lapLen;
  }

  draw(assets, t) {
    let headingDeg = this.heading * 57.2957795;
    let steerDeg = this.steerAngle * 57.2957795;
    let rotY = 180.0 - headingDeg + this.driftAngle - steerDeg * 0.4;
    let r = this.colorR;
    let g = this.colorG;
    let b = this.colorB;

    if (this.hitFlash > 0.0) {
      r = 255; g = 255; b = 255;
    }

    let drawX = this.worldX;

    // 3D Model
    assets.playCarModel(this.carId, drawX, this.y, this.z, rotY, this.scale, r, g, b);

    // Underglow neon reflection on road
    let glow = this.spec["glowColor"];
    gui.drawPlane3D(drawX, 0.03, this.z, 2.8, 4.4,
                    math.floor(glow[0] * 0.35), math.floor(glow[1] * 0.35), math.floor(glow[2] * 0.35));

    // Dynamic Headlights and Taillights rotating with vehicle heading
    let cosH = math.cos(this.heading);
    let sinH = math.sin(this.heading);
    let hx = 0.55;
    let hz = 1.8;

    // Front headlights (bright white/yellow)
    let fLeftX = drawX - hx * cosH - hz * sinH;
    let fLeftZ = this.z - hz * cosH + hx * sinH;
    let fRightX = drawX + hx * cosH - hz * sinH;
    let fRightZ = this.z - hz * cosH - hx * sinH;
    gui.drawSphere3D(fLeftX, this.y + 0.35, fLeftZ, 0.16, 240, 250, 255);
    gui.drawSphere3D(fRightX, this.y + 0.35, fRightZ, 0.16, 240, 250, 255);

    // Rear taillights (red)
    let rLeftX = drawX - hx * cosH + hz * sinH;
    let rLeftZ = this.z + hz * cosH + hx * sinH;
    let rRightX = drawX + hx * cosH + hz * sinH;
    let rRightZ = this.z + hz * cosH - hx * sinH;
    gui.drawSphere3D(rLeftX, this.y + 0.35, rLeftZ, 0.14, 255, 30, 30);
    gui.drawSphere3D(rRightX, this.y + 0.35, rRightZ, 0.14, 255, 30, 30);
  }
}

// Civilian Traffic Car for Highway Slalom Mode
export class TrafficCar {
  init(startZ) {
    this.x = mu.randFloat(-3.2, 3.2);
    this.worldX = this.x;
    this.y = 0.0;
    this.z = startZ;
    this.type = rand(5); // 0=Delivery, 1=Truck, 2=Sedan, 3=Taxi, 4=Ambulance
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
    let r = 240; let g = 240; let b = 240;
    if (this.type == 0) { r = 40; g = 180; b = 255; }      // Delivery Blue
    else if (this.type == 1) { r = 255; g = 140; b = 30; }  // Truck Orange
    else if (this.type == 2) { r = 180; g = 50; b = 220; }  // Sedan Purple
    else if (this.type == 3) { r = 255; g = 220; b = 20; }  // Taxi Yellow
    else { r = 255; g = 50; b = 50; }                      // Ambulance Red

    let drawX = this.worldX;
    assets.playTrafficModel(this.type, drawX, this.y, this.z, 180.0, 1.25, r, g, b);

    // Taillights
    gui.drawSphere3D(drawX - 0.5, this.y + 0.45, this.z + 1.6, 0.14, 255, 20, 20);
    gui.drawSphere3D(drawX + 0.5, this.y + 0.45, this.z + 1.6, 0.14, 255, 20, 20);
  }
}
