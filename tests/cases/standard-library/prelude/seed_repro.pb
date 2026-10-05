seed(42);
let a = rand();
let b = rand(100);
seed(42);
let c = rand();
let d = rand(100);
print(a == c);
print(b == d);
print(a >= 0 and a <= 1);
print(b >= 0 and b < 100);
seed(1);
let e = rand();
seed(2);
let f = rand();
print(e != f);
seed(0);
print(rand() >= 0 and rand() <= 1);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|true
//|true
//|true
//|true
//|true
//|true
// END EXPECTED OUTPUT
