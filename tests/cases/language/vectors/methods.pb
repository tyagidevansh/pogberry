let p = vec2(3, 4);
print(p.x);
print(p.y);
print(vec3(1, 2, 3).z);
print(vec4(1, 2, 3, 4).w);
print(p.dot(vec2(1, 0)));
print(p.length());
print(p.normalize());
print(type(vec2(0, 0)));
print(type(vec3(0, 0, 0)));
print(type(vec4(0, 0, 0, 0)));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|3
//|4
//|3
//|4
//|3
//|5
//|vec2(0.6, 0.8)
//|vec2
//|vec3
//|vec4
// END EXPECTED OUTPUT
