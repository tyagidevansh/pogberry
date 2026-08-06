var stats = {"hp": 100, "dead": false, nil: "none", true: "yes", 2: "two"};
print(stats["hp"]);
print(stats[nil]);
print(stats[true]);
print(stats.length);
print(stats.has("dead"));
print(stats.get("missing", 3));
print(stats.delete("dead"));
print(stats.has("dead"));

stats["hp"] = 85;
print(stats);

stats.delete("hp");
stats["hp"] = 90;
print(stats);

print({true: 1, nil: 2} == {nil: 2, true: 1});
stats.clear();
print(stats.length);
