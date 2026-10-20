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
    if (this.spec["roadWidth"] != nil) {
      this.roadWidth = this.spec["roadWidth"];
    }
    this.segmentLength = 6.0;
    this.drawDistance = 48; // 288m visible road ahead (high fidelity, zero gaps)

    // Curve scaling for optimal visual perspective
    this.curveScale = 1.0;

    // Precompute 128 2D minimap radar points around closed F1 circuit loop
    this.mapPoints = [];
    let numMapPoints = 128;
    let lapLen = this.spec["length"];
    let minX = 999999.0; let maxX = -999999.0;
    let minZ = 999999.0; let maxZ = -999999.0;

    for (let i = 0; i < numMapPoints; i += 1) {
      let s = (i / numMapPoints) * lapLen;
      let p = const.getTrackWorldPoint(this.trackId, s);
      if (p[0] < minX) minX = p[0];
      if (p[0] > maxX) maxX = p[0];
      if (p[1] < minZ) minZ = p[1];
      if (p[1] > maxZ) maxZ = p[1];
      this.mapPoints.push([p[0], p[1]]);
    }
    this.mapBounds = [minX, maxX, minZ, maxZ];

    // Checkpoint gate
    this.gateZ = -220.0;
    this.gateInterval = 600.0;

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
    for (let i = 0; i < 4; i += 1) {
      let hz = -60.0 - i * 70.0;
      let side = 1.0;
      if (i % 2 == 1) side = -1.0;
      let hx = side * mu.randFloat(2.4, 3.6);
      let kind = rand(2); // 0 = cone/boulder, 1 = box/barrel
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
      this.coreX = mu.randFloat(-3.2, 3.2);
      this.coreCollected = false;
    }

    // Scroll hazards
    for (let i = 0; i < len(this.hazards); i += 1) {
      let h = this.hazards[i];
      h["z"] = h["z"] + scrollSpeed * dt;
      if (h["z"] > 14.0) {
        h["z"] = h["z"] - 280.0;
        let side = 1.0;
        if (rand(2) == 0) side = -1.0;
        h["x"] = side * mu.randFloat(2.4, 3.6);
        h["hit"] = false;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // GEOMETRIC CLOSED CIRCUIT CURVES (RELATIVE HEADING WITH SOFT SATURATION)
  // ---------------------------------------------------------------------------
  getCurveOffset(z, distance) {
    let h0 = const.getTrackHeading(this.trackId, distance);
    let h1 = const.getTrackHeading(this.trackId, distance - z);
    let diff = h1 - h0;
    while (diff > 3.14159265) {
      diff = diff - 6.2831853;
    }
    while (diff < -3.14159265) {
      diff = diff + 6.2831853;
    }

    let d = -z;
    let raw = d * math.sin(diff * 0.5) * 0.75;
    let lat = raw / (1.0 + math.abs(raw) / 16.0);
    return lat * this.curveScale;
  }

  // ---------------------------------------------------------------------------
  // PROCEDURAL 3D ELEVATION (HILLS & VALLEYS) PER TRACK
  // ---------------------------------------------------------------------------
  getYOffset(z, distance) {
    let d = -z;
    let base = 0.0;
    let ahead = 0.0;
    if (this.trackId == 0) {
      // Suzuka: S-Curves climb, Dunlop downhill sweep, Spoon undulations
      let k = 0.005;
      let b_p = distance * k;
      let s_p = (distance + d) * k;
      base = (math.sin(b_p) + math.sin(b_p * 2.0) * 0.5) * 2.2;
      ahead = (math.sin(s_p) + math.sin(s_p * 2.0) * 0.5) * 2.2;
    } else if (this.trackId == 1) {
      // Monaco: Beau Rivage steep uphill climb, Casino crest, harbor drop
      let k = 0.007;
      let b_p = distance * k;
      let s_p = (distance + d) * k;
      base = (math.sin(b_p) + math.cos(b_p * 0.6) * 0.6) * 2.8;
      ahead = (math.sin(s_p) + math.cos(s_p * 0.6) * 0.6) * 2.8;
    } else if (this.trackId == 2) {
      // Spa-Francorchamps: Eau Rouge 17% steep climb, Pouhon & Blanchimont roller-coaster
      let k = 0.004;
      let b_p = distance * k;
      let s_p = (distance + d) * k;
      base = math.sin(b_p) * 3.6 + math.cos(b_p * 2.0) * 1.8;
      ahead = math.sin(s_p) * 3.6 + math.cos(s_p * 2.0) * 1.8;
    } else {
      // Monza: Royal parkland high-speed straight undulations
      let k = 0.005;
      let b_p = distance * k;
      let s_p = (distance + d) * k;
      base = math.sin(b_p) * 1.6;
      ahead = math.sin(s_p) * 1.6;
    }
    let rawY = ahead - base;
    return rawY / (1.0 + math.abs(rawY) / 10.0);
  }

  getCurvature(z, distance) {
    let s0 = distance - z;
    let s1 = s0 + 16.0;
    let h0 = const.getTrackHeading(this.trackId, s0);
    let h1 = const.getTrackHeading(this.trackId, s1);
    let diff = h1 - h0;
    while (diff > 3.14159265) {
      diff = diff - 6.2831853;
    }
    while (diff < -3.14159265) {
      diff = diff + 6.2831853;
    }
    return diff / 16.0;
  }

  // Check if position is inside an enclosed tunnel section
  isInTunnel(dist) {
    let lapLen = this.spec["length"];
    let prog = dist - math.floor(dist / lapLen) * lapLen;
    if (this.trackId == 0) {
      // Suzuka Circuit: Bridge Crossover Underpass
      if (prog > 2420.0 and prog < 2580.0) {
        return true;
      }
    }
    if (this.trackId == 1) {
      // Circuit de Monaco: World-famous Monte Carlo Harbor Tunnel
      if (prog > 620.0 and prog < 980.0) {
        return true;
      }
    }
    if (this.trackId == 2) {
      // Spa-Francorchamps: Stavelot Forest Covered Trench
      if (prog > 4100.0 and prog < 4450.0) {
        return true;
      }
    }
    if (this.trackId == 3) {
      // Monza: Royal Park Serraglio Railway Underpass
      if (prog > 2550.0 and prog < 2750.0) {
        return true;
      }
    }
    return false;
  }

  draw(scroll, distance, t, assets) {
    let rcA = this.spec["railColorA"];
    let rcB = this.spec["railColorB"];
    let roadCol = this.spec["roadColor"];
    let halfW = this.roadWidth * 0.5;

    // -------------------------------------------------------------------------
    // 0. Distant Atmospheric Backdrop per Track
    // -------------------------------------------------------------------------
    if (this.trackId == 0) {
      // Shibuya Tokyo Midnight Metropolis Skyline (9 towers across horizon)
      for (let k = -4; k <= 4; k += 1) {
        let bldX = k * 36.0;
        let bldH = 34.0 + math.abs(k * 7) + ((k * 3) % 11) * 2.0;
        gui.drawCube3D(bldX, bldH * 0.5 - 4.0, -260.0, 18.0, bldH, 18.0, 12, 16, 28);
        gui.drawCube3D(bldX, bldH * 0.5 - 4.0, -259.0, 14.0, bldH * 0.85, 0.2, 0, 160 + math.abs(k * 10), 220);
        gui.drawCylinder3D(bldX, bldH - 4.0, -260.0, 0.1, 0.2, 10.0, 4, 180, 190, 210);
        gui.drawSphere3D(bldX, bldH + 1.5, -260.0, 0.7, 255, 50, 60);
      }
    } else if (this.trackId == 1) {
      // Sunset Horizon: Giant glowing Synthwave Sunset Sun & Pacific Ocean
      gui.drawSphere3D(55.0, 20.0, -250.0, 36.0, 255, 110, 40);
      gui.drawSphere3D(55.0, 20.0, -249.0, 22.0, 255, 210, 80);
      // Ocean water plane extending across horizon
      gui.drawPlane3D(65.0, -1.2, -120.0, 200.0, 480.0, 24, 14, 46);
      for (let k = -3; k <= 3; k += 1) {
        let mX = k * 52.0 - 40.0;
        let mH = 22.0 + math.abs(k * 5);
        gui.drawCylinder3D(mX, mH * 0.5 - 6.0, -255.0, 0.1, 24.0, mH, 5, 48, 18, 42);
      }
    } else if (this.trackId == 2) {
      // Nebula Canyon: Titan Sandstone Mountain Massifs Backdrop
      for (let k = -4; k <= 4; k += 1) {
        let cX = k * 45.0;
        let cH = 36.0 + ((k * 5) % 13) * 3.0;
        gui.drawCylinder3D(cX, cH * 0.5 - 6.0, -255.0, 0.2, 22.0, cH, 6, 110, 40, 32);
        gui.drawSphere3D(cX, cH - 4.0, -254.0, 2.2, 220, 50, 255);
      }
    } else {
      // Hyperion Speedway: Earth globe & Orbital Station Trusses
      gui.drawSphere3D(-75.0, -32.0, -260.0, 55.0, 20, 80, 210);
      gui.drawSphere3D(-73.0, -30.0, -258.0, 42.0, 40, 140, 240);
      gui.drawCube3D(0.0, 32.0, -240.0, 260.0, 2.5, 3.0, 40, 60, 90);
      gui.drawCylinderWires3D(0.0, 32.0, -240.0, 26.0, 26.0, 2.0, 16, 0, 240, 255);
    }

    // -------------------------------------------------------------------------
    // 1. Render Road Segments & Elevation
    // -------------------------------------------------------------------------
    for (let i = 0; i < this.drawDistance; i += 1) {
      let segZ = 12.0 - i * this.segmentLength + scroll;
      let segDist = distance - segZ;
      let curve = this.getCurveOffset(segZ, distance);
      let hill = this.getYOffset(segZ, distance);
      let nextCurve = this.getCurveOffset(segZ - this.segmentLength, distance);
      let nextHill = this.getYOffset(segZ - this.segmentLength, distance);

      let midCurve = (curve + nextCurve) * 0.5;
      let midHill = (hill + nextHill) * 0.5;

      // Road Surface Plane
      gui.drawPlane3D(midCurve, midHill, segZ, this.roadWidth, this.segmentLength + 0.35,
                      roadCol[0], roadCol[1], roadCol[2]);

      // Racing Curbs / Rumble Strips (Left & Right Shoulders)
      let curbPulse = (math.floor(segDist / 6.0)) % 2;
      let curbCol = [255, 255, 255];
      if (curbPulse == 0) {
        if (this.trackId == 0) curbCol = [0, 240, 255];
        else if (this.trackId == 1) curbCol = [245, 50, 60];
        else if (this.trackId == 2) curbCol = [255, 200, 30];
        else curbCol = [0, 255, 170];
      }
      gui.drawCube3D(curve - halfW + 0.35, hill + 0.08, segZ, 0.70, 0.08, this.segmentLength,
                     curbCol[0], curbCol[1], curbCol[2]);
      gui.drawCube3D(curve + halfW - 0.35, hill + 0.08, segZ, 0.70, 0.08, this.segmentLength,
                     curbCol[0], curbCol[1], curbCol[2]);

      // Neon Guardrails (Left & Right)
      let railPulse = 200 + math.floor(math.sin(t * 3.0 + i * 0.4) * 55.0);

      // Left Rail
      gui.drawCube3D(curve - halfW, hill + 0.35, segZ, 0.25, 0.70, this.segmentLength,
                     rcA[0], rcA[1], rcA[2]);
      // Right Rail
      gui.drawCube3D(curve + halfW, hill + 0.35, segZ, 0.25, 0.70, this.segmentLength,
                     rcB[0], rcB[1], rcB[2]);

      // Lane Divider Dashes
      for (let lane = -1; lane <= 1; lane += 2) {
        let laneX = curve + lane * (this.roadWidth * 0.25);
        gui.drawCube3D(laneX, hill + 0.03, segZ, 0.12, 0.04, 5.0, 220, 235, 255);
      }

      // Enclosed Tunnel Roof & Arches (Shibuya & Canyon)
      let inTunnel = this.isInTunnel(segDist);
      if (inTunnel) {
        let tunnelH = 8.0;
        // Concrete Tunnel Ceiling
        gui.drawPlane3D(midCurve, midHill + tunnelH, segZ, this.roadWidth + 3.0, this.segmentLength + 0.2, 18, 22, 32);
        // Left tunnel wall
        gui.drawCube3D(curve - halfW - 0.5, midHill + tunnelH * 0.5, segZ, 0.4, tunnelH, this.segmentLength, 25, 30, 42);
        // Right tunnel wall
        gui.drawCube3D(curve + halfW + 0.5, midHill + tunnelH * 0.5, segZ, 0.4, tunnelH, this.segmentLength, 25, 30, 42);
        // Overhead amber tunnel light strips
        gui.drawSphere3D(curve, midHill + tunnelH - 0.3, segZ, 0.35, 255, 200, 50);
      }

      // Boost Pads on Monza GP (DRS Straightaway Boosters)
      if (this.trackId == 3) {
        let segPadProg = segDist - math.floor(segDist / 600.0) * 600.0;
        if (segPadProg >= 280.0 and segPadProg <= 300.0) {
          let padGlow = 200 + math.floor(math.sin(t * 8.0) * 55.0);
          gui.drawPlane3D(midCurve, midHill + 0.04, segZ, this.roadWidth * 0.45, this.segmentLength + 0.1, 0, padGlow, 180);
          gui.drawCube3D(midCurve, midHill + 0.06, segZ, this.roadWidth * 0.35, 0.05, 1.2, 240, 255, 255);
        }
      }

      // Overhead Streetlights / Energy Arches every 5 segments (every 30m when not in tunnel)
      if (!inTunnel and i % 5 == 0) {
        let archH = 7.5;
        // Left post
        gui.drawCube3D(curve - halfW - 0.5, midHill + archH * 0.5, segZ, 0.25, archH, 0.25, 30, 36, 52);
        // Right post
        gui.drawCube3D(curve + halfW + 0.5, midHill + archH * 0.5, segZ, 0.25, archH, 0.25, 30, 36, 52);
        // Crossbar
        gui.drawCube3D(curve, midHill + archH, segZ, this.roadWidth + 1.2, 0.25, 0.25, rcA[0], rcA[1], rcA[2]);
        // Glowing lights
        gui.drawSphere3D(curve - 3.0, midHill + archH - 0.2, segZ, 0.35, 255, 240, 180);
        gui.drawSphere3D(curve + 3.0, midHill + archH - 0.2, segZ, 0.35, 255, 240, 180);
      }

      // Illuminated Directional Chevron Warning Signs along Outside Rail of Sharp Corners
      let segCurv = this.getCurvature(segZ, distance);
      if (math.abs(segCurv) > 0.018 and i % 2 == 0) {
        let signSide = 1.0;
        if (segCurv > 0.0) {
          signSide = -1.0; // Turning right -> outside barrier is on the left
        }
        let signX = curve + signSide * (halfW + 0.65);
        let signH = 2.4;
        gui.drawCube3D(signX, midHill + signH * 0.5, segZ, 0.2, signH, 3.2, 20, 24, 34);
        gui.drawCube3D(signX, midHill + signH * 0.5, segZ, 0.22, signH - 0.2, 3.0, 255, 40, 50);
        let chvPulse = 200 + math.floor(math.sin(t * 12.0 + i) * 55.0);
        gui.drawSphere3D(signX, midHill + signH * 0.5, segZ, 0.45, 255, chvPulse, 30);
      }
    }

    // -------------------------------------------------------------------------
    // 2. Render Roadside Scenery (Unique per Track, Anchored to World Stations)
    // -------------------------------------------------------------------------
    let propInterval = 28.0;
    let baseStation = math.floor(distance / propInterval);
    for (let k = 0; k < 12; k += 1) {
      let stationIdx = baseStation + k;
      let worldDist = stationIdx * propInterval;
      let propZ = -(worldDist - distance);
      if (propZ > -280.0 and propZ < 10.0) {
        let curve = this.getCurveOffset(propZ, distance);
        let hill = this.getYOffset(propZ, distance);
        let i = stationIdx;

        if (this.trackId == 0) {
          // Neo Shibuya Skyscrapers & Cyber Billboards
          let bldScaleLeft = 3.0 + ((i * 7) % 3);
          let bldScaleRight = 3.5 + ((i * 11) % 4);
          let variantLeft = i % 4;
          let variantRight = (i + 2) % 4;

          assets.playBuildingModel(variantLeft, curve - 15.0, hill, propZ, bldScaleLeft, 90.0);
          assets.playBuildingModel(variantRight, curve + 15.0, hill, propZ - 12.0, bldScaleRight, -90.0);

          // Neon Billboards
          if (i % 2 == 0) {
            let glowPulse = 180 + math.floor(math.sin(t * 4.0 + i) * 70.0);
            gui.drawCube3D(curve - 11.5, hill + 5.0, propZ, 0.2, 3.2, 6.0, 255, 40, glowPulse);
            gui.drawCube3D(curve + 11.5, hill + 5.0, propZ - 8.0, 0.2, 3.2, 6.0, 40, glowPulse, 255);
          }
        } else if (this.trackId == 1) {
          // Sunset Horizon (Pacific Beach Dunes, Palm Trees, Moored Yachts)
          // Left: Sandy beach dunes & 3D Palm Trees
          gui.drawPlane3D(curve - 28.0, hill - 0.3, propZ, 32.0, 30.0, 180, 130, 85);

          // Palm Tree (Trunk + Fronds)
          gui.drawCylinder3D(curve - 10.5, hill + 3.2, propZ + 4.0, 0.22, 0.42, 6.5, 6, 95, 55, 32);
          gui.drawSphere3D(curve - 10.5, hill + 6.6, propZ + 4.0, 2.2, 35, 130, 65);
          gui.drawSphere3D(curve - 10.5, hill + 6.2, propZ + 4.0, 1.4, 60, 170, 80);

          // Second Palm Tree
          gui.drawCylinder3D(curve - 12.5, hill + 3.0, propZ - 6.0, 0.20, 0.38, 6.0, 6, 95, 55, 32);
          gui.drawSphere3D(curve - 12.5, hill + 6.2, propZ - 6.0, 1.9, 35, 130, 65);

          // Right: Ocean Water & Moored Yachts
          if (i % 3 == 0) {
            let yachtX = curve + 32.0 + ((i * 5) % 18);
            // Boat hull
            gui.drawCube3D(yachtX, hill - 0.6, propZ, 3.5, 1.2, 8.5, 240, 245, 255);
            // Sail mast
            gui.drawCylinder3D(yachtX, hill + 3.5, propZ, 0.1, 0.12, 7.5, 4, 180, 160, 140);
            // White triangular sail
            gui.drawCube3D(yachtX, hill + 3.5, propZ + 1.2, 0.08, 5.0, 2.6, 255, 250, 240);
          }

          // Coastal Highway Sign
          if (i % 4 == 1) {
            gui.drawCube3D(curve, hill + 6.8, propZ, 8.5, 1.6, 0.3, 20, 85, 55);
          }
        } else if (this.trackId == 2) {
          // Nebula Canyon (Towering Sandstone Spire Cliffs, Purple Crystals & Rings)
          let rockH = 14.0 + ((i * 9) % 16);
          // Left Canyon Rock Wall
          gui.drawCylinder3D(curve - 15.5, hill + rockH * 0.5, propZ, 4.5, 7.5, rockH, 8, 140, 50, 40);
          // Right Canyon Rock Wall
          gui.drawCylinder3D(curve + 15.5, hill + rockH * 0.5, propZ - 10.0, 4.5, 7.5, rockH, 8, 140, 50, 40);

          // Glowing Purple & Amber Alien Crystals
          let crystalGlow = 180 + math.floor(math.sin(t * 5.0 + i) * 60.0);
          gui.drawCylinder3D(curve - 15.5, hill + rockH + 2.0, propZ, 0.05, 1.5, 4.2, 5, 200, 50, crystalGlow);
          gui.drawCylinder3D(curve + 15.5, hill + rockH + 2.0, propZ - 10.0, 0.05, 1.5, 4.2, 5, 255, crystalGlow, 50);

          // Giant Overhead Floating Energy Rings
          if (i % 3 == 1) {
            gui.drawCylinderWires3D(curve, hill + 6.5, propZ, 6.0, 6.0, 1.2, 16, 255, 150, 30);
          }
        } else {
          // Hyperion Speedway (Orbital Solar Panels, Satellites & Space Arrays)
          // Giant Blue Solar Panels on left and right
          let panelW = 9.0;
          gui.drawCube3D(curve - 18.0, hill + 5.0, propZ, panelW, 0.25, 6.0, 30, 80, 200);
          gui.drawCube3D(curve + 18.0, hill + 5.0, propZ - 8.0, panelW, 0.25, 6.0, 30, 80, 200);

          // Pylon mast
          gui.drawCube3D(curve - 18.0, hill + 2.5, propZ, 0.4, 5.0, 0.4, 90, 100, 120);
          gui.drawCube3D(curve + 18.0, hill + 2.5, propZ - 8.0, 0.4, 5.0, 0.4, 90, 100, 120);

          // Floating navigation beacon rings
          if (i % 2 == 1) {
            gui.drawCylinderWires3D(curve, hill + 6.2, propZ, 7.5, 7.5, 0.8, 14, 0, 255, 180);
          }
        }
      }
    }

    // -------------------------------------------------------------------------
    // 3. Render Hazards (Cones, Boulders & Barrels)
    // -------------------------------------------------------------------------
    for (let i = 0; i < len(this.hazards); i += 1) {
      let h = this.hazards[i];
      if (h["z"] > -180.0 and h["z"] < 12.0 and !h["hit"]) {
        let curve = this.getCurveOffset(h["z"], distance);
        let hill = this.getYOffset(h["z"], distance);
        let hx = curve + h["x"];
        if (h["kind"] == 0) {
          if (this.trackId == 2) {
            // Boulder in Canyon
            gui.drawSphere3D(hx, hill + 0.6, h["z"], 0.7, 130, 50, 40);
          } else {
            assets.playHazardCone(hx, hill, h["z"], 1.1);
          }
        } else {
          assets.playHazardBox(hx, hill, h["z"], 1.0);
        }
      }
    }

    // -------------------------------------------------------------------------
    // 4. Render Checkpoint Gate
    // -------------------------------------------------------------------------
    if (this.gateZ > -240.0 and this.gateZ < 12.0) {
      let gCurve = this.getCurveOffset(this.gateZ, distance);
      let gHill = this.getYOffset(this.gateZ, distance);
      this.drawCheckpointGate(gCurve, gHill, this.gateZ, t);
    }

    // -------------------------------------------------------------------------
    // 5. Render Collectible Energy Core
    // -------------------------------------------------------------------------
    if (!this.coreCollected and this.coreZ > -180.0 and this.coreZ < 10.0) {
      let cCurve = this.getCurveOffset(this.coreZ, distance);
      let cHill = this.getYOffset(this.coreZ, distance);
      let coreRealX = cCurve + this.coreX;
      let bobY = cHill + 1.1 + math.sin(t * 6.0) * 0.25;
      let pulseR = 0.45 + math.sin(t * 8.0) * 0.08;

      // Outer glow core
      gui.drawSphere3D(coreRealX, bobY, this.coreZ, pulseR, 0, 255, 230);
      // Inner bright nucleus
      gui.drawSphere3D(coreRealX, bobY, this.coreZ, 0.22, 240, 255, 255);
      // Orbiting energy ring
      gui.drawCylinderWires3D(coreRealX, bobY, this.coreZ, 0.65, 0.65, 0.08, 10, 255, 80, 220);
    }
  }

  drawCheckpointGate(x, y, z, t) {
    let gateW = this.roadWidth + 2.5;
    let gateH = 8.5;
    let glow = 200 + math.floor(math.sin(t * 5.0) * 55.0);

    // Left Column
    gui.drawCube3D(x - gateW * 0.5, y + gateH * 0.5, z, 0.8, gateH, 0.8, 40, 50, 75);
    gui.drawCube3D(x - gateW * 0.5, y + gateH * 0.5, z, 0.25, gateH - 0.5, 0.85, 0, glow, 255);

    // Right Column
    gui.drawCube3D(x + gateW * 0.5, y + gateH * 0.5, z, 0.8, gateH, 0.8, 40, 50, 75);
    gui.drawCube3D(x + gateW * 0.5, y + gateH * 0.5, z, 0.25, gateH - 0.5, 0.85, 0, glow, 255);

    // Overhead Header Bar
    gui.drawCube3D(x, y + gateH - 0.2, z, gateW, 0.8, 0.8, 30, 40, 60);
    gui.drawCube3D(x, y + gateH - 0.2, z, gateW - 0.6, 0.35, 0.85, 255, glow, 80);

    // Neon Gate Arch Lights
    gui.drawSphere3D(x - 3.5, y + gateH - 0.8, z, 0.4, 255, 240, 80);
    gui.drawSphere3D(x, y + gateH - 0.8, z, 0.45, 0, 255, 240);
    gui.drawSphere3D(x + 3.5, y + gateH - 0.8, z, 0.4, 255, 240, 80);
  }
}
