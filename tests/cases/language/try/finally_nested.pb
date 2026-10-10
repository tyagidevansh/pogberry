let log = [];
try {
  try {
    throw "deep";
  } finally {
    log.push("inner-fin");
  }
} catch (e) {
  log.push(e["value"]);
} finally {
  log.push("outer-fin");
}
log.push("after");
print(log);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|[inner-fin, deep, outer-fin, after]
// END EXPECTED OUTPUT
