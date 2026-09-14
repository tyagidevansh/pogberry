let a = 1;
let b = 2;
(a + b) = 3;
// EXPECTED STATUS: 65
// EXPECTED OUTPUT:
//|(a + b) = 3;
//|        ^
//|[line 3] Error at '=': Invalid assignment target.
// END EXPECTED OUTPUT
