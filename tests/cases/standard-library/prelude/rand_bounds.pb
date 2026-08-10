let bounded = rand(10);
let normalized = rand();
print(bounded >= 0 and bounded < 10);
print(normalized >= 0 and normalized <= 1);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|true
//|true
// END EXPECTED OUTPUT
