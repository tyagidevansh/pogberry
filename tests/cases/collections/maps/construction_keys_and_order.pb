var data = {"name": "Pog", 2: "two", true: "yes", nil: "none"};
print(data);
print(data["name"]);
print(data[2]);
print(data[true]);
print(data[nil]);
print(data["missing"]);
print(data.length);
data["name"] = "Berry";
print(data);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|{name: Pog, 2: two, true: yes, nil: none}
//|Pog
//|two
//|yes
//|none
//|nil
//|4
//|{name: Berry, 2: two, true: yes, nil: none}
// END EXPECTED OUTPUT
