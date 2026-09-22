use "std.math";

print(math.ceil(4.1));
print(math.ceil(-2.9));
print(math.round(4.4));
print(math.round(4.6));
print(math.pow(3, 4));
print(math.sin(0));
print(math.cos(0));
print(math.tan(0));
print(math.atan2(0, 1));
print(math.lerp(10, 20, 0.5));
print(math.dist(0, 0, 3, 4));
print(math.rad2deg(math.deg2rad(90)));

// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|5
//|-2
//|4
//|5
//|81
//|0
//|1
//|0
//|0
//|15
//|5
//|90
// END EXPECTED OUTPUT

