{
  use "std.math" as math;
}
// EXPECTED STATUS: 65
// EXPECTED OUTPUT:
//|  use "std.math" as math;
//|  ^
//|[line 2] Error at 'use': Imports are only allowed at top level.
// END EXPECTED OUTPUT
