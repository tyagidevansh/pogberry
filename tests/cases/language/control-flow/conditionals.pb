if (true) {
  print("then");
} else {
  print("else");
}
if (nil) {
  print("wrong");
} else {
  print("nil is falsey");
}
if (0) print("zero is truthy");
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|then
//|nil is falsey
//|zero is truthy
// END EXPECTED OUTPUT
