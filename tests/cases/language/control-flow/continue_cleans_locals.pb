let iterations = 0;
while (iterations < 20000) {
  iterations += 1;
  let a = iterations;
  {
    let b = a + 1;
    if (b > 0) continue;
  }
}
print(iterations);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|20000
// END EXPECTED OUTPUT
