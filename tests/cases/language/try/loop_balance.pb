let total = 0;
for (let i = 0; i < 1000; i += 1) {
  try {
    if (i % 2 == 0) throw i;
    total = total + 1;
  } catch (e) {
    total = total + e["value"];
  }
}
print(total);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|250000
// END EXPECTED OUTPUT
