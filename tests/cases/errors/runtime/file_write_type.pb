use "std.file" as file;
file.writeText(42, "x");
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|writeText(path, text) expected.
//|[std.file line 40] in writeText()
//|[line 2] in script
// END EXPECTED OUTPUT
