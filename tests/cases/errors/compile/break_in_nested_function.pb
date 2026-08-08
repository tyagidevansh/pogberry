while (false) {
  fun invalid() {
    break;
  }
}
// EXPECTED STATUS: 65
// EXPECTED OUTPUT:
//|    break;
//|    ^
//|[line 3] Error at 'break': Can't use 'break' outside of a loop.
// END EXPECTED OUTPUT
