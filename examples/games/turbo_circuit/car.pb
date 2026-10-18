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
    this.driftAngle = 0.0;
    this.isDrifting = false;
    this.driftPoints = 0;
    this.isReversing = false;

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
    let cruiseTop = this.maxSpeed;
    let boostTop = this.boostSpeed;

    // 1. Steering & Inputs
    let steerInput = 0.0;
    if (gui.isKeyDown("KEY_A") or gui.isKeyDown("KEY_LEFT")) steerInput = steerInput - 1.0;
    if (gui.isKeyDown("KEY_D") or gui.isKeyDown("KEY_RIGHT")) steerInput = steerInput + 1.0;

    let throttleInput = gui.isKeyDown("KEY_W") or gui.isKeyDown("KEY_UP");
    let brakeInput = gui.isKeyDown("KEY_S") or gui.isKeyDown("KEY_DOWN");
    let boostKey = gui.isKeyDown("KEY_SPACE") or gui.isKeyDown("KEY_LEFT_SHIFT");
    let boostInput = boostKey and this.nitro > 4.0 and (throttleInput or this.speed > 25.0);

    // Drift activation (holding brake or shift while steering at high speed)
    let wantDrift = (brakeInput or gui.isKeyDown("KEY_LEFT_SHIFT")) and math.abs(steerInput) > 0.1 and this.speed > 32.0;
    if (wantDrift) {
      this.isDrifting = true;
      let targetDriftAngle = steerInput * 22.0;
      this.driftAngle = mu.approach(this.driftAngle, targetDriftAngle, dt * 80.0);
      this.driftPoints = this.driftPoints + math.floor(dt * 140.0);

      // Drifting refills nitro!
      this.nitro = mu.clamp(this.nitro + this.spec["nitroRegen"] * 2.2 * dt, 0.0, this.maxNitro);

      // Emit tire smoke and skid sfx
      let driftSign = 1.0;
      if (steerInput < 0.0) driftSign = -1.0;
      particles.emitDriftSmoke(this.worldX, 0.0, this.z, driftSign);
      if (rand(8) == 0) assets.playSfx(assets.sndSkid);
    } else {
      // If we just finished a high-value drift, reward with mini-turbo boost!
      if (this.isDrifting and this.driftPoints > 75) {
        this.speed = mu.clamp(this.speed + 12.0, 0.0, this.boostSpeed);
        assets.playSfx(assets.sndNitro);
        particles.emitNitroFlames(this.worldX, 0.0, this.z, this.speed, 1.2);
      }
      this.driftPoints = 0;
      this.isDrifting = false;
      this.driftAngle = mu.approach(this.driftAngle, 0.0, dt * 60.0);
    }

    // 2. Throttle, Brakes, Reverse & Nitro Overdrive
    if (boostInput) {
      this.isBoosting = true;
      this.isReversing = false;
      this.speed = mu.approach(this.speed, boostTop, dt * (this.accel * 2.4));
      this.nitro = mu.clamp(this.nitro - this.spec["nitroBurn"] * dt, 0.0, this.maxNitro);

      // Nitro exhaust particles
      let boostTier = 1.0;
      if (this.speed > 130.0) boostTier = 1.5;
      particles.emitNitroFlames(this.worldX, 0.0, this.z, this.speed, boostTier);
      if (rand(12) == 0) assets.playSfx(assets.sndNitro);
    } else if (throttleInput) {
      this.isBoosting = false;
      if (this.speed < 0.0) {
        // Accelerating out of reverse
        this.speed = mu.approach(this.speed, 0.0, dt * 50.0);
        this.isReversing = false;
      } else {
        this.speed = mu.approach(this.speed, cruiseTop, dt * this.accel);
        this.isReversing = false;
      }
      // Trickle nitro refill when not boosting
      this.nitro = mu.clamp(this.nitro + this.spec["nitroRegen"] * 0.3 * dt, 0.0, this.maxNitro);
    } else if (brakeInput and !this.isDrifting) {
      this.isBoosting = false;
      if (this.speed > 2.0) {
        // Active braking
        this.speed = mu.approach(this.speed, 0.0, dt * 55.0);
        this.isReversing = false;
      } else {
        // Reverse gear
        this.isReversing = true;
        this.speed = mu.approach(this.speed, -20.0, dt * 16.0);
      }
    } else if (this.isDrifting) {
      this.isBoosting = false;
      // Controlled slide speed retention
      let slideTarget = cruiseTop * 0.82;
      this.speed = mu.approach(this.speed, slideTarget, dt * 10.0);
    } else {
      // Coasting (no throttle, no brake)
      this.isBoosting = false;
      this.isReversing = false;
      this.speed = mu.approach(this.speed, 0.0, dt * 14.0);
      this.nitro = mu.clamp(this.nitro + this.spec["nitroRegen"] * 0.5 * dt, 0.0, this.maxNitro);
    }

    // 3. Steering & Agile Arcade Handling
    let effectiveSteerInput = steerInput;
    if (this.isReversing) effectiveSteerInput = -effectiveSteerInput;

    // Dialed-in lateral speed: smooth, controllable lane changing (~6-7 m/s)
    let steerSpeed = this.handling * 0.22;
    if (this.isDrifting) steerSpeed = steerSpeed * 1.35;
    this.steer = mu.approach(this.steer, effectiveSteerInput, dt * 10.0);
    this.x = this.x + this.steer * steerSpeed * dt;

    // Gentle curve feeling at higher speeds (subtle, never forces car into wall)
    if (this.speed > 50.0) {
      let curvature = track.getCurvature(0.0, this.trackDistance);
      let subtlePull = -curvature * (this.speed / 100.0) * 0.40 * dt;
      this.x = this.x + subtlePull;
    }

    // Track Distance accumulation
    this.trackDistance = this.trackDistance + this.speed * dt;
    if (this.trackDistance < 0.0) this.trackDistance = 0.0;

    // Synchronize world X on curved track: at player's wheels (z=0), road center is 0.0
    this.worldX = this.x;

    // 4. Track Boundary Collisions (Guardrails with bounce)
    let halfRoad = (track.roadWidth * 0.5) - 0.95;
    if (this.x < -halfRoad) {
      this.x = -halfRoad + 0.30; // Gentle bounce back onto tarmac!
      this.steer = 0.0;
      this.speed = this.speed * 0.92;
      this.hull = this.hull - 4.0;
      this.hitFlash = 0.25;
      particles.emitSparks(this.worldX - 0.8, 0.4, this.z, 6);
      assets.playSfx(assets.sndCrash);
    } else if (this.x > halfRoad) {
      this.x = halfRoad - 0.30; // Gentle bounce back onto tarmac!
      this.steer = 0.0;
      this.speed = this.speed * 0.92;
      this.hull = this.hull - 4.0;
      this.hitFlash = 0.25;
      particles.emitSparks(this.worldX + 0.8, 0.4, this.z, 6);
      assets.playSfx(assets.sndCrash);
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

    // Steer towards target lane
    this.x = mu.approach(this.x, this.aiLane, dt * 5.0 * this.aiSkill);

    // AI speed & rubberbanding
    let targetSpeed = this.maxSpeed * this.aiSkill;
    let distToPlayer = this.z - playerZ;

    if (distToPlayer > 70.0) {
      targetSpeed = targetSpeed * 0.92;
    } else if (distToPlayer < -35.0) {
      targetSpeed = targetSpeed * 1.15;
    }

    this.speed = mu.approach(this.speed, targetSpeed, dt * 25.0);

    // AI relative forward movement
    let relativeSpeed = this.speed - playerSpeed;
    this.z = this.z - relativeSpeed * dt;

    // AI track distance
    this.trackDistance = this.trackDistance + this.speed * dt;

    // AI worldX on curved track at this.z
    let roadCurve = track.getCurveOffset(this.z, this.trackDistance);
    this.worldX = roadCurve + this.x;
  }

  draw(assets, t) {
    let rotY = 180.0 + this.driftAngle - this.steer * 8.0;
    if (this.isReversing) rotY = 180.0;
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

    // Headlights / Reverse Lights
    let beamR = 240; let beamG = 250; let beamB = 255;
    if (this.isReversing) {
      gui.drawSphere3D(drawX - 0.55, this.y + 0.35, this.z + 1.8, 0.16, 255, 255, 255);
      gui.drawSphere3D(drawX + 0.55, this.y + 0.35, this.z + 1.8, 0.16, 255, 255, 255);
    } else {
      gui.drawSphere3D(drawX - 0.55, this.y + 0.35, this.z - 1.8, 0.16, beamR, beamG, beamB);
      gui.drawSphere3D(drawX + 0.55, this.y + 0.35, this.z - 1.8, 0.16, beamR, beamG, beamB);
    }
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
