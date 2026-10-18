// TURBO CIRCUIT: OVERDRIVE — Math Utilities
use "std.math" as math;

export fun clamp(v, lo, hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

export fun lerp(a, b, t) {
  return a + (b - a) * t;
}

export fun approach(current, target, rate) {
  if (current < target) {
    let nextVal = current + rate;
    if (nextVal > target) return target;
    return nextVal;
  }
  let nextVal = current - rate;
  if (nextVal < target) return target;
  return nextVal;
}

export fun distance2D(x1, z1, x2, z2) {
  let dx = x2 - x1;
  let dz = z2 - z1;
  return math.sqrt(dx * dx + dz * dz);
}

export fun distance3D(x1, y1, z1, x2, y2, z2) {
  let dx = x2 - x1;
  let dy = y2 - y1;
  let dz = z2 - z1;
  return math.sqrt(dx * dx + dy * dy + dz * dz);
}

export fun randFloat(minVal, maxVal) {
  let r = (rand(10000)) / 10000.0;
  return minVal + (maxVal - minVal) * r;
}

export fun sign(v) {
  if (v < 0) return -1.0;
  if (v > 0) return 1.0;
  return 0.0;
}

export fun sinWave(t, speed, amplitude) {
  return math.sin(t * speed) * amplitude;
}

