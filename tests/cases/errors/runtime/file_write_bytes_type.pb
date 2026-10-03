use "std.file" as file;
file.writeBytes("file_x_tmp.bin", 42);
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|writeBytes(path, bytes) expected a path and a byte list.
//|[std.file line 65] in writeBytes()
//|[line 2] in script
// END EXPECTED OUTPUT
