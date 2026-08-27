class Base {
  init(value) {
    this.value = value;
  }

  compute(x) {
    return this.value + x;
  }
}

class Middle < Base {
  init(value) {
    super.init(value);
    this.factor = 2;
  }

  compute(x) {
    return super.compute(x) * this.factor;
  }
}

class Leaf < Middle {
  init(value) {
    super.init(value);
    this.offset = 3;
  }

  compute(x) {
    return super.compute(x) + this.offset;
  }
}

let sum = 0;
for (var i = 0; i < 100000; i = i + 1) {
  let obj = Leaf(i);
  sum = sum + obj.compute(i);
}

print(sum);
