let x = 1;
try {
  x = 2;
  nope();
  x = 99;
} catch (e) {
  print(x);
  print(e["message"]);
  print(len(e["trace"]));
}
print(x);
try {
  throw "boom";
} catch (e) {
  print(e["value"]);
  print(e["message"]);
}
print("after");
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|2
//|Undefined variable 'nope'.
//|1
//|2
//|boom
//|boom
//|after
// END EXPECTED OUTPUT
