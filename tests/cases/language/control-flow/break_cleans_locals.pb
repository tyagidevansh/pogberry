var iterations = 0;
while (iterations < 20000) {
  while (true) {
    var temporary = iterations;
    iterations = temporary + 1;
    break;
  }
}
print(iterations);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|20000
// END EXPECTED OUTPUT
