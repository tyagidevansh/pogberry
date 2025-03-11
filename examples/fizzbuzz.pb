fun fizzbuzz(n) {
    for (var i = 1; i <= n; i = i + 1) {
        if (i % 3 == 0 and i % 5 == 0) {
            print("FizzBuzz");
        } else if (i % 3 == 0) {
            print("Fizz");
        } else if(i % 5 == 0) {
            print("Buzz");
        } else {
            print(i);
        }
    }
}

fizzbuzz(20);