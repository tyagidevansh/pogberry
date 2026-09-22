while (true) {
  fun foo() {
    continue;
  }
}
// EXPECTED STATUS: 65
// EXPECTED OUTPUT:
//|    continue;
//|    ^
//|[line 3] Error at 'continue': Can't use 'continue' outside of a loop.
// END EXPECTED OUTPUT
