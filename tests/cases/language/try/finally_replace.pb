try {
  throw "orig";
} finally {
  throw "replacement";
}
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|replacement
//|[line 4] in script
// END EXPECTED OUTPUT
