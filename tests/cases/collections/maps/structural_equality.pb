print({} == {});
print({"a": 1, "b": [2, 3]} == {"b": [2, 3], "a": 1});
print({"a": 1} == {"a": 2});
print({true: nil} != {true: false});
print({1: "number"} == {1: "number"});
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|true
//|true
//|false
//|true
//|true
// END EXPECTED OUTPUT
