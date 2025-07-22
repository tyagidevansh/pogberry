// Variables and arithmetic
var a = 5;
var b = 10;
print("Sum: " + (a + b)); // Sum: 15

// Strings and concatenation
var greeting = "Hello, ";
var name = "Pogberry";
print(greeting + name); // Hello, Pogberry

// Control flow
if (a < b) {
  print("a is less than b");
} else {
  print("a is not less than b");
}

var i = 0;
while (i < 3) {
  print("while: " + i);
  i = i + 1;
}

for (var j = 0; j < 3; j = j + 1) {
  print("for: " + j);
}

// Arrays
var arr = [1, 2, 3];
arr.push(4);
print("Array: " + arr); // [1, 2, 3, 4]
arr.remove(1); // remove element at index 1
print("After remove: " + arr); // [1, 3, 4]

// Hashmaps
var map = {
  "name": "Pog",
  "lang": "Berry"
};
map["year"] = 2025;
print("Map: " + map);
print("Lang: " + map["lang"]);

// Functions
fun square(x) {
  return x * x;
}
print("Square of 5: " + square(5)); // 25

fun fib(n) {
  if (n <= 1) return n;
  return fib(n - 1) + fib(n - 2);
}
print("fib(6): " + fib(6)); // 8

// Classes and Inheritance
class Animal {
  init(name) {
    this.name = name;
  }

  speak() {
    print(this.name + " makes a sound.");
  }
}

class Dog < Animal {
  speak() {
    print(this.name + " barks.");
  }
}

var pet = Dog("Buddy");
pet.speak(); // Buddy barks.

// Native functions
print("abs(-10): " + abs(-10)); // 10
print("floor(3.9): " + floor(3.9)); // 3
