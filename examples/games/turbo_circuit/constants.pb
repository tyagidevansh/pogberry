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
      "topSpeed": 118.0,
      "boostSpeed": 165.0,
      "accel": 34.0,
      "handling": 28.0,
      "driftRate": 2.2,
      "maxHull": 90.0,
      "nitroCapacity": 100.0,
      "nitroBurn": 30.0,
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
      "topSpeed": 98.0,
      "boostSpeed": 138.0,
      "accel": 26.0,
      "handling": 20.0,
      "driftRate": 1.3,
      "maxHull": 160.0,
      "nitroCapacity": 90.0,
      "nitroBurn": 24.0,
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
      "topSpeed": 108.0,
      "boostSpeed": 150.0,
      "accel": 38.0,
      "handling": 32.0,
      "driftRate": 3.0,
      "maxHull": 105.0,
      "nitroCapacity": 120.0,
      "nitroBurn": 26.0,
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
    "topSpeed": 104.0,
    "boostSpeed": 146.0,
    "accel": 32.0,
    "handling": 26.0,
    "driftRate": 2.0,
    "maxHull": 120.0,
    "nitroCapacity": 100.0,
    "nitroBurn": 28.0,
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
      "roadWidth": 11.4,
      "skyColor": [4, 8, 20],
      "roadColor": [16, 18, 28],
      "railColorA": [255, 40, 60],
      "railColorB": [255, 255, 255],
      "theme": "city",
      "shape": "SUZUKA FIGURE-8 & ESSES",
      "turns": 18,
      "elevationProfile": "S-Curves & Dunlop Rollercoaster",
      "groundColor": [8, 12, 18]
    };
  }
  if (id == 1) {
    return {
      "name": "MONACO GP",
      "subtitle": "Monaco Grand Prix // Circuit de Monaco",
      "difficulty": "EXPERT",
      "laps": 3,
      "length": 3337.0,
      "roadWidth": 9.4,
      "skyColor": [45, 14, 38],
      "roadColor": [26, 18, 30],
      "railColorA": [255, 60, 80],
      "railColorB": [255, 210, 40],
      "theme": "sunset",
      "shape": "MONTE CARLO HARBOR CIRCUIT",
      "turns": 19,
      "elevationProfile": "Beau Rivage Climb & Harbor Descents",
      "groundColor": [22, 12, 28]
    };
  }
  if (id == 2) {
    return {
      "name": "SPA GP",
      "subtitle": "Belgian Grand Prix // Spa-Francorchamps",
      "difficulty": "EXPERT",
      "laps": 3,
      "length": 7004.0,
      "roadWidth": 12.0,
      "skyColor": [10, 14, 26],
      "roadColor": [22, 18, 24],
      "railColorA": [255, 215, 0],
      "railColorB": [220, 20, 60],
      "theme": "canyon",
      "shape": "ARDENNES FOREST ROLLERCOASTER",
      "turns": 19,
      "elevationProfile": "Eau Rouge & Raidillon 17% Climb",
      "groundColor": [14, 18, 14]
    };
  }
  return {
    "name": "MONZA GP",
    "subtitle": "Italian Grand Prix // Temple of Speed",
    "difficulty": "HARD",
    "laps": 3,
    "length": 5793.0,
    "roadWidth": 13.0,
    "skyColor": [2, 6, 16],
    "roadColor": [12, 16, 26],
    "railColorA": [0, 255, 140],
    "railColorB": [255, 40, 50],
    "theme": "orbital",
    "shape": "TEMPLE OF SPEED & CHICANES",
    "turns": 11,
    "elevationProfile": "Flat-out Straights & Heavy Braking Chicanes",
    "groundColor": [6, 10, 16]
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

export fun getTrackBounds(id) {
  return f1.getF1Bounds(id);
}

