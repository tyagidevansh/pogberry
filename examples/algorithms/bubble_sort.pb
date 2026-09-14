fun bubbleSort(arr) {
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
}

let numbers = [64, 34, 25, 12, 22, 11, 90];
bubbleSort(numbers);
print(numbers); 
