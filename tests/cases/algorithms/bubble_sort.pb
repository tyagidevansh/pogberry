fun bubbleSort(values) {
  let n = len(values);
  for (let i = 0; i < n; i = i + 1) {
    for (let j = 0; j < n - i - 1; j = j + 1) {
      if (values[j] > values[j + 1]) {
        let temporary = values[j];
        values[j] = values[j + 1];
        values[j + 1] = temporary;
      }
    }
  }
}
let numbers = [64, 34, 25, 12, 22, 11, 90];
bubbleSort(numbers);
print(numbers);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|[11, 12, 22, 25, 34, 64, 90]
// END EXPECTED OUTPUT
