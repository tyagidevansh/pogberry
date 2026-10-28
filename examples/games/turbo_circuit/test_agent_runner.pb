use "constants" as const;
use "track" as track_mod;
use "car" as car_mod;
use "particles" as part_mod;
use "agent_driver" as bot_mod;

fun runTrial(trackId, carId, mode, maxSeconds) {
  let trk = track_mod.Track(trackId);
  let player = car_mod.Vehicle(carId, true, "PLAYER", 0.0);
  let particles = part_mod.ParticleSystem();
  let bot = bot_mod.DriverBot(mode);
  let trkSpec = const.getTrackSpec(trackId);
  let carSpec = const.getCarSpec(carId);
  let label = mode + " | " + carSpec["name"] + " on " + trkSpec["name"];
  let telemetry = bot_mod.TelemetryCollector(trackId, carId, label);

  let dt = 0.016;
  let maxFrames = maxSeconds / dt;

  for (let f = 0; f < maxFrames; f += 1) {
    let input = bot.computeInput(player, trk);
    player.inputOverride = input;

    player.updatePlayer(dt, trk, particles, nil);
    telemetry.recordFrame(player, trk, dt);

    if (telemetry.finishedLap) {
      break;
    }
  }

  telemetry.printReport();
  return telemetry.getSummary();
}

print("============================================================");
print("COMPREHENSIVE CHAMPIONSHIP BENCHMARK ACROSS ALL CIRCUITS");
print("============================================================");

let trackTimeouts = [180.0, 120.0, 220.0, 180.0];

for (let tId = 0; tId < const.TOTAL_TRACKS; tId += 1) {
  print("\n>>> TESTING CIRCUIT " + str(tId) + " <<<");
  // 1. Unsteered test (proves user MUST steer)
  runTrial(tId, const.CAR_PHANTOM, "NO_STEER", 45.0);
  // 2. Active arcade racer test
  runTrial(tId, const.CAR_PHANTOM, "HUMAN_ARCADE", trackTimeouts[tId]);
}

print("\n>>> TESTING MACHINE ROSTER on SUZUKA GP <<<");
for (let cId = 0; cId < const.TOTAL_CARS; cId += 1) {
  runTrial(const.TRACK_SUZUKA, cId, "HUMAN_ARCADE", 180.0);
}

print("ALL CHAMPIONSHIP BENCHMARKS COMPLETED!");
