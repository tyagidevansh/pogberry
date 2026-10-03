use "std.file" as file;

let save = file.open("file_methods_tmp.txt", "w");
save.write("health=85\n");
save.write("level=3");
save.close();
let load = file.open("file_methods_tmp.txt", "r");
print(load.read());
load.close();
print(file.exists("file_methods_tmp.txt"));
print(file.readText("file_methods_tmp.txt"));
print(file.delete("file_methods_tmp.txt"));
print(file.open("file_methods_missing_tmp.txt", "r"));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|health=85
//|level=3
//|true
//|health=85
//|level=3
//|true
//|nil
// END EXPECTED OUTPUT
