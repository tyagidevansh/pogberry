fun twoSum(numbers, target) {
  var complements = {};
  for (var i = 0; i < len(numbers); i = i + 1) {
    if (complements.has(numbers[i])) {
      return [complements[numbers[i]], i];
    }
    complements[target - numbers[i]] = i;
  }
  return [];
}
print(twoSum([2, 7, 11, 15], 9));
print(twoSum([3, 2, 4], 6));
print(twoSum([1, 2, 3], 99));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|[0, 1]
//|[1, 2]
//|[]
// END EXPECTED OUTPUT
