fun inner() {
  return nope() + 1;
}

fun outer() {
  try {
    return inner();
  } catch (e) {
    print(len(e["trace"]));
    return "caught";
  }
}

print(outer());

fun thrower() {
  throw 42;
}

try {
  thrower();
} catch (e) {
  print(e["value"]);
}
print("after");
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|3
//|caught
//|42
//|after
// END EXPECTED OUTPUT
