fun bubbleSort(arr) {
    var n = arr.size();
    for (var i = 0; i < n; i = i + 1) {
        for (var j = 0; j < n - i - 1; j = j + 1) {
            if (arr[j] > arr[j + 1]) {
                var temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
            }
        }
    }
}

var numbers = [64, 34, 25, 12, 22, 11, 90];
bubbleSort(numbers);
print(numbers); 
