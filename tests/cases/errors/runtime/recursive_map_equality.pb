var left = {};
left["self"] = left;
var right = {};
right["self"] = right;
print(left == right);
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|Cannot compare recursive containers.
//|[line 5] in script
// END EXPECTED OUTPUT
