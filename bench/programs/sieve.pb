fun count_primes(limit) {
  let flags = [];
  for (let i = 0; i <= limit; i = i + 1) {
    flags.push(true);
  }

  for (let p = 2; p * p <= limit; p = p + 1) {
    if (flags[p]) {
      for (let k = p * p; k <= limit; k = k + p) {
        flags[k] = false;
      }
    }
  }

  let count = 0;
  for (let p = 2; p <= limit; p = p + 1) {
    if (flags[p]) count = count + 1;
  }
  return count;
}

let total = 0;
for (let i = 0; i < 100; i = i + 1) {
  total = total + count_primes(10000);
}

print(total);

