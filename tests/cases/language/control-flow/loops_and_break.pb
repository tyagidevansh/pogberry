var i = 0;
while (i < 3) {
  print("while " + i);
  i = i + 1;
}
for (var j = 0; j < 5; j = j + 1) {
  if (j == 3) break;
  print("for " + j);
}
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|while 0
//|while 1
//|while 2
//|for 0
//|for 1
//|for 2
// END EXPECTED OUTPUT
