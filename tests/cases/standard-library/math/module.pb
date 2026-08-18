use "std.math";
use "std.math" as sameMath;

print(math == sameMath);
print(math.pi > 3.14 and math.pi < 3.15);
print(math.e > 2.71 and math.e < 2.72);
print(math.abs(-8));
print(math.floor(4.9));
print(math.sqrt(144));
print(math.min(7, 3));
print(math.max(7, 3));
print(math.clamp(-2, 0, 10));
print(math.clamp(4, 0, 10));
print(math.clamp(12, 0, 10));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|true
//|true
//|true
//|8
//|4
//|12
//|3
//|7
//|0
//|4
//|10
// END EXPECTED OUTPUT
