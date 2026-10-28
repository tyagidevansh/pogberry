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
export let MODE_OUTRUN = 1;
export let MODE_TIME_ATTACK = 2;

// Vehicle IDs
export let CAR_PHANTOM = 0;   // Formula futuristic interceptor (high top speed, fast nitro)
export let CAR_VALKYRIE = 1;  // Heavy armored SUV (massive ramming hull, bulldozer)
export let CAR_SHINOBI = 2;   // Tuner sports drift coupe (nimble, drift nitro bonus)
export let CAR_VANTA = 3;     // Police cruiser interceptor (balanced pursuit machine)
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
      "name": "PHANTOM GT",
      "subtitle": "Quantum Formula Prototype",
      "topSpeed": 78.0,
      "boostSpeed": 104.0,
      "accel": 16.0,
      "handling": 30.0,
      "driftRate": 2.2,
      "maxHull": 90.0,
      "nitroCapacity": 100.0,
      "nitroBurn": 26.0,
      "nitroRegen": 8.0,
      "model": "race-future.obj",
      "scale": 1.25,
      "primaryColor": [0, 240, 255],     // Cyan
      "glowColor": [255, 60, 180]         // Neon Pink
    };
  }
  if (id == 1) {
    return {
      "name": "VALKYRIE BRAWLER",
      "subtitle": "Armored Heavy Ram-Truck",
      "topSpeed": 66.0,
      "boostSpeed": 88.0,
      "accel": 12.0,
      "handling": 22.0,
      "driftRate": 1.3,
      "maxHull": 160.0,
      "nitroCapacity": 90.0,
      "nitroBurn": 22.0,
      "nitroRegen": 10.0,
      "model": "suv-luxury.obj",
      "scale": 1.30,
      "primaryColor": [255, 60, 60],     // Crimson
      "glowColor": [255, 180, 0]          // Amber
    };
  }
  if (id == 2) {
    return {
      "name": "SHINOBI DRIFT",
      "subtitle": "Twin-Turbo Street Meister",
      "topSpeed": 72.0,
      "boostSpeed": 96.0,
      "accel": 18.0,
      "handling": 34.0,
      "driftRate": 2.8,
      "maxHull": 105.0,
      "nitroCapacity": 120.0,
      "nitroBurn": 24.0,
      "nitroRegen": 14.0,                 // Bonus nitro on drift
      "model": "sedan-sports.obj",
      "scale": 1.25,
      "primaryColor": [255, 210, 30],    // Gold
      "glowColor": [0, 220, 255]          // Ice Blue
    };
  }
  return {
    "name": "VANTA INTERCEPTOR",
    "subtitle": "Metropolitan Pursuit Spec",
    "topSpeed": 70.0,
    "boostSpeed": 92.0,
    "accel": 15.0,
    "handling": 26.0,
    "driftRate": 2.0,
    "maxHull": 120.0,
    "nitroCapacity": 100.0,
    "nitroBurn": 25.0,
    "nitroRegen": 9.0,
    "model": "police.obj",
    "scale": 1.25,
    "primaryColor": [40, 100, 255],     // Deep Cobalt
    "glowColor": [255, 255, 255]        // Strobe White
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
      "length": 5807.0,
      "roadWidth": 16.8,
      "curbWidth": 1.4,
      "runoffWidth": 4.5,
      "skyColor": [6, 12, 32],
      "skyTop": [4, 8, 22],
      "skyBottom": [32, 50, 92],
      "fogColor": [24, 38, 68],
      "roadColor": [18, 20, 30],
      "curbColor": [255, 40, 50],
      "gravelColor": [135, 105, 75],
      "grassColor": [22, 42, 26],
      "barrierColor": [200, 205, 215],
      "barrierTopColor": [255, 30, 40],
      "railColorA": [255, 40, 60],
      "railColorB": [255, 255, 255],
      "theme": "city",
      "shape": "SUZUKA FIGURE-8 & ESSES",
      "turns": 18,
      "elevationProfile": "S-Curves & Dunlop Rollercoaster",
      "groundColor": [16, 28, 20]
    };
  }
  if (id == 1) {
    return {
      "name": "MONACO GP",
      "subtitle": "Monaco Grand Prix // Circuit de Monaco",
      "difficulty": "EXPERT",
      "laps": 3,
      "length": 3337.0,
      "roadWidth": 14.2,
      "curbWidth": 1.2,
      "runoffWidth": 3.4,
      "skyColor": [65, 22, 55],
      "skyTop": [50, 16, 44],
      "skyBottom": [235, 105, 60],
      "fogColor": [115, 45, 65],
      "roadColor": [24, 20, 32],
      "curbColor": [245, 45, 55],
      "gravelColor": [110, 35, 48],
      "grassColor": [18, 26, 45],
      "barrierColor": [220, 220, 225],
      "barrierTopColor": [255, 210, 30],
      "railColorA": [255, 60, 80],
      "railColorB": [255, 210, 40],
      "theme": "sunset",
      "shape": "MONTE CARLO HARBOR CIRCUIT",
      "turns": 19,
      "elevationProfile": "Beau Rivage Climb & Harbor Descents",
      "groundColor": [16, 22, 36]
    };
  }
  if (id == 2) {
    return {
      "name": "SPA GP",
      "subtitle": "Belgian Grand Prix // Spa-Francorchamps",
      "difficulty": "EXPERT",
      "laps": 3,
      "length": 7004.0,
      "roadWidth": 18.4,
      "curbWidth": 1.5,
      "runoffWidth": 5.0,
      "skyColor": [14, 22, 42],
      "skyTop": [10, 16, 34],
      "skyBottom": [70, 105, 138],
      "fogColor": [38, 58, 78],
      "roadColor": [20, 22, 28],
      "curbColor": [255, 215, 0],
      "gravelColor": [125, 95, 65],
      "grassColor": [20, 48, 24],
      "barrierColor": [195, 200, 210],
      "barrierTopColor": [230, 25, 35],
      "railColorA": [255, 215, 0],
      "railColorB": [220, 20, 60],
      "theme": "canyon",
      "shape": "ARDENNES FOREST ROLLERCOASTER",
      "turns": 19,
      "elevationProfile": "Eau Rouge & Raidillon 17% Climb",
      "groundColor": [18, 38, 20]
    };
  }
  return {
    "name": "MONZA GP",
    "subtitle": "Italian Grand Prix // Temple of Speed",
    "difficulty": "HARD",
    "laps": 3,
    "length": 5793.0,
    "roadWidth": 18.0,
    "curbWidth": 1.5,
    "runoffWidth": 4.8,
    "skyColor": [8, 14, 28],
    "skyTop": [6, 10, 22],
    "skyBottom": [40, 75, 105],
    "fogColor": [22, 48, 70],
    "roadColor": [16, 18, 28],
    "curbColor": [0, 200, 100],
    "gravelColor": [145, 120, 80],
    "grassColor": [24, 46, 22],
    "barrierColor": [210, 215, 220],
    "barrierTopColor": [0, 220, 120],
    "railColorA": [0, 255, 140],
    "railColorB": [255, 40, 50],
    "theme": "orbital",
    "shape": "TEMPLE OF SPEED & CHICANES",
    "turns": 11,
    "elevationProfile": "Flat-out Straights & Heavy Braking Chicanes",
    "groundColor": [18, 36, 18]
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

