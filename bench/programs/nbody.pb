use "std.math";

class Body {
  init(x, y, z, vx, vy, vz, mass) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.vx = vx;
    this.vy = vy;
    this.vz = vz;
    this.mass = mass;
  }
}

fun advance(bodies, dt) {
  let n = len(bodies);
  for (var i = 0; i < n; i = i + 1) {
    let bi = bodies[i];
    for (var j = i + 1; j < n; j = j + 1) {
      let bj = bodies[j];
      let dx = bi.x - bj.x;
      let dy = bi.y - bj.y;
      let dz = bi.z - bj.z;
      let dsq = dx * dx + dy * dy + dz * dz;
      let distance = math.sqrt(dsq);
      let mag = dt / (dsq * distance);

      bi.vx = bi.vx - dx * bj.mass * mag;
      bi.vy = bi.vy - dy * bj.mass * mag;
      bi.vz = bi.vz - dz * bj.mass * mag;

      bj.vx = bj.vx + dx * bi.mass * mag;
      bj.vy = bj.vy + dy * bi.mass * mag;
      bj.vz = bj.vz + dz * bi.mass * mag;
    }
  }

  for (var i = 0; i < n; i = i + 1) {
    let b = bodies[i];
    b.x = b.x + dt * b.vx;
    b.y = b.y + dt * b.vy;
    b.z = b.z + dt * b.vz;
  }
}

fun energy(bodies) {
  let n = len(bodies);
  var e = 0.0;
  for (var i = 0; i < n; i = i + 1) {
    let bi = bodies[i];
    e = e + 0.5 * bi.mass * (bi.vx * bi.vx + bi.vy * bi.vy + bi.vz * bi.vz);
    for (var j = i + 1; j < n; j = j + 1) {
      let bj = bodies[j];
      let dx = bi.x - bj.x;
      let dy = bi.y - bj.y;
      let dz = bi.z - bj.z;
      let distance = math.sqrt(dx * dx + dy * dy + dz * dz);
      e = e - (bi.mass * bj.mass) / distance;
    }
  }
  return e;
}

fun main() {
  let PI = 3.141592653589793;
  let SOLAR_MASS = 4.0 * PI * PI;
  let DAYS_PER_YEAR = 365.24;

  let bodies = [
    Body(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, SOLAR_MASS),
    Body(
      4.8414314424647209,
      -1.16032004402742839,
      -0.103622044471123109,
      0.00166007664274403694 * DAYS_PER_YEAR,
      0.00769901111281974650 * DAYS_PER_YEAR,
      -0.0000690460016972063023 * DAYS_PER_YEAR,
      0.000954791938424326609 * SOLAR_MASS
    ),
    Body(
      8.3433664256532493,
      4.12479856412430479,
      -0.403523417114321381,
      -0.00276742510726862411 * DAYS_PER_YEAR,
      0.00499852801234917238 * DAYS_PER_YEAR,
      0.0000230417297573763929 * DAYS_PER_YEAR,
      0.00028588567272224177 * SOLAR_MASS
    ),
    Body(
      12.894369562139131,
      -15.1111514016986312,
      -0.223307578892655734,
      0.00296460137564761618 * DAYS_PER_YEAR,
      0.0023784717395948095 * DAYS_PER_YEAR,
      -0.0000296589568540237556 * DAYS_PER_YEAR,
      0.0000436624404335156298 * SOLAR_MASS
    ),
    Body(
      15.3796971148509165,
      -25.9193146099879641,
      0.179258772950371181,
      0.00268067772490024322 * DAYS_PER_YEAR,
      0.00162824170038242295 * DAYS_PER_YEAR,
      -0.000095159225451971587 * DAYS_PER_YEAR,
      0.0000515138902046611451 * SOLAR_MASS
    )
  ];

  // Offset momentum of the sun
  var px = 0.0;
  var py = 0.0;
  var pz = 0.0;
  for (var i = 0; i < len(bodies); i = i + 1) {
    let b = bodies[i];
    px = px + b.vx * b.mass;
    py = py + b.vy * b.mass;
    pz = pz + b.vz * b.mass;
  }
  bodies[0].vx = -px / SOLAR_MASS;
  bodies[0].vy = -py / SOLAR_MASS;
  bodies[0].vz = -pz / SOLAR_MASS;

  for (var step = 0; step < 50000; step = step + 1) {
    advance(bodies, 0.01);
  }

  let finalE = energy(bodies);
  let rounded = math.floor(finalE * 10000) / 10000;
  print(rounded);
}

main();

