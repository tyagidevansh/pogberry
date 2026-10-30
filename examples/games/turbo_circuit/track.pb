// TURBO CIRCUIT: OVERDRIVE — True World-Space 3D Circuit Engine
use "pb_gui" as gui;
use "constants" as const;
use "f1_data" as f1;
use "std.math" as math;
use "math_util" as mu;

export class Track {
  init(trackId) {
    this.trackId = trackId;
    this.spec = const.getTrackSpec(trackId);
    this.roadWidth = 28.0;
    if (this.spec["roadWidth"] != nil) this.roadWidth = this.spec["roadWidth"];
    this.curbWidth = 2.4;
    if (this.spec["curbWidth"] != nil) this.curbWidth = this.spec["curbWidth"];
    this.runoffWidth = 8.5;
    if (this.spec["runoffWidth"] != nil) this.runoffWidth = this.spec["runoffWidth"];
    this.segmentLength = 6.0;
    this.curveScale = 1.0;
    this.hazards = [];

    // Precompute 2D minimap radar points
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

    // Build true 3D world geometry stations and scenery props
    this.stations = [];
    this.props = [];
    this.buildWorldTrack();
  }

  // ---------------------------------------------------------------------------
  // SMOOTH CLOSED-LOOP PERIODIC 3D ELEVATION PROFILE
  // ---------------------------------------------------------------------------
  getElevationAt(s) {
    let lapLen = this.spec["length"];
    if (this.trackId == 0) {
      // Suzuka: S-Curves climb, Dunlop sweep, Spoon rollercoaster
      let w1 = (6.2831853 * 7.0) / lapLen;
      let base = (math.sin(s * w1) + math.sin(s * w1 * 2.0) * 0.5 + 1.5) * 1.8;

      // Suzuka Figure-8 Overpass Bridge (West Straight crossing cleanly over Degner underpass at s=7460)
      let bridgeDist = s - 7460.0;
      if (math.abs(bridgeDist) < 650.0) {
        let u = bridgeDist / 650.0;
        let cosBell = (1.0 + math.cos(u * 3.14159265)) * 0.5;
        base = base + cosBell * 7.5;
      }
      return base;
    } else if (this.trackId == 1) {
      // Monaco: Beau Rivage uphill, Casino crest, harbor sea-level drop
      let w1 = (6.2831853 * 6.0) / lapLen;
      return (math.sin(s * w1) + math.cos(s * w1 * 0.6) * 0.6 + 1.6) * 2.2;
    } else if (this.trackId == 2) {
      // Spa-Francorchamps: Eau Rouge 17% steep climb, Pouhon & Blanchimont
      let w1 = (6.2831853 * 7.0) / lapLen;
      return (math.sin(s * w1) * 3.2 + math.cos(s * w1 * 2.0) * 1.6 + 4.8);
    } else {
      // Monza: Royal parkland high-speed straight undulations
      let w1 = (6.2831853 * 8.0) / lapLen;
      return (math.sin(s * w1) + 1.2) * 1.5;
    }
  }

  // ---------------------------------------------------------------------------
  // PRECOMPUTE WORLD-SPACE TRACK STATIONS & AUTHENTIC F1 SCENERY
  // ---------------------------------------------------------------------------
  buildWorldTrack() {
    let lapLen = this.spec["length"];
    let step = this.segmentLength;
    let numStations = math.floor(lapLen / step);
    let halfW = this.roadWidth * 0.5;
    let curbW = this.curbWidth;
    let runoffW = this.runoffWidth;
    let corridor = halfW + curbW + runoffW;

    this.stations = [];
    for (let i = 0; i < numStations; i += 1) {
      let s = i * step;
      let p = const.getTrackWorldPoint(this.trackId, s);
      let tan = const.getTrackTangent(this.trackId, s);
      let mag = math.sqrt(tan[0] * tan[0] + tan[1] * tan[1]);
      if (mag < 0.0001) mag = 0.0001;
      let tx = tan[0] / mag;
      let tz = tan[1] / mag;
      let nx = -tz;
      let nz = tx;
      let y = this.getElevationAt(s);

      // Precalculate static world-space cross-sections
      let rl_x = p[0] - halfW * nx; let rl_z = p[1] - halfW * nz;
      let rr_x = p[0] + halfW * nx; let rr_z = p[1] + halfW * nz;
      let cl_x = p[0] - (halfW + curbW) * nx; let cl_z = p[1] - (halfW + curbW) * nz;
      let cr_x = p[0] + (halfW + curbW) * nx; let cr_z = p[1] + (halfW + curbW) * nz;
      let ol_x = p[0] - corridor * nx; let ol_z = p[1] - corridor * nz;
      let or_x = p[0] + corridor * nx; let or_z = p[1] + corridor * nz;

      this.stations.push({
        "s": s,
        "x": p[0], "y": y, "z": p[1],
        "tx": tx, "tz": tz, "nx": nx, "nz": nz,
        "heading": math.atan2(tx, tz),
        "curv": const.getTrackCurvature(this.trackId, s),
        "rl_x": rl_x, "rl_z": rl_z,
        "rr_x": rr_x, "rr_z": rr_z,
        "cl_x": cl_x, "cl_z": cl_z,
        "cr_x": cr_x, "cr_z": cr_z,
        "ol_x": ol_x, "ol_z": ol_z,
        "or_x": or_x, "or_z": or_z
      });
    }

    // Formula 1 Racing Team Livery Palettes (Authentic Grand Prix Paddock)
    let teamLiveries = [
      [165, 38, 45],   // Ferrari Scarlet Red
      [35, 52, 115],   // Red Bull Racing Navy
      [125, 155, 160], // Mercedes-AMG Silver-Teal
      [185, 95, 28],   // McLaren Papaya Orange
      [25, 85, 55],    // Aston Martin British Racing Green
      [30, 80, 160],   // Alpine Blue
      [25, 60, 140],   // Williams Cobalt Blue
      [130, 145, 175], // Racing Bulls Slate-White
      [40, 150, 60],   // Kick Sauber Fluo Green
      [115, 120, 130]  // Haas Charcoal
    ];

    // Candidate Scenery Props Generation
    let rawProps = [];
    let propInterval = 16.0;
    let numProps = math.floor(lapLen / propInterval);
    let propDist = corridor + 5.0;

    for (let k = 0; k < numProps; k += 1) {
      let sStation = k * propInterval;
      let stIdx = math.floor(sStation / step) % numStations;
      let st = this.stations[stIdx];
      let pAngle = st["heading"] * (180.0 / 3.14159265);
      let lx = st["x"] - propDist * st["nx"]; let lz = st["z"] - propDist * st["nz"];
      let rx = st["x"] + propDist * st["nx"]; let rz = st["z"] + propDist * st["nz"];
      let py = st["y"];
      let teamCol = teamLiveries[k % 10];

      if (this.trackId == 0) {
        // SUZUKA GP (Japanese Grand Prix)
        let isPaddock = (sStation < 420.0 or sStation > lapLen - 260.0);
        if (isPaddock) {
          // Team Pit Garages on inside of pit straight
          if (k % 2 == 0) {
            rawProps.push({ "kind": "pitsGarage", "x": rx + 5.0 * st["nx"], "y": py, "z": rz + 5.0 * st["nz"], "scale": 11.5, "rot": pAngle - 90.0, "r": teamCol[0], "g": teamCol[1], "b": teamCol[2], "radius": 7.5 });
            rawProps.push({ "kind": "paddockHauler", "x": rx + 17.0 * st["nx"], "y": py, "z": rz + 17.0 * st["nx"], "scale": 1.4, "rot": pAngle - 90.0, "r": teamCol[0], "g": teamCol[1], "b": teamCol[2], "radius": 5.0 });
          } else {
            rawProps.push({ "kind": "tentLong", "x": rx + 14.0 * st["nx"], "y": py, "z": rz + 14.0 * st["nz"], "scale": 11.0, "rot": pAngle - 90.0, "r": 135, "g": 145, "b": 160, "radius": 6.5 });
          }
          // Main Grandstand on spectator side (set back nicely with open spacing)
          if (k % 5 == 0) {
            rawProps.push({ "kind": "grandstandCovered", "x": lx - 18.0 * st["nx"], "y": py, "z": lz - 18.0 * st["nz"], "scale": 11.5, "rot": pAngle + 90.0, "r": 150, "g": 160, "b": 175, "radius": 9.5 });
            rawProps.push({ "kind": "flagCheckers", "x": lx - 2.5 * st["nx"], "y": py, "z": lz - 2.5 * st["nz"], "scale": 7.5, "rot": pAngle, "radius": 1.5 });
          } else {
            rawProps.push({ "kind": "tree", "var": k % 2, "x": lx - 8.0 * st["nx"], "y": py, "z": lz - 8.0 * st["nz"], "scale": 11.0, "rot": pAngle, "radius": 4.0 });
          }
        } else {
          // Trackside Japanese Pines along S-Curves, Dunlop, Spoon
          let treeScaleL = 10.5 + ((k * 3) % 4);
          let treeScaleR = 10.0 + ((k * 5) % 4);
          rawProps.push({ "kind": "tree", "var": k % 2, "x": lx - 7.5 * st["nx"], "y": py, "z": lz - 7.5 * st["nz"], "scale": treeScaleL, "rot": pAngle, "radius": 4.0 });
          rawProps.push({ "kind": "tree", "var": (k + 1) % 2, "x": rx + 7.5 * st["nx"], "y": py, "z": rz + 7.5 * st["nz"], "scale": treeScaleR, "rot": pAngle, "radius": 4.0 });

          if (k % 8 == 0) {
            rawProps.push({ "kind": "grandstandAwning", "x": lx - 18.0 * st["nx"], "y": py, "z": lz - 18.0 * st["nz"], "scale": 11.5, "rot": pAngle + 90.0, "r": 150, "g": 160, "b": 175, "radius": 9.5 });
          } else if (k % 7 == 0) {
            rawProps.push({ "kind": "billboard", "x": rx + 5.5 * st["nx"], "y": py, "z": rz + 5.5 * st["nz"], "scale": 11.5, "rot": pAngle - 90.0, "radius": 3.5 });
          } else if (k % 9 == 0) {
            rawProps.push({ "kind": "floodlight", "x": lx - 4.5 * st["nx"], "y": py, "z": lz - 4.5 * st["nz"], "scale": 13.5, "rot": pAngle + 90.0, "radius": 2.5 });
          }
        }
      } else if (this.trackId == 1) {
        // MONACO GP (Circuit de Monaco / Monte Carlo)
        // Mediterranean Palm Trees
        rawProps.push({ "kind": "tree", "var": 1, "x": lx - 5.5 * st["nx"], "y": py, "z": lz - 5.5 * st["nz"], "scale": 8.5, "rot": pAngle, "radius": 3.0 });

        // Luxury Riviera hillside villas on spectator side
        if (k % 4 == 0) {
          rawProps.push({ "kind": "rivieraVilla", "x": lx - 20.0 * st["nx"], "y": py, "z": lz - 20.0 * st["nz"], "scale": 1.0, "rot": pAngle + 90.0, "radius": 9.0 });
        } else if (k % 6 == 2) {
          rawProps.push({ "kind": "grandstandCovered", "x": lx - 16.0 * st["nx"], "y": py, "z": lz - 16.0 * st["nz"], "scale": 11.0, "rot": pAngle + 90.0, "r": 255, "g": 255, "b": 255, "radius": 8.5 });
        }
        // Superyachts moored along the harbor quayside
        if (sStation > 1400.0 and sStation < 2800.0 and k % 3 == 0) {
          rawProps.push({ "kind": "yacht", "x": rx + 15.0 * st["nx"], "y": py, "z": rz + 15.0 * st["nz"], "scale": 1.0, "rot": pAngle, "radius": 6.5 });
        }
      } else if (this.trackId == 2) {
        // SPA-FRANCORCHAMPS (Belgian Grand Prix)
        // Dense Ardennes Pine Forest
        rawProps.push({ "kind": "tree", "var": 0, "x": lx - 8.0 * st["nx"], "y": py, "z": lz - 8.0 * st["nz"], "scale": 13.0, "rot": pAngle, "radius": 4.5 });
        rawProps.push({ "kind": "tree", "var": 1, "x": rx + 8.0 * st["nx"], "y": py, "z": rz + 8.0 * st["nz"], "scale": 11.5, "rot": pAngle, "radius": 4.5 });

        if (k % 8 == 0) {
          rawProps.push({ "kind": "grandstandCovered", "x": rx + 18.0 * st["nx"], "y": py, "z": rz + 18.0 * st["nz"], "scale": 11.5, "rot": pAngle - 90.0, "r": 255, "g": 255, "b": 255, "radius": 9.5 });
        } else if (k % 7 == 0) {
          rawProps.push({ "kind": "billboard", "x": lx - 5.5 * st["nx"], "y": py, "z": lz - 5.5 * st["nz"], "scale": 12.0, "rot": pAngle + 90.0, "radius": 3.5 });
        }
      } else {
        // MONZA GP (Italian Grand Prix / Temple of Speed)
        // Ancient Royal Parkland Oak Trees
        rawProps.push({ "kind": "tree", "var": 0, "x": lx - 7.5 * st["nx"], "y": py, "z": lz - 7.5 * st["nz"], "scale": 13.5, "rot": pAngle, "radius": 4.5 });
        rawProps.push({ "kind": "tree", "var": 1, "x": rx + 7.5 * st["nx"], "y": py, "z": rz + 7.5 * st["nz"], "scale": 12.0, "rot": pAngle, "radius": 4.5 });

        if (k % 8 == 0) {
          rawProps.push({ "kind": "grandstandCovered", "x": lx - 18.0 * st["nx"], "y": py, "z": lz - 18.0 * st["nz"], "scale": 11.5, "rot": pAngle + 90.0, "r": 255, "g": 255, "b": 255, "radius": 9.5 });
        } else if (k % 7 == 0) {
          rawProps.push({ "kind": "billboard", "x": rx + 5.5 * st["nx"], "y": py, "z": rz + 5.5 * st["nz"], "scale": 12.0, "rot": pAngle - 90.0, "radius": 3.5 });
        }
      }
    }

    // Brake Distance Countdown Boards (150m, 100m, 50m before major turns)
    for (let i = 0; i < numStations; i += 1) {
      let stCurv = math.abs(this.stations[i]["curv"]);
      if (stCurv > 0.016 and i > 25) {
        let prevCurv = math.abs(this.stations[(i - 5 + numStations) % numStations]["curv"]);
        if (stCurv > prevCurv + 0.005) {
          // Sharp turn entry detected: place 150m, 100m, 50m countdown boards
          let s150Idx = (i - 25 + numStations) % numStations;
          let s100Idx = (i - 17 + numStations) % numStations;
          let s50Idx = (i - 9 + numStations) % numStations;

          let st150 = this.stations[s150Idx];
          let st100 = this.stations[s100Idx];
          let st50 = this.stations[s50Idx];

          let bDist = corridor + 1.2;
          rawProps.push({ "kind": "brakeBoard", "val": 150, "x": st150["x"] - bDist * st150["nx"], "y": st150["y"], "z": st150["z"] - bDist * st150["nz"], "scale": 1.0, "rot": st150["heading"] * (180.0 / 3.14159265), "radius": 1.5 });
          rawProps.push({ "kind": "brakeBoard", "val": 100, "x": st100["x"] - bDist * st100["nx"], "y": st100["y"], "z": st100["z"] - bDist * st100["nz"], "scale": 1.0, "rot": st100["heading"] * (180.0 / 3.14159265), "radius": 1.5 });
          rawProps.push({ "kind": "brakeBoard", "val": 50, "x": st50["x"] - bDist * st50["nx"], "y": st50["y"], "z": st50["z"] - bDist * st50["nz"], "scale": 1.0, "rot": st50["heading"] * (180.0 / 3.14159265), "radius": 1.5 });
          i = i + 25; // Skip past this turn
        }
      }
    }

    // -------------------------------------------------------------------------
    // RIGOROUS ROAD CLEARANCE FILTER (Zero Model Clipping Guarantee)
    // -------------------------------------------------------------------------
    this.props = [];
    let numRaw = len(rawProps);
    for (let pIdx = 0; pIdx < numRaw; pIdx += 1) {
      let pr = rawProps[pIdx];
      let px = pr["x"];
      let pz = pr["z"];
      let propR = pr["radius"];
      if (propR == nil) propR = 4.0;

      let safeDist = corridor + propR + 3.0;
      let safeDistSq = safeDist * safeDist;
      let fits = true;

      // Check distance against every 2nd station centerline across the entire circuit
      for (let sIdx = 0; sIdx < numStations; sIdx += 2) {
        let st = this.stations[sIdx];
        let dx = px - st["x"];
        let dz = pz - st["z"];
        if (dx * dx + dz * dz < safeDistSq) {
          fits = false;
          break;
        }
      }

      if (fits) {
        this.props.push(pr);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // FAST SPLINE PROJECTION FROM WORLD POSITION (wx, wz) TO TRACK (s, offset)
  // ---------------------------------------------------------------------------
  projectWorldPoint(wx, wz, hintS) {
    let lapLen = this.spec["length"];
    let step = this.segmentLength;
    let numStations = len(this.stations);
    let hintIdx = math.floor(hintS / step) % numStations;
    while (hintIdx < 0) hintIdx = hintIdx + numStations;

    let searchRadius = 14; // High-speed sweeping search radius (84m lookahead)
    let bestDistSq = 99999999.0;
    let bestS = hintS;
    let bestOffset = 0.0;

    for (let d = -searchRadius; d <= searchRadius; d += 1) {
      let idx = (hintIdx + d) % numStations;
      while (idx < 0) idx = idx + numStations;
      let nextIdx = (idx + 1) % numStations;
      let st1 = this.stations[idx];
      let st2 = this.stations[nextIdx];

      let segX = st2["x"] - st1["x"];
      let segZ = st2["z"] - st1["z"];
      let segLenSq = segX * segX + segZ * segZ;
      if (segLenSq < 0.001) continue;

      let toPtX = wx - st1["x"];
      let toPtZ = wz - st1["z"];
      let u = (toPtX * segX + toPtZ * segZ) / segLenSq;
      if (u < 0.0) u = 0.0;
      if (u > 1.0) u = 1.0;

      let projX = st1["x"] + segX * u;
      let projZ = st1["z"] + segZ * u;
      let dx = wx - projX;
      let dz = wz - projZ;
      let dSq = dx * dx + dz * dz;

      if (dSq < bestDistSq) {
        bestDistSq = dSq;
        let segS = st1["s"] + u * step;
        if (segS >= lapLen) segS = segS - lapLen;
        bestS = segS;
        let nx = st1["nx"] * (1.0 - u) + st2["nx"] * u;
        let nz = st1["nz"] * (1.0 - u) + st2["nz"] * u;
        bestOffset = dx * nx + dz * nz;
      }
    }
    return [bestS, bestOffset, math.sqrt(bestDistSq)];
  }

  // ---------------------------------------------------------------------------
  // BACKWARD-COMPATIBLE QUERIES FOR AI, BOT RUNNERS & TESTS
  // ---------------------------------------------------------------------------
  getCurveOffset(z, distance) {
    let s0 = distance;
    let sAhead = distance - z;
    let p0 = const.getTrackWorldPoint(this.trackId, s0);
    let tan0 = const.getTrackTangent(this.trackId, s0);
    let mag = math.sqrt(tan0[0] * tan0[0] + tan0[1] * tan0[1]);
    if (mag < 0.0001) mag = 0.0001;
    let nx = -tan0[1] / mag;
    let nz = tan0[0] / mag;

    let pAhead = const.getTrackWorldPoint(this.trackId, sAhead);
    let dx = pAhead[0] - p0[0];
    let dz = pAhead[1] - p0[1];
    let rawLat = dx * nx + dz * nz;
    let sFactor = rawLat / 180.0;
    return (rawLat / math.sqrt(1.0 + sFactor * sFactor)) * this.curveScale;
  }

  getYOffset(z, distance) {
    let s0 = distance;
    let sAhead = distance - z;
    return this.getElevationAt(sAhead) - this.getElevationAt(s0);
  }

  getCurvature(z, distance) {
    return const.getTrackCurvature(this.trackId, distance - z);
  }

  isInTunnel(dist) {
    let lapLen = this.spec["length"];
    let prog = dist - math.floor(dist / lapLen) * lapLen;
    if (this.trackId == 0 and prog > 2420.0 and prog < 2580.0) return true;
    if (this.trackId == 1 and prog > 620.0 and prog < 980.0) return true;
    if (this.trackId == 2 and prog > 4100.0 and prog < 4450.0) return true;
    if (this.trackId == 3 and prog > 2550.0 and prog < 2750.0) return true;
    return false;
  }

  update(scrollSpeed, dt) {
    // Persistent World Engine: tracks are fully world-space static
  }

  // ---------------------------------------------------------------------------
  // 3D DISTANT HORIZON MOUNTAINS & ENVIRONMENT BACKDROP
  // ---------------------------------------------------------------------------
  drawDistantBackdrop(cX, cZ) {
    if (this.trackId == 0) {
      // SUZUKA GP: Majestic Mie Highlands Mountain Massifs & Suzuka Horizon
      let numMtn = 16;
      let mtnRadius = 1450.0;
      for (let m = 0; m < numMtn; m += 1) {
        let angle = (m / numMtn) * 6.2831853;
        let mx = cX + math.sin(angle) * mtnRadius;
        let mz = cZ + math.cos(angle) * mtnRadius;
        let mH = 140.0 + ((m * 37) % 65);
        let mW = 280.0 + ((m * 23) % 90);
        let mR = 24 + (m % 3) * 4;
        let mG = 40 + (m % 3) * 6;
        let mB = 68 + (m % 3) * 10;
        gui.drawCylinder3D(mx, mH * 0.5 - 2.0, mz, 1.0, mW * 0.5, mH, 5, mR, mG, mB);
      }
    } else if (this.trackId == 1) {
      // MONACO GP: French Riviera Mediterranean Sea & Alpine Coastal Cliffs
      gui.drawPlane3D(cX + 240.0, -1.8, cZ + 400.0, 1600.0, 1200.0, 22, 70, 125);
      let numMtn = 12;
      for (let m = 0; m < numMtn; m += 1) {
        let angle = 2.4 + (m / numMtn) * 2.8;
        let mx = cX + math.sin(angle) * 980.0;
        let mz = cZ + math.cos(angle) * 980.0;
        let mH = 160.0 + ((m * 29) % 70);
        let mW = 240.0 + ((m * 19) % 80);
        gui.drawCylinder3D(mx, mH * 0.5 - 2.0, mz, 2.0, mW * 0.5, mH, 5, 85, 45, 62);
      }
    } else if (this.trackId == 2) {
      // SPA GP: Dense Ardennes Pine Forest Hills & Rolling Valley Massifs
      let numMtn = 18;
      let mtnRadius = 1550.0;
      for (let m = 0; m < numMtn; m += 1) {
        let angle = (m / numMtn) * 6.2831853;
        let mx = cX + math.sin(angle) * mtnRadius;
        let mz = cZ + math.cos(angle) * mtnRadius;
        let mH = 150.0 + ((m * 31) % 60);
        let mW = 290.0 + ((m * 17) % 80);
        let mR = 18 + (m % 3) * 4;
        let mG = 42 + (m % 3) * 6;
        let mB = 34 + (m % 3) * 8;
        gui.drawCylinder3D(mx, mH * 0.5 - 2.0, mz, 1.0, mW * 0.5, mH, 5, mR, mG, mB);
      }
    } else {
      // MONZA GP: Royal Monza Parkland & Distant Italian Alpine Peaks
      let numMtn = 14;
      let mtnRadius = 1600.0;
      for (let m = 0; m < numMtn; m += 1) {
        let angle = (m / numMtn) * 6.2831853;
        let mx = cX + math.sin(angle) * mtnRadius;
        let mz = cZ + math.cos(angle) * mtnRadius;
        let mH = 165.0 + ((m * 41) % 80);
        let mW = 320.0 + ((m * 27) % 90);
        let mR = 30 + (m % 3) * 5;
        let mG = 42 + (m % 3) * 6;
        let mB = 72 + (m % 3) * 10;
        gui.drawCylinder3D(mx, mH * 0.5 - 2.0, mz, 1.0, mW * 0.5, mH, 5, mR, mG, mB);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 3D WORLD-SPACE TRACK & SCENERY RENDERING
  // ---------------------------------------------------------------------------
  draw(scroll, distance, t, assets, camObj) {
    let numStations = len(this.stations);
    if (numStations == 0) return;

    let roadCol = this.spec["roadColor"];
    let curbCol = this.spec["curbColor"];
    if (curbCol == nil) curbCol = [235, 40, 50];
    let gravelCol = this.spec["gravelColor"];
    if (gravelCol == nil) gravelCol = [155, 125, 90];
    let grassCol = this.spec["grassColor"];
    if (grassCol == nil) grassCol = [28, 62, 34];
    let barCol = this.spec["barrierColor"];
    if (barCol == nil) barCol = [68, 75, 88];
    let barTopCol = this.spec["barrierTopColor"];
    if (barTopCol == nil) barTopCol = [225, 40, 50];

    let cX = 0.0; let cY = 3.2; let cZ = 0.0;
    let fX = 0.0; let fZ = 1.0;
    if (camObj != nil) {
      cX = camObj.x; cY = camObj.y; cZ = camObj.z;
      let gX = camObj.targetX - cX; let gZ = camObj.targetZ - cZ;
      let gMag = math.sqrt(gX * gX + gZ * gZ);
      if (gMag > 0.001) { fX = gX / gMag; fZ = gZ / gMag; }
    }

    // 0. Distant 3D Mountains & Horizon Backdrop
    this.drawDistantBackdrop(cX, cZ);

    // 0b. Circuit Landmarks (e.g. Giant Suzuka Ferris Wheel)
    if (this.trackId == 0) {
      let fwX = 730.0; let fwY = 0.0; let fwZ = 60.0;
      let fDx = fwX - cX; let fDz = fwZ - cZ;
      if (fDx * fDx + fDz * fDz < 1500.0 * 1500.0) {
        // Dual A-Frame structural lattice towers
        gui.drawCylinder3D(fwX - 10.0, fwY + 36.0, fwZ - 4.0, 1.2, 3.2, 72.0, 6, 215, 220, 230);
        gui.drawCylinder3D(fwX + 10.0, fwY + 36.0, fwZ - 4.0, 1.2, 3.2, 72.0, 6, 215, 220, 230);
        gui.drawCylinder3D(fwX - 10.0, fwY + 36.0, fwZ + 4.0, 1.2, 3.2, 72.0, 6, 215, 220, 230);
        gui.drawCylinder3D(fwX + 10.0, fwY + 36.0, fwZ + 4.0, 1.2, 3.2, 72.0, 6, 215, 220, 230);
        // Central Axle Hub
        gui.drawCylinder3D(fwX, fwY + 68.0, fwZ, 3.5, 3.5, 9.0, 8, 190, 40, 50);
        // Giant Rotating Outer Rim with Spokes & Cabins
        let wheelAngle = t * 0.15;
        let rimR = 34.0;
        let numSpokes = 16;
        for (let sp = 0; sp < numSpokes; sp += 1) {
          let a = wheelAngle + (sp / numSpokes) * 6.2831853;
          let spX = fwX + math.sin(a) * rimR;
          let spY = fwY + 68.0 + math.cos(a) * rimR;
          gui.drawCylinder3D(fwX + math.sin(a) * (rimR * 0.5), fwY + 68.0 + math.cos(a) * (rimR * 0.5), fwZ, 0.25, 0.25, rimR, 4, 230, 235, 245);
          // Colorful passenger gondola
          let gCol = [255, 210, 30];
          if (sp % 4 == 1) gCol = [40, 140, 255];
          else if (sp % 4 == 2) gCol = [255, 60, 70];
          else if (sp % 4 == 3) gCol = [40, 200, 100];
          gui.drawCube3D(spX, spY, fwZ, 2.4, 2.8, 2.2, gCol[0], gCol[1], gCol[2]);
        }
      }
    }

    // 1. Render Visible Track Segments in 3D World Space (Full Circuit Coverage)
    let lapLen = this.spec["length"];
    for (let i = 0; i < numStations; i += 1) {
      let st1 = this.stations[i];
      let st2 = this.stations[(i + 1) % numStations];

      let dX = st1["x"] - cX;
      let dZ = st1["z"] - cZ;
      let distSq = dX * dX + dZ * dZ;
      if (distSq > 2400.0 * 2400.0) continue;

      let camDot = dX * fX + dZ * fZ;
      if (camDot < -30.0) continue; // Behind camera lens

      let y1 = st1["y"];
      let y2 = st2["y"];

      // A. Tarmac Surface (with rich speed-alternating asphalt)
      let rdR = roadCol[0]; let rdG = roadCol[1]; let rdB = roadCol[2];
      if (i % 2 == 1) { rdR = rdR + 5; rdG = rdG + 5; rdB = rdB + 7; }
      gui.drawQuad3D(st1["rl_x"], y1, st1["rl_z"], st1["rr_x"], y1, st1["rr_z"],
                     st2["rr_x"], y2, st2["rr_z"], st2["rl_x"], y2, st2["rl_z"],
                     rdR, rdG, rdB);

      // B. Rubberized Racing Grooves
      if (i % 2 == 0 and distSq < 300.0 * 300.0) {
        let grvR = math.floor(rdR * 0.70); let grvG = math.floor(rdG * 0.70); let grvB = math.floor(rdB * 0.70);
        let nx1 = st1["nx"]; let nz1 = st1["nz"];
        let nx2 = st2["nx"]; let nz2 = st2["nz"];
        gui.drawQuad3D(st1["x"] - 3.2 * nx1, y1 + 0.015, st1["z"] - 3.2 * nz1,
                       st1["x"] - 2.4 * nx1, y1 + 0.015, st1["z"] - 2.4 * nz1,
                       st2["x"] - 2.4 * nx2, y2 + 0.015, st2["z"] - 2.4 * nz2,
                       st2["x"] - 3.2 * nx2, y2 + 0.015, st2["z"] - 3.2 * nz2,
                       grvR, grvG, grvB);
        gui.drawQuad3D(st1["x"] + 2.4 * nx1, y1 + 0.015, st1["z"] + 2.4 * nz1,
                       st1["x"] + 3.2 * nx1, y1 + 0.015, st1["z"] + 3.2 * nz1,
                       st2["x"] + 3.2 * nx2, y2 + 0.015, st2["z"] + 3.2 * nz2,
                       st2["x"] + 2.4 * nx2, y2 + 0.015, st2["z"] + 2.4 * nz2,
                       grvR, grvG, grvB);
      }

      // C. Centerline Markings
      if (i % 2 == 0) {
        let nx1 = st1["nx"]; let nz1 = st1["nz"];
        let nx2 = st2["nx"]; let nz2 = st2["nz"];
        gui.drawQuad3D(st1["x"] - 0.22 * nx1, y1 + 0.02, st1["z"] - 0.22 * nz1,
                       st1["x"] + 0.22 * nx1, y1 + 0.02, st1["z"] + 0.22 * nz1,
                       st2["x"] + 0.22 * nx2, y2 + 0.02, st2["z"] + 0.22 * nz2,
                       st2["x"] - 0.22 * nx2, y2 + 0.02, st2["z"] - 0.22 * nz2,
                       245, 245, 250);
      }

      // D. Rumble Curbs (Alternating vibrant racing kerb colors with bevel height)
      let cR = 245; let cG = 245; let cB = 250;
      if (i % 2 == 0) { cR = curbCol[0]; cG = curbCol[1]; cB = curbCol[2]; }
      gui.drawQuad3D(st1["cl_x"], y1 + 0.05, st1["cl_z"], st1["rl_x"], y1 + 0.05, st1["rl_z"],
                     st2["rl_x"], y2 + 0.05, st2["rl_z"], st2["cl_x"], y2 + 0.05, st2["cl_z"],
                     cR, cG, cB);
      gui.drawQuad3D(st1["rr_x"], y1 + 0.05, st1["rr_z"], st1["cr_x"], y1 + 0.05, st1["cr_z"],
                     st2["cr_x"], y2 + 0.05, st2["cr_z"], st2["rr_x"], y2 + 0.05, st2["rr_z"],
                     cR, cG, cB);

      // E. Asphalt Runoff with High-Friction Painted Deceleration Stripes
      let isHighCurv = (math.abs(st1["curv"]) > 0.012);
      if (isHighCurv and i % 2 == 1) {
        // Modern F1 Painted Runoff Deceleration Band (Paul Ricard / Austin Blue)
        gui.drawQuad3D(st1["ol_x"], y1 - 0.02, st1["ol_z"], st1["cl_x"], y1 - 0.02, st1["cl_z"],
                       st2["cl_x"], y2 - 0.02, st2["cl_z"], st2["ol_x"], y2 - 0.02, st2["ol_z"],
                       28, 88, 205);
        gui.drawQuad3D(st1["cr_x"], y1 - 0.02, st1["cr_z"], st1["or_x"], y1 - 0.02, st1["or_z"],
                       st2["or_x"], y2 - 0.02, st2["or_z"], st2["cr_x"], y2 - 0.02, st2["cr_z"],
                       28, 88, 205);
      } else {
        gui.drawQuad3D(st1["ol_x"], y1 - 0.02, st1["ol_z"], st1["cl_x"], y1 - 0.02, st1["cl_z"],
                       st2["cl_x"], y2 - 0.02, st2["cl_z"], st2["ol_x"], y2 - 0.02, st2["ol_z"],
                       gravelCol[0], gravelCol[1], gravelCol[2]);
        gui.drawQuad3D(st1["cr_x"], y1 - 0.02, st1["cr_z"], st1["or_x"], y1 - 0.02, st1["or_z"],
                       st2["or_x"], y2 - 0.02, st2["or_z"], st2["cr_x"], y2 - 0.02, st2["cr_z"],
                       gravelCol[0], gravelCol[1], gravelCol[2]);
      }

      // E2. Natural Sloped Grass Embankment Skirts / Structural Overpass Bridge / Underpass Walls
      let sMid = st1["s"];
      let nx1 = st1["nx"]; let nz1 = st1["nz"];
      let nx2 = st2["nx"]; let nz2 = st2["nz"];
      let isSuzukaBridge = (this.trackId == 0 and sMid >= 7350.0 and sMid <= 7570.0);
      let isSuzukaUnderpass = (this.trackId == 0 and sMid >= 3650.0 and sMid <= 3770.0);

      if (isSuzukaBridge) {
        // A. Bridge Concrete Deck Fascia Sides (down 1.4m from bridge road)
        let deckD = 1.40;
        gui.drawQuad3D(st1["ol_x"], y1, st1["ol_z"], st1["ol_x"], y1 - deckD, st1["ol_z"],
                       st2["ol_x"], y2 - deckD, st2["ol_z"], st2["ol_x"], y2, st2["ol_z"],
                       52, 58, 70);
        gui.drawQuad3D(st1["or_x"], y1, st1["or_z"], st2["or_x"], y2, st2["or_z"],
                       st2["or_x"], y2 - deckD, st2["or_z"], st1["or_x"], y1 - deckD, st1["or_z"],
                       52, 58, 70);

        // B. Bridge Structural Underside (visible when looking up from the underpass below)
        gui.drawQuad3D(st1["ol_x"], y1 - deckD, st1["ol_z"], st1["or_x"], y1 - deckD, st1["or_z"],
                       st2["or_x"], y2 - deckD, st2["or_z"], st2["ol_x"], y2 - deckD, st2["ol_z"],
                       40, 45, 54);

        // C. Massive Concrete Support Abutment Pillars at bridge ends (stations 1236 and 1248)
        if (i == 1236 or i == 1248) {
          gui.drawCube3D(st1["ol_x"], y1 * 0.5, st1["ol_z"], 3.4, y1, 4.2, 58, 64, 76);
          gui.drawCube3D(st1["or_x"], y1 * 0.5, st1["or_z"], 3.4, y1, 4.2, 58, 64, 76);
        }
      } else if (isSuzukaUnderpass) {
        // Retaining cutting walls lining the underpass approach
        let retH = 2.8;
        gui.drawQuad3D(st1["ol_x"], y1, st1["ol_z"], st1["ol_x"], y1 + retH, st1["ol_z"],
                       st2["ol_x"], y2 + retH, st2["ol_z"], st2["ol_x"], y2, st2["ol_z"],
                       50, 56, 68);
        gui.drawQuad3D(st1["or_x"], y1, st1["or_z"], st1["or_x"], y1 + retH, st1["or_z"],
                       st2["or_x"], y2 + retH, st2["or_z"], st2["or_x"], y2, st2["or_z"],
                       50, 56, 68);
      } else {
        // Standard Natural Sloped Grass Embankment Skirts
        let embW = 14.0;
        gui.drawQuad3D(st1["ol_x"], y1 - 0.02, st1["ol_z"],
                       st1["ol_x"] - embW * nx1, -0.2, st1["ol_z"] - embW * nz1,
                       st2["ol_x"] - embW * nx2, -0.2, st2["ol_z"] - embW * nz2,
                       st2["ol_x"], y2 - 0.02, st2["ol_z"],
                       grassCol[0], grassCol[1], grassCol[2]);
        gui.drawQuad3D(st1["or_x"], y1 - 0.02, st1["or_z"],
                       st2["or_x"], y2 - 0.02, st2["or_z"],
                       st2["or_x"] + embW * nx2, -0.2, st2["or_z"] + embW * nz2,
                       st1["or_x"] + embW * nx1, -0.2, st1["or_z"] + embW * nz1,
                       grassCol[0], grassCol[1], grassCol[2]);
      }

      // F. Concrete Perimeter Barriers (Slate gray with alternating red/white safety top rails)
      let bH = 1.25;
      gui.drawQuad3D(st1["ol_x"], y1, st1["ol_z"], st1["ol_x"], y1 + bH, st1["ol_z"],
                     st2["ol_x"], y2 + bH, st2["ol_z"], st2["ol_x"], y2, st2["ol_z"],
                     barCol[0], barCol[1], barCol[2]);
      gui.drawQuad3D(st1["or_x"], y1, st1["or_z"], st1["or_x"], y1 + bH, st1["or_z"],
                     st2["or_x"], y2 + bH, st2["or_z"], st2["or_x"], y2, st2["or_z"],
                     barCol[0], barCol[1], barCol[2]);

      let topR = 230; let topG = 40; let topB = 50;
      if ((math.floor(i / 3)) % 2 == 1) { topR = 245; topG = 245; topB = 250; }
      gui.drawQuad3D(st1["ol_x"], y1 + bH, st1["ol_z"], st1["ol_x"] + 0.28 * nx1, y1 + bH, st1["ol_z"] + 0.28 * nz1,
                     st2["ol_x"] + 0.28 * nx2, y2 + bH, st2["ol_z"] + 0.28 * nz2, st2["ol_x"], y2 + bH, st2["ol_z"],
                     topR, topG, topB);
      gui.drawQuad3D(st1["or_x"] - 0.28 * nx1, y1 + bH, st1["or_z"] - 0.28 * nz1, st1["or_x"], y1 + bH, st1["or_z"],
                     st2["or_x"], y2 + bH, st2["or_z"], st2["or_x"] - 0.28 * nx2, y2 + bH, st2["or_z"] - 0.28 * nz2,
                     topR, topG, topB);

      // F2. Formula 1 Official Sponsor Hoardings Mounted on Perimeter Barriers
      if (i % 4 == 0) {
        let sponIdx = (math.floor(i / 4)) % 5;
        let sR = 12; let sG = 75; let sB = 42; // 0: Rolex Deep British Racing Green
        if (sponIdx == 1) { sR = 245; sG = 210; sB = 25; } // 1: Pirelli Yellow
        else if (sponIdx == 2) { sR = 0; sG = 165; sB = 215; } // 2: Aramco Cyan
        else if (sponIdx == 3) { sR = 215; sG = 30; sB = 40; } // 3: Mobil 1 / Shell Crimson
        else if (sponIdx == 4) { sR = 0; sG = 160; sB = 140; } // 4: Petronas Teal

        // Left Barrier Sponsor Board
        gui.drawQuad3D(st1["ol_x"] + 0.04 * nx1, y1 + 0.15, st1["ol_z"] + 0.04 * nz1,
                       st1["ol_x"] + 0.04 * nx1, y1 + 1.10, st1["ol_z"] + 0.04 * nz1,
                       st2["ol_x"] + 0.04 * nx2, y2 + 1.10, st2["ol_z"] + 0.04 * nz2,
                       st2["ol_x"] + 0.04 * nx2, y2 + 0.15, st2["ol_z"] + 0.04 * nz2,
                       sR, sG, sB);
        // Right Barrier Sponsor Board
        gui.drawQuad3D(st1["or_x"] - 0.04 * nx1, y1 + 0.15, st1["or_z"] - 0.04 * nz1,
                       st2["or_x"] - 0.04 * nx2, y2 + 0.15, st2["or_z"] - 0.04 * nz2,
                       st2["or_x"] - 0.04 * nx2, y2 + 1.10, st2["or_z"] - 0.04 * nz2,
                       st1["or_x"] - 0.04 * nx1, y1 + 1.10, st1["or_z"] - 0.04 * nz1,
                       sR, sG, sB);
      }

      // F3. Authentic Formula 1 Pit Wall & Team Timing Stands (Start/Finish Straight)
      let isPitStraight = (i < 55 or i > numStations - 35);
      if (isPitStraight) {
        // Pit Wall dividing track from pit lane
        let pwH = 1.15;
        let pNx1 = st1["nx"]; let pNz1 = st1["nz"];
        let pNx2 = st2["nx"]; let pNz2 = st2["nz"];
        gui.drawQuad3D(st1["rr_x"], y1, st1["rr_z"], st1["rr_x"], y1 + pwH, st1["rr_z"],
                       st2["rr_x"], y2 + pwH, st2["rr_z"], st2["rr_x"], y2, st2["rr_z"],
                       55, 62, 75);
        gui.drawQuad3D(st1["rr_x"], y1 + pwH, st1["rr_z"], st1["rr_x"] + 0.45 * pNx1, y1 + pwH, st1["rr_z"] + 0.45 * pNz1,
                       st2["rr_x"] + 0.45 * pNx2, y2 + pwH, st2["rr_z"] + 0.45 * pNz2, st2["rr_x"], y2 + pwH, st2["rr_z"],
                       225, 40, 50);

        // Team Pit Perch / Telemetry Timing Stand every 6 segments
        if (i % 6 == 0 and i > 5 and i < numStations - 10) {
          let standX = st1["rr_x"] + 1.8 * pNx1;
          let standZ = st1["rr_z"] + 1.8 * pNz1;
          gui.drawCube3D(standX, y1 + 1.3, standZ, 2.2, 1.8, 3.2, 45, 52, 65);
          gui.drawCube3D(standX, y1 + 2.3, standZ, 2.4, 0.25, 3.4, 180, 40, 48);
          // Glowing Telemetry Screens
          gui.drawCube3D(standX - 0.8 * pNx1, y1 + 1.5, standZ - 0.8 * pNz1, 0.2, 0.6, 2.4, 0, 230, 255);
        }
      }

      // G. Start / Finish Line Checkered Gantry Arch & 5 F1 Starting Lights at Station 0
      if (i == 0) {
        let archH = 8.5;
        gui.drawCube3D(st1["ol_x"], y1 + archH * 0.5, st1["ol_z"], 1.4, archH, 1.4, 35, 45, 65);
        gui.drawCube3D(st1["or_x"], y1 + archH * 0.5, st1["or_z"], 1.4, archH, 1.4, 35, 45, 65);
        gui.drawCube3D(st1["x"], y1 + archH, st1["z"], this.roadWidth + 4.0, 1.4, 1.8, 45, 55, 75);
        gui.drawCube3D(st1["x"], y1 + archH + 1.0, st1["z"], this.roadWidth * 0.5, 0.8, 0.3, 225, 35, 45);

        // 5 Official Formula 1 Starting Lights
        let lightSpacing = 2.4;
        for (let lt = -2; lt <= 2; lt += 1) {
          let lxPos = st1["x"] + lt * lightSpacing * nx1;
          let lzPos = st1["z"] + lt * lightSpacing * nz1;
          gui.drawCube3D(lxPos, y1 + archH - 1.2, lzPos, 0.6, 1.2, 0.3, 15, 18, 25);
          gui.drawSphere3D(lxPos, y1 + archH - 1.4, lzPos, 0.28, 255, 30, 35);
        }
      }
    }

    // 2. Render 3D Scenery Props in World Space
    if (assets != nil) {
      let numP = len(this.props);
      for (let k = 0; k < numP; k += 1) {
        let p = this.props[k];
        let pDx = p["x"] - cX; let pDz = p["z"] - cZ;
        let pDistSq = pDx * pDx + pDz * pDz;
        if (pDistSq > 1200.0 * 1200.0) continue;

        let pDot = pDx * fX + pDz * fZ;
        if (pDot < 0.0) continue; // Behind camera gaze

        let kind = p["kind"];
        let pr = p["r"]; if (pr == nil) pr = 120;
        let pg = p["g"]; if (pg == nil) pg = 130;
        let pb = p["b"]; if (pb == nil) pb = 145;

        if (kind == "pitsGarage") assets.playPitsGarage(p["x"], p["y"], p["z"], p["scale"], p["rot"], pr, pg, pb);
        else if (kind == "pitsOffice") assets.playPitsOffice(p["x"], p["y"], p["z"], p["scale"], p["rot"], pr, pg, pb);
        else if (kind == "grandstandAwning") assets.playGrandstandAwning(p["x"], p["y"], p["z"], p["scale"], p["rot"], pr, pg, pb);
        else if (kind == "grandstandCovered") assets.playGrandstand(1, p["x"], p["y"], p["z"], p["scale"], p["rot"], pr, pg, pb);
        else if (kind == "paddockHauler") assets.playPaddockHauler(p["x"], p["y"], p["z"], p["scale"], p["rot"], pr, pg, pb);
        else if (kind == "tentLong") assets.playTent(1, p["x"], p["y"], p["z"], p["scale"], p["rot"], pr, pg, pb);
        else if (kind == "tree") assets.playTree(p["var"], p["x"], p["y"], p["z"], p["scale"], p["rot"]);
        else if (kind == "billboard") assets.playDoubleBillboard(p["x"], p["y"], p["z"], p["scale"], p["rot"]);
        else if (kind == "radar") assets.playRadar(p["x"], p["y"], p["z"], p["scale"], p["rot"]);
        else if (kind == "floodlight") assets.playLargeFloodlight(p["x"], p["y"], p["z"], p["scale"], p["rot"]);
        else if (kind == "trackFlag") assets.playTrackFlag(p["var"], p["x"], p["y"], p["z"], p["scale"], p["rot"]);
        else if (kind == "flagCheckers") assets.playFlagCheckers(p["x"], p["y"], p["z"], p["scale"], p["rot"]);
        else if (kind == "bannerTower") assets.playBannerTower(p["x"], p["y"], p["z"], p["scale"], p["rot"]);
        else if (kind == "lightPost") assets.playLightPost(p["x"], p["y"], p["z"], p["scale"], p["rot"]);
        else if (kind == "brakeBoard") {
          // 3D Distance Countdown Marker Board (150m, 100m, 50m)
          let bx = p["x"]; let by = p["y"]; let bz = p["z"];
          let val = p["val"];
          // Stanchion Mast
          gui.drawCylinder3D(bx, by + 1.1, bz, 0.08, 0.08, 2.2, 4, 30, 35, 45);
          // White Board Face
          gui.drawCube3D(bx, by + 2.0, bz, 1.4, 1.8, 0.15, 245, 245, 250);
          // Bold Red Distance Stripes (3 for 150, 2 for 100, 1 for 50)
          if (val == 150) {
            gui.drawCube3D(bx, by + 2.4, bz + 0.08, 1.0, 0.22, 0.05, 225, 30, 35);
            gui.drawCube3D(bx, by + 2.0, bz + 0.08, 1.0, 0.22, 0.05, 225, 30, 35);
            gui.drawCube3D(bx, by + 1.6, bz + 0.08, 1.0, 0.22, 0.05, 225, 30, 35);
          } else if (val == 100) {
            gui.drawCube3D(bx, by + 2.2, bz + 0.08, 1.0, 0.26, 0.05, 225, 30, 35);
            gui.drawCube3D(bx, by + 1.7, bz + 0.08, 1.0, 0.26, 0.05, 225, 30, 35);
          } else {
            gui.drawCube3D(bx, by + 2.0, bz + 0.08, 1.0, 0.45, 0.05, 225, 30, 35);
          }
        } else if (kind == "yacht") {
          // Luxury Superyacht in Port Hercule
          let yx = p["x"]; let yy = p["y"]; let yz = p["z"];
          gui.drawCube3D(yx, yy - 0.6, yz, 4.2, 1.6, 12.0, 225, 230, 240); // Hull
          gui.drawCube3D(yx, yy + 0.4, yz - 1.0, 3.2, 1.2, 6.5, 245, 245, 252); // Main Cabin
          gui.drawCube3D(yx, yy + 1.2, yz - 1.5, 2.4, 0.9, 4.0, 215, 225, 235); // Flying Bridge
          gui.drawCylinder3D(yx, yy + 4.5, yz + 1.5, 0.12, 0.15, 8.5, 4, 190, 175, 150); // Mast
          gui.drawCube3D(yx, yy + 4.5, yz + 2.8, 0.08, 6.0, 3.2, 250, 248, 242); // Sail
        } else if (kind == "rivieraVilla") {
          let vx = p["x"]; let vy = p["y"]; let vz = p["z"];
          // Elegant Mediterranean Villa (cream stone facade, terracotta pitched roof, sun awnings)
          gui.drawCube3D(vx, vy + 4.5, vz, 11.0, 9.0, 15.0, 230, 222, 208); // Stone facade
          gui.drawCube3D(vx, vy + 9.6, vz, 11.8, 1.4, 15.8, 185, 75, 45);   // Terracotta pitched roof
          gui.drawCube3D(vx, vy + 5.5, vz, 12.2, 0.4, 10.0, 215, 45, 55);   // Riviera sun awning
          gui.drawCube3D(vx, vy + 3.0, vz, 12.4, 2.6, 10.4, 140, 145, 155); // Balcony railing
        }
      }
    }
  }
}
