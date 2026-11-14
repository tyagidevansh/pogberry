use "std.math" as math;
use "data/f1_data" as f1;

export let SCREEN_WIDTH = 1280;
export let SCREEN_HEIGHT = 720;
export let TARGET_FPS = 60;

export let STATE_TITLE = 0;
export let STATE_GARAGE = 1;
export let STATE_TRACK_SELECT = 2;
export let STATE_COUNTDOWN = 3;
export let STATE_RACE = 4;
export let STATE_PAUSED = 5;
export let STATE_FINISH = 6;
export let STATE_CRASHED = 7;
export let STATE_TIMEOUT = 8;
export let STATE_TRACK_EDITOR = 9;

export let MODE_GRAND_PRIX = 0;
export let MODE_TIME_ATTACK = 1;
export let MODE_REALISTIC = 2;
export let MODE_OUTRUN = -1;
export let TOTAL_MODES = 3;

export let AI_DIFF_ROOKIE = 0;
export let AI_DIFF_AMATEUR = 1;
export let AI_DIFF_PRO = 1;
export let AI_DIFF_CHAMPION = 2;
export let TOTAL_AI_DIFFS = 3;

export let CAR_VALKYRIE = 0;
export let CAR_SHINOBI = 1;
export let CAR_PHANTOM = 2;
export let CAR_VANTA = 3;
export let CAR_BRITISH = 4;
export let TOTAL_CARS = 4;

export let TRACK_SUZUKA = 0;
export let TRACK_SPA = 1;
export let TRACK_MONZA = 2;
export let TRACK_MONACO = 3;
export let TRACK_SHIBUYA = 0;
export let TRACK_CANYON = 1;
export let TRACK_HYPERION = 2;
export let TRACK_SUNSET = 3;
export let TOTAL_TRACKS = 4;

export fun getTotalTracks() {
  return 4 + len(f1.customTracks);
}

export fun registerCustomTrack(def) {
  return f1.registerCustomTrack(def);
}

export fun getCarSpec(id) {
  if (id == 0) {
    return {
      "name": "RB-20",
      "subtitle": "Pierre Wache will redeem himself",
      "team": "RED BULL RACING",
      "topSpeed": 158.0,
      "boostSpeed": 221.0,
      "accel": 38.4,
      "handling": 45.2,
      "driftRate": 2.0,
      "maxHull": 100.0,
      "nitroCapacity": 100.0,
      "nitroBurn": 24.0,
      "nitroRegen": 13.0,
      "model": "car_redbull.obj",
      "scale": 1.45,
      "primaryColor": [18, 32, 85],
      "glowColor": [255, 215, 30]
    };
  }
  if (id == 1) {
    return {
      "name": "W15",
      "subtitle": "Filled with Toto's love",
      "team": "MERCEDES-AMG PETRONAS",
      "topSpeed": 161.0,
      "boostSpeed": 225.0,
      "accel": 38.6,
      "handling": 43.4,
      "driftRate": 2.1,
      "maxHull": 100.0,
      "nitroCapacity": 100.0,
      "nitroBurn": 24.0,
      "nitroRegen": 13.0,
      "model": "car_mercedes.obj",
      "scale": 1.45,
      "primaryColor": [215, 222, 230],
      "glowColor": [0, 235, 215]
    };
  }
  if (id == 2) {
    return {
      "name": "SF-24",
      "subtitle": "Mamma mia!",
      "team": "SCUDERIA FERRARI",
      "topSpeed": 162.0,
      "boostSpeed": 227.0,
      "accel": 37.6,
      "handling": 43.0,
      "driftRate": 2.2,
      "maxHull": 100.0,
      "nitroCapacity": 100.0,
      "nitroBurn": 24.0,
      "nitroRegen": 13.0,
      "model": "car_ferrari.obj",
      "scale": 1.45,
      "primaryColor": [235, 25, 35],
      "glowColor": [255, 215, 20]
    };
  }
  if (id == 3) {
    return {
      "name": "MCL38",
      "subtitle": "Is this is the world champion hotline?",
      "team": "MCLAREN FORMULA 1",
      "topSpeed": 159.0,
      "boostSpeed": 223.0,
      "accel": 37.4,
      "handling": 44.8,
      "driftRate": 2.1,
      "maxHull": 100.0,
      "nitroCapacity": 100.0,
      "nitroBurn": 24.0,
      "nitroRegen": 13.0,
      "model": "car_mclaren.obj",
      "scale": 1.45,
      "primaryColor": [255, 130, 20],
      "glowColor": [40, 180, 255]
    };
  }
  return {
    "name": "BRITISH GP AMR24",
    "subtitle": "Silverstone British Racing Green",
    "team": "ASTON MARTIN ARAMCO",
    "topSpeed": 160.0,
    "boostSpeed": 224.0,
    "accel": 38.0,
    "handling": 44.0,
    "driftRate": 2.0,
    "maxHull": 100.0,
    "nitroCapacity": 100.0,
    "nitroBurn": 24.0,
    "nitroRegen": 13.0,
    "model": "race.obj",
    "scale": 1.45,
    "primaryColor": [0, 110, 68],
    "glowColor": [180, 255, 50]
  };
}

export fun getTrackSpec(id) {
  if (id == 0) {
    return {
      "name": "SUZUKA GP",
      "subtitle": "Japanese Grand Prix // Suzuka International",
      "difficulty": "HARD",
      "laps": 3,
      "length": 9200.0,
      "roadWidth": 28.0,
      "curbWidth": 2.4,
      "runoffWidth": 8.5,
      "skyColor": [36, 115, 210],
      "skyTop": [24, 88, 180],
      "skyBottom": [145, 192, 238],
      "fogColor": [145, 192, 238],
      "roadColor": [42, 45, 56],
      "curbColor": [235, 40, 50],
      "gravelColor": [155, 125, 90],
      "grassColor": [48, 128, 52],
      "barrierColor": [68, 75, 88],
      "barrierTopColor": [225, 40, 50],
      "railColorA": [255, 40, 60],
      "railColorB": [255, 255, 255],
      "theme": "city",
      "shape": "SUZUKA FIGURE-8 & ESSES",
      "turns": 18,
      "elevationProfile": "S-Curves & Dunlop Rollercoaster",
      "groundColor": [42, 115, 46]
    };
  }
  if (id == 1) {
    return {
      "name": "SPA GP",
      "subtitle": "Belgian Grand Prix // Spa-Francorchamps",
      "difficulty": "EXPERT",
      "laps": 3,
      "length": 11200.0,
      "roadWidth": 30.0,
      "curbWidth": 2.5,
      "runoffWidth": 10.0,
      "skyColor": [34, 102, 195],
      "skyTop": [22, 80, 170],
      "skyBottom": [148, 185, 225],
      "fogColor": [148, 185, 225],
      "roadColor": [44, 46, 55],
      "curbColor": [255, 205, 25],
      "gravelColor": [135, 105, 75],
      "grassColor": [42, 118, 48],
      "barrierColor": [66, 72, 85],
      "barrierTopColor": [225, 35, 45],
      "railColorA": [255, 215, 0],
      "railColorB": [220, 20, 60],
      "theme": "canyon",
      "shape": "ARDENNES FOREST ROROLLERCOASTER",
      "turns": 19,
      "elevationProfile": "Eau Rouge & Raidillon 17% Climb",
      "groundColor": [38, 105, 42]
    };
  }
  if (id == 2) {
    return {
      "name": "MONZA GP",
      "subtitle": "Italian Grand Prix // Temple of Speed",
      "difficulty": "HARD",
      "laps": 3,
      "length": 9600.0,
      "roadWidth": 32.0,
      "curbWidth": 2.6,
      "runoffWidth": 10.0,
      "skyColor": [38, 118, 215],
      "skyTop": [25, 90, 185],
      "skyBottom": [165, 202, 240],
      "fogColor": [165, 202, 240],
      "roadColor": [46, 48, 58],
      "curbColor": [30, 160, 75],
      "gravelColor": [140, 115, 85],
      "grassColor": [52, 126, 48],
      "barrierColor": [68, 74, 86],
      "barrierTopColor": [230, 40, 50],
      "railColorA": [30, 160, 75],
      "railColorB": [220, 35, 45],
      "theme": "orbital",
      "shape": "TEMPLE OF SPEED & CHICANES",
      "turns": 11,
      "elevationProfile": "Flat-out Straights & Heavy Braking Chicanes",
      "groundColor": [46, 112, 44]
    };
  }
  if (id >= 4) {
    let c = f1.getCustomTrack(id);
    if (c != nil) {
      let tLen = f1.getF1Length(id);
      let rCol = [48, 50, 60];
      if (c["roadR"] != nil) rCol = [c["roadR"], c["roadG"], c["roadB"]];
      let cCol = [235, 40, 50];
      if (c["curbR"] != nil) cCol = [c["curbR"], c["curbG"], c["curbB"]];
      let gCol = [42, 115, 46];
      if (c["groundColor"] != nil) gCol = c["groundColor"];
      let railA = [255, 60, 80];
      if (c["railColorA"] != nil) railA = c["railColorA"];
      let railB = [255, 210, 40];
      if (c["railColorB"] != nil) railB = c["railColorB"];
      let skyC = [35, 110, 215];
      if (c["skyColor"] != nil) skyC = c["skyColor"];
      let skyT = [20, 80, 190];
      if (c["skyTop"] != nil) skyT = c["skyTop"];
      let skyB = [160, 210, 245];
      if (c["skyBottom"] != nil) skyB = c["skyBottom"];
      return {
        "name": c["name"],
        "subtitle": c["subtitle"],
        "difficulty": c["difficulty"],
        "laps": c["laps"],
        "length": tLen,
        "roadWidth": c["roadWidth"],
        "curbWidth": c["curbWidth"],
        "runoffWidth": c["runoffWidth"],
        "skyColor": skyC,
        "skyTop": skyT,
        "skyBottom": skyB,
        "fogColor": skyB,
        "roadColor": rCol,
        "curbColor": cCol,
        "gravelColor": [150, 120, 85],
        "grassColor": [48, 125, 50],
        "barrierColor": [68, 75, 88],
        "barrierTopColor": [230, 40, 50],
        "railColorA": railA,
        "railColorB": railB,
        "theme": "custom",
        "shape": "USER DESIGNED CIRCUIT",
        "turns": len(c["nodes"]),
        "elevationProfile": "Custom Topography",
        "groundColor": gCol
      };
    }
  }

  return {
    "name": "MONACO GP",
    "subtitle": "Monaco Grand Prix // Circuit de Monaco",
    "difficulty": "EXPERT",
    "laps": 3,
    "length": 5800.0,
    "roadWidth": 20.0,
    "curbWidth": 1.4,
    "runoffWidth": 1.8,
    "skyColor": [28, 118, 222],
    "skyTop": [20, 92, 195],
    "skyBottom": [155, 208, 245],
    "fogColor": [155, 208, 245],
    "roadColor": [48, 50, 60],
    "curbColor": [240, 45, 55],
    "gravelColor": [140, 80, 70],
    "grassColor": [165, 170, 180],
    "barrierColor": [70, 76, 88],
    "barrierTopColor": [255, 215, 30],
    "railColorA": [255, 60, 80],
    "railColorB": [255, 210, 40],
    "theme": "sunset",
    "shape": "MONTE CARLO HARBOR CIRCUIT",
    "turns": 19,
    "elevationProfile": "Beau Rivage Climb & Harbor Descents",
    "groundColor": [150, 155, 165]
  };
}

export fun getTrackWorldPoint(id, s) {
  return f1.getTrackWorldPoint(id, s);
}

export fun getTrackTangent(id, s) {
  return f1.getTrackTangent(id, s);
}

export fun getTrackHeading(id, s) {
  return f1.getTrackHeading(id, s);
}

export fun getTrackCurvature(id, s) {
  return f1.getTrackCurvature(id, s);
}

export fun getTrackBounds(id) {
  return f1.getF1Bounds(id);
}
