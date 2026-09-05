fun count_primes(limit) {
  var flags = [];
  for (var i = 0; i <= limit; i = i + 1) {
    flags.push(true);
  }

  for (var p = 2; p * p <= limit; p = p + 1) {
    if (flags[p]) {
      for (var k = p * p; k <= limit; k = k + p) {
        flags[k] = false;
      }
    }
  }

  var count = 0;
  for (var p = 2; p <= limit; p = p + 1) {
    if (flags[p]) count = count + 1;
  }
  return count;
}

var total = 0;
for (var i = 0; i < 100; i = i + 1) {
  total = total + count_primes(10000);
}

print(total);

