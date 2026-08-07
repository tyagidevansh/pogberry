fun applyTwice(value) {
  fun double(number) {
    return number * 2;
  }
  return double(double(value));
}
fun fib(n) {
  if (n <= 1) return n;
  return fib(n - 1) + fib(n - 2);
}
print(applyTwice(3));
print(fib(8));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|12
//|21
// END EXPECTED OUTPUT
