fun makeGetter() {
  var getter = nil;
  while (true) {
    var captured = "still alive";
    fun get() {
      return captured;
    }
    getter = get;
    break;
  }
  return getter;
}

var get = makeGetter();
for (var i = 0; i < 20000; i = i + 1) {
  var temporary = [i, i + 1, i + 2];
}
print(get());
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|still alive
// END EXPECTED OUTPUT
