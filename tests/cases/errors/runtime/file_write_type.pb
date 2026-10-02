use "pb_file" as file;
file.writeText(42, "x");
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|writeText(path, text) expected.
//|[line 2] in script
// END EXPECTED OUTPUT
