use "std.file" as file;

print("Saving progress...");
let save = file.open("savegame.txt", "w");
save.write("name=Mira\n");
save.write("health=85\n");
save.write("level=3\n");
save.close();

print("Loading progress...");
print(file.readText("savegame.txt"));

print("Logging adventure...");
file.writeText("adventure_log.txt", "Entered the dark cave.\n");
file.appendText("adventure_log.txt", "Found a torch.\n");
print(file.readText("adventure_log.txt"));

file.delete("savegame.txt");
file.delete("adventure_log.txt");
print("Save files cleaned up.");
print(file.exists("savegame.txt"));
