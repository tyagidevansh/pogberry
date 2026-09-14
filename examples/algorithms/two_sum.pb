fun two_sum(nums, target) {
  let map = {};
  let res = [];

  for (let i = 0; i < len(nums); i = i + 1) {
    if (map.has(nums[i])) {
      res = [i, map[nums[i]]];
    } else {
      map[target - nums[i]] = i;
    }
  }

  return res;
}

let nums = [2,7,11,15];
let target = 9;

print(two_sum(nums, target));
