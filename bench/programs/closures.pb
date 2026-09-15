fun makeAccumulator(start) {
  let total = start;
  fun add(n) {
    total = total + n;
    return total;
  }
  return add;
}

let accumulators = [];
for (let i = 0; i < 10; i = i + 1) {
  accumulators.push(makeAccumulator(i));
}

let sum = 0;
for (let i = 0; i < 10; i = i + 1) {
  let acc = accumulators[i];
  let last = 0;
  for (let j = 0; j < 10000; j = j + 1) {
    last = acc(1);
  }
  sum = sum + last;
}

print(sum);
