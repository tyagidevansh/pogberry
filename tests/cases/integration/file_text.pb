use "pb_file" as file;

print(file.exists("file_text_tmp.txt"));
print(file.readText("file_text_tmp.txt"));
file.writeText("file_text_tmp.txt", "health=85\n");
print(file.readText("file_text_tmp.txt"));
print(file.exists("file_text_tmp.txt"));
file.appendText("file_text_tmp.txt", "level=3");
print(file.readText("file_text_tmp.txt"));
file.writeText("file_empty_tmp.txt", "");
print(file.exists("file_empty_tmp.txt"));
print(file.readText("file_empty_tmp.txt") == "");
print(file.delete("file_text_tmp.txt"));
print(file.delete("file_empty_tmp.txt"));
print(file.exists("file_text_tmp.txt"));
print(file.delete("file_text_tmp.txt"));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|false
//|nil
//|health=85
//|
//|true
//|health=85
//|level=3
//|true
//|true
//|true
//|true
//|false
//|false
// END EXPECTED OUTPUT
