fun identity(value) {
  return value;
}
class Empty {}
var instance = Empty();
print(len("hi"));
print(len([1, 2]));
print(len({"hp": 100}));
print(type(nil));
print(type(true));
print(type(1));
print(type("hi"));
print(type([]));
print(type({}));
print(type(identity));
print(type(len));
print(type(Empty));
print(type(instance));
print(str([1, {"hp": true}]));
var cycle = [];
cycle.push(cycle);
print(str(cycle));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|2
//|2
//|1
//|nil
//|bool
//|number
//|string
//|list
//|map
//|function
//|native
//|class
//|instance
//|[1, {hp: true}]
//|[<cycle>]
// END EXPECTED OUTPUT
