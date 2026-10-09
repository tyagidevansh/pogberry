try {
  let treasure = 1;
  nope();
} catch (e) {
  print(treasure);
}
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|Undefined variable 'treasure'.
//|[line 5] in script
// END EXPECTED OUTPUT
