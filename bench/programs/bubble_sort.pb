var seed = 42;
var arr = [];
for (var i = 0; i < 5000; i = i + 1) {
  seed = (seed * 1103515245 + 12345) % 2147483648;
  arr.push(seed % 100000);
}

var n = len(arr);
for (var i = 0; i < n; i = i + 1) {
  for (var j = 0; j < n - i - 1; j = j + 1) {
    if (arr[j] > arr[j + 1]) {
      var temp = arr[j];
      arr[j] = arr[j + 1];
      arr[j + 1] = temp;
    }
  }
}

var sum = 0;
for (var i = 0; i < n; i = i + 1) {
  sum = sum + arr[i];
}

print(sum);
