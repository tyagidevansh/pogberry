// TURBO CIRCUIT: OVERDRIVE — Game Constants & Configuration

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

// Track IDs
export let TRACK_SHIBUYA = 0; // Neo Shibuya Expressway (rainy cyber city, high-rises)
export let TRACK_SUNSET = 1;  // Sunset Coastline Highway (synthwave golden hour, ocean)
export let TRACK_CANYON = 2;  // Nebula Canyon Badlands (energy pylons, hazard chicanes)
export let TOTAL_TRACKS = 3;

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
      "name": "NEO SHIBUYA",
      "subtitle": "Midnight Expressway // Tokyo Sector 4",
      "difficulty": "EASY",
      "laps": 3,
      "length": 1800.0,
      "skyColor": [4, 6, 16],
      "roadColor": [16, 18, 28],
      "railColorA": [0, 240, 255],
      "railColorB": [255, 40, 160],
      "theme": "city"
    };
  }
  if (id == 1) {
    return {
      "name": "SUNSET HORIZON",
      "subtitle": "Coastal Grand Highway // Pacific Route 1",
      "difficulty": "MEDIUM",
      "laps": 3,
      "length": 2200.0,
      "skyColor": [38, 12, 34],
      "roadColor": [26, 20, 32],
      "railColorA": [255, 140, 40],
      "railColorB": [255, 60, 180],
      "theme": "sunset"
    };
  }
  return {
    "name": "NEBULA CANYON",
    "subtitle": "Industrial Badlands // Titan Rift",
    "difficulty": "HARD",
    "laps": 4,
    "length": 2600.0,
    "skyColor": [12, 8, 22],
    "roadColor": [22, 18, 26],
    "railColorA": [255, 200, 40],
    "railColorB": [120, 40, 255],
    "theme": "canyon"
  };
}

