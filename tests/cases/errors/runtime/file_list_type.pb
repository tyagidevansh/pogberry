use "std.file" as file;
file.listFiles(42);
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|listFiles(dir) expected.
//|[std.file line 70] in listFiles()
//|[line 2] in script
// END EXPECTED OUTPUT
