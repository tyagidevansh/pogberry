// TURBO CIRCUIT: OVERDRIVE — Game Constants & Configuration
use "std.math" as math;
use "f1_data" as f1;

export let SCREEN_WIDTH = 1280;
export let SCREEN_HEIGHT = 720;
export let TARGET_FPS = 60;

// Game States
export let STATE_TITLE = 0;
export let STATE_GARAGE = 1;
export let STATE_TRACK_SELECT = 2;
export let STATE_COUNTDOWN = 3;
export let STATE_RACE = 4;
export let STATE_PAUSED = 5;
export let STATE_FINISH = 6;
export let STATE_CRASHED = 7;
export let STATE_TIMEOUT = 8;

// Game Modes
export let MODE_GRAND_PRIX = 0;
export let MODE_TIME_ATTACK = 1;
export let MODE_OUTRUN = -1;

// AI Difficulty Levels
export let AI_DIFF_ROOKIE = 0;   // Easy (relaxed pace, gentle cornering)
export let AI_DIFF_AMATEUR = 1;  // Legacy alias for Medium
export let AI_DIFF_PRO = 1;      // Medium (former top tier: 85% pace, trail-braking)
export let AI_DIFF_CHAMPION = 2; // Hard / Legend (100% full throttle, late braking, full nitro)
export let TOTAL_AI_DIFFS = 3;

// Vehicle IDs
export let CAR_PHANTOM = 0;   // Scuderia Ferrari SF-24
export let CAR_VALKYRIE = 1;  // Red Bull Racing RB-20
export let CAR_SHINOBI = 2;   // Mercedes-AMG Silver Arrow W15
export let CAR_VANTA = 3;     // McLaren Papaya Speed MCL38
export let CAR_BRITISH = 4;   // Aston Martin British Racing AMR24
export let TOTAL_CARS = 4;

// Official FIA Formula 1 Track IDs
export let TRACK_SUZUKA = 0;   // Suzuka International Circuit (Japanese GP // Figure-8 & Esses)
export let TRACK_MONACO = 1;   // Circuit de Monaco (Riviera GP // Harbor & Casino Hairpin)
export let TRACK_SPA = 2;      // Circuit de Spa-Francorchamps (Ardennes GP // Eau Rouge & Kemmel)
export let TRACK_MONZA = 3;    // Autodromo Nazionale Monza (Italian GP // Temple of Speed & Chicanes)
export let TRACK_SHIBUYA = 0;  // Legacy alias
export let TRACK_SUNSET = 1;   // Legacy alias
export let TRACK_CANYON = 2;   // Legacy alias
export let TRACK_HYPERION = 3; // Legacy alias
export let TOTAL_TRACKS = 4;

// Machine Specs: [name, subtitle, topSpeed, accel, driftGrip, maxHull, nitroCapacity, modelName, scale]
export fun getCarSpec(id) {
  if (id == 0) {
    return {
      "name": "SCUDERIA SF-24",
      "subtitle": "Maranello V6 Turbo-Hybrid",
      "team": "SCUDERIA FERRARI",
      "topSpeed": 168.0,
      "boostSpeed": 232.0,
      "accel": 38.0,
      "handling": 44.0,
      "driftRate": 2.4,
      "maxHull": 100.0,
      "nitroCapacity": 100.0,
      "nitroBurn": 26.0,
      "nitroRegen": 12.0,
      "model": "car_ferrari.obj",
      "scale": 1.45,
      "primaryColor": [235, 25, 35],     // Ferrari Red
      "glowColor": [255, 215, 20]         // Modena Yellow
    };
  }
  if (id == 1) {
    return {
      "name": "APEX BULL RB-20",
      "subtitle": "Milton Keynes High-Downforce",
      "team": "RED BULL RACING",
      "topSpeed": 150.0,
      "boostSpeed": 210.0,
      "accel": 34.0,
      "handling": 40.0,
      "driftRate": 1.8,
      "maxHull": 100.0,
      "nitroCapacity": 90.0,
      "nitroBurn": 22.0,
      "nitroRegen": 14.0,
      "model": "car_redbull.obj",
      "scale": 1.45,
      "primaryColor": [18, 32, 85],      // Midnight Matte Navy
      "glowColor": [255, 215, 30]         // Gold
    };
  }
  if (id == 2) {
    return {
      "name": "SILVER ARROW W15",
      "subtitle": "Brackley Dual-Axis Aero",
      "team": "MERCEDES-AMG PETRONAS",
      "topSpeed": 160.0,
      "boostSpeed": 224.0,
      "accel": 42.0,
      "handling": 48.0,
      "driftRate": 3.0,
      "maxHull": 100.0,
      "nitroCapacity": 120.0,
      "nitroBurn": 24.0,
      "nitroRegen": 18.0,                 // Bonus nitro on drift
      "model": "car_mercedes.obj",
      "scale": 1.45,
      "primaryColor": [215, 222, 230],   // Mercedes Silver
      "glowColor": [0, 235, 215]          // Petronas Teal
    };
  }
  if (id == 3) {
    return {
      "name": "PAPAYA SPEED MCL38",
      "subtitle": "Woking High-Speed Specialist",
      "team": "MCLAREN FORMULA 1",
      "topSpeed": 156.0,
      "boostSpeed": 218.0,
      "accel": 36.0,
      "handling": 42.0,
      "driftRate": 2.2,
      "maxHull": 100.0,
      "nitroCapacity": 100.0,
      "nitroBurn": 25.0,
      "nitroRegen": 13.0,
      "model": "car_mclaren.obj",
      "scale": 1.45,
      "primaryColor": [255, 130, 20],     // Papaya Orange
      "glowColor": [40, 180, 255]         // Gulf Blue
    };
  }
  return {
    "name": "BRITISH GP AMR24",
    "subtitle": "Silverstone British Racing Green",
    "team": "ASTON MARTIN ARAMCO",
    "topSpeed": 154.0,
    "boostSpeed": 216.0,
    "accel": 35.0,
    "handling": 41.0,
    "driftRate": 2.0,
    "maxHull": 100.0,
    "nitroCapacity": 95.0,
    "nitroBurn": 23.0,
    "nitroRegen": 13.0,
    "model": "race.obj",
    "scale": 1.45,
    "primaryColor": [0, 110, 68],        // British Racing Green
    "glowColor": [180, 255, 50]          // Lime Green
  };
}

// Track Information
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
      "name": "MONACO GP",
      "subtitle": "Monaco Grand Prix // Circuit de Monaco",
      "difficulty": "EXPERT",
      "laps": 3,
      "length": 5800.0,
      "roadWidth": 24.0,
      "curbWidth": 2.0,
      "runoffWidth": 6.5,
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
  if (id == 2) {
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

// -----------------------------------------------------------------------------
// Official FIA Formula 1 Closed Circuit Geometry (via f1_data.pb)
// -----------------------------------------------------------------------------
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

