use "std.math";

fun eval_A(i, j) {
  return 1.0 / (((i + j) * (i + j + 1)) / 2 + i + 1);
}

fun eval_A_times_u(n, u, v) {
  for (let i = 0; i < n; i = i + 1) {
    let sum = 0.0;
    for (let j = 0; j < n; j = j + 1) {
      sum = sum + eval_A(i, j) * u[j];
    }
    v[i] = sum;
  }
}

fun eval_At_times_u(n, u, v) {
  for (let i = 0; i < n; i = i + 1) {
    let sum = 0.0;
    for (let j = 0; j < n; j = j + 1) {
      sum = sum + eval_A(j, i) * u[j];
    }
    v[i] = sum;
  }
}

fun eval_AtA_times_u(n, u, v, w) {
  eval_A_times_u(n, u, w);
  eval_At_times_u(n, w, v);
}

let n = 250;
let u = [];
let v = [];
let w = [];
for (let i = 0; i < n; i = i + 1) {
  u.push(1.0);
  v.push(0.0);
  w.push(0.0);
}

for (let i = 0; i < 10; i = i + 1) {
  eval_AtA_times_u(n, u, v, w);
  eval_AtA_times_u(n, v, u, w);
}

let vBv = 0.0;
let vv = 0.0;
for (let i = 0; i < n; i = i + 1) {
  vBv = vBv + u[i] * v[i];
  vv = vv + v[i] * v[i];
}

let result = math.floor(math.sqrt(vBv / vv) * 10000000);
print(result);

