let lapTimes = {
  "Hamilton": 78.4,
  "Verstappen": 77.9,
  "Leclerc": 78.1,
  "Norris": 78.0
};

// Sort by driver name
let byDriver = lapTimes.sortKey();
print("Alphabetical:");
for (let i = 0; i < len(byDriver); i += 1) {
  print(byDriver[i][0], byDriver[i][1]);
}

print();

// Sort by lap time
let byPace = lapTimes.sortValue();
print("Pace order:");
for (let i = 0; i < len(byPace); i += 1) {
  print(byPace[i][0], byPace[i][1]);
}
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|Alphabetical:
//|Hamilton 78.4
//|Leclerc 78.1
//|Norris 78
//|Verstappen 77.9
//|
//|Pace order:
//|Verstappen 77.9
//|Norris 78
//|Leclerc 78.1
//|Hamilton 78.4
// END EXPECTED OUTPUT