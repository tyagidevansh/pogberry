{
  let value = 1;
  var value = 2;
}
// EXPECTED STATUS: 65
// EXPECTED OUTPUT:
//|  var value = 2;
//|      ^
//|[line 3] Error at 'value': Already a variable with this name in this scope.
// END EXPECTED OUTPUT
