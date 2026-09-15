fun makeGetter() {
  let getter = nil;
  while (true) {
    let captured = "still alive";
    fun get() {
      return captured;
    }
    getter = get;
    break;
  }
  return getter;
}

let get = makeGetter();
for (let i = 0; i < 20000; i = i + 1) {
  let temporary = [i, i + 1, i + 2];
}
print(get());
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|still alive
// END EXPECTED OUTPUT
