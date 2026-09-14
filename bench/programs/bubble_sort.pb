let seed = 42;
let arr = [];
for (let i = 0; i < 5000; i = i + 1) {
  seed = (seed * 1103515245 + 12345) % 2147483648;
  arr.push(seed % 100000);
}

let n = len(arr);
for (let i = 0; i < n; i = i + 1) {
  for (let j = 0; j < n - i - 1; j = j + 1) {
    if (arr[j] > arr[j + 1]) {
      let temp = arr[j];
      arr[j] = arr[j + 1];
      arr[j + 1] = temp;
    }
  }
}

let sum = 0;
for (let i = 0; i < n; i = i + 1) {
  sum = sum + arr[i];
}

print(sum);
