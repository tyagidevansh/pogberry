let p = vec2(1, 2);
print(p + vec2(3, 4));
print(p - vec2(0.5, 1));
print(p * 3);
print(3 * p);
print(p / 2);
print(-p);
p += vec2(10, 10);
print(p);
print(vec2(1, 2) == vec2(1, 2));
print(vec2(1, 2) != vec2(1, 3));
print(vec2(1, 2) == vec3(1, 2, 3));
print(str(vec3(1, 2, 3)));
print(vec4(1, 2, 3, 4) - vec4(0, 1, 0, 1));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|vec2(4, 6)
//|vec2(0.5, 1)
//|vec2(3, 6)
//|vec2(3, 6)
//|vec2(0.5, 1)
//|vec2(-1, -2)
//|vec2(11, 12)
//|true
//|true
//|false
//|vec3(1, 2, 3)
//|vec4(1, 1, 3, 3)
// END EXPECTED OUTPUT
