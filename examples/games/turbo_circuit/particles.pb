// TURBO CIRCUIT: OVERDRIVE — 3D Particle Systems
use "pb_gui" as gui;
use "std.math" as math;
use "math_util" as mu;

export class ParticleSystem {
  init() {
    this.particles = [];
    this.maxParticles = 160;
  }

  emit(x, y, z, vx, vy, vz, size, r, g, b, life, kind) {
    if (len(this.particles) >= this.maxParticles) {
      // Replace oldest
      this.particles.pop();
    }
    this.particles.push({
      "x": x, "y": y, "z": z,
      "vx": vx, "vy": vy, "vz": vz,
      "size": size,
      "r": r, "g": g, "b": b,
      "life": life, "maxLife": life,
      "kind": kind
    });
  }

  emitNitroFlames(carX, carY, carZ, carSpeed, boostLevel) {
    // Twin exhaust flame jets behind the car
    let colorR = 0; let colorG = 230; let colorB = 255;
    if (boostLevel > 1.2) {
      colorR = 255; colorG = 60; colorB = 220; // Super Overdrive: Hot Pink
    }
    // Left nozzle
    this.emit(carX - 0.55, carY + 0.32, carZ + 1.85,
              mu.randFloat(-0.4, 0.4), mu.randFloat(-0.2, 0.5), carSpeed * 0.2 + mu.randFloat(18.0, 32.0),
              mu.randFloat(0.18, 0.32), colorR, colorG, colorB, 0.22, 0);
    // Right nozzle
    this.emit(carX + 0.55, carY + 0.32, carZ + 1.85,
              mu.randFloat(-0.4, 0.4), mu.randFloat(-0.2, 0.5), carSpeed * 0.2 + mu.randFloat(18.0, 32.0),
              mu.randFloat(0.18, 0.32), colorR, colorG, colorB, 0.22, 0);
  }

  emitDriftSmoke(carX, carY, carZ, driftSign) {
    // Tire smoke behind rear tires
    let offsetX = 0.85;
    if (driftSign < 0) offsetX = -0.85;
    this.emit(carX + offsetX, carY + 0.15, carZ + 1.2,
              mu.randFloat(-0.8, 0.8), mu.randFloat(0.4, 1.2), mu.randFloat(2.0, 6.0),
              mu.randFloat(0.22, 0.45), 200, 215, 235, 0.40, 1);
  }

  emitSparks(x, y, z, count) {
    for (let i = 0; i < count; i += 1) {
      this.emit(x, y, z,
                mu.randFloat(-6.0, 6.0), mu.randFloat(2.0, 8.0), mu.randFloat(-6.0, 6.0),
                mu.randFloat(0.08, 0.14), 255, mu.randFloat(120, 220), 40, 0.35, 2);
    }
  }

  update(dt) {
    let alive = [];
    for (let i = 0; i < len(this.particles); i += 1) {
      let p = this.particles[i];
      p["life"] = p["life"] - dt;
      if (p["life"] > 0) {
        p["x"] = p["x"] + p["vx"] * dt;
        p["y"] = p["y"] + p["vy"] * dt;
        p["z"] = p["z"] + p["vz"] * dt;

        // Smoke expands and rises
        if (p["kind"] == 1) {
          p["size"] = p["size"] + dt * 0.6;
          p["vy"] = p["vy"] + dt * 0.8;
        }
        // Sparks fall with gravity
        else if (p["kind"] == 2) {
          p["vy"] = p["vy"] - dt * 22.0;
        }

        alive.push(p);
      }
    }
    this.particles = alive;
  }

  draw() {
    for (let i = 0; i < len(this.particles); i += 1) {
      let p = this.particles[i];
      let alphaFade = p["life"] / p["maxLife"];
      let r = math.floor(p["r"] * alphaFade);
      let g = math.floor(p["g"] * alphaFade);
      let b = math.floor(p["b"] * alphaFade);
      if (r < 0) r = 0; if (g < 0) g = 0; if (b < 0) b = 0;

      if (p["kind"] == 0) {
        // Flame cube
        gui.drawCube3D(p["x"], p["y"], p["z"], p["size"], p["size"], p["size"] * 1.6, r, g, b);
      } else if (p["kind"] == 1) {
        // Smoke sphere
        gui.drawSphere3D(p["x"], p["y"], p["z"], p["size"], r, g, b);
      } else {
        // Spark
        gui.drawCube3D(p["x"], p["y"], p["z"], p["size"], p["size"], p["size"], r, g, b);
      }
    }
  }

  clear() {
    this.particles = [];
  }
}

