fun fib_iter(n) {
  var a = 0;
  var b = 1;
  for (var i = 0; i < n; i = i + 1) {
    var c = a + b;
    a = b;
    b = c;
  }
  return a;
}

var total = 0;
for (var i = 0; i < 200000; i = i + 1) {
  total = (total + fib_iter(30)) % 1000000007;
}

print(total);

