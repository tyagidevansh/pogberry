// var a = [1, 2, 5, 6, "text"];
// print(a); 
// var test = "test";
// print("indexing : " + test[0]);
// print("The first element of the list is: " + a[0]);

// a[0] = 0;
// print("Changed the first " + "element: ", newline = false);
// print(a);

// a.push("more text");
// print("Pushed an element :", newline= false);
// print(a);

// a.add("9", 3);
// print("Added an element at index 3: ", newline= false);
// print(a);

// a.remove(3);
// print("Removed the element at index 3: ", newline= false);
// print(a);

// a.pop();
// print("Popped an element from the list: ", newline= false);
// print(a);

// print("Size of the list is: " + a.size());
// var sampleStr = "hello world";
// print("Size of the string: " + sampleStr.size());
// var a = -5.2;
// print("variables can be freely reassigned lesgooo: " + a);

// //comment

// print(abs(a));

// var h = {"animal" : "lion", "plant" : "orchid" };
// print(h);
// print(h["animal"]);
// h["animal"] = "tiger";

// print(h.size());

// var a = "hello";
// print("First letter of hello is: " + a[0]);

// if (h["anial"]) {
//   print("exists");
// } else {
//   print("doesnt exist");
// }

// if (h.find("animal")) {
//   h.delete("animal");
// }

// print(h);

// var list = [["a", "c", [5, 4], 5, 3], ["bd", "b"]];
// print(list);
// print(list[0][2][1]);

// var numHash = {1 : "hello", 4: "world", 2: "ohayo"};
// print(numHash);
// print(numHash[4]);

// if (numHash.find(3)) {
//   print("exists");
// } else {
//   print("doesnt exist");
// }

// class Pair {}

// var pair = Pair();
// pair.first = 1; 
// pair.second = 2;
// print(pair.first);

// class Brunch {
//   bacon() {}
//   eggs() {}
// }


// class Scone {
//   topping(first, second) {
//     print("scone with " + first + " and " + second);
//   }
// }

// var scone = Scone();
// scone.topping("berries", "cream");

// class CoffeeMaker {
//   init(coffee) {
//     this.coffee = coffee;
//   }

//   brew() {
//     print("Enjoy your cup of " + this.coffee);
//     this.coffee = nil;
//   }
// }

// var maker = CoffeeMaker("coffee and chicory");
// maker.brew();
// maker.coffee = "coffee";
// maker.brew();

// class Coffee {
//   init(coffee) {
//     this.coffee = coffee;
//   }

//   describe() {
//     print("This coffee is " + this.coffee);
//   }
// }

// var c = Coffee("strong");
// c.describe(); 

// class Person {
//   init(name, age) {
//     this.name = name;
//     this.age = age;
//   }

//   greet() {
//     print("Hello, my name is " + this.name + " and I am " + this.age + " years old.");
//   }

//   haveBirthday() {
//     this.age = this.age + 1;
//   }
// }

// var p = Person("Alice", 25);
// p.greet(); 
// p.haveBirthday();
// p.greet();

// class Counter {
//   init() {
//     this.count = 0;
//   }

//   increment() {
//     this.count = this.count + 1;
//   }

//   getCount() {
//     return this.count;
//   }
// }

// var c = Counter();
// c.increment();
// c.increment();
// print(c.getCount()); // Expected: 2

// class Box {
//   init(value) {
//     this.value = value;
//   }

//   setValue(newValue) {
//     this.value = newValue;
//   }

//   getValue() {
//     return this.value;
//   }
// }

// var b = Box(10);
// print(b.getValue()); // Expected: 10
// b.setValue(42);
// print(b.getValue()); // Expected: 42

// class Animal {
//   init(name) {
//     this.name = name;
//   }

//   speak() {
//     print(this.name + " makes a sound.");
//   }
// }

// var a1 = Animal("Dog");
// var a2 = Animal("Cat");

// a1.speak(); // Expected: "Dog makes a sound."
// a2.speak(); // Expected: "Cat makes a sound."

// class Printer {
//   init(message) {
//     this.message = message;
//   }

//   printMessage() {
//     print(this.message);
//   }

//   duplicate() {
//     return Printer(this.message + " " + this.message);
//   }
// }

// var p1 = Printer("Hello");
// p1.printMessage(); // Expected: "Hello"

// var p2 = p1.duplicate();
// p2.printMessage(); // Expected: "Hello Hello"


// class LightSwitch {
//   init() {
//     this.isOn = false;
//   }

//   turnOn() {
//     this.isOn = true;
//   }

//   turnOff() {
//     this.isOn = false;
//   }

//   isLightOn() {
//     return this.isOn;
//   }
// }

// var light = LightSwitch();
// print(light.isLightOn()); // Expected: false
// light.turnOn();
// print(light.isLightOn()); // Expected: true
// light.turnOff();
// print(light.isLightOn()); // Expected: false

// class Rectangle {
//   init(width, height) {
//     this.width = width;
//     this.height = height;
//   }
  
//   area() {
//     return this.width * this.height;
//   }
  
//   perimeter() {
//     return 2 * (this.width + this.height);
//   }
// }

// var rect = Rectangle(5, 10);
// rect.color = "red";
// print("Area: " + rect.area()); // Outputs: Area: 50
// print("Perimeter: " + rect.perimeter()); // Outputs: Perimeter: 30
// print("Color " + rect.color);

class Animal {
  speak() {
    print("Some generic animal sound");
  }
}

class Dog < Animal {  // Dog inherits from Animal
  speak() {
    print("Woof!");
  }
}

var a = Animal();
a.speak();  

var d = Dog();
d.speak(); 

// class Invalid {
//   init() {
//     this = "wrong";  //expected compilation eror
//   }

//   test() {
//     print(this);
//   }
// }

// var i = Invalid();
// i.test();


// class Test {
//   init() {}
// }

// var t = Test();
// print(t.value); // Expected: Runtime error (undefined property)
