// TURBO CIRCUIT: OVERDRIVE — 3D Track & Environment
use "pb_gui" as gui;
use "std.math" as math;
use "math_util" as mu;
use "constants" as const;

export class Track {
  init(trackId) {
    this.trackId = trackId;
    this.spec = const.getTrackSpec(trackId);
    this.roadWidth = 16.8;
    if (this.spec["roadWidth"] != nil) {
      this.roadWidth = this.spec["roadWidth"];
    }
    this.curbWidth = 1.4;
    if (this.spec["curbWidth"] != nil) {
      this.curbWidth = this.spec["curbWidth"];
    }
    this.runoffWidth = 4.5;
    if (this.spec["runoffWidth"] != nil) {
      this.runoffWidth = this.spec["runoffWidth"];
    }
    this.segmentLength = 6.0;
    this.drawDistance = 52; // 312m visible Grand Prix road ahead (gapless 3D mesh)

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
  // ---------------------------------------------------------------------------
  // GEOMETRIC CLOSED CIRCUIT CURVES (RIGID BODY RELATIVE ROAD PROJECTION)
  // ---------------------------------------------------------------------------
  getCurveOffset(z, distance) {
    let d = -z;
    if (math.abs(d) < 0.001) return 0.0;

    let p_car = const.getTrackWorldPoint(this.trackId, distance);
    let p_ahead = const.getTrackWorldPoint(this.trackId, distance + d);
    let tan = const.getTrackTangent(this.trackId, distance);
    let mag = math.sqrt(tan[0] * tan[0] + tan[1] * tan[1]);
    if (mag < 0.001) return 0.0;
    let Tx = tan[0] / mag;
    let Tz = tan[1] / mag;

    let deltaX = p_ahead[0] - p_car[0];
    let deltaZ = p_ahead[1] - p_car[1];

    // Rigid body lateral offset in camera space (+X is right, -X is left):
    let rawLat = -deltaX * Tz + deltaZ * Tx;

    // Smooth algebraic saturation so distant segments (>150m) stay within the 3D frustum
    let sFactor = rawLat / 70.0;
    return (rawLat / math.sqrt(1.0 + sFactor * sFactor)) * this.curveScale;
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
    let s = distance - z;
    return const.getTrackCurvature(this.trackId, s);
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
    let curbW = this.curbWidth;
    let runoffW = this.runoffWidth;
    let outerW = halfW + curbW + runoffW;

    let curbCol = this.spec["curbColor"];
    if (curbCol == nil) curbCol = [255, 40, 50];
    let gravelCol = this.spec["gravelColor"];
    if (gravelCol == nil) gravelCol = [135, 105, 75];
    let grassCol = this.spec["grassColor"];
    if (grassCol == nil) grassCol = [20, 40, 22];
    let barCol = this.spec["barrierColor"];
    if (barCol == nil) barCol = [200, 205, 215];
    let barTopCol = this.spec["barrierTopColor"];
    if (barTopCol == nil) barTopCol = [255, 30, 40];

    // -------------------------------------------------------------------------
    // 0. Authentic Grand Prix Atmospheric Backdrop per Circuit
    // -------------------------------------------------------------------------
    if (this.trackId == 0) {
      // SUZUKA INTERNATIONAL: Mie Mountain Ridge + Giant Suzuka Ferris Wheel
      for (let k = -6; k <= 6; k += 1) {
        let mX = k * 44.0;
        let mH = 38.0 + math.abs(k * 7) + ((k * 4) % 11) * 3.0;
        gui.drawCylinder3D(mX, mH * 0.5 - 6.0, -280.0, 0.1, 28.0, mH, 5, 20, 32, 54);
      }
      // Suzuka Circuit Landmark: Giant Illuminated Ferris Wheel
      let fwX = 75.0;
      let fwY = 36.0;
      let fwZ = -240.0;
      let fwRadius = 22.0;
      gui.drawCylinderWires3D(fwX, fwY, fwZ, fwRadius, fwRadius, 2.0, 18, 0, 220, 255);
      gui.drawSphere3D(fwX, fwY, fwZ, 2.8, 255, 220, 60);
      for (let sp = 0; sp < 8; sp += 1) {
        let spAng = t * 0.35 + sp * (3.14159265 / 4.0);
        let gX = fwX + math.cos(spAng) * fwRadius;
        let gY = fwY + math.sin(spAng) * fwRadius;
        gui.drawSphere3D(gX, gY, fwZ, 1.4, 255, 50, 80);
      }
      // Grandstands along Pit Straight
      for (let st = -3; st <= 3; st += 1) {
        gui.drawCube3D(st * 32.0, 10.0, -220.0, 24.0, 14.0, 10.0, 32, 40, 58);
        gui.drawCube3D(st * 32.0, 18.0, -220.0, 25.0, 1.2, 12.0, 255, 40, 60);
      }
    } else if (this.trackId == 1) {
      // MONACO GP: French Riviera Cliffside Terraces, Villas & Port Hercule
      for (let k = -5; k <= 5; k += 1) {
        let cX = k * 48.0 - 20.0;
        let cH = 44.0 + math.abs(k * 6);
        gui.drawCylinder3D(cX, cH * 0.5 - 6.0, -280.0, 0.2, 32.0, cH, 6, 60, 28, 48);
      }
      // Mediterranean Sea water plane
      gui.drawPlane3D(60.0, -1.8, -140.0, 260.0, 480.0, 20, 28, 62);
      // Monte Carlo Villas with glowing warm windows
      for (let v = -4; v <= 4; v += 1) {
        let vX = v * 38.0 - 50.0;
        let vH = 26.0 + ((v * 5) % 9) * 3.0;
        gui.drawCube3D(vX, vH * 0.5 - 2.0, -250.0, 18.0, vH, 16.0, 95, 48, 56);
        gui.drawCube3D(vX, vH * 0.5 - 2.0, -249.0, 14.0, vH * 0.7, 0.2, 255, 210, 120);
      }
      // Port Hercule Luxury Yachts
      for (let yk = 0; yk < 4; yk += 1) {
        let yX = 40.0 + yk * 30.0;
        let yZ = -190.0 - yk * 22.0;
        gui.drawCube3D(yX, 1.5, yZ, 12.0, 4.0, 26.0, 230, 235, 245);
        gui.drawCylinder3D(yX, 8.0, yZ, 0.2, 0.3, 10.0, 4, 180, 190, 205);
        gui.drawSphere3D(yX, 13.5, yZ, 0.6, 255, 220, 50);
      }
    } else if (this.trackId == 2) {
      // SPA-FRANCORCHAMPS: Ardennes Forest Highlands & Raidillon Grandstand
      for (let k = -6; k <= 6; k += 1) {
        let aX = k * 45.0;
        let aH = 42.0 + math.abs(k * 8);
        gui.drawCylinder3D(aX, aH * 0.5 - 6.0, -280.0, 0.1, 30.0, aH, 6, 22, 42, 32);
      }
      // Famous Red Raidillon Crest Grandstand perched atop Eau Rouge
      gui.drawCube3D(65.0, 24.0, -230.0, 45.0, 22.0, 20.0, 40, 48, 56);
      gui.drawCube3D(65.0, 36.0, -230.0, 48.0, 2.0, 22.0, 225, 30, 40);
      // Ardennes pine tree clusters on the horizon
      for (let pt = -5; pt <= 5; pt += 1) {
        let pX = pt * 38.0;
        gui.drawCylinder3D(pX, 12.0, -250.0, 0.2, 10.0, 24.0, 5, 16, 44, 22);
      }
    } else {
      // MONZA GP: Royal Parkland Canopy, Historic Banked Oval Ruins & Italian GP Gantries
      for (let k = -6; k <= 6; k += 1) {
        let pX = k * 46.0;
        let pH = 50.0 + math.abs(k * 7);
        gui.drawCylinder3D(pX, pH * 0.5 - 6.0, -285.0, 0.1, 26.0, pH, 5, 28, 48, 72);
        gui.drawSphere3D(pX, pH - 6.0, -284.0, 4.0, 220, 235, 255);
      }
      // Historic Monza Concrete Banking Oval Ruins looming in background
      gui.drawCylinderWires3D(0.0, 16.0, -230.0, 75.0, 75.0, 12.0, 24, 70, 85, 95);
      // Italian GP Grandstands
      gui.drawCube3D(-55.0, 14.0, -210.0, 48.0, 16.0, 16.0, 35, 42, 50);
      gui.drawCube3D(-55.0, 23.0, -210.0, 50.0, 1.5, 18.0, 0, 200, 110);
      gui.drawCube3D(55.0, 14.0, -210.0, 48.0, 16.0, 16.0, 35, 42, 50);
      gui.drawCube3D(55.0, 23.0, -210.0, 50.0, 1.5, 18.0, 235, 40, 50);
    }

    // -------------------------------------------------------------------------
    // 1. Render Seamless Continuous 3D Quad Track Mesh (Behind & Ahead)
    // -------------------------------------------------------------------------
    for (let i = -16; i < 48; i += 1) {
      // Fixed depth rings in camera space: zero mesh popping, zero wrap jumps!
      let segZ1 = -i * this.segmentLength;
      let segZ2 = segZ1 - this.segmentLength;
      let segDist = distance - segZ1;

      let curve1 = this.getCurveOffset(segZ1, distance);
      let hill1 = this.getYOffset(segZ1, distance);
      let curve2 = this.getCurveOffset(segZ2, distance);
      let hill2 = this.getYOffset(segZ2, distance);

      // Coordinates at Near Edge (segZ1) - wide 140m terrain apron hugging road elevation
      let x_AL1 = curve1 - outerW - 140.0;
      let x_OL1 = curve1 - outerW;
      let x_CL1 = curve1 - halfW - curbW;
      let x_RL1 = curve1 - halfW;
      let x_RR1 = curve1 + halfW;
      let x_CR1 = curve1 + halfW + curbW;
      let x_OR1 = curve1 + outerW;
      let x_AR1 = curve1 + outerW + 140.0;

      // Coordinates at Far Edge (segZ2)
      let x_AL2 = curve2 - outerW - 140.0;
      let x_OL2 = curve2 - outerW;
      let x_CL2 = curve2 - halfW - curbW;
      let x_RL2 = curve2 - halfW;
      let x_RR2 = curve2 + halfW;
      let x_CR2 = curve2 + halfW + curbW;
      let x_OR2 = curve2 + outerW;
      let x_AR2 = curve2 + outerW + 140.0;

      // A. Outer Terrain Aprons (Left & Right, hugging road elevation)
      let grR = grassCol[0]; let grG = grassCol[1]; let grB = grassCol[2];
      let apronStripe = (math.floor((segDist + 600000.0) / 12.0)) % 2;
      if (apronStripe == 1) {
        grR = math.floor(grR * 0.90); grG = math.floor(grG * 0.90); grB = math.floor(grB * 0.90);
      }
      gui.drawQuad3D(x_AL1, hill1 - 0.12, segZ1,  x_OL1, hill1 - 0.05, segZ1,
                     x_OL2, hill2 - 0.05, segZ2,  x_AL2, hill2 - 0.12, segZ2,
                     grR, grG, grB);
      gui.drawQuad3D(x_OR1, hill1 - 0.05, segZ1,  x_AR1, hill1 - 0.12, segZ1,
                     x_AR2, hill2 - 0.12, segZ2,  x_OR2, hill2 - 0.05, segZ2,
                     grR, grG, grB);

      // B. Authentic Grand Prix Runoff Zones:
      // Straightaways feature clean green turf / paved shoulders.
      // Corner braking & runoff zones feature real gravel traps on the outside of bends!
      let segCurv = this.getCurvature(segZ1, distance);
      let isCorner = math.abs(segCurv) >= 0.006;
      let leftIsGravel = false;
      let rightIsGravel = false;
      if (isCorner) {
        if (segCurv > 0.0) {
          leftIsGravel = true;  // Turning right -> outside runoff is on the left
        } else {
          rightIsGravel = true; // Turning left -> outside runoff is on the right
        }
      }

      // Left Runoff Quad
      let lR = grassCol[0]; let lG = grassCol[1]; let lB = grassCol[2];
      if (leftIsGravel) {
        lR = gravelCol[0]; lG = gravelCol[1]; lB = gravelCol[2];
      }
      let runoffStripe = (math.floor((segDist + 600000.0) / 6.0)) % 2;
      if (runoffStripe == 1) {
        lR = math.floor(lR * 0.92); lG = math.floor(lG * 0.92); lB = math.floor(lB * 0.92);
      }
      gui.drawQuad3D(x_OL1, hill1 - 0.04, segZ1,  x_CL1, hill1 - 0.02, segZ1,
                     x_CL2, hill2 - 0.02, segZ2,  x_OL2, hill2 - 0.04, segZ2,
                     lR, lG, lB);

      // Right Runoff Quad
      let rRCol = grassCol[0]; let rGCol = grassCol[1]; let rBCol = grassCol[2];
      if (rightIsGravel) {
        rRCol = gravelCol[0]; rGCol = gravelCol[1]; rBCol = gravelCol[2];
      }
      if (runoffStripe == 1) {
        rRCol = math.floor(rRCol * 0.92); rGCol = math.floor(rGCol * 0.92); rBCol = math.floor(rBCol * 0.92);
      }
      gui.drawQuad3D(x_CR1, hill1 - 0.02, segZ1,  x_OR1, hill1 - 0.04, segZ1,
                     x_OR2, hill2 - 0.04, segZ2,  x_CR2, hill2 - 0.02, segZ2,
                     rRCol, rGCol, rBCol);

      // C. Rumble Strip Curbs (Left & Right)
      let curbPulse = (math.floor((segDist + 600000.0) / 4.0)) % 2;
      let cR = 245; let cG = 245; let cB = 250;
      if (curbPulse == 0) {
        cR = curbCol[0]; cG = curbCol[1]; cB = curbCol[2];
      }
      gui.drawQuad3D(x_CL1, hill1 + 0.04, segZ1,  x_RL1, hill1 + 0.04, segZ1,
                     x_RL2, hill2 + 0.04, segZ2,  x_CL2, hill2 + 0.04, segZ2,
                     cR, cG, cB);
      gui.drawQuad3D(x_RR1, hill1 + 0.04, segZ1,  x_CR1, hill1 + 0.04, segZ1,
                     x_CR2, hill2 + 0.04, segZ2,  x_RR2, hill2 + 0.04, segZ2,
                     cR, cG, cB);

      // D. Main Tarmac Racing Road Surface
      let rdR = roadCol[0]; let rdG = roadCol[1]; let rdB = roadCol[2];
      let tarmacStripe = (math.floor((segDist + 600000.0) / 6.0)) % 2;
      if (tarmacStripe == 1) {
        rdR = rdR + 4; rdG = rdG + 4; rdB = rdB + 6;
      }
      gui.drawQuad3D(x_RL1, hill1, segZ1,  x_RR1, hill1, segZ1,
                     x_RR2, hill2, segZ2,  x_RL2, hill2, segZ2,
                     rdR, rdG, rdB);

      // Subtle rubbered-in racing grooves give every circuit the same grounded
      // motorsport material language without hiding its own scenery or palette.
      let grooveR = math.floor(rdR * 0.68);
      let grooveG = math.floor(rdG * 0.68);
      let grooveB = math.floor(rdB * 0.68);
      gui.drawQuad3D(curve1 - 3.1, hill1 + 0.012, segZ1,  curve1 - 2.35, hill1 + 0.012, segZ1,
                     curve2 - 2.35, hill2 + 0.012, segZ2, curve2 - 3.1, hill2 + 0.012, segZ2,
                     grooveR, grooveG, grooveB);
      gui.drawQuad3D(curve1 + 2.35, hill1 + 0.012, segZ1, curve1 + 3.1, hill1 + 0.012, segZ1,
                     curve2 + 3.1, hill2 + 0.012, segZ2, curve2 + 2.35, hill2 + 0.012, segZ2,
                     grooveR, grooveG, grooveB);

      // A shared, readable chequered line anchors laps visually on all four tracks.
      let lapProg = segDist - math.floor(segDist / this.spec["length"]) * this.spec["length"];
      if (lapProg >= 0.0 and lapProg < this.segmentLength) {
        for (let sq = 0; sq < 8; sq += 1) {
          let leftA = curve1 - halfW + sq * (this.roadWidth / 8.0);
          let rightA = leftA + this.roadWidth / 8.0;
          let leftB = curve2 - halfW + sq * (this.roadWidth / 8.0);
          let rightB = leftB + this.roadWidth / 8.0;
          let check = 245;
          if (sq % 2 == 1) check = 30;
          gui.drawQuad3D(leftA, hill1 + 0.025, segZ1, rightA, hill1 + 0.025, segZ1,
                         rightB, hill2 + 0.025, segZ2, leftB, hill2 + 0.025, segZ2,
                         check, check, check);
        }
      }

      // E. Centerline Painted Dashes
      if ((math.floor((segDist + 600000.0) / 6.0)) % 2 == 0) {
        gui.drawQuad3D(curve1 - 0.12, hill1 + 0.02, segZ1,  curve1 + 0.12, hill1 + 0.02, segZ1,
                       curve2 + 0.12, hill2 + 0.02, segZ2,  curve2 - 0.12, hill2 + 0.02, segZ2,
                       240, 245, 255);
      }

      // F. Perimeter Concrete & Armco Barriers (Vertical Quads)
      let barrierH = 1.35;
      gui.drawQuad3D(x_OL1, hill1 - 0.04, segZ1,  x_OL1, hill1 + barrierH, segZ1,
                     x_OL2, hill2 + barrierH, segZ2,  x_OL2, hill2 - 0.04, segZ2,
                     barCol[0], barCol[1], barCol[2]);
      gui.drawQuad3D(x_OR1, hill1 - 0.04, segZ1,  x_OR1, hill1 + barrierH, segZ1,
                     x_OR2, hill2 + barrierH, segZ2,  x_OR2, hill2 - 0.04, segZ2,
                     barCol[0], barCol[1], barCol[2]);

      // Glowing Barrier Top Rail Cap
      gui.drawQuad3D(x_OL1 - 0.15, hill1 + barrierH, segZ1,  x_OL1 + 0.15, hill1 + barrierH, segZ1,
                     x_OL2 + 0.15, hill2 + barrierH, segZ2,  x_OL2 - 0.15, hill2 + barrierH, segZ2,
                     barTopCol[0], barTopCol[1], barTopCol[2]);
      gui.drawQuad3D(x_OR1 - 0.15, hill1 + barrierH, segZ1,  x_OR1 + 0.15, hill1 + barrierH, segZ1,
                     x_OR2 + 0.15, hill2 + barrierH, segZ2,  x_OR2 - 0.15, hill2 + barrierH, segZ2,
                     barTopCol[0], barTopCol[1], barTopCol[2]);

      // G. Directional Chevrons on Sharp Corners along outside barrier
      let chvStripe = (math.floor((segDist + 600000.0) / 12.0)) % 2;
      if (math.abs(segCurv) > 0.016 and chvStripe == 0) {
        let chvSide = x_OR1;
        let chvSide2 = x_OR2;
        if (segCurv > 0.0) {
          chvSide = x_OL1;
          chvSide2 = x_OL2;
        }
        let chvPulse = 200 + math.floor(math.sin(t * 14.0 + (segDist * 0.2)) * 55.0);
        gui.drawQuad3D(chvSide, hill1 + 0.3, segZ1,  chvSide, hill1 + barrierH + 0.6, segZ1,
                       chvSide2, hill2 + barrierH + 0.6, segZ2,  chvSide2, hill2 + 0.3, segZ2,
                       255, chvPulse, 30);
      }

      // H. Enclosed Tunnel Roof & Arches
      let inTunnel = this.isInTunnel(segDist);
      if (inTunnel) {
        let tunH = 7.5;
        // Concrete Ceiling Quad
        gui.drawQuad3D(x_OL1, hill1 + tunH, segZ1,  x_OR1, hill1 + tunH, segZ1,
                       x_OR2, hill2 + tunH, segZ2,  x_OL2, hill2 + tunH, segZ2,
                       20, 24, 34);
        // Concrete Wall Quads
        gui.drawQuad3D(x_OL1, hill1, segZ1,  x_OL1, hill1 + tunH, segZ1,
                       x_OL2, hill2 + tunH, segZ2,  x_OL2, hill2, segZ2,
                       28, 34, 46);
        gui.drawQuad3D(x_OR1, hill1, segZ1,  x_OR1, hill1 + tunH, segZ1,
                       x_OR2, hill2 + tunH, segZ2,  x_OR2, hill2, segZ2,
                       28, 34, 46);
        // Overhead Tunnel Sodium Lighting
        gui.drawSphere3D(curve1, hill1 + tunH - 0.3, segZ1, 0.45, 255, 190, 40);
      }

      // I. Boost Pads on Monza GP (DRS Straightaway Boosters)
      if (this.trackId == 3) {
        let segPadProg = segDist - math.floor(segDist / 600.0) * 600.0;
        if (segPadProg >= 280.0 and segPadProg <= 300.0) {
          let padGlow = 200 + math.floor(math.sin(t * 8.0) * 55.0);
          gui.drawQuad3D(curve1 - 3.0, hill1 + 0.03, segZ1,  curve1 + 3.0, hill1 + 0.03, segZ1,
                         curve2 + 3.0, hill2 + 0.03, segZ2,  curve2 - 3.0, hill2 + 0.03, segZ2,
                         0, padGlow, 180);
        }
      }

      // J. Overhead Streetlights & Gantry Arches anchored to continuous track distance
      let gantryProg = segDist - math.floor(segDist / 36.0) * 36.0;
      if (!inTunnel and gantryProg >= 0.0 and gantryProg < this.segmentLength) {
        let archH = 8.0;
        gui.drawCube3D(x_OL1, hill1 + archH * 0.5, segZ1, 0.35, archH, 0.35, 30, 36, 50);
        gui.drawCube3D(x_OR1, hill1 + archH * 0.5, segZ1, 0.35, archH, 0.35, 30, 36, 50);
        gui.drawCube3D(curve1, hill1 + archH, segZ1, outerW * 2.0 + 1.2, 0.3, 0.3, barTopCol[0], barTopCol[1], barTopCol[2]);
        gui.drawSphere3D(curve1 - 4.0, hill1 + archH - 0.2, segZ1, 0.35, 255, 240, 200);
        gui.drawSphere3D(curve1 + 4.0, hill1 + archH - 0.2, segZ1, 0.35, 255, 240, 200);
      }
    }

    // -------------------------------------------------------------------------
    // 2. Render Roadside Scenery (Unique per Track, Anchored to World Stations)
    // -------------------------------------------------------------------------
    let propInterval = 28.0;
    let baseStation = math.floor(distance / propInterval);
    let propSide = outerW + 4.5;

    for (let k = -4; k < 12; k += 1) {
      let stationIdx = baseStation + k;
      let worldDist = stationIdx * propInterval;
      let propZ = -(worldDist - distance);
      if (propZ > -280.0 and propZ < 90.0) {
        let curve = this.getCurveOffset(propZ, distance);
        let hill = this.getYOffset(propZ, distance);
        let i = stationIdx;

        if (this.trackId == 0) {
          // Suzuka: Trackside Pit Buildings & Japanese Grandstand Towers
          let bldScaleLeft = 3.2 + ((i * 7) % 3);
          let bldScaleRight = 3.6 + ((i * 11) % 4);
          let variantLeft = i % 4;
          let variantRight = (i + 2) % 4;

          assets.playBuildingModel(variantLeft, curve - (propSide + 6.0), hill, propZ, bldScaleLeft, 90.0);
          assets.playBuildingModel(variantRight, curve + (propSide + 6.0), hill, propZ - 12.0, bldScaleRight, -90.0);

          // Neon Sponsor Billboards
          if (i % 2 == 0) {
            let glowPulse = 180 + math.floor(math.sin(t * 4.0 + i) * 70.0);
            gui.drawCube3D(curve - (propSide + 1.2), hill + 5.0, propZ, 0.2, 3.2, 6.0, 255, 40, glowPulse);
            gui.drawCube3D(curve + (propSide + 1.2), hill + 5.0, propZ - 8.0, 0.2, 3.2, 6.0, 40, glowPulse, 255);
          }
        } else if (this.trackId == 1) {
          // Monaco: Mediterranean Palm Trees & Quayside Villas
          gui.drawPlane3D(curve - (propSide + 16.0), hill - 0.3, propZ, 32.0, 30.0, 180, 130, 85);

          // Palm Trees
          gui.drawCylinder3D(curve - (propSide + 2.0), hill + 3.2, propZ + 4.0, 0.22, 0.42, 6.5, 6, 95, 55, 32);
          gui.drawSphere3D(curve - (propSide + 2.0), hill + 6.6, propZ + 4.0, 2.2, 35, 130, 65);
          gui.drawSphere3D(curve - (propSide + 2.0), hill + 6.2, propZ + 4.0, 1.4, 60, 170, 80);

          // Moored Luxury Yachts
          if (i % 3 == 0) {
            let yachtX = curve + propSide + 12.0 + ((i * 5) % 14);
            gui.drawCube3D(yachtX, hill - 0.6, propZ, 3.5, 1.2, 8.5, 240, 245, 255);
            gui.drawCylinder3D(yachtX, hill + 3.5, propZ, 0.1, 0.12, 7.5, 4, 180, 160, 140);
            gui.drawCube3D(yachtX, hill + 3.5, propZ + 1.2, 0.08, 5.0, 2.6, 255, 250, 240);
          }
        } else if (this.trackId == 2) {
          // Spa: Ardennes Pine Trees & Rock Massifs
          let rockH = 14.0 + ((i * 9) % 16);
          gui.drawCylinder3D(curve - (propSide + 3.0), hill + rockH * 0.5, propZ, 4.5, 7.5, rockH, 8, 140, 50, 40);
          gui.drawCylinder3D(curve + (propSide + 3.0), hill + rockH * 0.5, propZ - 10.0, 4.5, 7.5, rockH, 8, 140, 50, 40);
          gui.drawCylinder3D(curve - (propSide + 2.0), hill + 4.0, propZ + 5.0, 0.2, 3.5, 9.0, 6, 18, 50, 24);
          gui.drawCylinder3D(curve + (propSide + 2.0), hill + 4.0, propZ - 4.0, 0.2, 3.5, 9.0, 6, 18, 50, 24);
        } else {
          // Monza: Royal Park Ancient Trees & Energy Arrays
          let panelW = 9.0;
          gui.drawCube3D(curve - (propSide + 4.0), hill + 5.0, propZ, panelW, 0.25, 6.0, 30, 80, 200);
          gui.drawCube3D(curve + (propSide + 4.0), hill + 5.0, propZ - 8.0, panelW, 0.25, 6.0, 30, 80, 200);
          gui.drawCube3D(curve - (propSide + 4.0), hill + 2.5, propZ, 0.4, 5.0, 0.4, 90, 100, 120);
          gui.drawCube3D(curve + (propSide + 4.0), hill + 2.5, propZ - 8.0, 0.4, 5.0, 0.4, 90, 100, 120);
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
