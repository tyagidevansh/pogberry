let log = [];
try {
  log.push("body");
} finally {
  log.push("finally");
}
log.push("after");
print(log);

try {
  log.push("b2");
  throw "e2";
} catch (e) {
  log.push("c2");
} finally {
  log.push("f2");
}

try {
  throw "e3";
} catch (e) {
  log.push(e["value"]);
} finally {
  log.push("f3");
}
print(log);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|[body, finally, after]
//|[body, finally, after, b2, c2, f2, e3, f3]
// END EXPECTED OUTPUT
