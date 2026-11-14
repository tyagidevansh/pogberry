// PB SPORTS F1 25, Visual In-Game Track Editor
use "pb_gui" as gui;
use "std.math" as math;
use "math_util" as mu;
use "constants" as const;
use "f1_data" as f1;
use "track_io" as io;
use "track" as track_mod;
use "car" as car_mod;
use "camera" as cam_mod;

export fun calculateTrackLength(nodes) {
  let N = len(nodes);
  if (N < 2) return 1000.0;
  let total = 0.0;
  for (let i = 0; i < N; i += 1) {
    let nextI = (i + 1) % N;
    let dx = nodes[nextI][0] - nodes[i][0];
    let dz = nodes[nextI][1] - nodes[i][1];
    total = total + math.sqrt(dx * dx + dz * dz);
  }
  return total * 1.05;
}

export class TrackEditor {
  init(assets, audioMgr) {
    this.assets = assets;
    this.audioMgr = audioMgr;

    this.w = gui.getScreenWidth();
    this.h = gui.getScreenHeight();
    if (this.w < 800) this.w = 800;
    if (this.h < 600) this.h = 600;

    this.sidebarWidth = 320;
    this.canvasW = this.w - this.sidebarWidth;
    this.canvasH = this.h;

    this.panX = 0.0;
    this.panZ = 0.0;
    this.zoom = 0.45;
    this.isPanning = false;
    this.panStartMouseX = 0;
    this.panStartMouseY = 0;
    this.panStartPanX = 0.0;
    this.panStartPanZ = 0.0;

    this.activeTab = 0; // 0: CIRCUIT, 1: ELEVATION, 2: TUNNELS, 3: PROPS
    this.selectedNode = 0;
    this.isDraggingNode = false;
    this.selectedPropType = "grandstandCovered";

    this.trackDef = nil;
    this.trackId = 4;
    this.filename = "custom_track.json";
    this.statusMessage = "Track Editor Ready";
    this.statusTimer = 3.0;

    // Test drive sub-engine
    this.isTestDriving = false;
    this.testTrack = nil;
    this.testCar = nil;
    this.testCam = nil;
    this.testLapTime = 0.0;

    // Initial default blank track
    this.createNewTrack("NEW CIRCUIT");
  }

  updateDimensions() {
    this.w = gui.getScreenWidth();
    this.h = gui.getScreenHeight();
    if (this.w < 800) this.w = 800;
    if (this.h < 600) this.h = 600;
    this.canvasW = this.w - this.sidebarWidth;
    this.canvasH = this.h;
  }

  createNewTrack(name) {
    let cleanId = io.cleanIdentifier(name);
    let defaultNodes = [
      [-300.0, -200.0],
      [ 300.0, -200.0],
      [ 380.0,  -50.0],
      [ 220.0,  150.0],
      [   0.0,  260.0],
      [-240.0,  180.0],
      [-360.0,    0.0]
    ];
    let calcLen = calculateTrackLength(defaultNodes);
    this.trackDef = {
      "version": 1,
      "id": cleanId,
      "name": name,
      "subtitle": "User Created Custom Circuit",
      "difficulty": "PRO RACER",
      "laps": 3,
      "length": calcLen,
      "roadWidth": 22.0,
      "curbWidth": 1.6,
      "runoffWidth": 3.5,
      "skyColor": [35, 110, 215],
      "skyTop": [20, 80, 190],
      "skyBottom": [160, 210, 245],
      "railColorA": [255, 60, 80],
      "railColorB": [255, 210, 40],
      "roadR": 48, "roadG": 50, "roadB": 58,
      "curbR": 235, "curbG": 40, "curbB": 48,
      "groundColor": [38, 105, 42],
      "nodes": defaultNodes,
      "elevations": [
        { "s": 0.0, "y": 2.0 },
        { "s": calcLen * 0.35, "y": 8.0 },
        { "s": calcLen * 0.70, "y": 1.5 }
      ],
      "tunnels": [],
      "props": []
    };
    this.filename = cleanId + ".json";
    this.selectedNode = 0;
    this.syncTrackDef();
    this.centerView();
    this.setStatus("Created new track: " + name);
  }

  loadTrack(def, filename) {
    this.trackDef = def;
    if (filename != nil) this.filename = filename;
    else this.filename = io.cleanIdentifier(def["name"]) + ".json";
    if (this.trackDef["nodes"] == nil or len(this.trackDef["nodes"]) < 3) {
      this.createNewTrack("RESTORED CIRCUIT");
      return;
    }
    this.selectedNode = 0;
    this.syncTrackDef();
    this.centerView();
    this.setStatus("Loaded: " + def["name"]);
  }

  syncTrackDef() {
    let nodes = this.trackDef["nodes"];
    let calcLen = calculateTrackLength(nodes);
    this.trackDef["length"] = calcLen;
    this.trackId = const.registerCustomTrack(this.trackDef);
  }

  centerView() {
    let nodes = this.trackDef["nodes"];
    let minX = 999999.0; let maxX = -999999.0;
    let minZ = 999999.0; let maxZ = -999999.0;
    for (let i = 0; i < len(nodes); i += 1) {
      let nx = nodes[i][0]; let nz = nodes[i][1];
      if (nx < minX) minX = nx;
      if (nx > maxX) maxX = nx;
      if (nz < minZ) minZ = nz;
      if (nz > maxZ) maxZ = nz;
    }
    this.panX = (minX + maxX) * 0.5;
    this.panZ = (minZ + maxZ) * 0.5;
    let spanX = maxX - minX + 120.0;
    let spanZ = maxZ - minZ + 120.0;
    if (spanX < 200.0) spanX = 200.0;
    if (spanZ < 200.0) spanZ = 200.0;
    let zX = this.canvasW / spanX;
    let zZ = this.canvasH / spanZ;
    this.zoom = math.min(zX, zZ);
    if (this.zoom < 0.15) this.zoom = 0.15;
    if (this.zoom > 1.2) this.zoom = 1.2;
  }

  setStatus(msg) {
    this.statusMessage = msg;
    this.statusTimer = 3.5;
  }

  worldToScreen(wx, wz) {
    let cx = this.canvasW * 0.5;
    let cy = this.canvasH * 0.5;
    let sx = cx + (wx - this.panX) * this.zoom;
    let sy = cy + (wz - this.panZ) * this.zoom;
    return [sx, sy];
  }

  screenToWorld(sx, sy) {
    let cx = this.canvasW * 0.5;
    let cy = this.canvasH * 0.5;
    let wx = this.panX + (sx - cx) / this.zoom;
    let wz = this.panZ + (sy - cy) / this.zoom;
    return [wx, wz];
  }

  saveTrack() {
    this.syncTrackDef();
    io.saveTrackFile(this.filename, this.trackDef);
    this.setStatus("Saved to custom_tracks/" + this.filename);
  }

  forkCurrentTrack() {
    let forked = io.forkTrack(this.trackId, this.trackDef["name"] + " COPY");
    if (forked != nil) {
      this.loadTrack(forked["trackDef"], forked["filename"]);
      this.setStatus("Forked into: " + forked["filename"]);
    }
  }

  startTestDrive() {
    this.syncTrackDef();
    this.testTrack = track_mod.Track(this.trackId);
    this.testCar = car_mod.Vehicle(0, true, "PLAYER", 0.0);
    this.testCam = cam_mod.ChaseCamera();
    this.testLapTime = 0.0;
    this.isTestDriving = true;
    this.setStatus("Test Drive Started. Press ESC to exit.");
  }

  stopTestDrive() {
    this.isTestDriving = false;
    this.testTrack = nil;
    this.testCar = nil;
    this.testCam = nil;
    this.setStatus("Returned to Track Editor");
  }

  update(dt) {
    this.updateDimensions();
    if (this.statusTimer > 0.0) {
      this.statusTimer = this.statusTimer - dt;
    }

    if (this.isTestDriving) {
      if (gui.isKeyPressed("KEY_ESCAPE")) {
        this.stopTestDrive();
        return "EDITOR";
      }
      this.updateTestDrive(dt);
      return "TEST_DRIVE";
    }

    // Hotkey actions
    if (gui.isKeyPressed("KEY_T")) {
      this.startTestDrive();
      return "TEST_DRIVE";
    }
    if (gui.isKeyPressed("KEY_ESCAPE")) {
      return "EXIT";
    }
    if (gui.isKeyPressed("KEY_DELETE") or gui.isKeyPressed("KEY_BACKSPACE")) {
      this.deleteSelectedNode();
    }
    if (gui.isKeyPressed("KEY_S")) {
      this.saveTrack();
    }

    let mX = gui.getMouseX();
    let mY = gui.getMouseY();
    let wheel = gui.getMouseWheelMove();

    // Canvas Mouse Interactions
    if (mX < this.canvasW) {
      // Mouse Wheel Zoom
      if (wheel != 0) {
        let prevWorld = this.screenToWorld(mX, mY);
        let factor = 1.0 + wheel * 0.12;
        this.zoom = mu.clamp(this.zoom * factor, 0.12, 3.5);
        let newWorld = this.screenToWorld(mX, mY);
        this.panX = this.panX - (newWorld[0] - prevWorld[0]);
        this.panZ = this.panZ - (newWorld[1] - prevWorld[1]);
      }

      // Right Mouse Drag Pan
      if (gui.isMouseButtonPressed("RIGHT")) {
        this.isPanning = true;
        this.panStartMouseX = mX;
        this.panStartMouseY = mY;
        this.panStartPanX = this.panX;
        this.panStartPanZ = this.panZ;
      }
      if (this.isPanning) {
        if (gui.isMouseButtonDown("RIGHT")) {
          let dx = (mX - this.panStartMouseX) / this.zoom;
          let dz = (mY - this.panStartMouseY) / this.zoom;
          this.panX = this.panStartPanX - dx;
          this.panZ = this.panStartPanZ - dz;
        } else {
          this.isPanning = false;
        }
      }

      // Left Mouse Node Select / Drag
      let nodes = this.trackDef["nodes"];
      if (gui.isMouseButtonPressed("LEFT")) {
        let hitNode = -1;
        for (let i = 0; i < len(nodes); i += 1) {
          let sp = this.worldToScreen(nodes[i][0], nodes[i][1]);
          let dx = mX - sp[0];
          let dy = mY - sp[1];
          if (dx * dx + dy * dy <= 16.0 * 16.0) {
            hitNode = i;
            break;
          }
        }
        if (hitNode >= 0) {
          this.selectedNode = hitNode;
          this.isDraggingNode = true;
        } else if (this.activeTab == 3) {
          // Prop placement tool in props tab
          let wPos = this.screenToWorld(mX, mY);
          this.addPropAtWorldPos(wPos[0], wPos[1]);
        }
      }

      if (this.isDraggingNode) {
        if (gui.isMouseButtonDown("LEFT")) {
          let wPos = this.screenToWorld(mX, mY);
          nodes[this.selectedNode][0] = math.floor(wPos[0] * 2.0) * 0.5;
          nodes[this.selectedNode][1] = math.floor(wPos[1] * 2.0) * 0.5;
          this.syncTrackDef();
        } else {
          this.isDraggingNode = false;
        }
      }
    }

    return "EDITOR";
  }

  updateTestDrive(dt) {
    this.testLapTime = this.testLapTime + dt;
    this.testCar.updatePlayer(dt, this.testTrack, nil, nil);
    this.testCam.update(this.testCar, this.testTrack, dt);
  }

  addNodeAfterSelected() {
    let nodes = this.trackDef["nodes"];
    let N = len(nodes);
    let nextIdx = (this.selectedNode + 1) % N;
    let midX = (nodes[this.selectedNode][0] + nodes[nextIdx][0]) * 0.5;
    let midZ = (nodes[this.selectedNode][1] + nodes[nextIdx][1]) * 0.5;

    let newNodes = [];
    for (let i = 0; i < N; i += 1) {
      newNodes.push([nodes[i][0], nodes[i][1]]);
      if (i == this.selectedNode) {
        newNodes.push([midX, midZ]);
      }
    }
    this.trackDef["nodes"] = newNodes;
    this.selectedNode = this.selectedNode + 1;
    this.syncTrackDef();
    this.setStatus("Added node #" + str(this.selectedNode));
  }

  deleteSelectedNode() {
    let nodes = this.trackDef["nodes"];
    let N = len(nodes);
    if (N <= 3) {
      this.setStatus("Circuit requires at least 3 nodes!");
      return;
    }
    let newNodes = [];
    for (let i = 0; i < N; i += 1) {
      if (i != this.selectedNode) {
        newNodes.push([nodes[i][0], nodes[i][1]]);
      }
    }
    this.trackDef["nodes"] = newNodes;
    if (this.selectedNode >= len(newNodes)) this.selectedNode = 0;
    this.syncTrackDef();
    this.setStatus("Deleted node");
  }

  smoothNodes() {
    let nodes = this.trackDef["nodes"];
    let N = len(nodes);
    let smoothed = [];
    for (let i = 0; i < N; i += 1) {
      let prevI = (i - 1 + N) % N;
      let nextI = (i + 1) % N;
      let sx = (nodes[prevI][0] + nodes[i][0] * 2.0 + nodes[nextI][0]) * 0.25;
      let sz = (nodes[prevI][1] + nodes[i][1] * 2.0 + nodes[nextI][1]) * 0.25;
      smoothed.push([sx, sz]);
    }
    this.trackDef["nodes"] = smoothed;
    this.syncTrackDef();
    this.setStatus("Curvature smoothed");
  }

  addPropAtWorldPos(wx, wz) {
    if (this.trackDef["props"] == nil) this.trackDef["props"] = [];
    let pList = this.trackDef["props"];
    let lapLen = this.trackDef["length"];
    let numSamples = 120;
    let bestDistSq = 99999999.0;
    let bestS = 0.0;
    let bestOffset = 0.0;

    for (let i = 0; i < numSamples; i += 1) {
      let s = (i / numSamples) * lapLen;
      let pt = f1.getTrackWorldPoint(this.trackId, s);
      let tan = f1.getTrackTangent(this.trackId, s);
      let mag = math.sqrt(tan[0] * tan[0] + tan[1] * tan[1]);
      if (mag < 0.001) mag = 1.0;
      let nx = -tan[1] / mag;
      let nz = tan[0] / mag;
      let dx = wx - pt[0];
      let dz = wz - pt[1];
      let dSq = dx * dx + dz * dz;
      if (dSq < bestDistSq) {
        bestDistSq = dSq;
        bestS = s;
        bestOffset = dx * nx + dz * nz;
      }
    }

    let minClearance = this.trackDef["roadWidth"] * 0.5 + this.trackDef["curbWidth"] + 2.0;
    if (math.abs(bestOffset) < minClearance) {
      if (bestOffset >= 0.0) bestOffset = minClearance + 4.0;
      else bestOffset = -minClearance - 4.0;
    }

    pList.push({
      "type": this.selectedPropType,
      "s": bestS,
      "offset": bestOffset,
      "scale": 1.0,
      "yaw": 0.0,
      "variant": 0
    });
    this.syncTrackDef();
    this.setStatus("Placed " + this.selectedPropType);
  }

  draw(t) {
    if (this.isTestDriving) {
      this.drawTestDrive(t);
      return;
    }

    // 1. Canvas Background & Coordinate Grid
    gui.drawRectangle(0, 0, this.canvasW, this.canvasH, 16, 20, 28);
    this.drawGrid();

    // 2. Track Spline (Road, Kerbs, Runoff, Start Line)
    this.drawTrackSpline();

    // 3. Scenery Props on Canvas
    this.drawProps();

    // 4. Control Points (Nodes) & Tangents
    this.drawNodes(t);

    // 5. Canvas Overlay Indicators (Zoom, Scale, Status, Shortcuts)
    this.drawCanvasOverlay();

    // 6. Sidebar Tools & Panels
    this.drawSidebar(t);
  }

  drawGrid() {
    let gridSize = 100.0; // 100 meters
    let pMin = this.screenToWorld(0, 0);
    let pMax = this.screenToWorld(this.canvasW, this.canvasH);

    let startX = math.floor(math.min(pMin[0], pMax[0]) / gridSize) * gridSize;
    let endX = math.ceil(math.max(pMin[0], pMax[0]) / gridSize) * gridSize;
    let startZ = math.floor(math.min(pMin[1], pMax[1]) / gridSize) * gridSize;
    let endZ = math.ceil(math.max(pMin[1], pMax[1]) / gridSize) * gridSize;

    for (let gx = startX; gx <= endX; gx += gridSize) {
      let sp1 = this.worldToScreen(gx, startZ);
      let sp2 = this.worldToScreen(gx, endZ);
      gui.drawLine(sp1[0], sp1[1], sp2[0], sp2[1], 28, 34, 46);
    }
    for (let gz = startZ; gz <= endZ; gz += gridSize) {
      let sp1 = this.worldToScreen(startX, gz);
      let sp2 = this.worldToScreen(endX, gz);
      gui.drawLine(sp1[0], sp1[1], sp2[0], sp2[1], 28, 34, 46);
    }
  }

  drawTrackSpline() {
    let lapLen = this.trackDef["length"];
    if (lapLen <= 10.0) return;

    let numSteps = 320;
    let hw = (this.trackDef["roadWidth"] * 0.5) * this.zoom;
    let cw = (this.trackDef["curbWidth"]) * this.zoom;
    let rw = (this.trackDef["runoffWidth"]) * this.zoom;

    let roadCol = [48, 50, 60];
    if (this.trackDef["roadR"] != nil) roadCol = [this.trackDef["roadR"], this.trackDef["roadG"], this.trackDef["roadB"]];
    let curbCol = [230, 40, 50];
    if (this.trackDef["curbR"] != nil) curbCol = [this.trackDef["curbR"], this.trackDef["curbG"], this.trackDef["curbB"]];

    let prevLeft = nil;
    let prevRight = nil;
    let prevCurbL = nil;
    let prevCurbR = nil;

    for (let i = 0; i <= numSteps; i += 1) {
      let s = (i / numSteps) * lapLen;
      let pt = f1.getTrackWorldPoint(this.trackId, s);
      let tan = f1.getTrackTangent(this.trackId, s);
      let mag = math.sqrt(tan[0] * tan[0] + tan[1] * tan[1]);
      if (mag < 0.0001) mag = 1.0;
      let nx = -tan[1] / mag;
      let nz = tan[0] / mag;

      let spCenter = this.worldToScreen(pt[0], pt[1]);
      let spL = [spCenter[0] - nx * hw, spCenter[1] - nz * hw];
      let spR = [spCenter[0] + nx * hw, spCenter[1] + nz * hw];
      let spCL = [spCenter[0] - nx * (hw + cw), spCenter[1] - nz * (hw + cw)];
      let spCR = [spCenter[0] + nx * (hw + cw), spCenter[1] + nz * (hw + cw)];

      if (prevLeft != nil) {
        // Road surface
        gui.drawLine(spL[0], spL[1], spR[0], spR[1], roadCol[0], roadCol[1], roadCol[2]);
        gui.drawLine(prevLeft[0], prevLeft[1], spL[0], spL[1], 120, 125, 140);
        gui.drawLine(prevRight[0], prevRight[1], spR[0], spR[1], 120, 125, 140);

        // Curbs
        let cPattern = (math.floor(i / 2)) % 2;
        let cR = curbCol[0]; let cG = curbCol[1]; let cB = curbCol[2];
        if (cPattern == 1) { cR = 240; cG = 240; cB = 245; }
        gui.drawLine(spL[0], spL[1], spCL[0], spCL[1], cR, cG, cB);
        gui.drawLine(spR[0], spR[1], spCR[0], spCR[1], cR, cG, cB);
      }

      prevLeft = spL;
      prevRight = spR;
      prevCurbL = spCL;
      prevCurbR = spCR;
    }

    // Start / Finish Line Checkered Bar at s = 0
    let s0Pt = f1.getTrackWorldPoint(this.trackId, 0.0);
    let s0Tan = f1.getTrackTangent(this.trackId, 0.0);
    let s0Mag = math.sqrt(s0Tan[0] * s0Tan[0] + s0Tan[1] * s0Tan[1]);
    if (s0Mag < 0.001) s0Mag = 1.0;
    let s0Nx = -s0Tan[1] / s0Mag;
    let s0Nz = s0Tan[0] / s0Mag;
    let s0Sc = this.worldToScreen(s0Pt[0], s0Pt[1]);
    let barLx = s0Sc[0] - s0Nx * hw; let barLy = s0Sc[1] - s0Nz * hw;
    let barRx = s0Sc[0] + s0Nx * hw; let barRy = s0Sc[1] + s0Nz * hw;
    gui.drawLine(barLx, barLy, barRx, barRy, 255, 235, 40);

    // Forward Direction Arrow
    let arrPt = this.worldToScreen(s0Pt[0] + (s0Tan[0] / s0Mag) * 16.0, s0Pt[1] + (s0Tan[1] / s0Mag) * 16.0);
    gui.drawLine(s0Sc[0], s0Sc[1], arrPt[0], arrPt[1], 0, 240, 255);
    gui.drawCircle(arrPt[0], arrPt[1], 4, 0, 240, 255);
  }

  drawProps() {
    let pList = this.trackDef["props"];
    if (pList == nil) return;
    let lapLen = this.trackDef["length"];
    let corridor = this.trackDef["roadWidth"] * 0.5 + this.trackDef["curbWidth"];

    for (let i = 0; i < len(pList); i += 1) {
      let p = pList[i];
      let pt = f1.getTrackWorldPoint(this.trackId, p["s"]);
      let tan = f1.getTrackTangent(this.trackId, p["s"]);
      let mag = math.sqrt(tan[0] * tan[0] + tan[1] * tan[1]);
      if (mag < 0.001) mag = 1.0;
      let nx = -tan[1] / mag;
      let nz = tan[0] / mag;

      let wx = pt[0] + nx * p["offset"];
      let wz = pt[1] + nz * p["offset"];
      let sp = this.worldToScreen(wx, wz);

      let isSafe = (math.abs(p["offset"]) >= corridor + 1.5);
      let cr = 0; let cg = 220; let cb = 80;
      if (!isSafe) { cr = 240; cg = 40; cb = 40; }

      gui.drawCircle(sp[0], sp[1], 5, cr, cg, cb);
      gui.drawCircleLines(sp[0], sp[1], 12, cr, cg, cb);
      gui.drawText(p["type"], sp[0] + 8, sp[1] - 6, 11, 200, 215, 230);
    }
  }

  drawNodes(t) {
    let nodes = this.trackDef["nodes"];
    let N = len(nodes);

    for (let i = 0; i < N; i += 1) {
      let sp = this.worldToScreen(nodes[i][0], nodes[i][1]);
      let isSel = (i == this.selectedNode);

      if (isSel) {
        let pulse = 14.0 + math.sin(t * 8.0) * 3.0;
        gui.drawCircleAlpha(sp[0], sp[1], pulse, 0, 240, 255, 90);
        gui.drawCircle(sp[0], sp[1], 9, 0, 240, 255);
        gui.drawCircle(sp[0], sp[1], 5, 255, 255, 255);
      } else {
        gui.drawCircle(sp[0], sp[1], 7, 245, 180, 20);
        gui.drawCircle(sp[0], sp[1], 4, 20, 24, 32);
      }

      gui.drawText(str(i + 1), sp[0] + 9, sp[1] + 3, 12, 255, 255, 255);
    }
  }

  drawCanvasOverlay() {
    // Upper Left status badge
    gui.drawRectangleAlpha(16, 16, 380, 72, 12, 16, 24, 220);
    gui.drawRectangleLines(16, 16, 380, 72, 40, 50, 70);
    gui.drawText(this.trackDef["name"], 28, 24, 18, 0, 240, 255);
    gui.drawText("LENGTH: " + str(math.floor(this.trackDef["length"])) + "m  |  NODES: " + str(len(this.trackDef["nodes"])), 28, 48, 13, 180, 195, 215);
    gui.drawText("ZOOM: " + str(math.floor(this.zoom * 100.0)) + "%  |  PAN: (" + str(math.floor(this.panX)) + ", " + str(math.floor(this.panZ)) + ")", 28, 66, 11, 140, 150, 170);

    // Status Message Toast
    if (this.statusTimer > 0.0) {
      let msgW = gui.measureText(this.statusMessage, 14) + 32;
      let toastX = (this.canvasW - msgW) * 0.5;
      gui.drawRectangleAlpha(toastX, this.canvasH - 54, msgW, 36, 10, 25, 45, 230);
      gui.drawRectangleLines(toastX, this.canvasH - 54, msgW, 36, 0, 210, 255);
      gui.drawText(this.statusMessage, toastX + 16, this.canvasH - 44, 14, 255, 255, 255);
    }

    // Shortcut reminders at bottom left
    gui.drawRectangleAlpha(16, this.canvasH - 38, 460, 26, 12, 16, 24, 200);
    gui.drawText("R-DRAG: Pan  |  WHEEL: Zoom  |  L-DRAG: Node  |  T: Test Drive  |  S: Save", 24, this.canvasH - 31, 11, 160, 175, 195);
  }

  drawSidebar(t) {
    let sX = this.canvasW;
    let sY = 0;
    let sW = this.sidebarWidth;
    let sH = this.canvasH;

    gui.drawRectangle(sX, sY, sW, sH, 20, 24, 34);
    gui.drawLine(sX, 0, sX, sH, 45, 55, 75);

    // Editor Header
    gui.drawRectangle(sX, 0, sW, 48, 14, 18, 26);
    gui.drawText("TRACK EDITOR", sX + 16, 14, 20, 0, 240, 255);
    gui.drawRectangle(sX + sW - 96, 12, 80, 24, 255, 30, 80);
    gui.drawText("CUSTOM", sX + sW - 84, 17, 13, 255, 255, 255);

    // Mode Tabs
    let tabNames = ["CIRCUIT", "ELEVATION", "TUNNELS", "PROPS"];
    let tabW = math.floor(sW / len(tabNames));
    for (let tb = 0; tb < len(tabNames); tb += 1) {
      let tX = sX + tb * tabW;
      let isSel = (tb == this.activeTab);
      let tCol = [28, 34, 48];
      if (isSel) tCol = [42, 60, 95];
      gui.drawRectangle(tX, 48, tabW, 32, tCol[0], tCol[1], tCol[2]);
      if (isSel) {
        gui.drawRectangle(tX, 78, tabW, 2, 0, 240, 255);
      }
      gui.drawText(tabNames[tb], tX + 10, 58, 11, 230, 235, 245);

      if (gui.isMouseButtonPressed("LEFT")) {
        let mX = gui.getMouseX(); let mY = gui.getMouseY();
        if (mX >= tX and mX < tX + tabW and mY >= 48 and mY < 80) {
          this.activeTab = tb;
        }
      }
    }

    // Active Tab Content
    let bodyY = 92;
    if (this.activeTab == 0) {
      this.drawCircuitTab(sX, bodyY, sW);
    } else if (this.activeTab == 1) {
      this.drawElevationTab(sX, bodyY, sW);
    } else if (this.activeTab == 2) {
      this.drawTunnelsTab(sX, bodyY, sW);
    } else if (this.activeTab == 3) {
      this.drawPropsTab(sX, bodyY, sW);
    }

    // Bottom Action Buttons
    let btnH = 38;
    let bY = sH - 180;
    let bW = sW - 32;
    let bX = sX + 16;

    // Test Drive Button (Green)
    if (this.drawButton(bX, bY, bW, btnH, "TEST DRIVE (T)", [20, 160, 90], [255, 255, 255], 16)) {
      this.startTestDrive();
    }

    // Save Button (Blue)
    if (this.drawButton(bX, bY + 46, bW, btnH, "SAVE CIRCUIT", [28, 100, 195], [255, 255, 255], 15)) {
      this.saveTrack();
    }

    // Fork & Center Buttons
    let halfBW = math.floor((bW - 8) * 0.5);
    if (this.drawButton(bX, bY + 92, halfBW, 34, "FORK COPY", [45, 55, 75], [230, 235, 245], 13)) {
      this.forkCurrentTrack();
    }
    if (this.drawButton(bX + halfBW + 8, bY + 92, halfBW, 34, "CENTER VIEW", [45, 55, 75], [230, 235, 245], 13)) {
      this.centerView();
    }

    // Exit Button
    if (this.drawButton(bX, bY + 134, bW, 32, "BACK TO MENU (ESC)", [34, 40, 52], [180, 190, 210], 12)) {
      this.stopTestDrive();
    }
  }

  drawButton(x, y, w, h, label, bgCol, textCol, fontSize) {
    let mX = gui.getMouseX();
    let mY = gui.getMouseY();
    let hovered = (mX >= x and mX <= x + w and mY >= y and mY <= y + h);

    let r = bgCol[0]; let g = bgCol[1]; let b = bgCol[2];
    let clicked = false;
    if (hovered) {
      r = math.min(255, r + 25);
      g = math.min(255, g + 25);
      b = math.min(255, b + 25);
      if (gui.isMouseButtonPressed("LEFT")) {
        clicked = true;
      }
    }

    gui.drawRectangle(x, y, w, h, r, g, b);
    gui.drawRectangleLines(x, y, w, h, math.min(255, r + 40), math.min(255, g + 40), math.min(255, b + 40));
    let tW = gui.measureText(label, fontSize);
    let tX = x + math.floor((w - tW) * 0.5);
    let tY = y + math.floor((h - fontSize) * 0.5);
    gui.drawText(label, tX, tY, fontSize, textCol[0], textCol[1], textCol[2]);
    return clicked;
  }

  drawCircuitTab(sX, startY, sW) {
    let pX = sX + 16;
    let curY = startY;

    gui.drawText("CIRCUIT PROPERTIES", pX, curY, 14, 0, 240, 255);
    curY = curY + 24;

    // Road Width
    gui.drawText("Road Width: " + str(this.trackDef["roadWidth"]) + " m", pX, curY, 13, 200, 215, 230);
    let rwDelta = this.drawStepper(pX + 180, curY - 4);
    if (rwDelta != 0) {
      this.trackDef["roadWidth"] = mu.clamp(this.trackDef["roadWidth"] + rwDelta * 2.0, 14.0, 36.0);
      this.syncTrackDef();
    }
    curY = curY + 32;

    // Curb Width
    gui.drawText("Kerb Width: " + str(this.trackDef["curbWidth"]) + " m", pX, curY, 13, 200, 215, 230);
    let cwDelta = this.drawStepper(pX + 180, curY - 4);
    if (cwDelta != 0) {
      this.trackDef["curbWidth"] = mu.clamp(this.trackDef["curbWidth"] + cwDelta * 0.2, 0.5, 3.5);
      this.syncTrackDef();
    }
    curY = curY + 32;

    // Runoff Width
    gui.drawText("Runoff Width: " + str(this.trackDef["runoffWidth"]) + " m", pX, curY, 13, 200, 215, 230);
    let roDelta = this.drawStepper(pX + 180, curY - 4);
    if (roDelta != 0) {
      this.trackDef["runoffWidth"] = mu.clamp(this.trackDef["runoffWidth"] + roDelta * 0.5, 1.0, 10.0);
      this.syncTrackDef();
    }
    curY = curY + 32;

    // Lap Count
    gui.drawText("Race Laps: " + str(this.trackDef["laps"]), pX, curY, 13, 200, 215, 230);
    let lapDelta = this.drawStepper(pX + 180, curY - 4);
    if (lapDelta != 0) {
      this.trackDef["laps"] = mu.clamp(this.trackDef["laps"] + lapDelta, 1, 10);
      this.syncTrackDef();
    }
    curY = curY + 44;

    // Node Tools
    gui.drawText("NODE CONTROLS (Node #" + str(this.selectedNode + 1) + ")", pX, curY, 14, 0, 240, 255);
    curY = curY + 22;

    let halfW = math.floor((sW - 40) * 0.5);
    if (this.drawButton(pX, curY, halfW, 30, "ADD NODE", [35, 75, 120], [255, 255, 255], 12)) {
      this.addNodeAfterSelected();
    }
    if (this.drawButton(pX + halfW + 8, curY, halfW, 30, "DELETE NODE", [120, 45, 45], [255, 255, 255], 12)) {
      this.deleteSelectedNode();
    }
    curY = curY + 38;

    if (this.drawButton(pX, curY, sW - 32, 28, "SMOOTH CIRCUIT CURVES", [45, 55, 75], [230, 235, 245], 12)) {
      this.smoothNodes();
    }
  }

  drawStepper(x, y) {
    let btnW = 28; let btnH = 24;
    let delta = 0;
    if (this.drawButton(x, y, btnW, btnH, "-", [45, 55, 75], [255, 255, 255], 13)) {
      delta = -1;
    }
    if (this.drawButton(x + 36, y, btnW, btnH, "+", [45, 55, 75], [255, 255, 255], 13)) {
      delta = 1;
    }
    return delta;
  }

  drawElevationTab(sX, startY, sW) {
    let pX = sX + 16;
    let curY = startY;
    gui.drawText("TOPOGRAPHY PROFILE", pX, curY, 14, 0, 240, 255);
    curY = curY + 22;

    // Graph viewport
    let gW = sW - 32;
    let gH = 110;
    gui.drawRectangle(pX, curY, gW, gH, 12, 16, 24);
    gui.drawRectangleLines(pX, curY, gW, gH, 35, 45, 65);

    let elevs = this.trackDef["elevations"];
    if (elevs != nil and len(elevs) > 0) {
      let lapLen = this.trackDef["length"];
      let prevGx = nil;
      let prevGy = nil;
      for (let i = 0; i < len(elevs); i += 1) {
        let e = elevs[i];
        let gx = pX + (e["s"] / lapLen) * gW;
        let gy = curY + gH - (e["y"] / 40.0) * gH;
        gui.drawCircle(gx, gy, 4, 0, 240, 255);
        if (prevGx != nil) {
          gui.drawLine(prevGx, prevGy, gx, gy, 0, 200, 240);
        }
        prevGx = gx;
        prevGy = gy;
      }
    }
    curY = curY + gH + 16;

    if (this.drawButton(pX, curY, sW - 32, 30, "ADD ELEVATION PEAK (15m)", [35, 75, 120], [255, 255, 255], 12)) {
      if (this.trackDef["elevations"] == nil) this.trackDef["elevations"] = [];
      let lapLen = this.trackDef["length"];
      this.trackDef["elevations"].push({ "s": lapLen * 0.5, "y": 15.0 });
      this.syncTrackDef();
      this.setStatus("Added elevation peak");
    }
    curY = curY + 38;

    if (this.drawButton(pX, curY, sW - 32, 28, "FLATTEN TRACK ELEVATION", [55, 60, 75], [230, 235, 245], 12)) {
      this.trackDef["elevations"] = [{ "s": 0.0, "y": 1.0 }];
      this.syncTrackDef();
      this.setStatus("Circuit flattened");
    }
  }

  drawTunnelsTab(sX, startY, sW) {
    let pX = sX + 16;
    let curY = startY;
    gui.drawText("TUNNEL SECTIONS", pX, curY, 14, 0, 240, 255);
    curY = curY + 24;

    let tunnels = this.trackDef["tunnels"];
    if (tunnels == nil or len(tunnels) == 0) {
      gui.drawText("No tunnels defined for this track.", pX, curY, 12, 160, 175, 195);
      curY = curY + 30;
    } else {
      for (let i = 0; i < len(tunnels); i += 1) {
        let tun = tunnels[i];
        gui.drawRectangle(pX, curY, sW - 32, 36, 28, 34, 46);
        gui.drawText(tun["name"] + ": " + str(math.floor(tun["startS"])) + "m -> " + str(math.floor(tun["endS"])) + "m", pX + 8, curY + 11, 11, 230, 235, 245);
        curY = curY + 42;
      }
    }

    if (this.drawButton(pX, curY, sW - 32, 32, "ADD 400m TUNNEL", [35, 75, 120], [255, 255, 255], 12)) {
      if (this.trackDef["tunnels"] == nil) this.trackDef["tunnels"] = [];
      let lapLen = this.trackDef["length"];
      let start = lapLen * 0.4;
      this.trackDef["tunnels"].push({ "startS": start, "endS": start + 400.0, "name": "Tunnel #" + str(len(this.trackDef["tunnels"]) + 1) });
      this.syncTrackDef();
      this.setStatus("Added tunnel section");
    }
  }

  drawPropsTab(sX, startY, sW) {
    let pX = sX + 16;
    let curY = startY;
    gui.drawText("SCENERY PROPS", pX, curY, 14, 0, 240, 255);
    curY = curY + 22;

    gui.drawText("Click canvas to place selected prop:", pX, curY, 12, 160, 175, 195);
    curY = curY + 22;

    let propsAvailable = [
      {"name": "grandstandCovered", "label": "Grandstand"},
      {"name": "tree", "label": "Oak / Pine Tree"},
      {"name": "tentLong", "label": "Spectator Tent"},
      {"name": "paddockHauler", "label": "Team Hauler"},
      {"name": "pitsGarage", "label": "Pit Garage"},
      {"name": "billboard", "label": "Sponsor Board"}
    ];

    for (let i = 0; i < len(propsAvailable); i += 1) {
      let pr = propsAvailable[i];
      let isSel = (this.selectedPropType == pr["name"]);
      let bg = [32, 38, 52];
      if (isSel) bg = [45, 85, 140];
      if (this.drawButton(pX, curY, sW - 32, 28, pr["label"], bg, [240, 245, 255], 12)) {
        this.selectedPropType = pr["name"];
      }
      curY = curY + 34;
    }

    curY = curY + 12;
    if (this.drawButton(pX, curY, sW - 32, 28, "CLEAR ALL PROPS", [100, 40, 40], [255, 255, 255], 12)) {
      this.trackDef["props"] = [];
      this.syncTrackDef();
      this.setStatus("Cleared props");
    }
  }

  drawTestDrive(t) {
    // 3D Test Drive Viewport
    let spd = this.testCar.speed;
    let kph = math.floor(spd * 3.6);
    let dist = this.testCar.trackDistance;
    let lapLen = this.testTrack.spec["length"];
    let pct = math.floor((dist / lapLen) * 100.0);

    // 1. Sky & Track 3D Pass
    gui.clearBackground(this.testTrack.spec["skyBottom"][0], this.testTrack.spec["skyBottom"][1], this.testTrack.spec["skyBottom"][2]);
    this.testTrack.draw(this.testCar.trackDistance, this.testCar.worldX, this.testCar.worldY, this.testCar.worldZ, this.testCam.forwardX, this.testCam.forwardZ, this.assets);

    // 2. Player Vehicle 3D Pass
    this.testCar.draw(this.assets, t);

    // 3. Test Drive HUD Overlay
    gui.drawRectangleAlpha(16, 16, 320, 96, 12, 16, 24, 220);
    gui.drawRectangleLines(16, 16, 320, 96, 0, 240, 255);
    gui.drawText("TEST DRIVE: " + this.trackDef["name"], 28, 26, 16, 0, 240, 255);
    gui.drawText("SPEED: " + str(kph) + " KPH  |  GEAR: " + str(this.testCar.gear), 28, 52, 14, 255, 255, 255);
    gui.drawText("LAP PROGRESS: " + str(pct) + "%  |  TIME: " + str(math.floor(this.testLapTime * 10.0) / 10.0) + "s", 28, 74, 13, 180, 200, 220);

    // Exit prompt
    gui.drawRectangleAlpha(this.w - 240, 16, 224, 36, 12, 16, 24, 220);
    gui.drawText("PRESS [ESC] TO EXIT", this.w - 224, 26, 14, 255, 80, 80);
  }
}
