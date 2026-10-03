use "std.file" as file;

print(file.listFiles("file_dirs_tmp"));
file.makeDir("file_dirs_tmp");
print(file.exists("file_dirs_tmp"));
file.makeDir("file_dirs_tmp");
print(file.listFiles("file_dirs_tmp"));
file.writeText("file_dirs_tmp/b.txt", "b");
file.writeText("file_dirs_tmp/a.txt", "a");
print(file.listFiles("file_dirs_tmp"));
print(file.delete("file_dirs_tmp/b.txt"));
print(file.delete("file_dirs_tmp/a.txt"));
print(file.listFiles("file_dirs_tmp"));
file.removeDir("file_dirs_tmp");
print(file.exists("file_dirs_tmp"));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|nil
//|true
//|[]
//|[a.txt, b.txt]
//|true
//|true
//|[]
//|false
// END EXPECTED OUTPUT
