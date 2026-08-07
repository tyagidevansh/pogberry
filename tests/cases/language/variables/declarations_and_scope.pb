var global = "global";
let total = 3;
{
  var global = "local";
  let total = 4;
  print(global);
  print(total);
}
global = "changed";
total = total + 5;
print(global);
print(total);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|local
//|4
//|changed
//|8
// END EXPECTED OUTPUT
