class Greeter {
  greet(name) {
    return "hello " + name;
  }
}
var greet = Greeter().greet;
print(greet("Pogberry"));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|hello Pogberry
// END EXPECTED OUTPUT
