// TURBO CIRCUIT: OVERDRIVE — Game Constants & Configuration
use "std.math" as math;

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
export let TRACK_HYPERION = 3;// Hyperion Orbital Speedway (Zero-G ring, boost pads)
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
      "name": "NEO SHIBUYA",
      "subtitle": "Midnight Expressway // Tokyo Sector 4",
      "difficulty": "EASY",
      "laps": 3,
      "length": 1800.0,
      "roadWidth": 12.0,
      "skyColor": [4, 6, 16],
      "roadColor": [14, 16, 26],
      "railColorA": [0, 240, 255],
      "railColorB": [255, 40, 160],
      "theme": "city",
      "shape": "URBAN RECTANGLE",
      "turns": 6,
      "elevationProfile": "Flyovers & Subway Dips",
      "groundColor": [8, 10, 16]
    };
  }
  if (id == 1) {
    return {
      "name": "SUNSET HORIZON",
      "subtitle": "Coastal Grand Highway // Pacific Route 1",
      "difficulty": "MEDIUM",
      "laps": 3,
      "length": 2200.0,
      "roadWidth": 10.6,
      "skyColor": [45, 14, 38],
      "roadColor": [26, 18, 30],
      "railColorA": [255, 150, 40],
      "railColorB": [255, 60, 160],
      "theme": "sunset",
      "shape": "COASTAL PENINSULA",
      "turns": 4,
      "elevationProfile": "Rolling Ocean Bluffs",
      "groundColor": [22, 12, 28]
    };
  }
  if (id == 2) {
    return {
      "name": "NEBULA CANYON",
      "subtitle": "Industrial Badlands // Titan Rift",
      "difficulty": "HARD",
      "laps": 4,
      "length": 2600.0,
      "roadWidth": 9.6,
      "skyColor": [14, 8, 24],
      "roadColor": [28, 16, 22],
      "railColorA": [255, 200, 40],
      "railColorB": [160, 40, 255],
      "theme": "canyon",
      "shape": "SERPENTINE SWITCHBACK",
      "turns": 8,
      "elevationProfile": "Extreme Mountain Drops",
      "groundColor": [26, 12, 14]
    };
  }
  return {
    "name": "HYPERION SPEEDWAY",
    "subtitle": "Orbital Superspeedway // Geo Ring 01",
    "difficulty": "EXPERT",
    "laps": 4,
    "length": 2400.0,
    "roadWidth": 14.0,
    "skyColor": [2, 4, 14],
    "roadColor": [10, 14, 24],
    "railColorA": [0, 255, 170],
    "railColorB": [0, 210, 255],
    "theme": "orbital",
    "shape": "ORBITAL TRI-OVAL",
    "turns": 3,
    "elevationProfile": "Parabolic Banking",
    "groundColor": [3, 5, 12]
  };
}

// -----------------------------------------------------------------------------
// Closed Circuit Loop Geometry for 3D Road Curves & 2D Minimap Radar
// -----------------------------------------------------------------------------
export fun getTrackWorldPoint(id, s) {
  let lapLen = 1800.0;
  if (id == 1) lapLen = 2200.0;
  else if (id == 2) lapLen = 2600.0;
  else if (id == 3) lapLen = 2400.0;

  let u = (s / lapLen) * 6.2831853;
  if (id == 0) {
    // Neo Shibuya: Tokyo Metropolis Circuit (elongated rectangle with chicane waist)
    let x = 240.0 * math.sin(u) + 35.0 * math.sin(3.0 * u) - 10.0 * math.sin(5.0 * u);
    let z = 380.0 * math.cos(u) + 40.0 * math.cos(3.0 * u);
    return [x, z];
  }
  if (id == 1) {
    // Sunset Horizon: Pacific Coast Ocean Loop (flowing kidney peninsula)
    let x = 300.0 * math.sin(u) + 75.0 * math.sin(2.0 * u);
    let z = 360.0 * math.cos(u) + 55.0 * math.cos(2.0 * u) - 25.0 * math.sin(u);
    return [x, z];
  }
  if (id == 2) {
    // Nebula Canyon: Titan Mountain Switchback (serpentine figure-8 with hairpins)
    let x = 200.0 * math.sin(u) + 120.0 * math.sin(3.0 * u) - 20.0 * math.sin(5.0 * u);
    let z = 380.0 * math.cos(u) + 30.0 * math.cos(2.0 * u);
    return [x, z];
  }
  // Hyperion Speedway: Orbital Tri-Oval Superspeedway
  let x = 320.0 * math.sin(u) + 80.0 * math.sin(2.0 * u);
  let z = 320.0 * math.cos(u) - 80.0 * math.cos(2.0 * u);
  return [x, z];
}

export fun getTrackTangent(id, s) {
  let lapLen = 1800.0;
  if (id == 1) lapLen = 2200.0;
  else if (id == 2) lapLen = 2600.0;
  else if (id == 3) lapLen = 2400.0;

  let u = (s / lapLen) * 6.2831853;
  if (id == 0) {
    let dx = 240.0 * math.cos(u) + 105.0 * math.cos(3.0 * u) - 50.0 * math.cos(5.0 * u);
    let dz = -380.0 * math.sin(u) - 120.0 * math.sin(3.0 * u);
    return [dx, dz];
  }
  if (id == 1) {
    let dx = 300.0 * math.cos(u) + 150.0 * math.cos(2.0 * u);
    let dz = -360.0 * math.sin(u) - 110.0 * math.sin(2.0 * u) - 25.0 * math.cos(u);
    return [dx, dz];
  }
  if (id == 2) {
    let dx = 200.0 * math.cos(u) + 360.0 * math.cos(3.0 * u) - 100.0 * math.cos(5.0 * u);
    let dz = -380.0 * math.sin(u) - 60.0 * math.sin(2.0 * u);
    return [dx, dz];
  }
  let dx = 320.0 * math.cos(u) + 160.0 * math.cos(2.0 * u);
  let dz = -320.0 * math.sin(u) + 160.0 * math.sin(2.0 * u);
  return [dx, dz];
}

export fun getTrackHeading(id, s) {
  let tan = getTrackTangent(id, s);
  return math.atan2(tan[0], tan[1]);
}

export fun getTrackBounds(id) {
  if (id == 0) return [-216.0, 216.0, -420.0, 420.0];
  if (id == 1) return [-330.0, 330.0, -360.0, 360.0];
  if (id == 2) return [-240.0, 240.0, -380.0, 380.0];
  return [-352.0, 352.0, -320.0, 320.0];
}

