use "std.file" as file;
file.readText("../evil.txt");
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|Invalid path '../evil.txt'.
//|[std.file line 35] in readText()
//|[line 2] in script
// END EXPECTED OUTPUT
