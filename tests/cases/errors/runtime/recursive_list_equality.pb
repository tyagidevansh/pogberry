var left = [];
left.push(left);
var right = [];
right.push(right);
print(left == right);
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|Cannot compare recursive containers.
//|[line 5] in script
// END EXPECTED OUTPUT
