use "pb.time" as time;

let savedAt = time.unix();

let today = time.parts(savedAt, true);
let daySeed = today["year"] * 10000 + today["month"] * 100 + today["day"];
seed(daySeed);
let firstRoll = rand(100);
seed(daySeed);
let secondRoll = rand(100);

let before = time.cpu();
let total = 0;
let i = 0;
while (i < 1000)
{
  total = total + i;
  i = i + 1;
}
let elapsed = time.cpu() - before;

let stamp = time.fromParts({"year": 2026, "month": 6, "day": 15, "hour": 12, "min": 30, "sec": 0});
let label = time.format(stamp, "%Y-%m-%d");

let ticks = 0;
let n = 0;
while (n < 3)
{
  time.sleep(0.01);
  ticks = ticks + 1;
  n = n + 1;
}

print(savedAt > 1000000000);
print(firstRoll == secondRoll);
print(firstRoll >= 0 and firstRoll < 100);
print(total == 499500);
print(elapsed >= 0);
print(label);
print(ticks == 3);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|true
//|true
//|true
//|true
//|true
//|2026-06-15
//|true
// END EXPECTED OUTPUT
