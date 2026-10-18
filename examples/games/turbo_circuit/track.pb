// TURBO CIRCUIT: OVERDRIVE — 3D Track & Environment
use "pb_gui" as gui;
use "std.math" as math;
use "math_util" as mu;
use "constants" as const;

export class Track {
  init(trackId) {
    this.trackId = trackId;
    this.spec = const.getTrackSpec(trackId);
    this.roadWidth = 11.0;
    this.segmentLength = 20.0;
    this.drawDistance = 24; // visible segments ahead

    // Checkpoint gate
    this.gateZ = -220.0;
    this.gateInterval = 320.0;

    // Energy cores
    this.coreX = 0.0;
    this.coreZ = -80.0;
    this.coreCollected = false;

    // Roadside hazards
    this.hazards = [];
    this.initHazards();
  }

  initHazards() {
    this.hazards = [];
    for (let i = 0; i < 6; i += 1) {
      let hz = -60.0 - i * 55.0;
      let hx = mu.randFloat(-3.2, 3.2);
      let kind = rand(2); // 0 = cone, 1 = box
      this.hazards.push({"x": hx, "z": hz, "kind": kind, "hit": false});
    }
  }

  update(scrollSpeed, dt) {
    // Scroll gate
    this.gateZ = this.gateZ + scrollSpeed * dt;
    if (this.gateZ > 14.0) {
      this.gateZ = this.gateZ - this.gateInterval;
    }

    // Scroll energy core
    this.coreZ = this.coreZ + scrollSpeed * dt;
    if (this.coreZ > 14.0) {
      this.coreZ = -140.0 - mu.randFloat(20.0, 60.0);
      this.coreX = mu.randFloat(-3.8, 3.8);
      this.coreCollected = false;
    }

    // Scroll hazards
    for (let i = 0; i < len(this.hazards); i += 1) {
      let h = this.hazards[i];
      h["z"] = h["z"] + scrollSpeed * dt;
      if (h["z"] > 14.0) {
        h["z"] = h["z"] - 330.0;
        h["x"] = mu.randFloat(-3.5, 3.5);
        h["hit"] = false;
      }
    }
  }

  getCurveOffset(z, distance) {
    let k = 0.0030;
    let curveAmt = 4.0;
    if (this.trackId == 1) curveAmt = 5.2;
    else if (this.trackId == 2) curveAmt = 6.5;

    // Player-relative curve offset: zero at z = 0, curves smoothly into the distance
    let base = math.sin(distance * k) * curveAmt;
    let ahead = math.sin((distance - z) * k) * curveAmt;
    return ahead - base;
  }

  getCurvature(z, distance) {
    let k = 0.0030;
    let curveAmt = 4.0;
    if (this.trackId == 1) curveAmt = 5.2;
    else if (this.trackId == 2) curveAmt = 6.5;

    // Curvature rate of upcoming curve ahead (30m down the road)
    let lookAhead = (math.sin((distance + 30.0) * k) - math.sin(distance * k)) * curveAmt;
    return lookAhead * 0.025;
  }

  draw(scroll, distance, t, assets) {
    let rcA = this.spec["railColorA"];
    let rcB = this.spec["railColorB"];
    let roadCol = this.spec["roadColor"];

    // 1. Render Road Segments
    for (let i = 0; i < this.drawDistance; i += 1) {
      let segZ = 16.0 - i * this.segmentLength + scroll;
      let curve = this.getCurveOffset(segZ, distance);
      let nextCurve = this.getCurveOffset(segZ - this.segmentLength, distance);
      let midCurve = (curve + nextCurve) * 0.5;

      // Road Surface Plane
      gui.drawPlane3D(midCurve, 0.0, segZ, this.roadWidth, this.segmentLength + 0.2,
                      roadCol[0], roadCol[1], roadCol[2]);

      // Neon Rails (Left & Right)
      let railPulse = 200 + math.floor(math.sin(t * 3.0 + i * 0.4) * 55.0);
      let halfW = this.roadWidth * 0.5;

      // Left Rail
      gui.drawCube3D(curve - halfW, 0.35, segZ, 0.22, 0.70, this.segmentLength,
                     rcA[0], rcA[1], rcA[2]);
      // Right Rail
      gui.drawCube3D(curve + halfW, 0.35, segZ, 0.22, 0.70, this.segmentLength,
                     rcB[0], rcB[1], rcB[2]);

      // Lane Divider Dashes
      for (let lane = -1; lane <= 1; lane += 2) {
        let laneX = curve + lane * (this.roadWidth * 0.25);
        gui.drawCube3D(laneX, 0.03, segZ, 0.12, 0.04, 5.0, 220, 235, 255);
      }

      // Overhead Streetlights / Energy Arches every 3 segments
      if (i % 3 == 0) {
        let archH = 7.5;
        // Left post
        gui.drawCube3D(curve - halfW - 0.5, archH * 0.5, segZ, 0.25, archH, 0.25, 30, 36, 52);
        // Right post
        gui.drawCube3D(curve + halfW + 0.5, archH * 0.5, segZ, 0.25, archH, 0.25, 30, 36, 52);
        // Crossbar
        gui.drawCube3D(curve, archH, segZ, this.roadWidth + 1.2, 0.25, 0.25, rcA[0], rcA[1], rcA[2]);
        // Glowing lights
        gui.drawSphere3D(curve - 3.0, archH - 0.2, segZ, 0.35, 255, 240, 180);
        gui.drawSphere3D(curve + 3.0, archH - 0.2, segZ, 0.35, 255, 240, 180);
      }
    }

    // 2. Render Roadside Scenery (Buildings / Canyon Props)
    for (let i = 0; i < 14; i += 1) {
      let propZ = -30.0 - i * 28.0 + scroll;
      let curve = this.getCurveOffset(propZ, distance);

      if (this.trackId == 0) {
        // Neo Shibuya Skyscrapers
        let bldScaleLeft = 3.0 + ((i * 7) % 3);
        let bldScaleRight = 3.5 + ((i * 11) % 4);
        let variantLeft = i % 4;
        let variantRight = (i + 2) % 4;

        assets.playBuildingModel(variantLeft, curve - 14.5, 0.0, propZ, bldScaleLeft, 90.0);
        assets.playBuildingModel(variantRight, curve + 14.5, 0.0, propZ - 12.0, bldScaleRight, -90.0);

        // Neon Billboards
        if (i % 2 == 0) {
          let glowPulse = 180 + math.floor(math.sin(t * 4.0 + i) * 70.0);
          gui.drawCube3D(curve - 11.0, 5.0, propZ, 0.2, 3.2, 6.0, 255, 40, glowPulse);
          gui.drawCube3D(curve + 11.0, 5.0, propZ - 8.0, 0.2, 3.2, 6.0, 40, glowPulse, 255);
        }
      } else if (this.trackId == 1) {
        // Sunset Horizon (Grandstand, Palm Silhouettes & Highway Signs)
        let pillarH = 7.0 + ((i * 5) % 6);
        gui.drawCube3D(curve - 13.0, pillarH * 0.5, propZ, 3.5, pillarH, 4.0, 48, 22, 38);
        gui.drawCube3D(curve + 13.0, pillarH * 0.5, propZ - 8.0, 3.5, pillarH, 4.0, 48, 22, 38);

        // Palm Tree Trunk & Fronds
        gui.drawCylinder3D(curve - 11.0, 3.0, propZ + 4.0, 0.25, 0.45, 6.0, 6, 90, 50, 30);
        gui.drawSphere3D(curve - 11.0, 6.2, propZ + 4.0, 1.8, 30, 110, 60);

        gui.drawCylinder3D(curve + 11.0, 3.0, propZ - 4.0, 0.25, 0.45, 6.0, 6, 90, 50, 30);
        gui.drawSphere3D(curve + 11.0, 6.2, propZ - 4.0, 1.8, 30, 110, 60);

        // Overhead Highway Distance Signs
        if (i % 3 == 0) {
          gui.drawCube3D(curve, 6.8, propZ, 8.5, 1.6, 0.3, 20, 80, 50);
        }

        // Ocean horizon on right with sunset reflection
        gui.drawPlane3D(curve + 70.0, -1.0, propZ, 95.0, 35.0, 28, 14, 45);
      } else {
        // Nebula Canyon (Futuristic Rock Pillars & Titan Spires)
        let rockH = 12.0 + ((i * 9) % 14);
        gui.drawCylinder3D(curve - 15.0, rockH * 0.5, propZ, 4.0, 6.5, rockH, 8, 45, 30, 40);
        gui.drawCylinder3D(curve + 15.0, rockH * 0.5, propZ - 10.0, 4.0, 6.5, rockH, 8, 45, 30, 40);

        // Glowing Energy Spire Crystals
        let crystalGlow = 180 + math.floor(math.sin(t * 5.0 + i) * 60.0);
        gui.drawCylinder3D(curve - 15.0, rockH + 2.0, propZ, 0.05, 1.5, 4.0, 5, 255, 160, crystalGlow);
        gui.drawCylinder3D(curve + 15.0, rockH + 2.0, propZ - 10.0, 0.05, 1.5, 4.0, 5, 255, 160, crystalGlow);

        // Giant Overhead Floating Energy Rings
        if (i % 2 == 1) {
          gui.drawCylinderWires3D(curve, 6.5, propZ, 6.0, 6.0, 1.2, 16, 255, 150, 30);
        }
      }
    }

    // 3. Render Hazards (Cones & Boxes)
    for (let i = 0; i < len(this.hazards); i += 1) {
      let h = this.hazards[i];
      if (h["z"] > -180.0 and h["z"] < 12.0 and !h["hit"]) {
        let curve = this.getCurveOffset(h["z"], distance);
        let hx = curve + h["x"];
        if (h["kind"] == 0) assets.playHazardCone(hx, 0.0, h["z"], 1.1);
        else assets.playHazardBox(hx, 0.0, h["z"], 1.0);
      }
    }

    // 4. Render Checkpoint Gate
    if (this.gateZ > -240.0 and this.gateZ < 12.0) {
      let gCurve = this.getCurveOffset(this.gateZ, distance);
      this.drawCheckpointGate(gCurve, this.gateZ, t);
    }

    // 5. Render Collectible Energy Core
    if (!this.coreCollected and this.coreZ > -180.0 and this.coreZ < 10.0) {
      let cCurve = this.getCurveOffset(this.coreZ, distance);
      let coreRealX = cCurve + this.coreX;
      let bobY = 1.1 + math.sin(t * 6.0) * 0.25;
      let pulseR = 0.45 + math.sin(t * 8.0) * 0.08;

      // Outer glow core
      gui.drawSphere3D(coreRealX, bobY, this.coreZ, pulseR, 0, 255, 230);
      // Inner bright nucleus
      gui.drawSphere3D(coreRealX, bobY, this.coreZ, 0.22, 240, 255, 255);
      // Orbiting energy ring
      gui.drawCylinderWires3D(coreRealX, bobY, this.coreZ, 0.65, 0.65, 0.08, 10, 255, 80, 220);
    }
  }

  drawCheckpointGate(x, z, t) {
    let gateW = this.roadWidth + 2.5;
    let gateH = 8.5;
    let glow = 200 + math.floor(math.sin(t * 5.0) * 55.0);

    // Left Column
    gui.drawCube3D(x - gateW * 0.5, gateH * 0.5, z, 0.8, gateH, 0.8, 40, 50, 75);
    gui.drawCube3D(x - gateW * 0.5, gateH * 0.5, z, 0.25, gateH - 0.5, 0.85, 0, glow, 255);

    // Right Column
    gui.drawCube3D(x + gateW * 0.5, gateH * 0.5, z, 0.8, gateH, 0.8, 40, 50, 75);
    gui.drawCube3D(x + gateW * 0.5, gateH * 0.5, z, 0.25, gateH - 0.5, 0.85, 0, glow, 255);

    // Overhead Header Bar
    gui.drawCube3D(x, gateH - 0.2, z, gateW, 0.8, 0.8, 30, 40, 60);
    gui.drawCube3D(x, gateH - 0.2, z, gateW - 0.6, 0.35, 0.85, 255, glow, 80);

    // Neon Gate Arch Lights
    gui.drawSphere3D(x - 3.5, gateH - 0.8, z, 0.4, 255, 240, 80);
    gui.drawSphere3D(x, gateH - 0.8, z, 0.45, 0, 255, 240);
    gui.drawSphere3D(x + 3.5, gateH - 0.8, z, 0.4, 255, 240, 80);
  }
}
