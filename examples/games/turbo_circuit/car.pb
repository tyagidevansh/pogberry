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
    this.y = 0.0;
    this.z = startZ;
    this.steer = 0.0;
    this.driftAngle = 0.0;
    this.isDrifting = false;
    this.driftPoints = 0;

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

    // 1. Steering & Drift Input
    let steerInput = 0.0;
    if (gui.isKeyDown("KEY_A") or gui.isKeyDown("KEY_LEFT")) steerInput = steerInput - 1.0;
    if (gui.isKeyDown("KEY_D") or gui.isKeyDown("KEY_RIGHT")) steerInput = steerInput + 1.0;

    let brakeInput = gui.isKeyDown("KEY_S") or gui.isKeyDown("KEY_DOWN");
    let boostInput = (gui.isKeyDown("KEY_SPACE") or gui.isKeyDown("KEY_LEFT_SHIFT")) and this.nitro > 4.0;

    // Drift activation (holding brake while turning at high speed)
    if (brakeInput and math.abs(steerInput) > 0.1 and this.speed > 45.0) {
      this.isDrifting = true;
      this.driftAngle = mu.approach(this.driftAngle, steerInput * 24.0, dt * 80.0);
      this.driftPoints = this.driftPoints + math.floor(dt * 120.0);

      // Shinobi & other cars gain nitro from drifting!
      this.nitro = mu.clamp(this.nitro + this.spec["nitroRegen"] * 1.5 * dt, 0.0, this.maxNitro);

      // Emit tire smoke
      particles.emitDriftSmoke(this.x, 0.0, this.z, steerInput);
      if (rand(8) == 0) assets.playSfx(assets.sndSkid);
    } else {
      this.isDrifting = false;
      this.driftAngle = mu.approach(this.driftAngle, 0.0, dt * 70.0);
    }

    // Steering velocity
    let steerSensitivity = this.handling * (0.6 + (this.speed / cruiseTop) * 0.4);
    if (this.isDrifting) steerSensitivity = steerSensitivity * 1.35;
    this.steer = mu.approach(this.steer, steerInput, dt * 6.5);
    this.x = this.x + this.steer * steerSensitivity * dt;

    // 2. Acceleration & Nitro Overdrive
    if (boostInput) {
      this.isBoosting = true;
      this.speed = mu.approach(this.speed, boostTop, dt * (this.accel * 2.2));
      this.nitro = mu.clamp(this.nitro - this.spec["nitroBurn"] * dt, 0.0, this.maxNitro);

      // Nitro exhaust particles
      let boostTier = 1.0;
      if (this.speed > 130.0) boostTier = 1.5;
      particles.emitNitroFlames(this.x, 0.0, this.z, this.speed, boostTier);
      if (rand(12) == 0) assets.playSfx(assets.sndNitro);
    } else {
      this.isBoosting = false;
      let targetSpeed = cruiseTop;
      if (brakeInput and !this.isDrifting) targetSpeed = cruiseTop * 0.4;
      this.speed = mu.approach(this.speed, targetSpeed, dt * this.accel);
      // Passive nitro refill
      this.nitro = mu.clamp(this.nitro + this.spec["nitroRegen"] * 0.5 * dt, 0.0, this.maxNitro);
    }

    // 3. Track Boundary Collisions
    let halfRoad = (track.roadWidth * 0.5) - 1.1;
    if (this.x < -halfRoad) {
      this.x = -halfRoad;
      this.speed = this.speed * 0.94;
      this.hull = this.hull - 35.0 * dt;
      this.hitFlash = 0.35;
      particles.emitSparks(this.x - 0.7, 0.4, this.z, 4);
      assets.playSfx(assets.sndCrash);
    } else if (this.x > halfRoad) {
      this.x = halfRoad;
      this.speed = this.speed * 0.94;
      this.hull = this.hull - 35.0 * dt;
      this.hitFlash = 0.35;
      particles.emitSparks(this.x + 0.7, 0.4, this.z, 4);
      assets.playSfx(assets.sndCrash);
    }

    if (this.hitFlash > 0.0) this.hitFlash = this.hitFlash - dt;
    if (this.nearMissTimer > 0.0) this.nearMissTimer = this.nearMissTimer - dt;
  }

  updateAi(playerZ, playerSpeed, dt, track) {
    // AI Lane logic
    this.aiLaneTimer = this.aiLaneTimer - dt;
    if (this.aiLaneTimer <= 0.0) {
      this.aiLane = mu.randFloat(-3.2, 3.2);
      this.aiLaneTimer = mu.randFloat(2.5, 6.0);
    }

    // Steer towards target lane
    this.x = mu.approach(this.x, this.aiLane, dt * 6.0 * this.aiSkill);

    // Competitive rubber-banding speed
    let targetSpeed = this.maxSpeed * this.aiSkill;
    let distToPlayer = this.z - playerZ;

    if (distToPlayer > 80.0) {
      // Way ahead: slow down slightly so player can catch up
      targetSpeed = targetSpeed * 0.92;
    } else if (distToPlayer < -40.0) {
      // Far behind: boost up to rejoin pack
      targetSpeed = targetSpeed * 1.15;
    }

    this.speed = mu.approach(this.speed, targetSpeed, dt * 25.0);

    // AI relative forward movement
    let relativeSpeed = this.speed - playerSpeed;
    this.z = this.z - relativeSpeed * dt;
  }

  draw(assets, t) {
    let rotY = 180.0 + this.driftAngle - this.steer * 8.0;
    let r = this.colorR;
    let g = this.colorG;
    let b = this.colorB;

    if (this.hitFlash > 0.0) {
      r = 255; g = 255; b = 255;
    }

    // 3D Model
    assets.playCarModel(this.carId, this.x, this.y, this.z, rotY, this.scale, r, g, b);

    // Underglow neon reflection on road
    let glow = this.spec["glowColor"];
    let glowPulse = 180 + math.floor(math.sin(t * 12.0) * 45.0);
    gui.drawPlane3D(this.x, 0.03, this.z, 2.8, 4.4,
                    math.floor(glow[0] * 0.35), math.floor(glow[1] * 0.35), math.floor(glow[2] * 0.35));

    // Headlights (Twin forward light beams)
    let beamR = 240; let beamG = 250; let beamB = 255;
    gui.drawSphere3D(this.x - 0.55, this.y + 0.35, this.z - 1.8, 0.16, beamR, beamG, beamB);
    gui.drawSphere3D(this.x + 0.55, this.y + 0.35, this.z - 1.8, 0.16, beamR, beamG, beamB);
  }
}

// Civilian Traffic Car for Highway Slalom Mode
export class TrafficCar {
  init(startZ) {
    this.x = mu.randFloat(-3.5, 3.5);
    this.y = 0.0;
    this.z = startZ;
    this.type = rand(5); // 0=Delivery, 1=Truck, 2=Sedan, 3=Taxi, 4=Ambulance
    this.speed = mu.randFloat(35.0, 55.0);
    this.passed = false;
  }

  update(playerSpeed, dt) {
    // Relative movement against player's forward progress
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

    assets.playTrafficModel(this.type, this.x, this.y, this.z, 180.0, 1.25, r, g, b);

    // Taillights
    gui.drawSphere3D(this.x - 0.5, this.y + 0.45, this.z + 1.6, 0.14, 255, 20, 20);
    gui.drawSphere3D(this.x + 0.5, this.y + 0.45, this.z + 1.6, 0.14, 255, 20, 20);
  }
}

