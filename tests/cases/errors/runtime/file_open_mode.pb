use "std.file" as file;
file.open("file_x_tmp.txt", "rw");
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|open(path, mode) expected mode "r", "w", or "a".
//|[std.file line 28] in open()
//|[line 2] in script
// END EXPECTED OUTPUT
