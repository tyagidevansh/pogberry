use "std.file" as file;
file.writeText("file_mode_tmp.txt", "hi");
let h = file.open("file_mode_tmp.txt", "r");
file.delete("file_mode_tmp.txt");
h.write("x");
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|write(handle, text) expected a writable file.
//|[std.file line 17] in write()
//|[line 5] in script
// END EXPECTED OUTPUT
