var arr = [];

for (var i = 0; i < 5; i = i + 1) {
    // if no argumets are given, rand() generates a value from 0 to 1, floor() can be used to take out the integer part
    arr.push(floor(rand() * 100)); 
    // if argument is given, random numbers are generated in range 0 to arg
    arr.push(rand(100));
}

sort(arr);
print(arr);
