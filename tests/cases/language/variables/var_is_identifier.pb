let var = 10;
var = var + 5;
print(var);

fun identity(var) {
  return var;
}

print(identity(20));

// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|15
//|20
// END EXPECTED OUTPUT