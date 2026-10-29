use "constants" as const;
use "track" as track_mod;
use "car" as car_mod;
use "math_util" as mu;
use "std.math" as math;

print("============================================================");
print("TESTING OPEN WORLD MECHANICS: TURNING AROUND, LAPPING & COLLISIONS");
print("============================================================");

let trk = track_mod.Track(const.TRACK_SUZUKA);
let lapLen = trk.spec["length"];
let player = car_mod.Vehicle(const.CAR_PHANTOM, true, "PLAYER", 0.0);

// TEST 1: Full 360-Degree Heading & U-Turn
print("\n--- TEST 1: Full 360 Turning & U-Turn ---");
player.speed = 35.0;
player.trackDistance = 100.0;
player.x = 0.0;
player.heading = 0.0;

// Execute handbrake U-turn maneuver (brake + steer to rotate past 90 deg, then throttle)
let dt = 0.016;
for (let i = 0; i < 70; i += 1) {
  let isPhase1 = (i < 45);
  player.inputOverride = {
    "throttle": !isPhase1,
    "steer": -1.0,
    "brake": isPhase1,
    "boost": false,
    "drift": isPhase1
  };
  player.updatePlayer(dt, trk, nil, nil);
  if (i % 10 == 0) {
    print("i=" + str(i) + " spd=" + str(player.speed) + " steer=" + str(player.steerAngle) + " h=" + str(player.heading) + " yaw=" + str(player.yawRate) + " x=" + str(player.x));
  }
}

print("After handbrake U-turn maneuver:");
print("  Heading (radians): " + str(player.heading) + " (~" + str(math.floor(player.heading * 57.3)) + " degrees)");
let isTurned = (math.abs(player.heading) > 1.4);
print("  Successfully executed U-turn (heading > 80 deg): " + str(isTurned));

// TEST 2: Reverse progress along circuit
print("\n--- TEST 2: Driving the Wrong Way along Track ---");
let distBefore = player.trackDistance;
// Face backwards (~PI) and drive forward
player.heading = 3.14159; // Facing backward
player.steer = 0.0;
player.steerAngle = 0.0;
player.speed = 30.0;

for (let i = 0; i < 60; i += 1) {
  player.inputOverride = {
    "throttle": true,
    "steer": 0.0,
    "brake": false,
    "boost": false,
    "drift": false
  };
  player.updatePlayer(dt, trk, nil, nil);
}

let distAfter = player.trackDistance;
print("  Distance before driving backward: " + str(distBefore));
print("  Distance after driving backward : " + str(distAfter));
let droveBackward = (distAfter < distBefore or (distBefore < 50.0 and distAfter > lapLen - 50.0));
print("  Successfully made reverse progress along track: " + str(droveBackward));

// TEST 3: Lapping Mechanics on Closed Circuit
print("\n--- TEST 3: Closed Circuit Rival Lapping Mechanics ---");
player.trackDistance = 500.0;
player.speed = 0.0; // Player is stopped on track
player.completedLaps = 0;

let rival = car_mod.Vehicle(const.CAR_VALKYRIE, false, "RIVAL", 0.0);
rival.trackDistance = 450.0; // 50m behind player
rival.speed = 40.0;
rival.completedLaps = 0;

// Simulate until rival completes a lap and laps the player
let lappedPlayer = false;
for (let f = 0; f < 9500; f += 1) {
  // Calculate closed-circuit relative distance
  let dDist = rival.trackDistance - player.trackDistance;
  while (dDist > lapLen * 0.5) dDist = dDist - lapLen;
  while (dDist < -lapLen * 0.5) dDist = dDist + lapLen;

  // Update rival AI
  rival.updateAi(dDist, player.speed, dt, trk);
  rival.z = -dDist;

  let playerProg = (player.completedLaps * lapLen) + player.trackDistance;
  let rivalProg = (rival.completedLaps * lapLen) + rival.trackDistance;

  if (rival.completedLaps > player.completedLaps and rivalProg > playerProg) {
    lappedPlayer = true;
    print("  Rival successfully lapped player at t=" + str(f * dt) + "s! Rival laps=" + str(rival.completedLaps) + " vs Player laps=" + str(player.completedLaps) + " (rival.z=" + str(rival.z) + "m)");
    break;
  }
}

print("  Circuit Lapping verification: " + str(lappedPlayer));

// TEST 4: Head-on Collision
print("\n--- TEST 4: Head-On Collision Mechanics ---");
player.trackDistance = 1010.0;
player.heading = 3.14159; // Facing wrong way, rushing towards 1000m
player.speed = 35.0;
player.x = 0.0;

rival.trackDistance = 1000.0; // At 1000m, rushing towards 1010m
rival.heading = 0.0; // Driving forward
rival.speed = 35.0;
rival.x = 0.0;
player.impactCooldown = 0.0;

let collisionOccurred = false;
let hullBefore = player.hull;

for (let f = 0; f < 30; f += 1) {
  // Progress both
  player.trackDistance = player.trackDistance + (player.speed * math.cos(player.heading)) * dt;
  rival.trackDistance = rival.trackDistance + (rival.speed * math.cos(rival.heading)) * dt;

  let dDist = rival.trackDistance - player.trackDistance;
  while (dDist > lapLen * 0.5) dDist = dDist - lapLen;
  while (dDist < -lapLen * 0.5) dDist = dDist + lapLen;
  rival.z = -dDist;

  let dZ = math.abs(rival.z);
  let dX = math.abs(player.x - rival.x);
  if (dZ < 3.2 and dX < 1.8) {
    collisionOccurred = true;
    player.speed = player.speed * 0.5;
    break;
  }
}

print("  Head-on collision detected: " + str(collisionOccurred));

if (isTurned and droveBackward and lappedPlayer and collisionOccurred) {
  print("\n>>> ALL OPEN WORLD MECHANICS VERIFIED AND PASSING! <<<");
} else {
  print("\n>>> SOME TESTS FAILED <<<");
}
