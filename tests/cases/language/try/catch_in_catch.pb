try {
  try {
    throw "inner";
  } catch (e) {
    print(e["value"]);
    nope();
  }
} catch (outer) {
  print(outer["message"]);
}
print("after");
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|inner
//|Undefined variable 'nope'.
//|after
// END EXPECTED OUTPUT
