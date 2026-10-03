use "std.file" as file;

file.writeBytes("file_bytes_tmp.bin", [72, 105, 0, 255, 128]);
print(file.readBytes("file_bytes_tmp.bin"));
print(file.readBytes("file_bytes_missing_tmp.bin"));
print(file.delete("file_bytes_tmp.bin"));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|[72, 105, 0, 255, 128]
//|nil
//|true
// END EXPECTED OUTPUT
