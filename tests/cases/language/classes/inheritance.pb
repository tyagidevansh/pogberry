class Animal {
  speak() {
    return "sound";
  }
}
class Dog < Animal {
  speak() {
    return "bark";
  }
}
class Cat < Animal {}
print(Dog().speak());
print(Cat().speak());
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|bark
//|sound
// END EXPECTED OUTPUT
