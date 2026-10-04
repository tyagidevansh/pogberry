use "std.file" as file;
use "std.json" as json;

print("Saving progress...");
let out = file.open("savegame.txt", "w");
out.write('{"name": "Mira", "health": 85, "level": 3}');
out.close();

print("Loading progress...");
let data = file.readText("savegame.txt");
print(data);
let save = json.parse(data);
print(save["health"]);
print(save["health"] > 80);

print("Logging adventure...");
file.writeText("adventure_log.txt", "Entered the dark cave.\n");
file.appendText("adventure_log.txt", "Found a torch.\n");
print(file.readText("adventure_log.txt"));

file.delete("savegame.txt");
file.delete("adventure_log.txt");
print("Save files cleaned up.");
print(file.exists("savegame.txt"));
