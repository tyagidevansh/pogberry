{
  let value = 1;
  let value = 2;
}
// EXPECTED STATUS: 65
// EXPECTED OUTPUT:
//|  let value = 2;
//|      ^
//|[line 3] Error at 'value': Already a variable with this name in this scope.
// END EXPECTED OUTPUT
