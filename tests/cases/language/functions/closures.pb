fun makeCounter(start) {
  var value = start;
  fun next() {
    value = value + 1;
    return value;
  }
  return next;
}

var first = makeCounter(10);
var second = makeCounter(100);
print(first());
print(first());
print(second());

fun outer() {
  var message = "captured";
  fun middle() {
    fun inner() {
      return message;
    }
    return inner;
  }
  return middle();
}
print(outer()());

class Box {
  init(value) {
    this.value = value;
  }

  getter() {
    fun get() {
      return this.value;
    }
    return get;
  }
}
var getBox = Box(42).getter();
print(getBox());
print(type(getBox));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|11
//|12
//|101
//|captured
//|42
//|function
// END EXPECTED OUTPUT
