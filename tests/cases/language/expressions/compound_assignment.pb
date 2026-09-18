let globalNum = 10;
globalNum += 5;
print(globalNum);
globalNum -= 3;
print(globalNum);
globalNum *= 2;
print(globalNum);
globalNum /= 4;
print(globalNum);
globalNum %= 5;
print(globalNum);

let localNum = 100;
localNum += 25;
print(localNum);
localNum -= 15;
print(localNum);

let strVal = "hello ";
strVal += "world";
print(strVal);

class Point {
  init(x, y) {
    this.x = x;
    this.y = y;
  }
}

let pt = Point(10, 20);
pt.x += 5;
pt.y *= 2;
print(pt.x);
print(pt.y);

let arr = [10, 20, 30];
arr[0] += 5;
arr[1] *= 2;
arr[2] -= 10;
print(arr[0]);
print(arr[1]);
print(arr[2]);

let dict = {"score": 50};
dict["score"] += 25;
print(dict["score"]);

// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|15
//|12
//|24
//|6
//|1
//|125
//|110
//|hello world
//|15
//|40
//|15
//|40
//|20
//|75
// END EXPECTED OUTPUT

