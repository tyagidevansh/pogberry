try {
  throw 42;
} catch (e) {
  print(e["value"]);
}
try {
  throw nil;
} catch (e) {
  print(e["value"]);
}
try {
  throw {"code": 7};
} catch (e) {
  print(e["value"]["code"]);
  print(e["message"]);
}
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|42
//|nil
//|7
//|{code: 7}
// END EXPECTED OUTPUT
