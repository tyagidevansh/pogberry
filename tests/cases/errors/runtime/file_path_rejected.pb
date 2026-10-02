use "pb_file" as file;
file.readText("../evil.txt");
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|Invalid path '../evil.txt'.
//|[line 2] in script
// END EXPECTED OUTPUT
