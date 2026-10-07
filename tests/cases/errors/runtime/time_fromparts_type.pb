use "pb.time" as time;
time.fromParts(42);
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|fromParts() expects a map of date fields with an optional utc flag.
//|[line 2] in script
// END EXPECTED OUTPUT
