# Pogberry Interpreter

Welcome to the Pogberry Interpreter! This project is an interpreter for the Pogberry language, based on the CLOX interpreter from the book "Crafting Interpreters" by Robert Nystrom.

## Table of Contents

- [Introduction](#introduction)
- [How It Works](#how-it-works)
- [Syntax](#syntax)
- [Arrays and Hashmaps](#arrays-and-hashmaps)
- [Classes](#classes)
- [Native Functions](#native-functions)
- [Getting Started](#getting-started)

## Introduction

Pogberry is a simple programming language designed for learning and experimentation. My future plans for this language remain unknown. This interpreter allows you to execute Pogberry code and explore its features (more features coming soon!).

## How It Works

Here's what happens when you run Pogberry code:

1. **Tokenization**: First, the interpreter reads your code character by character and groups them into meaningful "words" (tokens) - like how you'd recognize words in a sentence.
2. **Parsing**: Then, it makes sure those words form valid "sentences" according to Pogberry's grammar rules.
3. **Bytecode Generation**: Next, it translates your human-readable code into simple instructions the computer can understand more easily.
4. **Interpretation**: Finally, the VM kicks into action and goes through the stack from top to bottom, executing each instruction it comes across. All the bytecode as well as the local data (indexes, variables inside functions etc) live inside this stack. Functions, strings and other objects are allocated separately.

## Syntax

Pogberry uses a friendly, easy-to-read syntax. Here are the basics:

### Variables

```pogberry
var x = 10;
var name = "Pogberry";
```

### Functions

```pogberry
fun greet() {
  print "Hello, World!";
}
```

### Control Flow

```pogberry
if (x > 5) {
  print "x is greater than 5";
} else {
  print "x is 5 or less";
}
```

### Loops

```pogberry
for (var i = 0; i < 10; i = i + 1) {
  print i;
}
```

### Strings

All strings are interned in pogberry! This means that if two strings have the same value, they MUST reside at the same address. Whenever you allocate a new string, the string pool is first checked if the same string exists in memory already. If it does, reference to the other string is returned.
Concatenation makes new strings. "+" is the supported concatenation operator. Numbers are coerced into strings when using concatenation.

```pogberry
var a = "Hello"; //defining a string
var b = a + " World" //concatenation

print a[3]; //Outputs: l
```

## Arrays and Hashmaps

Pogberry supports arrays and hashmaps for managing collections of data.

### Arrays

Arrays are ordered collections of elements. Pogberry supports mixed type arrays, you can have floats, ints and strings inside a single list without any problems. Multi-levelelled lists are also supported. You can create, access, and manipulate arrays using the following syntax:

```pogberry
var numbers = [1, 2, 3, 4, 5];
print numbers[0]; // Outputs: 1

numbers.push(6);
print numbers; // Outputs: [1, 2, 3, 4, 5, 6]

numbers.add(9, 3)
print numbers; //Outputs: [1, 2, 3, 9, 4, 5, 6]

numbers.pop();
print numbers; //Outputs: [1, 2, 3, 9, 4, 5]

numbers.remove(3) // provide index
print numbers; //Outputs: [1, 2, 3, 4, 5]

numbers.sort();
print numbers; // Outputs: [1, 2, 3, 4, 5, 6]

var matrix = [[1, 2], [3, 4]];
print matrix[0][1] // Outputs: 2
```

### Hashmaps

Hashmaps are collections of key-value pairs. Keys and values can be floats, ints or strings. You can create, access, and manipulate hashmaps using the following syntax:

```pogberry
var person = {
  "name": "Alice",
  "age": 30
};
print person["name"]; // Outputs: Alice

person["age"] = 31;
print person; // Outputs: {"name": "Alice", "age": 31}

person.delete("name");
print person; // Outputs: {"age" : 31};

// Outputs: "does not exist"
if (person.find(name)) {
  print "exists";
} else {
  print "does not exist";
}
```

## Classes

Pogberry supports object-oriented programming through classes. Classes allow you to bundle data (properties) and behavior (methods) together.

### Class Definition and Instantiation

init() is the constructor for any class, it is not required. If defined, it does not return any value except the class instance. init() accepts arguments, like any other function. 

```pogberry
class Person {
  init(name, age) {
    this.name = name;
    this.age = age;
  }
  
  sayHello() {
    print "Hello, my name is " + this.name;
  }
  
  birthday() {
    this.age = this.age + 1;
    print this.name + " is now " + this.age;
  }
}

var alice = Person("Alice", 30);
alice.sayHello(); // Outputs: Hello, my name is Alice
alice.birthday(); // Outputs: Alice is now 31
```

### Using `this` Keyword

In Pogberry, the `this` keyword refers to the current instance of the class. It lets methods access and modify the object's properties:

```pogberry
class Counter {
  init() {
    this.count = 0;
  }
  
  increment() {
    this.count = this.count + 1;
    return this.count;
  }
  
  reset() {
    this.count = 0;
    print "Counter reset";
  }
}

var counter = Counter();
print counter.increment(); // Outputs: 1
print counter.increment(); // Outputs: 2
counter.reset(); // Outputs: Counter reset
```

You cannot assign directly to 'this', you can only assign to fields defined on 'this' (ie current instance).

### Methods and Properties

You can add methods and properties to your classes, properties need not only by defined inside the init() method, you can freely define new properties outside the class, on any instance.:

```pogberry
class Rectangle {
  init(width, height) {
    this.width = width;
    this.height = height;
  }
  
  area() {
    return this.width * this.height;
  }
  
  perimeter() {
    return 2 * (this.width + this.height);
  }
}

var rect = Rectangle(5, 10);
rect.color = "red";
print("Area: " + rect.area()); // Outputs: Area: 50
print("Perimeter: " + rect.perimeter()); // Outputs: Perimeter: 30
print("Color: " + rect.color);  // Outputs: Color: red
```

Note: Inheritance is not yet supported in Pogberry.

## Native Functions

Pogberry includes several built-in native functions:

- `print(value, newline = true)`: Outputs the value to the console.

  ```pogberry
  print("Hello, Pogberry!"); // Outputs: Hello, Pogberry!
  print("Hello ", newline = false);
  print("again!); // Outputs: Hello again! (single line)
  ```

- `clock()`: Returns the current time in seconds since the program started.

  ```pogberry
  var time = clock();
  print time; // Outputs: time in seconds
  ```

- `rand()`: Generates a random number.

  ```pogberry
  var randomNum = rand();
  print randomNum; // Outputs: a random double-precision float between 0 and 1
  ```

- `strInput()`: Reads user input as a string from the console.

  ```pogberry
  var input = strInput();
  print input; // Outputs: user input
  ```

- `sqrt(number)`: Calculates the square root of a number.

  ```pogberry
  var result = sqrt(16);
  print result; // Outputs: 4
  ```

- `abs(number)`: Returns the absolute value of a number.

  ```pogberry
  var absolute = abs(-5);
  print absolute; // Outputs: 5
  ```

- `add(array, value, index)`: Adds a value at the specified index in an array.

  ```pogberry
  var numbers = [1, 2, 3];
  add(numbers, 4, 1);
  print numbers; // Outputs: [1, 4, 2, 3]
  ```

- `remove(array, index)`: Removes the element at the specified index from an array.

  ```pogberry
  var numbers = [1, 2, 3];
  remove(numbers, 1);
  print numbers; // Outputs: [1, 3]
  ```

- `sort(array)`: Sorts the elements of an array in ascending order. Implements quicksort, so it is not stable. Sorts by casting everything to the type of the first element, so sorting behaviour may be unexpected when array elements are of mixed types. Can also sort strings and hashmaps.

  ```pogberry
  var numbers = [3, 1, 2];
  sort(numbers);
  print numbers; // Outputs: [1, 2, 3]

  sort(numbers, True); //reverse = True
  print numbers; // Outputs: [3, 2, 1]

  var str = "hello";
  sort(str);
  print str; // Outputs: ehllo
  ```

## Getting Started

To get started with the Pogberry interpreter, follow these steps:

1. Clone the repository:
   ```sh
   gh repo clone tyagidevansh/pogberry
   ```
2. Navigate to the project directory:
   ```sh
   cd pogberry
   ```
3. Build the interpreter:
   If you have makefile installed, run:

   ```sh
   make
   ```

   Or if you would rather rely on just gcc:

   ```sh
   gcc  -std=c11 -c main.c value.c memory.c chunk.c debug.c vm.c scanner.c compiler.c object.c table.c
   ```

   ```sh
   gcc -std=c11 main.o value.o memory.o chunk.o debug.o vm.o scanner.o compiler.o object.o table.o -lm -lreadline -o pogberry
   ```

   Or use any other build system

4. Run your first Pogberry program:

   ```sh
   ./pogberry examples/fizzbuzz.pg
   ```

   OR

   Run the REPL by simply typing:

   ```sh
   ./pogberry
   ```

Happy coding with Pogberry!
