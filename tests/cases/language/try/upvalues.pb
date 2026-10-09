fun make() {
  let x = 1;
  fun get() {
    return x;
  }
  try {
    x = 2;
    nope();
  } catch (e) {
    x = 3;
  }
  return get;
}

let g = make();
print(g());

fun deep() {
  let y = 10;
  fun get() {
    return y;
  }
  try {
    try {
      y = 20;
      nope();
    } catch (inner) {
      y = 30;
      throw "rethrown";
    }
  } catch (outer) {
    print(y);
    print(outer["value"]);
  }
  return get;
}

print(deep()());
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|3
//|30
//|rethrown
//|30
// END EXPECTED OUTPUT
