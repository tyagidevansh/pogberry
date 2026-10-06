use "pb.time" as time;

let t = time.unix();
print(t > 1000000000);
print(t % 1 == 0);
print(time.cpu() >= 0);
time.sleep(0);
seed(t);
print(rand() >= 0 and rand() <= 1);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|true
//|true
//|true
//|true
// END EXPECTED OUTPUT
