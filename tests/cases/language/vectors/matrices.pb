use "std.math" as math;

print(mat4());
print(mat4().translate(5, 7));
print(mat4().scale(2, 3));
print(mat4().scale(2));
print(mat4().rotateZ(0) == mat4());
let base = mat4();
base.translate(5, 7);
print(base == mat4());
let chained = mat4().translate(1, 2).scale(2, 2);
print(chained * vec3(1, 1, 0));
print(mat4().translate(5, 7, 9) * vec4(1, 1, 1, 1));
print(mat4().translate(1, 2) * mat4().translate(3, 4) * vec3(0, 0, 0));
print(2 * mat4());
print(type(mat4()));
print(mat4() == mat4());
print(mat4().translate(1, 0) == mat4());
let spin = mat4().rotateZ(math.pi / 2) * vec3(1, 0, 0);
print(spin.y == 1);
print(spin.x < 0.000001 and spin.x > -0.000001);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|mat4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
//|mat4(1, 0, 0, 5, 0, 1, 0, 7, 0, 0, 1, 0, 0, 0, 0, 1)
//|mat4(2, 0, 0, 0, 0, 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
//|mat4(2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1)
//|true
//|true
//|vec3(3, 4, 0)
//|vec4(6, 8, 10, 1)
//|vec3(4, 6, 0)
//|mat4(2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2)
//|mat4
//|true
//|false
//|true
//|true
// END EXPECTED OUTPUT
