let i = 0;
let whileSum = 0;
while (i < 6) {
  i = i + 1;
  if (i % 2 == 1) continue;
  whileSum = whileSum + i;
}
print(whileSum);

let forSum = 0;
for (let j = 0; j < 6; j += 1) {
  if (j == 2 or j == 4) continue;
  forSum += j;
}
print(forSum);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|12
//|9
// END EXPECTED OUTPUT
