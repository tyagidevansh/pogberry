let m = mat4();
m.foo = 1;
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|Matrices are immutable.
//|[line 2] in script
// END EXPECTED OUTPUT
