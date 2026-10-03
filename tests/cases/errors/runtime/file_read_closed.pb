use "std.file" as file;
let h = file.open("file_closed_tmp.txt", "w");
h.write("hi");
h.close();
let r = file.open("file_closed_tmp.txt", "r");
r.close();
file.delete("file_closed_tmp.txt");
r.read();
// EXPECTED STATUS: 70
// EXPECTED OUTPUT:
//|file has been closed.
//|[std.file line 12] in read()
//|[line 8] in script
// END EXPECTED OUTPUT
