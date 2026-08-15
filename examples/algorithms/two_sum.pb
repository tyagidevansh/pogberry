fun two_sum(nums, target) {
  var map = {};
  var res = [];

  for (var i = 0; i < len(nums); i = i + 1) {
    if (map.has(nums[i])) {
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
