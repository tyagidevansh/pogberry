use "pb.time" as time;

let known = time.fromParts({"year": 2026, "month": 6, "day": 15, "hour": 12, "min": 30, "sec": 45});
let back = time.parts(known);
print(back["year"] == 2026 and back["month"] == 6 and back["day"] == 15);
print(back["hour"] == 12 and back["min"] == 30 and back["sec"] == 45);
print(time.format(known, "%Y") == "2026");
print(time.format(known, "%m") == "06");
print(time.format("%Y-%m") == time.format(time.unix(), "%Y-%m"));
let u = time.parts(known, true);
print(u["year"] == 2026 and u["month"] == 6);
let ku = time.fromParts({"year": 2026, "month": 6, "day": 15, "hour": 12, "min": 0, "sec": 0}, true);
let bu = time.parts(ku, true);
print(bu["hour"] == 12 and bu["day"] == 15);
let partial = time.parts(time.fromParts({"hour": 12}));
print(partial["hour"] == 12);
let extra = time.parts(time.fromParts({"year": 2026, "month": 6, "day": 15, "hour": 12, "yer": 1}));
print(extra["year"] == 2026 and extra["day"] == 15);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|true
//|true
//|true
//|true
//|true
//|true
//|true
//|true
//|true
// END EXPECTED OUTPUT
