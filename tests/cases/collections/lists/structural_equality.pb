print([] == []);
print([1, 2, [3]] == [1, 2, [3]]);
print([1, 2] == [2, 1]);
print([1] != [1, 2]);
print([{"hp": 10}] == [{"hp": 10}]);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|true
//|true
//|false
//|true
//|true
// END EXPECTED OUTPUT
