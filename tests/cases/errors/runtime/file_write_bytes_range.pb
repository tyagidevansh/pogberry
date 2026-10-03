use "std.file" as file;
file.writeBytes("file_x_tmp.bin", [300]);
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|writeBytes() bytes must be integers from 0 to 255.
//|[std.file line 65] in writeBytes()
//|[line 2] in script
// END EXPECTED OUTPUT
