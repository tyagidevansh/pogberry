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
    this.initCloudDome();
    this.buildWorldTrack();
  }

  // ---------------------------------------------------------------------------
  // SMOOTH CLOSED-LOOP PERIODIC 3D ELEVATION PROFILE
  // Authentic Formula 1 topography: steep climbs, rollercoasters, mountain crests
  // ---------------------------------------------------------------------------
  getElevationAt(s) {
    let lapLen = this.spec["length"];
    while (s < 0.0) s = s + lapLen;
    while (s >= lapLen) s = s - lapLen;

    if (this.trackId == 0) {
      // Suzuka: S-Curves climb, Dunlop sweep, Degner cutting underpass, Spoon plateau, Overpass bridge
      let w1 = 6.2831853 / lapLen;
      let base = 6.0 + math.sin(s * w1) * 3.5 + math.cos(s * w1 * 2.0) * 1.5;

      // Degner underpass cutting (dive down under bridge at s=3710)
      let dDist = s - 3710.0;
      if (math.abs(dDist) < 450.0) {
        let u = dDist / 450.0;
        let bell = (1.0 + math.cos(u * 3.14159265)) * 0.5;
        base = base - bell * 5.0;
      }

      // West Straight Overpass Bridge (crossing high over the cutting at s=7460)
      let bDist = s - 7460.0;
      if (math.abs(bDist) < 650.0) {
        let u = bDist / 650.0;
        let bell = (1.0 + math.cos(u * 3.14159265)) * 0.5;
        base = base + bell * 8.5;
      }
      return base;

    } else if (this.trackId == 1) {
      // Spa-Francorchamps: The legendary Ardennes Rollercoaster
      // Start straight at 14m, drop into Eau Rouge brook (2.5m at s=720),
      // STEEP Raidillon wall climb up to 38.5m at s=1260 (17% grade!),
      // elevated Kemmel Straight (38-42m), descent into Bruxelles & Pouhon (12m),
      // climb back to Stavelot (24m), descend through Blanchimont back to start (14m).
      let base = 14.0;
      if (s < 450.0) {
        // Start straight to La Source
        let u = s / 450.0;
        base = 14.0 - (u * u * (3.0 - 2.0 * u)) * 2.0;
      } else if (s < 720.0) {
        // Descent into Eau Rouge brook compression
        let u = (s - 450.0) / 270.0;
        base = 12.0 - (u * u * (3.0 - 2.0 * u)) * 9.5; // reaches 2.5m
      } else if (s < 1260.0) {
        // Raidillon 17% steep hill climb! 2.5m -> 38.5m!
        let u = (s - 720.0) / 540.0;
        base = 2.5 + (u * u * (3.0 - 2.0 * u)) * 36.0; // climbs 36m over 540m
      } else if (s < 3200.0) {
        // Kemmel straight ridge
        let u = (s - 1260.0) / (3200.0 - 1260.0);
        base = 38.5 + math.sin(u * 3.14159265) * 3.0;
      } else if (s < 4600.0) {
        // Les Combes into Bruxelles hairpin descent
        let u = (s - 3200.0) / (4600.0 - 3200.0);
        base = 38.5 - (u * u * (3.0 - 2.0 * u)) * 16.5;
      } else if (s < 6200.0) {
        // Descent into Pouhon floor
        let u = (s - 4600.0) / (6200.0 - 4600.0);
        base = 22.0 - (u * u * (3.0 - 2.0 * u)) * 10.0;
      } else if (s < 8000.0) {
        // Stavelot climb
        let u = (s - 6200.0) / (8000.0 - 6200.0);
        base = 12.0 + (u * u * (3.0 - 2.0 * u)) * 12.0;
      } else {
        // Blanchimont into Bus Stop chicane and start straight
        let u = (s - 8000.0) / (11200.0 - 8000.0);
        base = 24.0 - (u * u * (3.0 - 2.0 * u)) * 10.0;
      }
      return base;

    } else if (this.trackId == 2) {
      // Monza: Royal parkland subtle undulation
      let w1 = (6.2831853 * 4.0) / lapLen;
      return 3.0 + math.sin(s * w1) * 1.5;

    } else if (this.trackId == 3) {
      // Monaco: Natural city street gradient
      // Start/harbor straight at y = 0.5. Gentle climb up Beau Rivage to Casino Square peaking at y = 7.5 (a smooth 7m rise).
      // Gentle slope down through Mirabeau & Fairmont hairpin to Portier at y = 1.5, then flat y = 0.8 through the tunnel and harbor quayside.
      let base = 0.5;
      if (s >= 480.0 and s < 1350.0) {
        // Beau Rivage uphill climb (s=480 to 1350): climb 0.5m -> 7.5m
        let u = (s - 480.0) / (1350.0 - 480.0);
        let smoothU = u * u * (3.0 - 2.0 * u);
        base = 0.5 + smoothU * 7.0;
      } else if (s >= 1350.0 and s < 1740.0) {
        // Casino Square crest (s=1350 to 1740): plateau peaking at 7.5m
        let u = (s - 1350.0) / 390.0;
        base = 7.5 - math.sin(u * 3.14159265 * 0.5) * 0.3;
      } else if (s >= 1740.0 and s < 2650.0) {
        // Mirabeau & Fairmont descent (s=1740 to 2650): slope down from 7.2m -> 1.0m
        let u = (s - 1740.0) / (2650.0 - 1740.0);
        let smoothU = u * u * (3.0 - 2.0 * u);
        base = 7.2 - smoothU * 6.2;
      } else if (s >= 2650.0 and s < 2720.0) {
        // Portier / Tunnel approach: gentle descent 1.0m -> 0.8m
        let u = (s - 2650.0) / 70.0;
        let smoothU = u * u * (3.0 - 2.0 * u);
        base = 1.0 - smoothU * 0.2;
      } else if (s >= 2720.0 and s < 5200.0) {
        // Flat through the tunnel and harbor quayside at y = 0.8m
        base = 0.8;
      } else if (s >= 5200.0 and s < 5500.0) {
        // Harbor quayside blend to start straight: 0.8m -> 0.5m
        let u = (s - 5200.0) / 300.0;
        let smoothU = u * u * (3.0 - 2.0 * u);
        base = 0.8 - smoothU * 0.3;
      } else {
        // Start straight: flat y = 0.5m
        base = 0.5;
      }
      return base;

    } else if (this.trackId >= 4) {
      // Custom track smoothstep piecewise elevation profile
      let c = f1.getCustomTrack(this.trackId);
      if (c != nil and c["elevations"] != nil and len(c["elevations"]) > 0) {
        let elevs = c["elevations"];
        let numE = len(elevs);
        if (numE == 1) return elevs[0]["y"];
        let idx = 0;
        while (idx < numE - 1 and elevs[idx + 1]["s"] <= s) {
          idx = idx + 1;
        }
        let kf1 = elevs[idx];
        let kf2 = elevs[(idx + 1) % numE];
        let s1 = kf1["s"];
        let s2 = kf2["s"];
        if (s2 <= s1) s2 = s2 + lapLen;
        let span = s2 - s1;
        if (span < 0.001) return kf1["y"];
        let u = (s - s1) / span;
        if (u < 0.0) u = 0.0;
        if (u > 1.0) u = 1.0;
        let smoothU = u * u * (3.0 - 2.0 * u);
        return kf1["y"] + smoothU * (kf2["y"] - kf1["y"]);
      }
      return 0.5;

    } else {
      return 0.5;
    }
  }

  // ---------------------------------------------------------------------------
  // SCENERY PROP REGISTRATION HELPER
  // ---------------------------------------------------------------------------
  addSceneryProp(rawProps, kind, sStation, lateralOffset, scale, rotOffset, r, g, b, variant, radius, val) {
    let lapLen = this.spec["length"];
    while (sStation < 0.0) sStation = sStation + lapLen;
    while (sStation >= lapLen) sStation = sStation - lapLen;
    let step = this.segmentLength;
    let numStations = len(this.stations);
    if (numStations == 0) return;
    let stIdx = math.floor(sStation / step) % numStations;
    let st = this.stations[stIdx];
    let pAngle = st["heading"] * (180.0 / 3.14159265);
    let px = st["x"] + lateralOffset * st["nx"];
    let pz = st["z"] + lateralOffset * st["nz"];
    let py = st["y"];
    let pr = 120; if (r != nil) pr = r;
    let pg = 130; if (g != nil) pg = g;
    let pb = 145; if (b != nil) pb = b;
    let pVar = 0; if (variant != nil) pVar = variant;
    let pRad = 4.0; if (radius != nil) pRad = radius;
    let pScale = 1.0; if (scale != nil) pScale = scale;
    let pRot = pAngle; if (rotOffset != nil) pRot = pAngle + rotOffset;

    // Global track clearance check: reject props that would intrude into any track corridor
    let defCorridor = this.roadWidth * 0.5 + this.curbWidth + this.runoffWidth;
    let safeProp = true;
    for (let k = 0; k < numStations; k += 2) {
      let otherSt = this.stations[k];
      let dx = px - otherSt["x"];
      let dz = pz - otherSt["z"];
      let minClearance = defCorridor + pRad * 0.65 + 1.0;
      if (dx * dx + dz * dz < minClearance * minClearance) {
        safeProp = false;
        break;
      }
    }
    if (!safeProp) return;

    rawProps.push({
      "kind": kind, "s": sStation, "lat": lateralOffset,
      "x": px, "y": py, "z": pz,
      "nx": st["nx"], "nz": st["nz"],
      "tx": st["tx"], "tz": st["tz"],
      "scale": pScale, "rot": pRot,
      "r": pr, "g": pg, "b": pb,
      "var": pVar, "radius": pRad, "val": val
    });

    if (kind == "grandstandCovered" or kind == "grandstandAwning") {
      for (let d = -4; d <= 4; d += 1) {
        let gIdx = (stIdx + d + numStations) % numStations;
        if (lateralOffset < 0.0) this.stations[gIdx]["hasWallL"] = true;
        else this.stations[gIdx]["hasWallR"] = true;
      }
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
        "curbL": curbW, "curbR": curbW,
        "ol_x": ol_x, "ol_z": ol_z,
        "or_x": or_x, "or_z": or_z,
        "outL": corridor, "outR": corridor,
        "embL": corridor + 14.0, "embR": corridor + 14.0,
        "hasWallL": false, "hasWallR": false,
        "runL": true, "runR": true, "embOkL": true, "embOkR": true
      });
    }

    // ------------------------------------------------------------------
    // CLEARANCE & CURVATURE PASS
    // Narrows the verge, barrier and grass skirt where two sections of the
    // circuit run close together.
    // ------------------------------------------------------------------
    let roadEdge = halfW + curbW;
    for (let i = 0; i < numStations; i += 1) {
      let st = this.stations[i];
      let curv = st["curv"];
      let absCurv = math.abs(curv);
      let curveRadius = 99999.0;
      if (absCurv > 0.0001) curveRadius = 1.0 / absCurv;

      let curbL = this.curbWidth;
      let curbR = this.curbWidth;

      if (this.trackId == 3) {
        // Monaco GP: Curbs dynamically placed on all genuine corner apexes and exits
        let absCurv = math.abs(st["curv"]);
        if (absCurv > 0.0035) {
          if (st["curv"] > 0.001) {
            // Right turn: inside curb on right, exit curb on left
            curbR = 1.4;
            curbL = 0.8;
          } else {
            // Left turn: inside curb on left, exit curb on right
            curbL = 1.4;
            curbR = 0.8;
          }
        } else {
          curbL = 0.0;
          curbR = 0.0;
        }
      }

      // When curvature is high (|curv| > 0.0001), compute inner radius R = 1.0 / |curv|.
      // If R - halfW < curbWidth, clamp the inner curb width to math.max(0.3, (R - halfW) * 0.5)
      // so inner kerb vertices never cross the center of curvature or invert.
      if (absCurv > 0.0001) {
        let R = 1.0 / absCurv;
        if (curv < 0.0) {
          if (R - halfW < curbR) {
            let innerLim = (R - halfW) * 0.5;
            if (innerLim < 0.3) innerLim = 0.3;
            if (innerLim < curbR) curbR = innerLim;
          }
        } else {
          if (R - halfW < curbL) {
            let innerLim = (R - halfW) * 0.5;
            if (innerLim < 0.3) innerLim = 0.3;
            if (innerLim < curbL) curbL = innerLim;
          }
        }
      }

      let outL = halfW + curbL + runoffW;
      let outR = halfW + curbR + runoffW;
      let embL = corridor + 14.0;
      let embR = corridor + 14.0;

      // Ensure embankment vertices don't cross center of curvature on sharp turns
      let innerEmb = curveRadius * 0.78;
      if (curv < 0.0 and innerEmb < embR) embR = innerEmb;
      else if (curv > 0.0 and innerEmb < embL) embL = innerEmb;

      // Nearest other section of the circuit on each side of this station.
      let gapL = 99999.0; let gapR = 99999.0;
      let lowGapL = 99999.0; let lowGapR = 99999.0;
      for (let j = 0; j < numStations; j += 1) {
        let ox = this.stations[j]["x"] - st["x"];
        if (ox > 120.0 or ox < -120.0) continue;
        let oz = this.stations[j]["z"] - st["z"];
        if (oz > 120.0 or oz < -120.0) continue;
        let ds = st["s"] - this.stations[j]["s"];
        if (ds < 0.0) ds = -ds;
        if (ds > lapLen * 0.5) ds = lapLen - ds;
        if (ds < 120.0) continue; // Skip local track points ahead/behind

        // Only segments that are longitudinally adjacent (side-by-side)
        let longit = ox * st["tx"] + oz * st["tz"];
        if (longit > 18.0 or longit < -18.0) continue;

        // Only parallel or anti-parallel roads
        let dotT = st["tx"] * this.stations[j]["tx"] + st["tz"] * this.stations[j]["tz"];
        if (math.abs(dotT) < 0.60) continue;

        let dy = this.stations[j]["y"] - st["y"];
        let sameLevel = (math.abs(dy) < 6.0);
        let lateral = ox * st["nx"] + oz * st["nz"];

        if (lateral > roadEdge + 0.5) {
          if (sameLevel and lateral < gapR) gapR = lateral;
          if (math.abs(dy) < 8.0 and lateral < lowGapR) lowGapR = lateral;
        } else if (lateral < -roadEdge - 0.5) {
          let latDist = -lateral;
          if (sameLevel and latDist < gapL) gapL = latDist;
          if (math.abs(dy) < 8.0 and latDist < lowGapL) lowGapL = latDist;
        }
      }

      // In the clearance pass with nearby track sections (gapL, gapR),
      // Nearest other section of the circuit on each side of this station.
      // Boundaries are clamped strictly outside the active tarmac and kerbs.
      let minClearL = halfW + curbL + 0.8;
      let minClearR = halfW + curbR + 0.8;

      if (gapL < 900.0) {
        let maxHalfL = gapL * 0.48 - 0.2;
        let clearL = gapL - roadEdge - 1.5;
        if (maxHalfL < clearL) clearL = maxHalfL;
        if (clearL < minClearL) clearL = minClearL;
        if (clearL < outL) outL = clearL;
      }

      if (gapR < 900.0) {
        let maxHalfR = gapR * 0.48 - 0.2;
        let clearR = gapR - roadEdge - 1.5;
        if (maxHalfR < clearR) clearR = maxHalfR;
        if (clearR < minClearR) clearR = minClearR;
        if (clearR < outR) outR = clearR;
      }

      if (lowGapL < 900.0) {
        let maxHalfL = lowGapL * 0.48 - 9.0;
        let clear = lowGapL - roadEdge - 10.0;
        if (maxHalfL < clear) clear = maxHalfL;
        if (clear < minClearL + 0.5) clear = minClearL + 0.5;
        if (clear < embL) embL = clear;
      }
      if (lowGapR < 900.0) {
        let maxHalfR = lowGapR * 0.48 - 9.0;
        let clear = lowGapR - roadEdge - 10.0;
        if (maxHalfR < clear) clear = maxHalfR;
        if (clear < minClearR + 0.5) clear = minClearR + 0.5;
        if (clear < embR) embR = clear;
      }

      // Hard safety clamp: outL and outR can NEVER encroach inside the road + kerb
      if (outL < minClearL) outL = minClearL;
      if (outR < minClearR) outR = minClearR;
      if (embL < outL + 1.0) embL = outL + 1.0;
      if (embR < outR + 1.0) embR = outR + 1.0;

      // On start/finish straight, right barrier aligns with solid Pit Wall with safe road clearance
      let sVal = st["s"];
      let isPitZone = (sVal < 220.0 or sVal > lapLen - 220.0);
      if (isPitZone and this.trackId < 4) {
        let pitWallDist = halfW + curbR + 1.2;
        if (outR > pitWallDist) outR = pitWallDist;
      }

      // SELECTIVE BARRIER PLACEMENT (Formula 1 Circuit Authenticity)
      let sMid = st["s"];
      let isSuzukaBridge = (this.trackId == 0 and sMid >= 7280.0 and sMid <= 7650.0);
      let isSuzukaUnderpass = (this.trackId == 0 and sMid >= 3630.0 and sMid <= 3790.0);

      // Formula 1 FIA Grade 1 Continuous Perimeter Safety Barrier Enclosure
      let hasWallL = true;
      let hasWallR = true;

      st["curbL"] = curbL;
      st["curbR"] = curbR;
      st["cl_x"] = st["x"] - (halfW + curbL) * st["nx"];
      st["cl_z"] = st["z"] - (halfW + curbL) * st["nz"];
      st["cr_x"] = st["x"] + (halfW + curbR) * st["nx"];
      st["cr_z"] = st["z"] + (halfW + curbR) * st["nz"];
      st["outL"] = outL;
      st["outR"] = outR;
      st["embL"] = embL;
      st["embR"] = embR;
      st["gapL"] = gapL;
      st["gapR"] = gapR;
      st["hasWallL"] = hasWallL;
      st["hasWallR"] = hasWallR;
      st["runL"] = (outL >= halfW + curbL + 0.2);
      st["runR"] = (outR >= halfW + curbR + 0.2);
      st["embOkL"] = true;
      st["embOkR"] = true;

      st["ol_x"] = st["x"] - outL * st["nx"];
      st["ol_z"] = st["z"] - outL * st["nz"];
      st["or_x"] = st["x"] + outR * st["nx"];
      st["or_z"] = st["z"] + outR * st["nz"];
      st["el_x"] = st["x"] - embL * st["nx"];
      st["el_z"] = st["z"] - embL * st["nz"];
      st["er_x"] = st["x"] + embR * st["nx"];
      st["er_z"] = st["z"] + embR * st["nz"];
    }

    // Bidirectional spatial Laplacian smoothing across outL, outR, embL, embR:
    // Guarantees perimeter boundaries, sidewalks, and barriers curve and round smoothly without jagged steps
    for (let pass = 0; pass < 6; pass += 1) {
      let smoothOutL = [];
      let smoothOutR = [];
      let smoothEmbL = [];
      let smoothEmbR = [];
      for (let i = 0; i < numStations; i += 1) {
        let prevIdx = (i - 1 + numStations) % numStations;
        let nextIdx = (i + 1) % numStations;
        let avgL = (this.stations[prevIdx]["outL"] + this.stations[i]["outL"] * 2.0 + this.stations[nextIdx]["outL"]) * 0.25;
        let avgR = (this.stations[prevIdx]["outR"] + this.stations[i]["outR"] * 2.0 + this.stations[nextIdx]["outR"]) * 0.25;
        let avgEmbL = (this.stations[prevIdx]["embL"] + this.stations[i]["embL"] * 2.0 + this.stations[nextIdx]["embL"]) * 0.25;
        let avgEmbR = (this.stations[prevIdx]["embR"] + this.stations[i]["embR"] * 2.0 + this.stations[nextIdx]["embR"]) * 0.25;
        smoothOutL.push(avgL);
        smoothOutR.push(avgR);
        smoothEmbL.push(avgEmbL);
        smoothEmbR.push(avgEmbR);
      }
      for (let i = 0; i < numStations; i += 1) {
        let st = this.stations[i];
        let minL = halfW + st["curbL"] + 0.6;
        let minR = halfW + st["curbR"] + 0.6;
        let sL = smoothOutL[i];
        let sR = smoothOutR[i];
        if (sL < minL) sL = minL;
        if (sR < minR) sR = minR;
        let sEmbL = smoothEmbL[i];
        let sEmbR = smoothEmbR[i];
        if (sEmbL < sL + 1.0) sEmbL = sL + 1.0;
        if (sEmbR < sR + 1.0) sEmbR = sR + 1.0;

        st["outL"] = sL;
        st["outR"] = sR;
        st["embL"] = sEmbL;
        st["embR"] = sEmbR;
      }
    }

    // Recompute world geometry from smoothed boundary offsets
    for (let i = 0; i < numStations; i += 1) {
      let st = this.stations[i];
      let nx = st["nx"];
      let nz = st["nz"];
      let gapL = st["gapL"];
      let gapR = st["gapR"];

      // If an adjacent road is nearby, clamp embankment and calculate safe slope width
      let slopeL = 8.0;
      let slopeR = 8.0;
      if (gapL < 900.0) {
        let maxReachL = gapL - roadEdge - 2.5;
        if (st["embL"] > maxReachL - 1.0) st["embL"] = maxReachL - 1.0;
        if (st["embL"] < st["outL"]) st["embL"] = st["outL"];
        let remL = maxReachL - st["embL"];
        if (remL < slopeL) slopeL = remL;
        if (slopeL < 0.2) slopeL = 0.2;
      }
      if (gapR < 900.0) {
        let maxReachR = gapR - roadEdge - 2.5;
        if (st["embR"] > maxReachR - 1.0) st["embR"] = maxReachR - 1.0;
        if (st["embR"] < st["outR"]) st["embR"] = st["outR"];
        let remR = maxReachR - st["embR"];
        if (remR < slopeR) slopeR = remR;
        if (slopeR < 0.2) slopeR = 0.2;
      }
      st["slopeL"] = slopeL;
      st["slopeR"] = slopeR;
      st["embOkL"] = true;
      st["embOkR"] = true;

      st["ol_x"] = st["x"] - st["outL"] * nx;
      st["ol_z"] = st["z"] - st["outL"] * nz;
      st["or_x"] = st["x"] + st["outR"] * nx;
      st["or_z"] = st["z"] + st["outR"] * nz;
      st["el_x"] = st["x"] - st["embL"] * nx;
      st["el_z"] = st["z"] - st["embL"] * nz;
      st["er_x"] = st["x"] + st["embR"] * nx;
      st["er_z"] = st["z"] + st["embR"] * nz;
    }

    // Dilate wall presence so barriers form solid, continuous runs along corners
    let wallExt = 4;
    let tempWallL = [];
    let tempWallR = [];
    for (let i = 0; i < numStations; i += 1) {
      tempWallL.push(this.stations[i]["hasWallL"]);
      tempWallR.push(this.stations[i]["hasWallR"]);
    }
    for (let i = 0; i < numStations; i += 1) {
      if (tempWallL[i]) {
        for (let d = -wallExt; d <= wallExt; d += 1) {
          let idx = (i + d + numStations) % numStations;
          this.stations[idx]["hasWallL"] = true;
        }
      }
      if (tempWallR[i]) {
        for (let d = -wallExt; d <= wallExt; d += 1) {
          let idx = (i + d + numStations) % numStations;
          this.stations[idx]["hasWallR"] = true;
        }
      }
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

    // Track-specific authentic Formula 1 buildings, stands, and scenery
    if (this.trackId == 0) {
      // -----------------------------------------------------------------------
      // SUZUKA INTERNATIONAL RACING COURSE (Japanese Grand Prix)
      // -----------------------------------------------------------------------
      // 1. Paddock & Start/Finish Straight:
      //    Driver's Left: Continuous V1 & V2 Main Covered Grandstands, floodlights, flags
      //    Driver's Right: Suzuka Pit Garages with F1 liveries, Haulers, Hospitality, Race Office
      for (let s = -400.0; s <= 460.0; s += 22.0) {
        let isAwning = ((math.floor(s / 22.0)) % 2 == 1);
        let gKind = "grandstandCovered";
        if (isAwning) gKind = "grandstandAwning";
        this.addSceneryProp(rawProps, gKind, s, -corridor - 18.0, 11.5, -90.0, 150, 160, 175, 0, 9.5, nil);
        this.addSceneryProp(rawProps, "flagCheckers", s, -corridor - 2.5, 7.5, 0.0, 255, 255, 255, 0, 1.5, nil);
      }
      for (let s = -380.0; s <= 440.0; s += 44.0) {
        this.addSceneryProp(rawProps, "floodlight", s, -corridor - 4.5, 13.5, -90.0, 200, 210, 220, 0, 2.5, nil);
      }

      // Pit Garages on inside of pit straight
      let liveryIdx = 0;
      for (let s = -360.0; s <= 420.0; s += 20.0) {
        let teamCol = teamLiveries[liveryIdx % 10];
        liveryIdx += 1;
        this.addSceneryProp(rawProps, "pitsGarage", s, halfW + 6.0, 11.5, 90.0, 255, 255, 255, 0, 7.5, nil);
        this.addSceneryProp(rawProps, "paddockHauler", s, halfW + 18.0, 1.4, 90.0, teamCol[0], teamCol[1], teamCol[2], 0, 5.0, nil);
      }
      this.addSceneryProp(rawProps, "pitsOffice", 180.0, halfW + 10.0, 11.5, 90.0, 140, 150, 165, 0, 8.5, nil);
      this.addSceneryProp(rawProps, "tentLong", 340.0, halfW + 15.0, 11.0, 90.0, 135, 145, 160, 0, 6.5, nil);
      this.addSceneryProp(rawProps, "tentLong", -240.0, halfW + 15.0, 11.0, 90.0, 135, 145, 160, 0, 6.5, nil);

      // 2. Turn 1 & 2 (First Corner): Grandstand B on outside
      this.addSceneryProp(rawProps, "grandstandCovered", 640.0, -corridor - 18.0, 11.5, -90.0, 150, 160, 175, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "grandstandCovered", 720.0, -corridor - 18.0, 11.5, -90.0, 150, 160, 175, 0, 9.5, nil);

      // 3. S-Curves / Esses (Turns 3-6): Japanese red pines and Grandstand D
      for (let s = 860.0; s <= 1760.0; s += 36.0) {
        this.addSceneryProp(rawProps, "tree", s, -corridor - 9.0, 11.5 + ((s * 3) % 4), 0.0, 255, 255, 255, (math.floor(s / 36.0)) % 2, 4.0, nil);
        this.addSceneryProp(rawProps, "tree", s, corridor + 9.0, 11.0 + ((s * 5) % 4), 0.0, 255, 255, 255, (math.floor(s / 36.0) + 1) % 2, 4.0, nil);
      }
      this.addSceneryProp(rawProps, "grandstandCovered", 1380.0, corridor + 18.0, 11.5, 90.0, 150, 160, 175, 0, 9.5, nil);

      // 4. Dunlop Curve (Turn 7): Covered Grandstand E on Dunlop Hill
      this.addSceneryProp(rawProps, "grandstandCovered", 2050.0, corridor + 18.0, 11.5, 90.0, 150, 160, 175, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "grandstandAwning", 2120.0, corridor + 18.0, 11.5, 90.0, 150, 160, 175, 0, 9.5, nil);

      // 5. Degner 2: Grandstand
      this.addSceneryProp(rawProps, "grandstandAwning", 2850.0, -corridor - 18.0, 11.5, -90.0, 150, 160, 175, 0, 9.5, nil);

      // 6. Turn 11 Hairpin: The famous covered Suzuka Hairpin Grandstand (Grandstand G / I)!
      this.addSceneryProp(rawProps, "grandstandCovered", 5740.0, -corridor - 18.0, 11.5, -90.0, 150, 160, 175, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "grandstandAwning", 5800.0, -corridor - 18.0, 11.5, -90.0, 150, 160, 175, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "grandstandCovered", 5860.0, -corridor - 18.0, 11.5, -90.0, 150, 160, 175, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "billboard", 5680.0, corridor + 6.0, 11.5, 90.0, 255, 255, 255, 0, 3.5, nil);

      // 7. 200R & Spoon Curve (Turns 13-14): Grandstand J & M
      this.addSceneryProp(rawProps, "grandstandCovered", 6550.0, corridor + 18.0, 11.5, 90.0, 150, 160, 175, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "grandstandAwning", 6850.0, corridor + 18.0, 11.5, 90.0, 150, 160, 175, 0, 9.5, nil);

      // Pines along Spoon & back straight
      for (let s = 6300.0; s <= 7200.0; s += 48.0) {
        this.addSceneryProp(rawProps, "tree", s, -corridor - 9.0, 11.0, 0.0, 255, 255, 255, 0, 4.0, nil);
      }

      // 8. Casio Triangle Chicane: Covered Grandstand Q and R
      this.addSceneryProp(rawProps, "grandstandCovered", 8580.0, corridor + 18.0, 11.5, 90.0, 150, 160, 175, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "grandstandCovered", 8660.0, -corridor - 18.0, 11.5, -90.0, 150, 160, 175, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "billboard", 8720.0, -corridor - 6.0, 11.5, -90.0, 255, 255, 255, 0, 3.5, nil);

    } else if (this.trackId == 1) {
      // -----------------------------------------------------------------------
      // CIRCUIT DE SPA-FRANCORCHAMPS (Belgian Grand Prix)
      // -----------------------------------------------------------------------
      // Dense Ardennes Pine Forest
      for (let s = 0.0; s < lapLen; s += 36.0) {
        let pVar = (math.floor(s / 36.0)) % 2;
        this.addSceneryProp(rawProps, "tree", s, -corridor - 8.5, 13.0, 0.0, 255, 255, 255, pVar, 4.5, nil);
        this.addSceneryProp(rawProps, "tree", s, corridor + 8.5, 11.5, 0.0, 255, 255, 255, (pVar + 1) % 2, 4.5, nil);
      }

      // 1. Pit Straight & Paddock (s = 10600 to 11200 & 0 to 100)
      for (let s = -350.0; s <= 100.0; s += 20.0) {
        this.addSceneryProp(rawProps, "pitsGarage", s, halfW + 6.5, 11.5, 90.0, 130, 140, 155, 0, 7.5, nil);
        this.addSceneryProp(rawProps, "grandstandCovered", s, -corridor - 18.0, 11.5, -90.0, 255, 255, 255, 0, 9.5, nil);
      }
      this.addSceneryProp(rawProps, "pitsOffice", 20.0, halfW + 10.0, 11.5, 90.0, 140, 150, 165, 0, 8.5, nil);

      // 2. La Source Hairpin (Turn 1): Covered Grandstand overlooking the hairpin
      this.addSceneryProp(rawProps, "grandstandCovered", 340.0, -corridor - 18.0, 11.5, -90.0, 255, 255, 255, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "pitsGarage", 420.0, corridor + 8.0, 11.5, 90.0, 110, 120, 135, 0, 7.5, nil);

      // 3. Eau Rouge & Raidillon (Turns 2-4): Grandstand at foot and crest
      this.addSceneryProp(rawProps, "grandstandCovered", 820.0, corridor + 18.0, 11.5, 90.0, 255, 255, 255, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "grandstandAwning", 1150.0, corridor + 18.0, 11.5, 90.0, 255, 255, 255, 0, 9.5, nil);

      // 4. Les Combes & Malmedy (Turns 5-7): Covered Grandstand
      this.addSceneryProp(rawProps, "grandstandCovered", 3450.0, -corridor - 18.0, 11.5, -90.0, 255, 255, 255, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "billboard", 3350.0, corridor + 6.0, 12.0, 90.0, 255, 255, 255, 0, 3.5, nil);

      // 5. Bruxelles Hairpin (Turn 8): Downhill turn
      this.addSceneryProp(rawProps, "billboard", 4450.0, -corridor - 6.0, 12.0, -90.0, 255, 255, 255, 0, 3.5, nil);

      // 6. Pouhon Amphitheater (Turns 10-11): Spectator camping hillside with tents!
      for (let s = 5700.0; s <= 6500.0; s += 80.0) {
        this.addSceneryProp(rawProps, "tentLong", s, corridor + 22.0, 11.0, 90.0, 140, 150, 170, 0, 6.5, nil);
        this.addSceneryProp(rawProps, "tent", s + 40.0, corridor + 24.0, 10.0, 90.0, 185, 95, 28, 0, 5.0, nil);
      }

      // 7. Fagnes Chicane: Covered Grandstand
      this.addSceneryProp(rawProps, "grandstandCovered", 7250.0, -corridor - 18.0, 11.5, -90.0, 255, 255, 255, 0, 9.5, nil);

      // 8. Bus Stop Chicane: Covered Grandstand
      this.addSceneryProp(rawProps, "grandstandCovered", 10320.0, corridor + 18.0, 11.5, 90.0, 255, 255, 255, 0, 9.5, nil);

    } else if (this.trackId == 2) {
      // -----------------------------------------------------------------------
      // AUTODROMO NAZIONALE MONZA (Italian Grand Prix / Temple of Speed)
      // -----------------------------------------------------------------------
      // Royal Parkland Oak Trees
      for (let s = 0.0; s < lapLen; s += 36.0) {
        let pVar = (math.floor(s / 36.0)) % 2;
        this.addSceneryProp(rawProps, "tree", s, -corridor - 8.5, 13.5, 0.0, 255, 255, 255, pVar, 4.5, nil);
        this.addSceneryProp(rawProps, "tree", s, corridor + 8.5, 12.0, 0.0, 255, 255, 255, (pVar + 1) % 2, 4.5, nil);
      }

      // 1. Rettifilo Main Straight & Tribuna Grandstands (s = 8900 to 9600 & 0 to 750)
      for (let s = -450.0; s <= 550.0; s += 22.0) {
        let isAwning = ((math.floor(s / 22.0)) % 2 == 1);
        let gKind = "grandstandCovered";
        if (isAwning) gKind = "grandstandAwning";
        this.addSceneryProp(rawProps, gKind, s, -corridor - 18.0, 11.5, -90.0, 255, 255, 255, 0, 9.5, nil);
      }
      // Monza Pit Building with authentic Formula 1 constructor team colors
      let liveryIdx = 0;
      for (let s = -350.0; s <= 450.0; s += 20.0) {
        let teamCol = teamLiveries[liveryIdx % 10];
        liveryIdx += 1;
        this.addSceneryProp(rawProps, "pitsGarage", s, halfW + 6.5, 11.5, 90.0, 135, 140, 150, 0, 7.5, nil);
        this.addSceneryProp(rawProps, "paddockHauler", s, halfW + 18.0, 1.4, 90.0, teamCol[0], teamCol[1], teamCol[2], 0, 5.0, nil);
      }
      this.addSceneryProp(rawProps, "pitsOffice", 180.0, halfW + 10.0, 11.5, 90.0, 140, 150, 165, 0, 8.5, nil);

      // 2. Variante del Rettifilo Chicane: Tribuna 6 and Tribuna 8
      this.addSceneryProp(rawProps, "grandstandCovered", 1120.0, -corridor - 18.0, 11.5, -90.0, 255, 255, 255, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "grandstandCovered", 1250.0, -corridor - 18.0, 11.5, -90.0, 255, 255, 255, 0, 9.5, nil);

      // 3. Variante della Roggia: Tribuna Roggia
      this.addSceneryProp(rawProps, "grandstandCovered", 3020.0, corridor + 18.0, 11.5, 90.0, 255, 255, 255, 0, 9.5, nil);

      // 4. Variante Ascari: Continuous Tribuna Ascari Grandstands
      this.addSceneryProp(rawProps, "grandstandCovered", 6450.0, corridor + 18.0, 11.5, 90.0, 255, 255, 255, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "grandstandAwning", 6650.0, corridor + 18.0, 11.5, 90.0, 255, 255, 255, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "grandstandCovered", 6850.0, corridor + 18.0, 11.5, 90.0, 255, 255, 255, 0, 9.5, nil);

      // 5. Curva Parabolica (Curva Alboreto): Grandstand 21 and 22
      this.addSceneryProp(rawProps, "grandstandCovered", 8450.0, -corridor - 18.0, 11.5, -90.0, 255, 255, 255, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "grandstandCovered", 8720.0, -corridor - 18.0, 11.5, -90.0, 255, 255, 255, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "billboard", 8550.0, corridor + 6.0, 12.0, 90.0, 255, 255, 255, 0, 3.5, nil);

    } else if (this.trackId == 3) {
      // -----------------------------------------------------------------------
      // CIRCUIT DE MONACO (Monaco Grand Prix / Monte Carlo)
      // -----------------------------------------------------------------------
      // 1. Pit Straight & Anthony Noghes: Covered Grandstand on driver's left
      this.addSceneryProp(rawProps, "grandstandCovered", 120.0, -corridor - 18.0, 8.5, -90.0, 255, 255, 255, 0, 10.0, nil);

      // 2. Sainte-Devote approach & Turn 1 braking zone
      this.addSceneryProp(rawProps, "grandstandCovered", 330.0, -corridor - 18.0, 8.5, -90.0, 255, 255, 255, 0, 10.0, nil);
      this.addSceneryProp(rawProps, "sainteDevote", 420.0, -corridor - 26.0, 1.0, -90.0, 220, 210, 195, 0, 14.0, nil);

      // 3. Beau Rivage uphill streetscape: Riviera pastel apartments on left cliff
      for (let s = 620.0; s <= 1350.0; s += 65.0) {
        let bVar = (math.floor(s / 65.0)) % 5;
        this.addSceneryProp(rawProps, "monacoBuilding", s, -corridor - 24.0, 1.0, -90.0, 255, 255, 255, bVar, 12.0, nil);
      }

      // 4. Monte Carlo Casino & Hotel de Paris at Casino Square (s = 1500 to 1700)
      this.addSceneryProp(rawProps, "grandstandCovered", 1500.0, corridor + 18.0, 8.0, 90.0, 255, 255, 255, 0, 10.0, nil);
      this.addSceneryProp(rawProps, "monacoCasino", 1560.0, -corridor - 26.0, 1.0, -90.0, 236, 230, 218, 0, 12.0, nil);
      this.addSceneryProp(rawProps, "hotelDeParis", 1620.0, corridor + 26.0, 1.0, 90.0, 245, 240, 228, 0, 12.0, nil);

      // 5. Mirabeau descent: Monegasque pastel apartment streetscape
      for (let s = 1800.0; s <= 2200.0; s += 65.0) {
        let bVar = (math.floor(s / 65.0)) % 5;
        this.addSceneryProp(rawProps, "monacoBuilding", s, -corridor - 22.0, 1.0, -90.0, 255, 255, 255, bVar, 11.0, nil);
      }

      // 6. The Fairmont Hotel wrapping around Turn 6 Lowes Hairpin
      this.addSceneryProp(rawProps, "grandstandCovered", 2360.0, corridor + 20.0, 8.0, 90.0, 255, 255, 255, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "fairmontHotel", 2440.0, corridor + 24.0, 1.0, 90.0, 232, 228, 220, 0, 24.0, nil);

      // 7. Portier & Tunnel approach buildings
      this.addSceneryProp(rawProps, "monacoBuilding", 2640.0, -corridor - 22.0, 1.0, -90.0, 255, 255, 255, 0, 11.0, nil);

      // 8. Port Hercule Quayside: Moored luxury superyachts along Quai des Etats-Unis
      this.addSceneryProp(rawProps, "grandstandCovered", 3740.0, -corridor - 16.0, 8.5, -90.0, 255, 255, 255, 0, 10.0, nil);
      this.addSceneryProp(rawProps, "grandstandCovered", 4050.0, -corridor - 16.0, 8.5, -90.0, 255, 255, 255, 0, 10.0, nil);
      for (let s = 3700.0; s <= 4250.0; s += 50.0) {
        let yVar = (math.floor(s / 50.0)) % 3;
        this.addSceneryProp(rawProps, "superyacht", s, corridor + 22.0, 1.0, 0.0, 255, 255, 255, yVar, 6.0, nil);
      }

      // 9. Rainier III Nautical Stadium (The Swimming Pool chicane, s = 4300 to 4600)
      this.addSceneryProp(rawProps, "grandstandCovered", 4320.0, -corridor - 18.0, 8.5, -90.0, 255, 255, 255, 0, 10.0, nil);
      this.addSceneryProp(rawProps, "swimmingPool", 4420.0, corridor + 28.0, 1.0, 90.0, 28, 185, 225, 0, 28.0, nil);
      this.addSceneryProp(rawProps, "grandstandCovered", 4580.0, -corridor - 18.0, 8.5, -90.0, 255, 255, 255, 0, 10.0, nil);

      // 10. La Rascasse & Anthony Noghes (s = 5100 to 5150)
      this.addSceneryProp(rawProps, "grandstandCovered", 5100.0, -corridor - 16.0, 8.5, -90.0, 255, 255, 255, 0, 10.0, nil);
      this.addSceneryProp(rawProps, "rascasseBar", 5150.0, corridor + 14.0, 1.0, 90.0, 215, 120, 95, 0, 8.0, nil);

      // 11. Boulevard Albert 1er high-rise streetscape (pit straight)
      for (let s = 5300.0; s <= 5750.0; s += 50.0) {
        let bVar = (math.floor(s / 50.0)) % 5;
        this.addSceneryProp(rawProps, "monacoBuilding", s, -corridor - 24.0, 1.0, -90.0, 255, 255, 255, bVar, 11.0, nil);
      }

      // Pit Garages and Pit Office on Driver's Right
      for (let s = -220.0; s <= 240.0; s += 22.0) {
        this.addSceneryProp(rawProps, "pitsGarage", s, halfW + 6.0, 10.5, 90.0, 120, 130, 145, 0, 6.0, nil);
      }
      this.addSceneryProp(rawProps, "pitsOffice", 120.0, halfW + 10.0, 10.5, 90.0, 140, 150, 165, 0, 6.0, nil);

      // 11. Riviera Villas and Grand Hotels on Monte Carlo hillside
      this.addSceneryProp(rawProps, "rivieraVilla", 420.0, -corridor - 32.0, 1.0, -90.0, 230, 222, 208, 0, 8.0, nil);
      this.addSceneryProp(rawProps, "rivieraVilla", 850.0, -corridor - 34.0, 1.2, -90.0, 230, 222, 208, 0, 8.0, nil);
      this.addSceneryProp(rawProps, "monacoBuilding", 1260.0, -corridor - 32.0, 1.0, -90.0, 242, 235, 220, 1, 10.0, nil);
      // -----------------------------------------------------------------------
      // AUTODROMO NAZIONALE MONZA (Italian Grand Prix / Temple of Speed)
      // -----------------------------------------------------------------------
      // Royal Parkland Oak Trees
      for (let s = 0.0; s < lapLen; s += 36.0) {
        let pVar = (math.floor(s / 36.0)) % 2;
        this.addSceneryProp(rawProps, "tree", s, -corridor - 8.5, 13.5, 0.0, 255, 255, 255, pVar, 4.5, nil);
        this.addSceneryProp(rawProps, "tree", s, corridor + 8.5, 12.0, 0.0, 255, 255, 255, (pVar + 1) % 2, 4.5, nil);
      }

      // 1. Rettifilo Main Straight & Tribuna Grandstands (s = 8900 to 9600 & 0 to 750)
      for (let s = -450.0; s <= 550.0; s += 22.0) {
        let isAwning = ((math.floor(s / 22.0)) % 2 == 1);
        let gKind = "grandstandCovered";
        if (isAwning) gKind = "grandstandAwning";
        this.addSceneryProp(rawProps, gKind, s, -corridor - 18.0, 11.5, -90.0, 255, 255, 255, 0, 9.5, nil);
      }
      // Monza Pit Building with authentic Formula 1 constructor team colors
      let liveryIdx = 0;
      for (let s = -350.0; s <= 450.0; s += 20.0) {
        let teamCol = teamLiveries[liveryIdx % 10];
        liveryIdx += 1;
        this.addSceneryProp(rawProps, "pitsGarage", s, halfW + 6.5, 11.5, 90.0, 135, 140, 150, 0, 7.5, nil);
        this.addSceneryProp(rawProps, "paddockHauler", s, halfW + 18.0, 1.4, 90.0, teamCol[0], teamCol[1], teamCol[2], 0, 5.0, nil);
      }
      this.addSceneryProp(rawProps, "pitsOffice", 180.0, halfW + 10.0, 11.5, 90.0, 140, 150, 165, 0, 8.5, nil);

      // 2. Variante del Rettifilo Chicane: Tribuna 6 and Tribuna 8
      this.addSceneryProp(rawProps, "grandstandCovered", 1120.0, -corridor - 18.0, 11.5, -90.0, 255, 255, 255, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "grandstandCovered", 1250.0, -corridor - 18.0, 11.5, -90.0, 255, 255, 255, 0, 9.5, nil);

      // 3. Variante della Roggia: Tribuna Roggia
      this.addSceneryProp(rawProps, "grandstandCovered", 3020.0, corridor + 18.0, 11.5, 90.0, 255, 255, 255, 0, 9.5, nil);

      // 4. Variante Ascari: Continuous Tribuna Ascari Grandstands
      this.addSceneryProp(rawProps, "grandstandCovered", 6450.0, corridor + 18.0, 11.5, 90.0, 255, 255, 255, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "grandstandAwning", 6650.0, corridor + 18.0, 11.5, 90.0, 255, 255, 255, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "grandstandCovered", 6850.0, corridor + 18.0, 11.5, 90.0, 255, 255, 255, 0, 9.5, nil);

      // 5. Curva Parabolica (Curva Alboreto): Grandstand 21 and 22
      this.addSceneryProp(rawProps, "grandstandCovered", 8450.0, -corridor - 18.0, 11.5, -90.0, 255, 255, 255, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "grandstandCovered", 8720.0, -corridor - 18.0, 11.5, -90.0, 255, 255, 255, 0, 9.5, nil);
      this.addSceneryProp(rawProps, "billboard", 8550.0, corridor + 6.0, 12.0, 90.0, 255, 255, 255, 0, 3.5, nil);

    } else if (this.trackId >= 4) {
      let c = f1.getCustomTrack(this.trackId);
      if (c != nil and c["props"] != nil) {
        let pList = c["props"];
        for (let k = 0; k < len(pList); k += 1) {
          let p = pList[k];
          let pRot = 0.0; if (p["yaw"] != nil) pRot = p["yaw"];
          let pScale = 1.0; if (p["scale"] != nil) pScale = p["scale"];
          let pVar = 0; if (p["variant"] != nil) pVar = p["variant"];
          this.addSceneryProp(rawProps, p["type"], p["s"], p["offset"], pScale, pRot, 255, 255, 255, pVar, 8.0, nil);
        }
      }
    }

    // Brake Distance Countdown Boards (150m, 100m, 50m before major braking zones)
    let brakeZones = [];
    if (this.trackId == 0) {
      // Suzuka: Turn 1, Turn 11 Hairpin, Casio Triangle
      brakeZones = [540.0, 5640.0, 8450.0];
    } else if (this.trackId == 1) {
      // Spa: La Source, Les Combes, Bus Stop
      brakeZones = [240.0, 3220.0, 10120.0];
    } else if (this.trackId == 2) {
      // Monza: Rettifilo Chicane, Roggia Chicane, Ascari Chicane, Parabolica
      brakeZones = [980.0, 2820.0, 6240.0, 8280.0];
    } else if (this.trackId == 3) {
      // Monaco: Sainte-Devote, Mirabeau, Nouvelle Chicane, Rascasse
      brakeZones = [360.0, 1650.0, 2980.0, 4850.0];
    } else {
      brakeZones = [];
    }

    for (let bz = 0; bz < len(brakeZones); bz += 1) {
      let bzS = brakeZones[bz];
      let bSt150 = math.floor((bzS - 150.0 + lapLen) / step) % numStations;
      let bSt100 = math.floor((bzS - 100.0 + lapLen) / step) % numStations;
      let bSt50 = math.floor((bzS - 50.0 + lapLen) / step) % numStations;

      let st150 = this.stations[bSt150];
      let st100 = this.stations[bSt100];
      let st50 = this.stations[bSt50];

      let bDist = corridor + 1.2;
      rawProps.push({ "kind": "brakeBoard", "val": 150, "s": bzS - 150.0, "lat": -bDist, "x": st150["x"] - bDist * st150["nx"], "y": st150["y"], "z": st150["z"] - bDist * st150["nz"], "nx": st150["nx"], "nz": st150["nz"], "tx": st150["tx"], "tz": st150["tz"], "scale": 1.0, "rot": st150["heading"] * (180.0 / 3.14159265), "radius": 1.5 });
      rawProps.push({ "kind": "brakeBoard", "val": 100, "s": bzS - 100.0, "lat": -bDist, "x": st100["x"] - bDist * st100["nx"], "y": st100["y"], "z": st100["z"] - bDist * st100["nz"], "nx": st100["nx"], "nz": st100["nz"], "tx": st100["tx"], "tz": st100["tz"], "scale": 1.0, "rot": st100["heading"] * (180.0 / 3.14159265), "radius": 1.5 });
      rawProps.push({ "kind": "brakeBoard", "val": 50, "s": bzS - 50.0, "lat": -bDist, "x": st50["x"] - bDist * st50["nx"], "y": st50["y"], "z": st50["z"] - bDist * st50["nz"], "nx": st50["nx"], "nz": st50["nz"], "tx": st50["tx"], "tz": st50["tz"], "scale": 1.0, "rot": st50["heading"] * (180.0 / 3.14159265), "radius": 1.5 });
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
      let pKind = pr["kind"];
      if (pKind == "grandstandCovered" or pKind == "grandstandAwning") {
        let gScale = pr["scale"];
        if (gScale == nil) gScale = 8.5;
        propR = gScale * 1.15;
      } else if (pKind == "building" or pKind == "monacoBuilding") {
        propR = 12.0;
      }

      let minSafe = roadEdge + propR + 0.8;
      let minSafeSq = minSafe * minSafe;
      let fits = true;

      for (let sIdx = 0; sIdx < numStations; sIdx += 1) {
        let st = this.stations[sIdx];
        let dx = px - st["x"];
        let dz = pz - st["z"];
        if (dx * dx + dz * dz < minSafeSq) {
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
  projectWorldPoint(wx, wz, hintS, carHeading) {
    let lapLen = this.spec["length"];
    let step = this.segmentLength;
    let numStations = len(this.stations);
    let hintIdx = math.floor(hintS / step) % numStations;
    while (hintIdx < 0) hintIdx = hintIdx + numStations;

    let searchRadius = 2; // Continuous frame tracking: +/-2 stations covers up to 720 m/s without jumping
    let bestDistSq = 99999999.0;
    let bestS = hintS;
    let bestOffset = 0.0;
    let PI = 3.14159265;
    let TWO_PI = 6.2831853;

    for (let d = -searchRadius; d <= searchRadius; d += 1) {
      let idx = (hintIdx + d) % numStations;
      while (idx < 0) idx = idx + numStations;
      let nextIdx = (idx + 1) % numStations;
      let st1 = this.stations[idx];
      let st2 = this.stations[nextIdx];

      // Disallow stations pointing > 75 degrees away from car heading
      if (carHeading != nil) {
        let dH = carHeading - st1["heading"];
        while (dH > PI) dH = dH - TWO_PI;
        while (dH < -PI) dH = dH + TWO_PI;
        if (math.abs(dH) > 1.30) continue;
      }

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

    // Fallback if car has spun or is perpendicular to track
    if (bestDistSq > 999990.0) {
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
    if (this.trackId == 3 and prog > 2720.0 and prog < 3570.0) return true;
    if (this.trackId >= 4) {
      let c = f1.getCustomTrack(this.trackId);
      if (c != nil and c["tunnels"] != nil) {
        let tList = c["tunnels"];
        for (let k = 0; k < len(tList); k += 1) {
          let t = tList[k];
          if (prog >= t["startS"] and prog <= t["endS"]) return true;
        }
      }
    }
    return false;
  }

  getBarrierLimits(s) {
    let lapLen = this.spec["length"];
    while (s < 0.0) s = s + lapLen;
    while (s >= lapLen) s = s - lapLen;
    let step = this.segmentLength;
    if (step <= 0.001) step = 8.0;
    let numStations = len(this.stations);
    if (numStations == 0) {
      let defLim = this.roadWidth * 0.5 + this.curbWidth + this.runoffWidth;
      return [defLim, defLim, true, true];
    }
    let idx = math.floor(s / step) % numStations;
    while (idx < 0) idx = idx + numStations;
    let nextIdx = (idx + 1) % numStations;
    let u = (s - idx * step) / step;
    if (u < 0.0) u = 0.0;
    if (u > 1.0) u = 1.0;
    let st1 = this.stations[idx];
    let st2 = this.stations[nextIdx];

    let hasWallL = st1["hasWallL"] or st2["hasWallL"];
    let hasWallR = st1["hasWallR"] or st2["hasWallR"];

    let limL = st1["outL"] * (1.0 - u) + st2["outL"] * u;
    let limR = st1["outR"] * (1.0 - u) + st2["outR"] * u;

    if (!hasWallL) limL = limL + 2.5;
    if (!hasWallR) limR = limR + 2.5;

    return [limL, limR, hasWallL, hasWallR];
  }

  update(scrollSpeed, dt) {
    // Persistent World Engine: tracks are fully world-space static
  }

  // ---------------------------------------------------------------------------
  // ORIENTED 3D BOX / BEAM RENDERER
  // ---------------------------------------------------------------------------
  drawOrientedBox(cx, cy, cz, spanW, beamH, beamD, nx, nz, tx, tz, r, g, b) {
    let halfW = spanW * 0.5;
    let halfD = beamD * 0.5;
    let yB = cy - beamH * 0.5;
    let yT = cy + beamH * 0.5;

    // 4 base corners in XZ plane
    let fl_x = cx - halfW * nx - halfD * tx;
    let fl_z = cz - halfW * nz - halfD * tz;
    let fr_x = cx + halfW * nx - halfD * tx;
    let fr_z = cz + halfW * nz - halfD * tz;
    let br_x = cx + halfW * nx + halfD * tx;
    let br_z = cz + halfW * nz + halfD * tz;
    let bl_x = cx - halfW * nx + halfD * tx;
    let bl_z = cz - halfW * nz + halfD * tz;

    // Front face (incoming traffic side)
    gui.drawQuad3D(fl_x, yB, fl_z, fr_x, yB, fr_z, fr_x, yT, fr_z, fl_x, yT, fl_z, r, g, b);
    // Back face (downstream traffic side)
    gui.drawQuad3D(br_x, yB, br_z, bl_x, yB, bl_z, bl_x, yT, bl_z, br_x, yT, br_z, r, g, b);
    // Top face
    gui.drawQuad3D(fl_x, yT, fl_z, fr_x, yT, fr_z, br_x, yT, br_z, bl_x, yT, bl_z, r, g, b);
    // Bottom face
    gui.drawQuad3D(fl_x, yB, fl_z, bl_x, yB, bl_z, br_x, yB, br_z, fr_x, yB, fr_z, r, g, b);
    // Left face
    gui.drawQuad3D(bl_x, yB, bl_z, fl_x, yB, fl_z, fl_x, yT, fl_z, bl_x, yT, bl_z, r, g, b);
    // Right face
    gui.drawQuad3D(fr_x, yB, fr_z, br_x, yB, br_z, br_x, yT, br_z, fr_x, yT, fr_z, r, g, b);
  }

  // ---------------------------------------------------------------------------
  // 3D DISTANT HORIZON MOUNTAINS & ENVIRONMENT BACKDROP
  // ---------------------------------------------------------------------------
  drawMountainPeak(x1, z1, xC, zC, x2, z2, apexX, apexY, apexZ, r1, g1, b1, r2, g2, b2, snow) {
    if (snow) {
      let sFrac = 0.30;
      let sY = apexY * (1.0 - sFrac);
      let sx1 = apexX + (x1 - apexX) * sFrac;
      let sz1 = apexZ + (z1 - apexZ) * sFrac;
      let sx2 = apexX + (x2 - apexX) * sFrac;
      let sz2 = apexZ + (z2 - apexZ) * sFrac;
      let sxC = apexX + (xC - apexX) * sFrac;
      let szC = apexZ + (zC - apexZ) * sFrac;

      // Grey mountain rock base as quad trapezoids from y = -60.0 up to sY
      gui.drawQuad3D(x1, -60.0, z1, sx1, sY, sz1, sxC, sY, szC, xC, -60.0, zC, r1, g1, b1);
      gui.drawQuad3D(xC, -60.0, zC, sxC, sY, szC, sx2, sY, sz2, x2, -60.0, z2, r2, g2, b2);

      // Solid snow cap triangles covering peak from sY up to apexY
      gui.drawTriangle3D(sx1, sY, sz1, apexX, apexY, apexZ, sxC, sY, szC, 242, 246, 252);
      gui.drawTriangle3D(sxC, sY, szC, apexX, apexY, apexZ, sx2, sY, sz2, 218, 224, 236);
    } else {
      gui.drawTriangle3D(x1, -60.0, z1, apexX, apexY, apexZ, xC, -60.0, zC, r1, g1, b1);
      gui.drawTriangle3D(xC, -60.0, zC, apexX, apexY, apexZ, x2, -60.0, z2, r2, g2, b2);
    }
  }

  drawMountainRidge(cX, cZ, radius, numPeaks, startAng, totalAng, baseH, varH, r1, g1, b1, r2, g2, b2, snow) {
    let angStep = totalAng / numPeaks;
    let wAng = angStep * 1.35;
    for (let m = 0; m < numPeaks; m += 1) {
      let ang = startAng + m * angStep;
      let pH = baseH + ((m * 37 + 13) % varH);
      let aX = cX + math.sin(ang) * radius;
      let aZ = cZ + math.cos(ang) * radius;
      let x1 = cX + math.sin(ang - wAng * 0.5) * radius;
      let z1 = cZ + math.cos(ang - wAng * 0.5) * radius;
      let x2 = cX + math.sin(ang + wAng * 0.5) * radius;
      let z2 = cZ + math.cos(ang + wAng * 0.5) * radius;
      let xC = cX + math.sin(ang) * radius;
      let zC = cZ + math.cos(ang) * radius;
      this.drawMountainPeak(x1, z1, xC, zC, x2, z2, aX, pH, aZ, r1, g1, b1, r2, g2, b2, snow);
    }
  }

  initCloudDome() {
    this.cloudBanks = [];
    let count = 28;
    for (let i = 0; i < count; i += 1) {
      let ang = i * 2.39996323 + 0.35;
      let rFrac = (i + 0.5) / count;
      let radius = 600.0 + rFrac * 1100.0;
      let initX = math.cos(ang) * radius;
      let initZ = math.sin(ang) * radius;
      let alt = 240.0 + ((i * 37 + 19) % 120);
      let len = 80.0 + ((i * 47 + 13) % 140);
      let wid = 50.0 + ((i * 31 + 23) % 90);
      let hgt = 18.0 + ((i * 17 + 7) % 17);
      let swapAxes = (i % 2 == 1);

      this.cloudBanks.push({
        "initX": initX,
        "initZ": initZ,
        "alt": alt,
        "len": len,
        "wid": wid,
        "hgt": hgt,
        "swapAxes": swapAxes
      });
    }
  }

  drawCelestialDome(cX, cZ, t) {
    if (t == nil) t = 0.0;

    // 1. 3D Celestial Sun
    let sunAzimuth = 0.82;
    let sunElev = 0.48;
    let sunDist = 1850.0;
    let sunWorldX = cX + sunDist * math.cos(sunElev) * math.sin(sunAzimuth);
    let sunWorldY = 18.0 + sunDist * math.sin(sunElev);
    let sunWorldZ = cZ + sunDist * math.cos(sunElev) * math.cos(sunAzimuth);

    // Radiant sun spheres
    gui.drawSphere3D(sunWorldX, sunWorldY, sunWorldZ, 120.0, 255, 240, 190);
    gui.drawSphere3D(sunWorldX, sunWorldY, sunWorldZ, 80.0, 255, 248, 210);
    gui.drawSphere3D(sunWorldX, sunWorldY, sunWorldZ, 48.0, 255, 255, 245);

    // 2. 3D Volumetric Cloud Banks
    if (this.cloudBanks == nil) this.initCloudDome();

    let wrapRadius = 1800.0;
    let wrapDiameter = 3600.0;
    let driftX = t * 4.5;
    let driftZ = t * 2.0;

    for (let c = 0; c < len(this.cloudBanks); c += 1) {
      let cb = this.cloudBanks[c];
      let rawX = cb["initX"] + driftX - cX;
      let rawZ = cb["initZ"] + driftZ - cZ;

      let wrapX = rawX - math.floor((rawX + wrapRadius) / wrapDiameter) * wrapDiameter;
      let wrapZ = rawZ - math.floor((rawZ + wrapRadius) / wrapDiameter) * wrapDiameter;

      let clX = cX + wrapX;
      let clY = cb["alt"];
      let clZ = cZ + wrapZ;

      let cLen = cb["len"];
      let cWid = cb["wid"];
      let cHgt = cb["hgt"];
      let dimX = cWid;
      let dimZ = cLen;
      if (cb["swapAxes"]) {
        dimX = cLen;
        dimZ = cWid;
      }

      // Flat shaded base quad or box
      gui.drawCube3D(clX, clY + cHgt * 0.18, clZ, dimX, cHgt * 0.36, dimZ, 200, 208, 222);

      // Puffy sunlit mid quads or boxes
      gui.drawCube3D(clX, clY + cHgt * 0.52, clZ, dimX * 0.82, cHgt * 0.44, dimZ * 0.82, 248, 250, 255);
      gui.drawCube3D(clX + dimX * 0.20, clY + cHgt * 0.46, clZ + dimZ * 0.12, dimX * 0.55, cHgt * 0.38, dimZ * 0.55, 248, 250, 255);
      gui.drawCube3D(clX - dimX * 0.22, clY + cHgt * 0.44, clZ - dimZ * 0.14, dimX * 0.52, cHgt * 0.36, dimZ * 0.52, 248, 250, 255);

      // Upper crest quad or box
      gui.drawCube3D(clX + dimX * 0.04, clY + cHgt * 0.78, clZ + dimZ * 0.04, dimX * 0.50, cHgt * 0.34, dimZ * 0.50, 248, 250, 255);
    }
  }

  drawDistantBackdrop(cX, cZ, t) {
    if (t == nil) t = 0.0;
    this.drawCelestialDome(cX, cZ, t);

    if (this.trackId == 0) {
      // SUZUKA GP: Layered Mie mountain silhouettes with depth shading
      // Far Layer: Mount Gozaisho and Suzuka mountain massifs
      this.drawMountainRidge(cX, cZ, 3600.0, 16, 0.0, 6.2831853, 390.0, 150, 36, 52, 78, 22, 34, 56, false);
      // Mid Layer: Highland forested ridges
      this.drawMountainRidge(cX, cZ, 3100.0, 16, 0.20, 6.2831853, 300.0, 145, 28, 58, 50, 18, 42, 36, false);
      // Near Layer: Undulating Japanese highland foothills
      this.drawMountainRidge(cX, cZ, 2600.0, 14, 0.44, 6.2831853, 190.0, 140, 32, 74, 42, 20, 52, 28, false);

    } else if (this.trackId == 1) {
      // SPA GP: Rolling Ardennes valley pine forest ridges
      // Far Layer: Distant Ardennes blue-green ridge
      this.drawMountainRidge(cX, cZ, 3600.0, 18, 0.0, 6.2831853, 350.0, 130, 24, 46, 60, 16, 32, 44, false);
      // Mid Layer: Rolling coniferous valley pine ridge
      this.drawMountainRidge(cX, cZ, 3100.0, 18, 0.18, 6.2831853, 285.0, 130, 22, 56, 36, 14, 40, 26, false);
      // Near Layer: Valley slope pine crowns
      this.drawMountainRidge(cX, cZ, 2600.0, 16, 0.35, 6.2831853, 170.0, 135, 30, 76, 42, 18, 54, 30, false);

    } else if (this.trackId == 2) {
      // MONZA GP: Alpine peaks on the distant northern horizon and royal parkland tree canopies
      // Distant snow-capped Italian Alps on northern horizon
      this.drawMountainRidge(cX, cZ, 3600.0, 10, 2.1, 2.2, 450.0, 160, 138, 148, 170, 92, 102, 126, true);
      // Royal parkland continuous oak tree canopies
      this.drawMountainRidge(cX, cZ, 2600.0, 20, 0.0, 6.2831853, 135.0, 100, 38, 76, 42, 24, 52, 28, false);

    } else {
      // MONACO GP: Mediterranean Sea azure horizon and coastal waters
      gui.drawPlane3D(-1200.0, -2.0, 200.0, 3600.0, 3600.0, 18, 88, 158);
      gui.drawPlane3D(cX - 200.0, -1.2, cZ + 200.0, 1800.0, 1800.0, 22, 102, 172);
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
    this.drawDistantBackdrop(cX, cZ, t);

    // 0a. Port Hercule Harbor Water Basin (Monaco GP)
    if (this.trackId == 3) {
      // Confined Mediterranean harbor water surface inside the quayside basin
      gui.drawPlane3D(200.0, 0.05, 340.0, 180.0, 280.0, 18, 98, 160);

      // Central floating marina pontoon in Port Hercule
      gui.drawCube3D(200.0, 0.45, 340.0, 4.2, 0.7, 130.0, 175, 140, 105);
      gui.drawCube3D(200.0, 0.25, 340.0, 4.8, 0.5, 132.0, 55, 60, 70);
      for (let pz = 285.0; pz <= 395.0; pz += 15.0) {
        gui.drawCylinder3D(200.0, 1.1, pz, 0.06, 0.06, 0.6, 4, 220, 225, 235);
      }
    }

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
      let nx1 = st1["nx"]; let nz1 = st1["nz"];
      let nx2 = st2["nx"]; let nz2 = st2["nz"];
      let tx1 = st1["tx"]; let tz1 = st1["tz"];
      let tx2 = st2["tx"]; let tz2 = st2["tz"];

      // A. Tarmac Surface
      let hw = this.roadWidth * 0.5;
      let rdR = roadCol[0]; let rdG = roadCol[1]; let rdB = roadCol[2];
      let whiteR = 232; let whiteG = 234; let whiteB = 240;

      // Base solid tarmac road quad
      gui.drawQuad3D(st1["rl_x"], y1, st1["rl_z"], st1["rr_x"], y1, st1["rr_z"],
                     st2["rr_x"], y2, st2["rr_z"], st2["rl_x"], y2, st2["rl_z"],
                     rdR, rdG, rdB);

      // Underside soffit and fascia for elevated track sections (eliminates empty space below slopes)
      if (y1 > 0.05 or y2 > 0.05) {
        let deckD = 0.35;
        // Underside soffit
        gui.drawQuad3D(st1["rl_x"], y1 - deckD, st1["rl_z"], st1["rr_x"], y1 - deckD, st1["rr_z"],
                       st2["rr_x"], y2 - deckD, st2["rr_z"], st2["rl_x"], y2 - deckD, st2["rl_z"],
                       36, 38, 44);
        // Left edge fascia
        gui.drawQuad3D(st1["rl_x"], y1, st1["rl_z"], st1["rl_x"], y1 - deckD, st1["rl_z"],
                       st2["rl_x"], y2 - deckD, st2["rl_z"], st2["rl_x"], y2, st2["rl_z"],
                       45, 48, 56);
        // Right edge fascia
        gui.drawQuad3D(st1["rr_x"], y1, st1["rr_z"], st2["rr_x"], y2, st2["rr_z"],
                       st2["rr_x"], y2 - deckD, st2["rr_z"], st1["rr_x"], y1 - deckD, st1["rr_z"],
                       45, 48, 56);
      }

      // White painted edge lines (track boundary limits)
      let edgeW = 0.34;
      gui.drawQuad3D(st1["rl_x"], y1 + 0.004, st1["rl_z"],
                     st1["rl_x"] + edgeW * nx1, y1 + 0.004, st1["rl_z"] + edgeW * nz1,
                     st2["rl_x"] + edgeW * nx2, y2 + 0.004, st2["rl_z"] + edgeW * nz2,
                     st2["rl_x"], y2 + 0.004, st2["rl_z"],
                     whiteR, whiteG, whiteB);
      gui.drawQuad3D(st1["rr_x"] - edgeW * nx1, y1 + 0.004, st1["rr_z"] - edgeW * nz1,
                     st1["rr_x"], y1 + 0.004, st1["rr_z"],
                     st2["rr_x"], y2 + 0.004, st2["rr_z"],
                     st2["rr_x"] - edgeW * nx2, y2 + 0.004, st2["rr_z"] - edgeW * nz2,
                     whiteR, whiteG, whiteB);

      // Dynamic apex-tracking rubbered racing line
      let apexShift1 = -st1["curv"] * 360.0;
      if (apexShift1 < -hw * 0.54) apexShift1 = -hw * 0.54;
      if (apexShift1 > hw * 0.54) apexShift1 = hw * 0.54;
      let apexShift2 = -st2["curv"] * 360.0;
      if (apexShift2 < -hw * 0.54) apexShift2 = -hw * 0.54;
      if (apexShift2 > hw * 0.54) apexShift2 = hw * 0.54;

      let rLineW = 1.35;
      let rDark = 0.70;
      if (math.abs(st1["curv"]) > 0.007) rDark = 0.54;
      let grvR = math.floor(rdR * rDark);
      let grvG = math.floor(rdG * rDark);
      let grvB = math.floor(rdB * rDark);

      gui.drawQuad3D(st1["x"] + (apexShift1 - rLineW) * nx1, y1 + 0.006, st1["z"] + (apexShift1 - rLineW) * nz1,
                     st1["x"] + (apexShift1 + rLineW) * nx1, y1 + 0.006, st1["z"] + (apexShift1 + rLineW) * nz1,
                     st2["x"] + (apexShift2 + rLineW) * nx2, y2 + 0.006, st2["z"] + (apexShift2 + rLineW) * nz2,
                     st2["x"] + (apexShift2 - rLineW) * nx2, y2 + 0.006, st2["z"] + (apexShift2 - rLineW) * nz2,
                     grvR, grvG, grvB);

      // Heavy braking zone tire skid marks
      let s1 = st1["s"];
      let inBrakeZone = false;
      if (this.trackId == 0 and ((s1 >= 440.0 and s1 <= 540.0) or (s1 >= 5530.0 and s1 <= 5640.0) or (s1 >= 8350.0 and s1 <= 8450.0))) inBrakeZone = true;
      else if (this.trackId == 1 and ((s1 >= 150.0 and s1 <= 240.0) or (s1 >= 3120.0 and s1 <= 3220.0) or (s1 >= 10020.0 and s1 <= 10120.0))) inBrakeZone = true;
      else if (this.trackId == 2 and ((s1 >= 880.0 and s1 <= 980.0) or (s1 >= 2720.0 and s1 <= 2820.0) or (s1 >= 6140.0 and s1 <= 6240.0) or (s1 >= 8180.0 and s1 <= 8280.0))) inBrakeZone = true;
      else if (this.trackId == 3 and ((s1 >= 270.0 and s1 <= 360.0) or (s1 >= 1560.0 and s1 <= 1650.0) or (s1 >= 2890.0 and s1 <= 2980.0) or (s1 >= 4760.0 and s1 <= 4850.0))) inBrakeZone = true;

      if (inBrakeZone) {
        let skidW = 0.26;
        let wheelSpacing = 0.78;
        let skL1 = apexShift1 - wheelSpacing;
        let skL2 = apexShift2 - wheelSpacing;
        gui.drawQuad3D(st1["x"] + (skL1 - skidW * 0.5) * nx1, y1 + 0.009, st1["z"] + (skL1 - skidW * 0.5) * nz1,
                       st1["x"] + (skL1 + skidW * 0.5) * nx1, y1 + 0.009, st1["z"] + (skL1 + skidW * 0.5) * nz1,
                       st2["x"] + (skL2 + skidW * 0.5) * nx2, y2 + 0.009, st2["z"] + (skL2 + skidW * 0.5) * nz2,
                       st2["x"] + (skL2 - skidW * 0.5) * nx2, y2 + 0.009, st2["z"] + (skL2 - skidW * 0.5) * nz2,
                       18, 18, 22);
        let skR1 = apexShift1 + wheelSpacing;
        let skR2 = apexShift2 + wheelSpacing;
        gui.drawQuad3D(st1["x"] + (skR1 - skidW * 0.5) * nx1, y1 + 0.009, st1["z"] + (skR1 - skidW * 0.5) * nz1,
                       st1["x"] + (skR1 + skidW * 0.5) * nx1, y1 + 0.009, st1["z"] + (skR1 + skidW * 0.5) * nz1,
                       st2["x"] + (skR2 + skidW * 0.5) * nx2, y2 + 0.009, st2["z"] + (skR2 + skidW * 0.5) * nz2,
                       st2["x"] + (skR2 - skidW * 0.5) * nx2, y2 + 0.009, st2["z"] + (skR2 - skidW * 0.5) * nz2,
                       18, 18, 22);
      }

      // Authentic Formula 1 Starting Grid Slots (20 staggered grid boxes)
      let s2 = s1 + this.segmentLength;
      if (s1 >= lapLen - 225.0 and s1 <= lapLen - 8.0) {
        for (let k = 1; k <= 20; k += 1) {
          let slotS = lapLen - (16.0 + (k - 1) * 10.5);
          if (slotS >= s1 and slotS < s2) {
            let u = (slotS - s1) / (s2 - s1);
            let gx = st1["x"] + u * (st2["x"] - st1["x"]);
            let gy = y1 + u * (y2 - y1) + 0.015;
            let gz = st1["z"] + u * (st2["z"] - st1["z"]);
            let gnx = nx1 + u * (nx2 - nx1);
            let gnz = nz1 + u * (nz2 - nz1);
            let gtx = st1["tx"] + u * (st2["tx"] - st1["tx"]);
            let gtz = st1["tz"] + u * (st2["tz"] - st1["tz"]);
            let mag = math.sqrt(gnx * gnx + gnz * gnz);
            if (mag > 0.001) { gnx = gnx / mag; gnz = gnz / mag; }
            let tmag = math.sqrt(gtx * gtx + gtz * gtz);
            if (tmag > 0.001) { gtx = gtx / tmag; gtz = gtz / tmag; }

            // Staggered grid: odd slots on left (-), even slots on right (+)
            let slotLat = hw * 0.40;
            if (k % 2 == 1) slotLat = -hw * 0.40;
            let cx = gx + slotLat * gnx;
            let cz = gz + slotLat * gnz;

            let bW = 2.4;
            let bL = 4.8;
            let halfBW = bW * 0.5;
            let halfBL = bL * 0.5;

            // 1. Bright Yellow Stop Bar at front of slot
            let fLx = cx - halfBW * gnx + halfBL * gtx;
            let fLz = cz - halfBW * gnz + halfBL * gtz;
            let fRx = cx + halfBW * gnx + halfBL * gtx;
            let fRz = cz + halfBW * gnz + halfBL * gtz;
            let barThick = 0.28;
            let bLx = fLx - barThick * gtx; let bLz = fLz - barThick * gtz;
            let bRx = fRx - barThick * gtx; let bRz = fRz - barThick * gtz;
            gui.drawQuad3D(fLx, gy, fLz, fRx, gy, fRz, bRx, gy, bRz, bLx, gy, bLz, 255, 215, 20);

            // 2. White Side Lines (Left and Right brackets)
            let rLx = cx - halfBW * gnx - halfBL * gtx;
            let rLz = cz - halfBW * gnz - halfBL * gtz;
            let rRx = cx + halfBW * gnx - halfBL * gtx;
            let rRz = cz + halfBW * gnz - halfBL * gtz;
            let lThick = 0.14;
            gui.drawQuad3D(fLx, gy, fLz, fLx + lThick * gnx, gy, fLz + lThick * gnz,
                           rLx + lThick * gnx, gy, rLz + lThick * gnz, rLx, gy, rLz,
                           240, 242, 248);
            gui.drawQuad3D(fRx - lThick * gnx, gy, fRz - lThick * gnz, fRx, gy, fRz,
                           rRx, gy, rRz, rRx - lThick * gnx, gy, rRz - lThick * gnz,
                           240, 242, 248);
            // Rear line
            gui.drawQuad3D(rLx, gy, rLz, rRx, gy, rRz,
                           rRx + barThick * 0.6 * gtx, gy, rRz + barThick * 0.6 * gtz,
                           rLx + barThick * 0.6 * gtx, gy, rLz + barThick * 0.6 * gtz,
                           240, 242, 248);

            // 3. Center Position Marker
            gui.drawQuad3D(cx - 0.20 * gnx - 0.6 * gtx, gy, cz - 0.20 * gnz - 0.6 * gtz,
                           cx + 0.20 * gnx - 0.6 * gtx, gy, cz + 0.20 * gnz - 0.6 * gtz,
                           cx + 0.20 * gnx + 0.6 * gtx, gy, cz + 0.20 * gnz + 0.6 * gtz,
                           cx - 0.20 * gnx + 0.6 * gtx, gy, cz - 0.20 * gnz + 0.6 * gtz,
                           245, 245, 252);
          }
        }
      }

      // Pit Lane Dividing Blend Line (Pit Straight)
      if (s1 >= lapLen - 260.0 or s1 <= 240.0) {
        let pLineOff = hw - 0.65;
        let pLineW = 0.22;
        let pl_x1 = st1["x"] + pLineOff * nx1; let pl_z1 = st1["z"] + pLineOff * nz1;
        let pr_x1 = pl_x1 + pLineW * nx1;      let pr_z1 = pl_z1 + pLineW * nz1;
        let pl_x2 = st2["x"] + pLineOff * nx2; let pl_z2 = st2["z"] + pLineOff * nz2;
        let pr_x2 = pl_x2 + pLineW * nx2;      let pr_z2 = pl_z2 + pLineW * nz2;
        gui.drawQuad3D(pl_x1, y1 + 0.012, pl_z1, pr_x1, y1 + 0.012, pr_z1,
                       pr_x2, y2 + 0.012, pr_z2, pl_x2, y2 + 0.012, pl_z2,
                       245, 245, 252);

        // Chevron hazard lines in pit blend merge zone
        if (i % 2 == 0 and ((s1 >= lapLen - 260.0 and s1 <= lapLen - 190.0) or (s1 >= 140.0 and s1 <= 230.0))) {
          let chX1 = pl_x1; let chZ1 = pl_z1;
          let chX2 = pl_x1 + 1.6 * nx1 - 1.2 * st1["tx"];
          let chZ2 = pl_z1 + 1.6 * nz1 - 1.2 * st1["tz"];
          gui.drawQuad3D(chX1, y1 + 0.014, chZ1, chX1 + 0.18 * nx1, y1 + 0.014, chZ1 + 0.18 * nz1,
                         chX2 + 0.18 * nx1, y1 + 0.014, chZ2 + 0.18 * nz1, chX2, y1 + 0.014, chZ2,
                         255, 215, 25);
        }
      }

      // A2. Checkered start / finish band across the road.
      if (i == 0) {
        let tiles = 16;
        let tileW = (hw * 2.0) / tiles;
        let finishLen = 1.4;
        for (let q = 0; q < tiles; q += 1) {
          let aOff = -hw + q * tileW;
          let bOff = aOff + tileW;
          let qR = 20; let qG = 22; let qB = 28;
          if (q % 2 == 0) { qR = 235; qG = 236; qB = 242; }
          gui.drawQuad3D(st1["x"] + aOff * nx1, y1 + 0.016, st1["z"] + aOff * nz1,
                         st1["x"] + bOff * nx1, y1 + 0.016, st1["z"] + bOff * nz1,
                         st1["x"] + bOff * nx1 + finishLen * tx1, y1 + 0.016, st1["z"] + bOff * nz1 + finishLen * tz1,
                         st1["x"] + aOff * nx1 + finishLen * tx1, y1 + 0.016, st1["z"] + aOff * nz1 + finishLen * tz1,
                         qR, qG, qB);
        }
      }

      // D. National Formula 1 Rumble Curbs
      let isCornerCurb = (math.abs(st1["curv"]) > 0.0035 or math.abs(st2["curv"]) > 0.0035);
      if (isCornerCurb) {
        let cR = 196; let cG = 198; let cB = 206;
        if (this.trackId == 2) {
          // Monza: Italian Tricolore (Green, White, Red)
          let mMod = i % 3;
          if (mMod == 0) { cR = 25; cG = 145; cB = 60; }
          else if (mMod == 1) { cR = 242; cG = 244; cB = 248; }
          else { cR = 220; cG = 32; cB = 38; }
        } else if (this.trackId == 1) {
          // Spa-Francorchamps: Belgian Tricolore (Black, Yellow, Red)
          let sMod = i % 3;
          if (sMod == 0) { cR = 25; cG = 25; cB = 28; }
          else if (sMod == 1) { cR = 248; cG = 212; cB = 24; }
          else { cR = 220; cG = 32; cB = 38; }
        } else if (this.trackId == 3) {
          // Monaco: Swimming Pool chicane aprons (Yellow & Cyan), red/white elsewhere
          if (s1 >= 4450.0 and s1 <= 4620.0) {
            if (i % 2 == 0) { cR = 25; cG = 140; cB = 220; }
            else { cR = 248; cG = 212; cB = 24; }
          } else {
            if (i % 2 == 0) { cR = 225; cG = 35; cB = 40; }
            else { cR = 242; cG = 244; cB = 248; }
          }
        } else {
          // Suzuka: Red and White
          if (i % 2 == 0) { cR = 225; cG = 35; cB = 40; }
          else { cR = 242; cG = 244; cB = 248; }
        }

        if (st1["curbL"] > 0.2 and st2["curbL"] > 0.2) {
          gui.drawQuad3D(st1["cl_x"], y1 + 0.045, st1["cl_z"], st1["rl_x"], y1 + 0.045, st1["rl_z"],
                         st2["rl_x"], y2 + 0.045, st2["rl_z"], st2["cl_x"], y2 + 0.045, st2["cl_z"],
                         cR, cG, cB);
          if (this.trackId == 0) {
            let astroW = 1.35;
            gui.drawQuad3D(st1["cl_x"] - astroW * nx1, y1 + 0.040, st1["cl_z"] - astroW * nz1,
                           st1["cl_x"], y1 + 0.040, st1["cl_z"],
                           st2["cl_x"], y2 + 0.040, st2["cl_z"],
                           st2["cl_x"] - astroW * nx2, y2 + 0.040, st2["cl_z"] - astroW * nz2,
                           26, 120, 45);
          }
        }

        if (st1["curbR"] > 0.2 and st2["curbR"] > 0.2) {
          gui.drawQuad3D(st1["rr_x"], y1 + 0.045, st1["rr_z"], st1["cr_x"], y1 + 0.045, st1["cr_z"],
                         st2["cr_x"], y2 + 0.045, st2["cr_z"], st2["rr_x"], y2 + 0.045, st2["rr_z"],
                         cR, cG, cB);
          if (this.trackId == 0) {
            let astroW = 1.35;
            gui.drawQuad3D(st1["cr_x"], y1 + 0.040, st1["cr_z"],
                           st1["cr_x"] + astroW * nx1, y1 + 0.040, st1["cr_z"] + astroW * nz1,
                           st2["cr_x"] + astroW * nx2, y2 + 0.040, st2["cr_z"] + astroW * nz2,
                           st2["cr_x"], y2 + 0.040, st2["cr_z"],
                           26, 120, 45);
          }
        }
      }

      // E. Runoff / Pedestrian Sidewalks
      if (this.trackId == 3) {
        // MONACO GP: Light-grey urban concrete pedestrian sidewalks on both sides
        let swR = 165; let swG = 170; let swB = 180;
        let cL1_x = st1["cl_x"]; let cL1_z = st1["cl_z"];
        let cL2_x = st2["cl_x"]; let cL2_z = st2["cl_z"];
        if (st1["curbL"] <= 0.2) { cL1_x = st1["rl_x"]; cL1_z = st1["rl_z"]; }
        if (st2["curbL"] <= 0.2) { cL2_x = st2["rl_x"]; cL2_z = st2["rl_z"]; }
        gui.drawQuad3D(st1["ol_x"], y1 - 0.01, st1["ol_z"], cL1_x, y1 - 0.01, cL1_z,
                       cL2_x, y2 - 0.01, cL2_z, st2["ol_x"], y2 - 0.01, st2["ol_z"],
                       swR, swG, swB);

        let cR1_x = st1["cr_x"]; let cR1_z = st1["cr_z"];
        let cR2_x = st2["cr_x"]; let cR2_z = st2["cr_z"];
        if (st1["curbR"] <= 0.2) { cR1_x = st1["rr_x"]; cR1_z = st1["rr_z"]; }
        if (st2["curbR"] <= 0.2) { cR2_x = st2["rr_x"]; cR2_z = st2["rr_z"]; }
        gui.drawQuad3D(cR1_x, y1 - 0.01, cR1_z, st1["or_x"], y1 - 0.01, st1["or_z"],
                       st2["or_x"], y2 - 0.01, st2["or_z"], cR2_x, y2 - 0.01, cR2_z,
                       swR, swG, swB);
      } else {
        // Road Circuits: gravel on corners, green grass on open straights, blue high-friction bands
        let isHighCurv = (math.abs(st1["curv"]) > 0.012 and math.abs(st2["curv"]) > 0.010);
        let runR = gravelCol[0]; let runG = gravelCol[1]; let runB = gravelCol[2];
        if (isHighCurv and i % 2 == 1) { runR = 28; runG = 88; runB = 205; }

        let cL1_x = st1["cl_x"]; let cL1_z = st1["cl_z"];
        let cL2_x = st2["cl_x"]; let cL2_z = st2["cl_z"];
        if (st1["curbL"] <= 0.2) { cL1_x = st1["rl_x"]; cL1_z = st1["rl_z"]; }
        if (st2["curbL"] <= 0.2) { cL2_x = st2["rl_x"]; cL2_z = st2["rl_z"]; }

        let cR1_x = st1["cr_x"]; let cR1_z = st1["cr_z"];
        let cR2_x = st2["cr_x"]; let cR2_z = st2["cr_z"];
        if (st1["curbR"] <= 0.2) { cR1_x = st1["rr_x"]; cR1_z = st1["rr_z"]; }
        if (st2["curbR"] <= 0.2) { cR2_x = st2["rr_x"]; cR2_z = st2["rr_z"]; }

        if (st1["runL"] and st2["runL"]) {
          let leftColR = runR; let leftColG = runG; let leftColB = runB;
          if (!st1["hasWallL"] and !st2["hasWallL"] and math.abs(st1["curv"]) < 0.007) {
            leftColR = grassCol[0]; leftColG = grassCol[1]; leftColB = grassCol[2];
          }
          gui.drawQuad3D(st1["ol_x"], y1 - 0.02, st1["ol_z"], cL1_x, y1 - 0.02, cL1_z,
                         cL2_x, y2 - 0.02, cL2_z, st2["ol_x"], y2 - 0.02, st2["ol_z"],
                         leftColR, leftColG, leftColB);
        }
        if (st1["runR"] and st2["runR"]) {
          let rightColR = runR; let rightColG = runG; let rightColB = runB;
          if (!st1["hasWallR"] and !st2["hasWallR"] and math.abs(st1["curv"]) < 0.007) {
            rightColR = grassCol[0]; rightColG = grassCol[1]; rightColB = grassCol[2];
          }
          gui.drawQuad3D(cR1_x, y1 - 0.02, cR1_z, st1["or_x"], y1 - 0.02, st1["or_z"],
                         st2["or_x"], y2 - 0.02, st2["or_z"], cR2_x, y2 - 0.02, cR2_z,
                         rightColR, rightColG, rightColB);
        }
      }

      // E2. Grass Embankments / Suzuka Overpass / Monaco Tunnel
      let sMid = st1["s"];
      let isSuzukaBridge = (this.trackId == 0 and sMid >= 7290.0 and sMid <= 7644.0);
      let isSuzukaUnderpass = (this.trackId == 0 and sMid >= 3640.0 and sMid <= 3780.0);
      let isMonacoTunnel = (this.trackId == 3 and sMid >= 2720.0 and sMid <= 3570.0);

      if (isSuzukaBridge) {
        // A. Reinforced concrete deck fascia along both elevated edges
        let deckD = 1.65;
        gui.drawQuad3D(st1["ol_x"], y1, st1["ol_z"], st1["ol_x"], y1 - deckD, st1["ol_z"],
                       st2["ol_x"], y2 - deckD, st2["ol_z"], st2["ol_x"], y2, st2["ol_z"],
                       56, 62, 74);
        gui.drawQuad3D(st1["or_x"], y1, st1["or_z"], st2["or_x"], y2, st2["or_z"],
                       st2["or_x"], y2 - deckD, st2["or_z"], st1["or_x"], y1 - deckD, st1["or_z"],
                       56, 62, 74);

        // B. Structural steel underside visible from the underpass cutting
        gui.drawQuad3D(st1["ol_x"], y1 - deckD, st1["ol_z"], st1["or_x"], y1 - deckD, st1["or_z"],
                       st2["or_x"], y2 - deckD, st2["or_z"], st2["ol_x"], y2 - deckD, st2["ol_z"],
                       42, 46, 56);

        // C. Catch-fence safety mesh upright posts along the bridge
        if (i % 2 == 0) {
          gui.drawCylinder3D(st1["ol_x"], y1 + 2.3, st1["ol_z"], 0.08, 0.08, 2.3, 4, 185, 190, 200);
          gui.drawCylinder3D(st1["or_x"], y1 + 2.3, st1["or_z"], 0.08, 0.08, 2.3, 4, 185, 190, 200);
        }

        // D. Solid abutment end caps at bridge approaches
        if (sMid < 7296.0 or sMid > 7638.0) {
          gui.drawQuad3D(st1["ol_x"], y1, st1["ol_z"], st1["or_x"], y1, st1["or_z"],
                         st1["or_x"], y1 - deckD, st1["or_z"], st1["ol_x"], y1 - deckD, st1["ol_z"],
                         48, 54, 65);
        }

        // E. Twin massive portal piers straddling the lower track
        if (i == 1227 or i == 1259) {
          let pierH = y1;
          gui.drawCube3D(st1["ol_x"], pierH * 0.5, st1["ol_z"], 3.2, pierH, 4.8, 62, 68, 80);
          gui.drawCube3D(st1["or_x"], pierH * 0.5, st1["or_z"], 3.2, pierH, 4.8, 62, 68, 80);
          gui.drawCube3D(st1["ol_x"], pierH - 0.25, st1["ol_z"], 3.8, 0.5, 5.2, 52, 58, 70);
          gui.drawCube3D(st1["or_x"], pierH - 0.25, st1["or_z"], 3.8, 0.5, 5.2, 52, 58, 70);
        }
      } else if (isSuzukaUnderpass) {
        // Cutting retaining walls diving beneath the bridge
        let retH = 2.8;
        gui.drawQuad3D(st1["ol_x"], y1, st1["ol_z"], st1["ol_x"], y1 + retH, st1["ol_z"],
                       st2["ol_x"], y2 + retH, st2["ol_z"], st2["ol_x"], y2, st2["ol_z"],
                       52, 58, 70);
        gui.drawQuad3D(st1["or_x"], y1, st1["or_z"], st1["or_x"], y1 + retH, st1["or_z"],
                       st2["or_x"], y2 + retH, st2["or_z"], st2["or_x"], y2, st2["or_z"],
                       52, 58, 70);
      } else if (isMonacoTunnel) {
        // Formula 1 Monaco Tunnel Realism
        let tunH = 5.2;

        // 1. Vaulted Concrete Ceiling
        gui.drawQuad3D(st1["ol_x"], y1 + tunH, st1["ol_z"], st1["or_x"], y1 + tunH, st1["or_z"],
                       st2["or_x"], y2 + tunH, st2["or_z"], st2["ol_x"], y2 + tunH, st2["ol_z"],
                       45, 48, 56);

        // 2. Continuous Overhead Warm Fluorescent Tubes (Dual Rows)
        let tubeL_x1 = st1["x"] - hw * 0.45 * nx1; let tubeL_z1 = st1["z"] - hw * 0.45 * nz1;
        let tubeL_x2 = st2["x"] - hw * 0.45 * nx2; let tubeL_z2 = st2["z"] - hw * 0.45 * nz2;
        let tubeR_x1 = st1["x"] + hw * 0.45 * nx1; let tubeR_z1 = st1["z"] + hw * 0.45 * nz1;
        let tubeR_x2 = st2["x"] + hw * 0.45 * nx2; let tubeR_z2 = st2["z"] + hw * 0.45 * nz2;
        let tw = 0.22;
        gui.drawQuad3D(tubeL_x1 - tw * nx1, y1 + tunH - 0.08, tubeL_z1 - tw * nz1,
                       tubeL_x1 + tw * nx1, y1 + tunH - 0.08, tubeL_z1 + tw * nz1,
                       tubeL_x2 + tw * nx2, y2 + tunH - 0.08, tubeL_z2 + tw * nz2,
                       tubeL_x2 - tw * nx2, y2 + tunH - 0.08, tubeL_z2 - tw * nz2,
                       255, 215, 90);
        gui.drawQuad3D(tubeR_x1 - tw * nx1, y1 + tunH - 0.08, tubeR_z1 - tw * nz1,
                       tubeR_x1 + tw * nx1, y1 + tunH - 0.08, tubeR_z1 + tw * nz1,
                       tubeR_x2 + tw * nx2, y2 + tunH - 0.08, tubeR_z2 + tw * nz2,
                       tubeR_x2 - tw * nx2, y2 + tunH - 0.08, tubeR_z2 - tw * nz2,
                       255, 215, 90);

        // 3. Mountain-side Wall (Left): Acoustic ceramic tile bands
        let tileR = 195;
        let tileG = 200;
        let tileB = 210;
        if (i % 2 == 0) {
          tileR = 175;
          tileG = 180;
          tileB = 190;
        }
        gui.drawQuad3D(st1["ol_x"], y1, st1["ol_z"], st1["ol_x"], y1 + tunH, st1["ol_z"],
                       st2["ol_x"], y2 + tunH, st2["ol_z"], st2["ol_x"], y2, st2["ol_z"],
                       tileR, tileG, tileB);

        // Emergency Alcoves (every 6 stations)
        if (i % 6 == 0) {
          gui.drawCube3D(st1["ol_x"] - 0.4 * nx1, y1 + 1.8, st1["ol_z"] - 0.4 * nz1, 0.4, 1.4, 1.2, 220, 30, 35);
          gui.drawCube3D(st1["ol_x"] - 0.4 * nx1, y1 + 2.8, st1["ol_z"] - 0.4 * nz1, 0.3, 0.5, 0.8, 30, 195, 75);
        }

        // 4. Seaside Portico Colonnade (Right): Massive concrete pillars open to harbor & yachts
        if (i % 2 == 0) {
          gui.drawCube3D(st1["or_x"], y1 + tunH * 0.5, st1["or_z"], 1.6, tunH, 2.2, 72, 78, 88);
        }
        // Top lintel beam connecting pillars
        gui.drawQuad3D(st1["or_x"], y1 + tunH, st1["or_z"], st1["or_x"], y1 + tunH - 0.8, st1["or_z"],
                       st2["or_x"], y2 + tunH - 0.8, st2["or_z"], st2["or_x"], y2 + tunH, st2["or_z"],
                       60, 65, 75);

        // 5. Reflective Cat's-Eye Centerline Studs
        gui.drawSphere3D(st1["x"], y1 + 0.05, st1["z"], 0.12, 255, 225, 110);

        // 6. Tunnel Portals at Entry and Exit with solid transverse bulkhead capping
        if (sMid >= 2720.0 and sMid <= 2732.0) {
          // Entry Portal Arch
          this.drawOrientedBox(st1["x"], y1 + tunH + 0.9, st1["z"], this.roadWidth + 7.0, 1.8, 2.2, nx1, nz1, tx1, tz1, 65, 70, 82);
          this.drawOrientedBox(st1["x"] - 1.15 * tx1, y1 + tunH + 0.9, st1["z"] - 1.15 * tz1, this.roadWidth * 0.65, 0.8, 0.2, nx1, nz1, tx1, tz1, 245, 210, 25);
          gui.drawQuad3D(st1["or_x"], y1 + tunH, st1["or_z"],
                         st1["ol_x"], y1 + tunH, st1["ol_z"],
                         st1["ol_x"], y1 + tunH + 2.4, st1["ol_z"],
                         st1["or_x"], y1 + tunH + 2.4, st1["or_z"],
                         65, 70, 82);
        } else if (sMid >= 3558.0 and sMid <= 3570.0) {
          // Exit Portal Arch
          this.drawOrientedBox(st1["x"], y1 + tunH + 0.9, st1["z"], this.roadWidth + 7.0, 1.8, 2.2, nx1, nz1, tx1, tz1, 65, 70, 82);
          gui.drawQuad3D(st2["ol_x"], y2 + tunH, st2["ol_z"],
                         st2["or_x"], y2 + tunH, st2["or_z"],
                         st2["or_x"], y2 + tunH + 2.4, st2["or_z"],
                         st2["ol_x"], y2 + tunH + 2.4, st2["ol_z"],
                         65, 70, 82);
        }

        // Retaining walls down to ground plane y = -0.2
        if (y1 > 0.0 or y2 > 0.0) {
          gui.drawQuad3D(st1["ol_x"], y1, st1["ol_z"],
                         st1["ol_x"] - 0.4 * nx1, -0.2, st1["ol_z"] - 0.4 * nz1,
                         st2["ol_x"] - 0.4 * nx2, -0.2, st2["ol_z"] - 0.4 * nz2,
                         st2["ol_x"], y2, st2["ol_z"],
                         140, 135, 130);
          gui.drawQuad3D(st1["or_x"], y1, st1["or_z"],
                         st2["or_x"], y2, st2["or_z"],
                         st2["or_x"] + 0.4 * nx2, -0.2, st2["or_z"] + 0.4 * nz2,
                         st1["or_x"] + 0.4 * nx1, -0.2, st1["or_z"] + 0.4 * nz1,
                         140, 135, 130);
        }
      } else {
        if (this.trackId == 3) {
          // MONACO GP: Authentic city street circuit sidewalks and solid retaining foundations
          let swR = 165; let swG = 170; let swB = 180;
          let apronW = 4.0;
          let apL1_x = st1["ol_x"] - apronW * nx1; let apL1_z = st1["ol_z"] - apronW * nz1;
          let apL2_x = st2["ol_x"] - apronW * nx2; let apL2_z = st2["ol_z"] - apronW * nz2;
          gui.drawQuad3D(st1["ol_x"], y1 - 0.01, st1["ol_z"],
                         apL1_x, y1 - 0.01, apL1_z,
                         apL2_x, y2 - 0.01, apL2_z,
                         st2["ol_x"], y2 - 0.01, st2["ol_z"],
                         swR, swG, swB);

          let apR1_x = st1["or_x"] + apronW * nx1; let apR1_z = st1["or_z"] + apronW * nz1;
          let apR2_x = st2["or_x"] + apronW * nx2; let apR2_z = st2["or_z"] + apronW * nz2;
          gui.drawQuad3D(st1["or_x"], y1 - 0.01, st1["or_z"],
                         st2["or_x"], y2 - 0.01, st2["or_z"],
                         apR2_x, y2 - 0.01, apR2_z,
                         apR1_x, y1 - 0.01, apR1_z,
                         swR, swG, swB);

          // Solid stone foundation retaining walls eliminating all empty space beneath slopes
          if (y1 > 0.0 or y2 > 0.0) {
            gui.drawQuad3D(apL1_x, y1 - 0.01, apL1_z,
                           apL1_x, -0.2, apL1_z,
                           apL2_x, -0.2, apL2_z,
                           apL2_x, y2 - 0.01, apL2_z,
                           140, 135, 130);
            gui.drawQuad3D(apR1_x, y1 - 0.01, apR1_z,
                           apR2_x, y2 - 0.01, apR2_z,
                           apR2_x, -0.2, apR2_z,
                           apR1_x, -0.2, apR1_z,
                           140, 135, 130);
          }
        } else {
          // Road circuits: Suzuka, Spa, Monza
          let grassPattern = (math.floor(i / 4)) % 2;
          let gR = math.floor(grassCol[0] * 1.25 + 6);
          let gG = math.floor(grassCol[1] * 1.28 + 12);
          let gB = math.floor(grassCol[2] * 1.22 + 5);
          if (grassPattern == 0) {
            gR = grassCol[0];
            gG = grassCol[1];
            gB = grassCol[2];
          }

          if (st1["embOkL"] and st2["embOkL"]) {
            gui.drawQuad3D(st1["ol_x"], y1 - 0.02, st1["ol_z"],
                           st1["el_x"], y1 - 0.02, st1["el_z"],
                           st2["el_x"], y2 - 0.02, st2["el_z"],
                           st2["ol_x"], y2 - 0.02, st2["ol_z"],
                           gR, gG, gB);
          }
          if (st1["embOkR"] and st2["embOkR"]) {
            gui.drawQuad3D(st1["or_x"], y1 - 0.02, st1["or_z"],
                           st2["or_x"], y2 - 0.02, st2["or_z"],
                           st2["er_x"], y2 - 0.02, st2["er_z"],
                           st1["er_x"], y1 - 0.02, st1["er_z"],
                           gR, gG, gB);
          }

          // Solid ground embankments connecting outer edges down to ground plane y = -0.2
          if (!isSuzukaBridge and (y1 > 0.0 or y2 > 0.0)) {
            let slopeW1_L = st1["slopeL"]; if (slopeW1_L == nil) slopeW1_L = 8.0;
            let slopeW2_L = st2["slopeL"]; if (slopeW2_L == nil) slopeW2_L = 8.0;
            let slopeW1_R = st1["slopeR"]; if (slopeW1_R == nil) slopeW1_R = 8.0;
            let slopeW2_R = st2["slopeR"]; if (slopeW2_R == nil) slopeW2_R = 8.0;

            if (st1["embOkL"] and st2["embOkL"]) {
              let embR = math.floor(grassCol[0] * 0.72);
              let embG = math.floor(grassCol[1] * 0.72);
              let embB = math.floor(grassCol[2] * 0.72);
              if (grassPattern == 0) {
                embR = math.floor(grassCol[0] * 0.65);
                embG = math.floor(grassCol[1] * 0.65);
                embB = math.floor(grassCol[2] * 0.65);
              }

              let exL1 = st1["el_x"]; let ezL1 = st1["el_z"];
              let exL2 = st2["el_x"]; let ezL2 = st2["el_z"];
              let fxL1 = exL1 - slopeW1_L * nx1; let fzL1 = ezL1 - slopeW1_L * nz1;
              let fxL2 = exL2 - slopeW2_L * nx2; let fzL2 = ezL2 - slopeW2_L * nz2;

              gui.drawQuad3D(exL1, y1 - 0.02, ezL1,
                             fxL1, -0.2, fzL1,
                             fxL2, -0.2, fzL2,
                             exL2, y2 - 0.02, ezL2,
                             embR, embG, embB);
            }

            if (st1["embOkR"] and st2["embOkR"]) {
              let embR = math.floor(grassCol[0] * 0.72);
              let embG = math.floor(grassCol[1] * 0.72);
              let embB = math.floor(grassCol[2] * 0.72);
              if (grassPattern == 0) {
                embR = math.floor(grassCol[0] * 0.65);
                embG = math.floor(grassCol[1] * 0.65);
                embB = math.floor(grassCol[2] * 0.65);
              }

              let exR1 = st1["er_x"]; let ezR1 = st1["er_z"];
              let exR2 = st2["er_x"]; let ezR2 = st2["er_z"];
              let fxR1 = exR1 + slopeW1_R * nx1; let fzR1 = ezR1 + slopeW1_R * nz1;
              let fxR2 = exR2 + slopeW2_R * nx2; let fzR2 = ezR2 + slopeW2_R * nz2;

              gui.drawQuad3D(exR1, y1 - 0.02, ezR1,
                             exR2, y2 - 0.02, ezR2,
                             fxR2, -0.2, fzR2,
                             fxR1, -0.2, fzR1,
                             embR, embG, embB);
            }
          }
        }
      }

      // Underside bottom quad for all elevated track sections to eliminate hollow floating road gaps
      if (!isSuzukaBridge and (y1 > 0.0 or y2 > 0.0)) {
        gui.drawQuad3D(st1["ol_x"], y1 - 0.04, st1["ol_z"],
                       st2["ol_x"], y2 - 0.04, st2["ol_z"],
                       st2["or_x"], y2 - 0.04, st2["or_z"],
                       st1["or_x"], y1 - 0.04, st1["or_z"],
                       42, 45, 52);
      }

      // F. Concrete Perimeter Barriers (Rendered ONLY outside tunnels where hasWall is true)
      let bH = 1.25;

      if (!isMonacoTunnel) {
        // Left Barrier & Sponsor Boards
        if (st1["hasWallL"] and st2["hasWallL"]) {
          gui.drawQuad3D(st1["ol_x"], y1, st1["ol_z"], st1["ol_x"], y1 + bH, st1["ol_z"],
                         st2["ol_x"], y2 + bH, st2["ol_z"], st2["ol_x"], y2, st2["ol_z"],
                         barCol[0], barCol[1], barCol[2]);

          let topR = barTopCol[0]; let topG = barTopCol[1]; let topB = barTopCol[2];
          if ((math.floor(i / 3)) % 2 == 1) { topR = 242; topG = 243; topB = 248; }
          gui.drawQuad3D(st1["ol_x"], y1 + bH, st1["ol_z"], st1["ol_x"] + 0.28 * nx1, y1 + bH, st1["ol_z"] + 0.28 * nz1,
                         st2["ol_x"] + 0.28 * nx2, y2 + bH, st2["ol_z"] + 0.28 * nz2, st2["ol_x"], y2 + bH, st2["ol_z"],
                         topR, topG, topB);

          if (i % 4 == 0) {
            let sponIdx = (math.floor(i / 4)) % 5;
            let sR = 12; let sG = 75; let sB = 42; // Rolex Green
            if (sponIdx == 1) { sR = 245; sG = 210; sB = 25; } // Pirelli Yellow
            else if (sponIdx == 2) { sR = 0; sG = 165; sB = 215; } // Aramco Cyan
            else if (sponIdx == 3) { sR = 215; sG = 30; sB = 40; } // Shell Crimson
            else if (sponIdx == 4) { sR = 0; sG = 160; sB = 140; } // Petronas Teal

            gui.drawQuad3D(st1["ol_x"] + 0.04 * nx1, y1 + 0.15, st1["ol_z"] + 0.04 * nz1,
                           st1["ol_x"] + 0.04 * nx1, y1 + 1.10, st1["ol_z"] + 0.04 * nz1,
                           st2["ol_x"] + 0.04 * nx2, y2 + 1.10, st2["ol_z"] + 0.04 * nz2,
                           st2["ol_x"] + 0.04 * nx2, y2 + 0.15, st2["ol_z"] + 0.04 * nz2,
                           sR, sG, sB);
          }
        } else if (st1["hasWallL"] and !st2["hasWallL"]) {
          // Wall termination end cap
          gui.drawQuad3D(st1["ol_x"], y1, st1["ol_z"],
                         st1["ol_x"] + 0.28 * nx1, y1, st1["ol_z"] + 0.28 * nz1,
                         st1["ol_x"] + 0.28 * nx1, y1 + bH, st1["ol_z"] + 0.28 * nz1,
                         st1["ol_x"], y1 + bH, st1["ol_z"],
                         barCol[0], barCol[1], barCol[2]);
        } else if (!st1["hasWallL"] and st2["hasWallL"]) {
          // Wall starting end cap
          gui.drawQuad3D(st2["ol_x"] + 0.28 * nx2, y2, st2["ol_z"] + 0.28 * nz2,
                         st2["ol_x"], y2, st2["ol_z"],
                         st2["ol_x"], y2 + bH, st2["ol_z"],
                         st2["ol_x"] + 0.28 * nx2, y2 + bH, st2["ol_z"] + 0.28 * nz2,
                         barCol[0], barCol[1], barCol[2]);
        }

        // Right Barrier & Sponsor Boards
        if (st1["hasWallR"] and st2["hasWallR"]) {
          gui.drawQuad3D(st1["or_x"], y1, st1["or_z"], st1["or_x"], y1 + bH, st1["or_z"],
                         st2["or_x"], y2 + bH, st2["or_z"], st2["or_x"], y2, st2["or_z"],
                         barCol[0], barCol[1], barCol[2]);

          let topR = barTopCol[0]; let topG = barTopCol[1]; let topB = barTopCol[2];
          if ((math.floor(i / 3)) % 2 == 1) { topR = 242; topG = 243; topB = 248; }
          gui.drawQuad3D(st1["or_x"] - 0.28 * nx1, y1 + bH, st1["or_z"] - 0.28 * nz1, st1["or_x"], y1 + bH, st1["or_z"],
                         st2["or_x"], y2 + bH, st2["or_z"], st2["or_x"] - 0.28 * nx2, y2 + bH, st2["or_z"] - 0.28 * nz2,
                         topR, topG, topB);

          if (i % 4 == 0) {
            let sponIdx = (math.floor(i / 4)) % 5;
            let sR = 12; let sG = 75; let sB = 42; // Rolex Green
            if (sponIdx == 1) { sR = 245; sG = 210; sB = 25; } // Pirelli Yellow
            else if (sponIdx == 2) { sR = 0; sG = 165; sB = 215; } // Aramco Cyan
            else if (sponIdx == 3) { sR = 215; sG = 30; sB = 40; } // Shell Crimson
            else if (sponIdx == 4) { sR = 0; sG = 160; sB = 140; } // Petronas Teal

            gui.drawQuad3D(st2["or_x"] - 0.04 * nx2, y2 + 0.15, st2["or_z"] - 0.04 * nz2,
                           st2["or_x"] - 0.04 * nx2, y2 + 1.10, st2["or_z"] - 0.04 * nz2,
                           st1["or_x"] - 0.04 * nx1, y1 + 1.10, st1["or_z"] - 0.04 * nz1,
                           st1["or_x"] - 0.04 * nx1, y1 + 0.15, st1["or_z"] - 0.04 * nz1,
                           sR, sG, sB);
          }
        } else if (st1["hasWallR"] and !st2["hasWallR"]) {
          // Wall termination end cap
          gui.drawQuad3D(st1["or_x"] - 0.28 * nx1, y1, st1["or_z"] - 0.28 * nz1,
                         st1["or_x"], y1, st1["or_z"],
                         st1["or_x"], y1 + bH, st1["or_z"],
                         st1["or_x"] - 0.28 * nx1, y1 + bH, st1["or_z"] - 0.28 * nz1,
                         barCol[0], barCol[1], barCol[2]);
        } else if (!st1["hasWallR"] and st2["hasWallR"]) {
          // Wall starting end cap
          gui.drawQuad3D(st2["or_x"], y2, st2["or_z"],
                         st2["or_x"] - 0.28 * nx2, y2, st2["or_z"] - 0.28 * nz2,
                         st2["or_x"] - 0.28 * nx2, y2 + bH, st2["or_z"] - 0.28 * nz2,
                         st2["or_x"], y2 + bH, st2["or_z"],
                         barCol[0], barCol[1], barCol[2]);
        }
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
                       85, 92, 105);

        // Team Pit Perch / Telemetry Timing Stand every 6 segments
        if (i % 6 == 0 and i > 5 and i < numStations - 10) {
          let standX = st1["rr_x"] + 1.8 * pNx1;
          let standZ = st1["rr_z"] + 1.8 * pNz1;
          this.drawOrientedBox(standX, y1 + 1.3, standZ, 2.2, 1.8, 3.2, pNx1, pNz1, tx1, tz1, 45, 52, 65);
          this.drawOrientedBox(standX, y1 + 2.3, standZ, 2.4, 0.25, 3.4, pNx1, pNz1, tx1, tz1, 180, 40, 48);
          // Glowing Telemetry Screens
          this.drawOrientedBox(standX - 0.8 * pNx1, y1 + 1.5, standZ - 0.8 * pNz1, 0.2, 0.6, 2.4, pNx1, pNz1, tx1, tz1, 0, 230, 255);
        }
      }

      // G. Start / Finish Line Checkered Gantry Arch & 5 F1 Starting Lights at Station 0
      if (i == 0) {
        let archH = 9.0;
        let halfSpan = (this.roadWidth + 5.5) * 0.5;
        let towL_x = st1["x"] - halfSpan * nx1; let towL_z = st1["z"] - halfSpan * nz1;
        let towR_x = st1["x"] + halfSpan * nx1; let towR_z = st1["z"] + halfSpan * nz1;
        // Heavy steel portal towers oriented perpendicular to track
        this.drawOrientedBox(towL_x, y1 + archH * 0.5, towL_z, 1.6, archH, 1.8, nx1, nz1, tx1, tz1, 35, 45, 65);
        this.drawOrientedBox(towR_x, y1 + archH * 0.5, towR_z, 1.6, archH, 1.8, nx1, nz1, tx1, tz1, 35, 45, 65);
        // Main overhead gantry beam spanning the track perpendicular to road
        this.drawOrientedBox(st1["x"], y1 + archH, st1["z"], halfSpan * 2.0 + 1.6, 1.6, 2.0, nx1, nz1, tx1, tz1, 45, 55, 75);
        // Circuit Name & FIA Sponsor Plaque on incoming side
        this.drawOrientedBox(st1["x"] - 1.05 * tx1, y1 + archH + 1.1, st1["z"] - 1.05 * tz1, this.roadWidth * 0.65, 0.8, 0.35, nx1, nz1, tx1, tz1, 225, 35, 45);
        // Central Digital Timing LED display
        this.drawOrientedBox(st1["x"] - 1.10 * tx1, y1 + archH - 0.7, st1["z"] - 1.10 * tz1, 3.2, 0.75, 0.25, nx1, nz1, tx1, tz1, 15, 18, 25);
        this.drawOrientedBox(st1["x"] - 1.20 * tx1, y1 + archH - 0.7, st1["z"] - 1.20 * tz1, 2.8, 0.5, 0.10, nx1, nz1, tx1, tz1, 255, 190, 40);

        // 5 Official Formula 1 Starting Lights
        let lightSpacing = 2.2;
        for (let lt = -2; lt <= 2; lt += 1) {
          let lxPos = st1["x"] + lt * lightSpacing * nx1;
          let lzPos = st1["z"] + lt * lightSpacing * nz1;
          this.drawOrientedBox(lxPos, y1 + archH - 1.5, lzPos, 0.65, 1.3, 0.35, nx1, nz1, tx1, tz1, 15, 18, 25);
          gui.drawSphere3D(lxPos - 0.22 * tx1, y1 + archH - 1.7, lzPos - 0.22 * tz1, 0.30, 255, 30, 35);
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
        else if (kind == "building") assets.playBuildingModel(p["var"], p["x"], p["y"], p["z"], p["scale"], p["rot"]);
        else if (kind == "tent") assets.playTent(0, p["x"], p["y"], p["z"], p["scale"], p["rot"], pr, pg, pb);
        else if (kind == "fenceStraight") assets.playFenceStraight(p["x"], p["y"], p["z"], p["scale"], p["rot"]);
        else if (kind == "barrier") assets.playBarrier(p["var"], p["x"], p["y"], p["z"], p["scale"], p["rot"]);
        else if (kind == "brakeBoard") {
          // 3D Distance Countdown Marker Board (150m, 100m, 50m)
          let bx = p["x"]; let by = p["y"]; let bz = p["z"];
          let val = p["val"];
          let pNx = p["nx"]; let pNz = p["nz"];
          let pTx = p["tx"]; let pTz = p["tz"];
          if (pNx == nil) { pNx = 0.0; pNz = 1.0; pTx = 1.0; pTz = 0.0; }

          // Stanchion Mast
          gui.drawCylinder3D(bx, by + 1.1, bz, 0.08, 0.08, 2.2, 4, 30, 35, 45);
          // White Board Face oriented to incoming driver
          this.drawOrientedBox(bx, by + 2.0, bz, 1.4, 1.8, 0.15, pNx, pNz, pTx, pTz, 245, 245, 250);
          // Bold Red Distance Stripes on incoming face (3 for 150, 2 for 100, 1 for 50)
          let sOff = -0.09;
          if (val == 150) {
            this.drawOrientedBox(bx + sOff * pTx, by + 2.4, bz + sOff * pTz, 1.0, 0.22, 0.05, pNx, pNz, pTx, pTz, 225, 30, 35);
            this.drawOrientedBox(bx + sOff * pTx, by + 2.0, bz + sOff * pTz, 1.0, 0.22, 0.05, pNx, pNz, pTx, pTz, 225, 30, 35);
            this.drawOrientedBox(bx + sOff * pTx, by + 1.6, bz + sOff * pTz, 1.0, 0.22, 0.05, pNx, pNz, pTx, pTz, 225, 30, 35);
          } else if (val == 100) {
            this.drawOrientedBox(bx + sOff * pTx, by + 2.2, bz + sOff * pTz, 1.0, 0.26, 0.05, pNx, pNz, pTx, pTz, 225, 30, 35);
            this.drawOrientedBox(bx + sOff * pTx, by + 1.7, bz + sOff * pTz, 1.0, 0.26, 0.05, pNx, pNz, pTx, pTz, 225, 30, 35);
          } else {
            this.drawOrientedBox(bx + sOff * pTx, by + 2.0, bz + sOff * pTz, 1.0, 0.45, 0.05, pNx, pNz, pTx, pTz, 225, 30, 35);
          }
        } else if (kind == "yacht" or kind == "superyacht") {
          // Luxury Superyachts in Port Hercule
          let yx = p["x"]; let yy = p["y"]; let yz = p["z"];
          let yVar = p["var"];
          if (yVar == nil) yVar = 0;

          if (yVar == 1) {
            // Sailing yacht with tall masts and rigging
            gui.drawCube3D(yx, yy + 0.3, yz, 4.2, 2.0, 22.0, 25, 35, 58); // Navy hull
            gui.drawCube3D(yx, yy + 1.35, yz, 4.0, 0.1, 21.0, 180, 145, 105); // Teak deck
            gui.drawCube3D(yx, yy + 2.0, yz - 1.0, 2.6, 1.0, 8.0, 245, 245, 250); // Deckhouse
            // Tall main mast (22m tall) & cross-trees
            gui.drawCylinder3D(yx, yy + 11.5, yz + 2.0, 0.12, 0.20, 21.0, 4, 210, 205, 195);
            gui.drawCube3D(yx, yy + 14.0, yz + 2.0, 2.8, 0.12, 0.15, 215, 215, 225); // Cross-tree spreaders
            // Mizzen mast (14m tall)
            gui.drawCylinder3D(yx, yy + 7.5, yz - 6.0, 0.10, 0.16, 13.0, 4, 210, 205, 195);
            // Furled white sail canvas along booms
            gui.drawCube3D(yx, yy + 3.2, yz + 4.5, 0.35, 0.6, 6.0, 248, 246, 240);
            gui.drawCube3D(yx, yy + 2.8, yz - 8.0, 0.30, 0.5, 4.5, 248, 246, 240);
          } else if (yVar == 2) {
            // Flagship Mega Yacht (4-deck vessel)
            gui.drawCube3D(yx, yy + 0.8, yz, 7.5, 3.0, 32.0, 35, 42, 55); // Hull
            gui.drawCube3D(yx, yy + 2.35, yz, 7.2, 0.1, 31.0, 180, 145, 105); // Teak deck
            gui.drawCube3D(yx, yy + 3.4, yz - 2.0, 6.2, 2.0, 22.0, 245, 248, 252); // Main superstructure
            gui.drawCube3D(yx, yy + 3.4, yz - 1.0, 6.3, 1.3, 18.0, 20, 26, 38); // Dark tinted windows
            gui.drawCube3D(yx, yy + 5.2, yz - 4.0, 5.0, 1.6, 14.0, 245, 248, 252); // Bridge deck
            gui.drawCube3D(yx, yy + 5.2, yz - 3.5, 5.1, 1.0, 11.0, 20, 26, 38); // Bridge windows
            gui.drawCube3D(yx, yy + 6.6, yz - 5.0, 4.0, 1.2, 8.0, 245, 248, 252); // Top sun deck
            // Quad satellite communication radomes
            gui.drawSphere3D(yx - 1.2, yy + 7.6, yz - 5.0, 0.55, 255, 255, 255);
            gui.drawSphere3D(yx + 1.2, yy + 7.6, yz - 5.0, 0.55, 255, 255, 255);
            gui.drawSphere3D(yx, yy + 8.2, yz - 6.5, 0.60, 255, 255, 255);
          } else {
            // 3-Deck Luxury Motor Yacht (White hull, tinted windows, flying bridge, radar domes)
            gui.drawCube3D(yx, yy + 0.4, yz, 5.5, 2.2, 24.0, 242, 245, 252); // White hull
            gui.drawCube3D(yx, yy - 0.4, yz, 5.0, 1.2, 22.0, 28, 45, 75); // Dark hull bottom
            gui.drawCube3D(yx, yy + 1.55, yz, 5.3, 0.1, 23.0, 180, 145, 105); // Teak deck
            // Main salon with wraparound tinted windows
            gui.drawCube3D(yx, yy + 2.5, yz - 2.0, 4.4, 1.8, 14.0, 245, 248, 252);
            gui.drawCube3D(yx, yy + 2.5, yz - 1.5, 4.5, 1.2, 12.0, 22, 28, 42); // Tinted glass
            // Upper bridge deck
            gui.drawCube3D(yx, yy + 4.0, yz - 3.0, 3.6, 1.4, 9.0, 245, 248, 252);
            gui.drawCube3D(yx, yy + 4.0, yz - 2.5, 3.7, 0.9, 7.0, 22, 28, 42); // Tinted glass
            // Flying bridge / sun deck with Bimini top
            gui.drawCube3D(yx, yy + 5.2, yz - 4.0, 3.0, 1.0, 5.5, 240, 242, 248);
            // Radar mast and twin satellite communication domes
            gui.drawCylinder3D(yx, yy + 6.2, yz - 4.5, 0.08, 0.08, 1.6, 4, 210, 215, 225);
            gui.drawSphere3D(yx - 0.7, yy + 6.6, yz - 4.5, 0.45, 252, 252, 255);
            gui.drawSphere3D(yx + 0.7, yy + 6.6, yz - 4.5, 0.45, 252, 252, 255);
            // Stern swim platform
            gui.drawCube3D(yx, yy + 0.4, yz + 12.6, 4.5, 0.3, 1.8, 180, 145, 105);
          }
        } else if (kind == "monacoCasino") {
          // The Grand Casino de Monte Carlo (Beaux-Arts facade, dual domed corner towers, marble portico, red carpet, palm plaza)
          let cx = p["x"]; let cy = p["y"]; let cz = p["z"];
          let pNx = p["nx"]; let pNz = p["nz"];
          let pTx = p["tx"]; let pTz = p["tz"];
          if (pNx == nil) { pNx = 1.0; pNz = 0.0; pTx = 0.0; pTz = 1.0; }

          // Beaux-Arts limestone palace facade
          this.drawOrientedBox(cx, cy + 9.0, cz, 22.0, 18.0, 46.0, pNx, pNz, pTx, pTz, 236, 230, 218);
          // Pediment and central entrance arch
          this.drawOrientedBox(cx, cy + 19.5, cz, 22.4, 3.0, 18.0, pNx, pNz, pTx, pTz, 242, 238, 226);
          this.drawOrientedBox(cx, cy + 21.5, cz, 22.5, 1.8, 12.0, pNx, pNz, pTx, pTz, 230, 225, 212);
          // Dual corner domed towers
          let tw1_x = cx - 19.0 * pTx; let tw1_z = cz - 19.0 * pTz;
          let tw2_x = cx + 19.0 * pTx; let tw2_z = cz + 19.0 * pTz;
          this.drawOrientedBox(tw1_x, cy + 20.0, tw1_z, 8.0, 4.0, 8.0, pNx, pNz, pTx, pTz, 225, 220, 210);
          this.drawOrientedBox(tw2_x, cy + 20.0, tw2_z, 8.0, 4.0, 8.0, pNx, pNz, pTx, pTz, 225, 220, 210);
          gui.drawSphere3D(tw1_x, cy + 23.5, tw1_z, 4.2, 62, 148, 118);
          gui.drawSphere3D(tw2_x, cy + 23.5, tw2_z, 4.2, 62, 148, 118);
          // Grand marble entrance portico
          this.drawOrientedBox(cx, cy + 5.0, cz, 26.0, 10.0, 20.0, pNx, pNz, pTx, pTz, 248, 246, 242);
        } else if (kind == "hotelDeParis") {
          // Hotel de Paris Monte-Carlo (Belle Epoque palace facade, French balconies, Mansard roof)
          let hx = p["x"]; let hy = p["y"]; let hz = p["z"];
          let pNx = p["nx"]; let pNz = p["nz"];
          let pTx = p["tx"]; let pTz = p["tz"];
          if (pNx == nil) { pNx = 1.0; pNz = 0.0; pTx = 0.0; pTz = 1.0; }

          this.drawOrientedBox(hx, hy + 11.0, hz, 24.0, 22.0, 42.0, pNx, pNz, pTx, pTz, 245, 240, 228);
          // Mansard roof
          this.drawOrientedBox(hx, hy + 23.5, hz, 22.0, 3.5, 40.0, pNx, pNz, pTx, pTz, 75, 82, 95);
          // Continuous French balconies
          for (let fl = 1; fl <= 4; fl += 1) {
            let flY = hy + 6.0 + (fl - 1) * 4.5;
            this.drawOrientedBox(hx, flY, hz, 25.0, 0.9, 38.0, pNx, pNz, pTx, pTz, 235, 230, 218);
          }
        } else if (kind == "fairmontHotel") {
          // The Fairmont Hotel (6-story modern luxury hotel wrapping around Turn 6 Lowes Hairpin)
          let fx = p["x"]; let fy = p["y"]; let fz = p["z"];
          let pNx = p["nx"]; let pNz = p["nz"];
          let pTx = p["tx"]; let pTz = p["tz"];
          if (pNx == nil) { pNx = 1.0; pNz = 0.0; pTx = 0.0; pTz = 1.0; }

          this.drawOrientedBox(fx, fy + 12.0, fz, 28.0, 24.0, 44.0, pNx, pNz, pTx, pTz, 232, 228, 220);
          // Tiered spectator balconies on 6 levels
          for (let bl = 1; bl <= 6; bl += 1) {
            let bY = fy + bl * 4.0;
            this.drawOrientedBox(fx, bY, fz, 29.5, 1.0, 42.0, pNx, pNz, pTx, pTz, 245, 242, 238);
          }
        } else if (kind == "sainteDevote") {
          // Sainte-Devote Church (Turn 1 Gaumates ravine stone chapel with bell tower)
          let sx = p["x"]; let sy = p["y"]; let sz = p["z"];
          let pNx = p["nx"]; let pNz = p["nz"];
          let pTx = p["tx"]; let pTz = p["tz"];
          if (pNx == nil) { pNx = 1.0; pNz = 0.0; pTx = 0.0; pTz = 1.0; }

          this.drawOrientedBox(sx, sy + 5.0, sz, 14.0, 10.0, 20.0, pNx, pNz, pTx, pTz, 220, 210, 192);
          this.drawOrientedBox(sx, sy + 10.8, sz, 15.0, 2.0, 20.8, pNx, pNz, pTx, pTz, 185, 78, 48);
          let twX = sx - 6.0 * pTx; let twZ = sz - 6.0 * pTz;
          this.drawOrientedBox(twX, sy + 9.5, twZ, 4.5, 19.0, 4.5, pNx, pNz, pTx, pTz, 215, 205, 188);
          gui.drawSphere3D(twX, sy + 20.5, twZ, 1.5, 185, 78, 48);
        } else if (kind == "swimmingPool") {
          // Rainier III Nautical Stadium (Olympic Swimming Pool with turquoise water and diving tower)
          let px = p["x"]; let py = p["y"]; let pz = p["z"];
          gui.drawCube3D(px, py + 0.4, pz, 30.0, 0.8, 56.0, 242, 244, 248);
          gui.drawCube3D(px, py + 0.5, pz, 22.0, 0.6, 48.0, 28, 185, 225);
          gui.drawCube3D(px - 11.0, py + 6.0, pz - 16.0, 2.2, 12.0, 3.2, 245, 248, 252);
        } else if (kind == "rascasseBar") {
          // La Rascasse Bar & Restaurant (outdoor terrace, red umbrellas, harbor railings)
          let rx = p["x"]; let ry = p["y"]; let rz = p["z"];
          let pNx = p["nx"]; let pNz = p["nz"];
          let pTx = p["tx"]; let pTz = p["tz"];
          if (pNx == nil) { pNx = 1.0; pNz = 0.0; pTx = 0.0; pTz = 1.0; }

          this.drawOrientedBox(rx, ry + 4.5, rz, 16.0, 9.0, 18.0, pNx, pNz, pTx, pTz, 215, 120, 95);
          this.drawOrientedBox(rx, ry + 4.5, rz, 18.0, 0.5, 17.5, pNx, pNz, pTx, pTz, 235, 230, 220);
        } else if (kind == "monacoBuilding") {
          // Monegasque High-Rise Apartment Buildings aligned with street curvature
          let mx = p["x"]; let my = p["y"]; let mz = p["z"];
          let mVar = p["var"];
          if (mVar == nil) mVar = 0;
          let pNx = p["nx"]; let pNz = p["nz"];
          let pTx = p["tx"]; let pTz = p["tz"];
          if (pNx == nil) { pNx = 1.0; pNz = 0.0; pTx = 0.0; pTz = 1.0; }

          let bH = 22.0 + (mVar % 4) * 5.5; // 5 to 10 stories
          let bW = 16.0; // depth perpendicular to street
          let bD = 24.0; // length along street tangent
          let bR = 208; let bG = 108; let bB = 76; // Terracotta
          if (mVar == 1) { bR = 242; bG = 235; bB = 220; } // Warm cream
          else if (mVar == 2) { bR = 236; bG = 164; bB = 134; } // Peach
          else if (mVar == 3) { bR = 232; bG = 196; bB = 126; } // Mediterranean yellow
          else if (mVar == 4) { bR = 224; bG = 168; bB = 168; } // Rose

          // Main apartment block oriented with street tangent
          this.drawOrientedBox(mx, my + bH * 0.5, mz, bW, bH, bD, pNx, pNz, pTx, pTz, bR, bG, bB);
          // Ground floor entrance lobby
          this.drawOrientedBox(mx, my + 2.0, mz, bW + 0.3, 3.8, bD + 0.3, pNx, pNz, pTx, pTz, 45, 52, 65);
          // Floor balconies and dark window bands
          let numFl = math.floor((bH - 5.0) / 3.8);
          for (let fl = 1; fl <= numFl; fl += 1) {
            let flY = my + 3.8 + fl * 3.8;
            this.drawOrientedBox(mx, flY, mz, bW + 0.8, 0.5, bD - 1.5, pNx, pNz, pTx, pTz, 245, 245, 250);
            this.drawOrientedBox(mx, flY + 0.6, mz, bW + 0.9, 0.7, bD - 1.8, pNx, pNz, pTx, pTz, 60, 65, 75);
          }
          // Penthouse roof structure
          this.drawOrientedBox(mx, my + bH + 1.5, mz, bW - 3.0, 3.0, bD - 4.0, pNx, pNz, pTx, pTz, 240, 238, 232);
        } else if (kind == "limestoneCliff") {
          // Towering Alpine Maritime Limestone Cliffs (Tete de Chien / Mont Agel)
          let lx = p["x"]; let ly = p["y"]; let lz = p["z"];
          let clH = 160.0;
          gui.drawCube3D(lx, ly + clH * 0.5, lz, 48.0, clH, 48.0, 185, 180, 172);
          gui.drawCube3D(lx + 12.0, ly + clH * 0.6, lz - 8.0, 36.0, clH * 0.8, 36.0, 165, 160, 152);
          gui.drawCube3D(lx - 10.0, ly + clH * 0.4, lz + 10.0, 32.0, clH * 0.6, 32.0, 145, 140, 134);
          gui.drawCylinder3D(lx, ly + clH + 10.0, lz, 4.0, 22.0, 20.0, 5, 195, 190, 182);
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
