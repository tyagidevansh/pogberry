fun fib_iter(n) {
  let a = 0;
  let b = 1;
  for (let i = 0; i < n; i = i + 1) {
    let c = a + b;
    a = b;
    b = c;
  }
  return a;
}

let total = 0;
for (let i = 0; i < 200000; i = i + 1) {
  total = (total + fib_iter(30)) % 1000000007;
}

print(total);

