// TURBO CIRCUIT: OVERDRIVE — Automated AI Agent Driver & Telemetry System
use "constants" as const;
use "track" as track_mod;
use "car" as car_mod;
use "particles" as part_mod;
use "math_util" as mu;
use "std.math" as math;

export class DriverBot {
  init(behaviorMode) {
    this.mode = behaviorMode; // "NO_STEER", "HUMAN_ARCADE", "PRO_RACER"
    this.driftActive = false;
    this.driftTimer = 0.0;
  }

  computeInput(player, track) {
    let input = {
      "throttle": true,
      "steer": 0.0,
      "brake": false,
      "boost": false,
      "drift": false
    };

    if (this.mode == "NO_STEER") {
      // Just hold throttle, zero steering
      return input;
    }

    // Racing line lookahead
    let speed = player.speed;
    let dist = player.trackDistance;
    let lookDist = 26.0 + (speed / 70.0) * 14.0;

    let curveOffset = track.getCurveOffset(-lookDist, dist);
    let curv = track.getCurvature(0.0, dist);
    let lookCurv = track.getCurvature(-lookDist, dist);
    let maxCurv = math.max(math.abs(curv), math.abs(lookCurv));

    // Pure Pursuit heading error towards lookahead track trajectory
    let targetLat = curveOffset * 0.70;
    let latDelta = targetLat - player.x;
    let desiredHeading = math.atan2(latDelta, lookDist);
    let headingError = desiredHeading - player.heading;

    let desiredSteer = mu.clamp(headingError * 1.8 - curv * 24.0, -1.0, 1.0);
    input["steer"] = desiredSteer;

    // Corner braking & power drift logic
    if (this.mode == "HUMAN_ARCADE" or this.mode == "PRO_RACER") {
      // Brake if approaching sharp corner at high speed
      let brake = (maxCurv > 0.018 and speed > 62.0) or (maxCurv > 0.028 and speed > 42.0);
      if (brake) {
        input["brake"] = true;
        input["throttle"] = false;
      }

      // Initiate power drift on medium and sharp corners
      if (maxCurv > 0.014 and math.abs(desiredSteer) > 0.35 and speed > 35.0) {
        input["drift"] = true;
        this.driftActive = true;
      } else {
        this.driftActive = false;
      }

      // Nitro boost on clean straights
      let isStraight = (maxCurv < 0.004 and math.abs(player.x) < 4.5);
      if (isStraight and speed > 50.0 and player.nitro > 15.0) {
        input["boost"] = true;
      }
    }

    return input;
  }
}

export class TelemetryCollector {
  init(trackId, carId, label) {
    this.trackId = trackId;
    this.carId = carId;
    this.label = label;

    this.totalTime = 0.0;
    this.totalFrames = 0;
    this.maxSpeed = 0.0;
    this.avgSpeedSum = 0.0;
    this.maxAbsX = 0.0;
    this.offTrackTime = 0.0;
    this.wallHits = 0;
    this.driftsCompleted = 0;
    this.boostTime = 0.0;
    this.minHull = 100.0;
    this.wasDrifting = false;
    this.finishedLap = false;
    this.lapTime = 0.0;

    // Jitter measurement: track segment vertex positions across consecutive frames
    this.vertexSamples = [];
    this.maxVertexJerk = 0.0;
    this.prevVertexX = 0.0;
    this.prevVertexVel = 0.0;
  }

  recordFrame(player, track, dt) {
    this.totalTime = this.totalTime + dt;
    this.totalFrames = this.totalFrames + 1;

    let spd = player.speed;
    if (spd > this.maxSpeed) this.maxSpeed = spd;
    this.avgSpeedSum = this.avgSpeedSum + spd;

    let absX = math.abs(player.x);
    if (absX > this.maxAbsX) this.maxAbsX = absX;

    if (player.isOffTrack) this.offTrackTime = this.offTrackTime + dt;
    if (player.hull < this.minHull) this.minHull = player.hull;

    if (player.wallHitShake > 0.0) {
      this.wallHits = this.wallHits + 1;
      player.wallHitShake = 0.0;
    }

    if (player.isDrifting and !this.wasDrifting) {
      this.driftsCompleted = this.driftsCompleted + 1;
    }
    this.wasDrifting = player.isDrifting;

    if (player.isBoosting) {
      this.boostTime = this.boostTime + dt;
    }

    // Check lap completion
    let lapLen = track.spec["length"];
    if ((player.completedLaps > 0 or player.trackDistance >= lapLen) and !this.finishedLap) {
      this.finishedLap = true;
      this.lapTime = this.totalTime;
    }

    // Measure road geometry smoothness (mid-distance vertex at 30m ahead)
    let sampleZ = -30.0;
    let vertX = track.getCurveOffset(sampleZ, player.trackDistance);
    if (this.totalFrames > 2) {
      let vel = (vertX - this.prevVertexX) / dt;
      let accel = math.abs(vel - this.prevVertexVel) / dt;
      if (accel > this.maxVertexJerk) this.maxVertexJerk = accel;
      this.prevVertexVel = vel;
    }
    this.prevVertexX = vertX;
  }

  getSummary() {
    let avgSpeed = 0.0;
    if (this.totalFrames > 0) avgSpeed = this.avgSpeedSum / this.totalFrames;
    return {
      "label": this.label,
      "totalTime": this.totalTime,
      "finishedLap": this.finishedLap,
      "lapTime": this.lapTime,
      "maxSpeed": this.maxSpeed,
      "avgSpeed": avgSpeed,
      "maxAbsX": this.maxAbsX,
      "offTrackTime": this.offTrackTime,
      "wallHits": this.wallHits,
      "driftsCompleted": this.driftsCompleted,
      "boostTime": this.boostTime,
      "minHull": this.minHull,
      "maxVertexJerk": this.maxVertexJerk
    };
  }

  printReport() {
    let s = this.getSummary();
    print("------------------------------------------------------------");
    print("TELEMETRY REPORT: " + s["label"]);
    print("------------------------------------------------------------");
    print("  Time Simulated    : " + str(s["totalTime"]) + " s (" + str(this.totalFrames) + " frames)");
    print("  Lap Completed     : " + str(s["finishedLap"]) + " (Lap Time: " + str(s["lapTime"]) + " s)");
    print("  Max Speed         : " + str(s["maxSpeed"]) + " MPH | Avg Speed: " + str(s["avgSpeed"]) + " MPH");
    print("  Max Lateral |X|   : " + str(s["maxAbsX"]) + " m");
    print("  Off-Track Time    : " + str(s["offTrackTime"]) + " s");
    print("  Wall Collisions   : " + str(s["wallHits"]));
    print("  Drifts Executed   : " + str(s["driftsCompleted"]));
    print("  Nitro Boost Time  : " + str(s["boostTime"]) + " s");
    print("  Min Hull Left     : " + str(s["minHull"]) + " HP");
    print("  Max Vertex Jerk   : " + str(s["maxVertexJerk"]) + " m/s^2");
    print("------------------------------------------------------------");
  }
}
