//Given an array of integers nums and an integer target, return indices of the two numbers such that they add up to target.

fun two_sum(nums, target) {
  var map = {};
  var res = [];

  for (var i = 0; i < nums.size(); i = i + 1) {
    if (map.find(nums[i])) {
      res = [i, map[nums[i]]];
    } else {
      map[target - nums[i]] = i;
    }
  }

  return res;
}

var nums = [2,7,11,15];
var target = 9;

print(two_sum(nums, target));