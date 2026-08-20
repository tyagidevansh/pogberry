use "std.math";

let arr = [];

for (var i = 0; i < 5; i = i + 1) {
    arr.push(math.floor(rand() * 100));
    arr.push(rand(100));
}

arr.sort();
print(arr);
