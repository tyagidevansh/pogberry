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
      "topSpeed": 168.0,
      "boostSpeed": 232.0,
      "accel": 38.0,
      "handling": 44.0,
      "driftRate": 2.4,
      "maxHull": 100.0,
      "nitroCapacity": 100.0,
      "nitroBurn": 26.0,
      "nitroRegen": 12.0,
      "model": "race-future.obj",
      "scale": 1.45,
      "primaryColor": [0, 240, 255],     // Cyan
      "glowColor": [255, 60, 180]         // Neon Pink
    };
  }
  if (id == 1) {
    return {
      "name": "VALKYRIE BRAWLER",
      "subtitle": "Armored Heavy Ram-Truck",
      "topSpeed": 148.0,
      "boostSpeed": 206.0,
      "accel": 32.0,
      "handling": 36.0,
      "driftRate": 1.6,
      "maxHull": 100.0,
      "nitroCapacity": 90.0,
      "nitroBurn": 22.0,
      "nitroRegen": 14.0,
      "model": "suv-luxury.obj",
      "scale": 1.50,
      "primaryColor": [255, 60, 60],     // Crimson
      "glowColor": [255, 180, 0]          // Amber
    };
  }
  if (id == 2) {
    return {
      "name": "SHINOBI DRIFT",
      "subtitle": "Twin-Turbo Street Meister",
      "topSpeed": 160.0,
      "boostSpeed": 224.0,
      "accel": 42.0,
      "handling": 48.0,
      "driftRate": 3.0,
      "maxHull": 100.0,
      "nitroCapacity": 120.0,
      "nitroBurn": 24.0,
      "nitroRegen": 18.0,                 // Bonus nitro on drift
      "model": "sedan-sports.obj",
      "scale": 1.45,
      "primaryColor": [255, 210, 30],    // Gold
      "glowColor": [0, 220, 255]          // Ice Blue
    };
  }
  return {
    "name": "VANTA INTERCEPTOR",
    "subtitle": "Metropolitan Pursuit Spec",
    "topSpeed": 154.0,
    "boostSpeed": 214.0,
    "accel": 35.0,
    "handling": 40.0,
    "driftRate": 2.2,
    "maxHull": 100.0,
    "nitroCapacity": 100.0,
    "nitroBurn": 25.0,
    "nitroRegen": 13.0,
    "model": "police.obj",
    "scale": 1.45,
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
      "length": 9200.0,
      "roadWidth": 28.0,
      "curbWidth": 2.4,
      "runoffWidth": 8.5,
      "skyColor": [18, 28, 56],
      "skyTop": [12, 18, 42],
      "skyBottom": [48, 82, 142],
      "fogColor": [36, 58, 98],
      "roadColor": [42, 45, 56],
      "curbColor": [235, 40, 50],
      "gravelColor": [155, 125, 90],
      "grassColor": [28, 62, 34],
      "barrierColor": [68, 75, 88],
      "barrierTopColor": [225, 40, 50],
      "railColorA": [255, 40, 60],
      "railColorB": [255, 255, 255],
      "theme": "city",
      "shape": "SUZUKA FIGURE-8 & ESSES",
      "turns": 18,
      "elevationProfile": "S-Curves & Dunlop Rollercoaster",
      "groundColor": [24, 52, 28]
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
      "skyColor": [75, 28, 62],
      "skyTop": [45, 18, 48],
      "skyBottom": [235, 120, 68],
      "fogColor": [140, 65, 85],
      "roadColor": [48, 50, 60],
      "curbColor": [240, 45, 55],
      "gravelColor": [140, 80, 70],
      "grassColor": [24, 50, 42],
      "barrierColor": [70, 76, 88],
      "barrierTopColor": [255, 215, 30],
      "railColorA": [255, 60, 80],
      "railColorB": [255, 210, 40],
      "theme": "sunset",
      "shape": "MONTE CARLO HARBOR CIRCUIT",
      "turns": 19,
      "elevationProfile": "Beau Rivage Climb & Harbor Descents",
      "groundColor": [20, 45, 35]
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
      "skyColor": [16, 26, 48],
      "skyTop": [10, 18, 38],
      "skyBottom": [60, 95, 135],
      "fogColor": [42, 65, 88],
      "roadColor": [44, 46, 55],
      "curbColor": [255, 205, 25],
      "gravelColor": [135, 105, 75],
      "grassColor": [25, 58, 30],
      "barrierColor": [66, 72, 85],
      "barrierTopColor": [225, 35, 45],
      "railColorA": [255, 215, 0],
      "railColorB": [220, 20, 60],
      "theme": "canyon",
      "shape": "ARDENNES FOREST ROROLLERCOASTER",
      "turns": 19,
      "elevationProfile": "Eau Rouge & Raidillon 17% Climb",
      "groundColor": [22, 50, 26]
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
    "skyColor": [14, 24, 46],
    "skyTop": [8, 16, 35],
    "skyBottom": [85, 95, 140],
    "fogColor": [48, 60, 88],
    "roadColor": [46, 48, 58],
    "curbColor": [30, 160, 75],
    "gravelColor": [140, 115, 85],
    "grassColor": [32, 68, 34],
    "barrierColor": [68, 74, 86],
    "barrierTopColor": [230, 40, 50],
    "railColorA": [30, 160, 75],
    "railColorB": [220, 35, 45],
    "theme": "orbital",
    "shape": "TEMPLE OF SPEED & CHICANES",
    "turns": 11,
    "elevationProfile": "Flat-out Straights & Heavy Braking Chicanes",
    "groundColor": [26, 58, 28]
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

