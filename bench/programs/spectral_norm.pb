use "std.math";

fun eval_A(i, j) {
  return 1.0 / (((i + j) * (i + j + 1)) / 2 + i + 1);
}

fun eval_A_times_u(n, u, v) {
  for (var i = 0; i < n; i = i + 1) {
    var sum = 0.0;
    for (var j = 0; j < n; j = j + 1) {
      sum = sum + eval_A(i, j) * u[j];
    }
    v[i] = sum;
  }
}

fun eval_At_times_u(n, u, v) {
  for (var i = 0; i < n; i = i + 1) {
    var sum = 0.0;
    for (var j = 0; j < n; j = j + 1) {
      sum = sum + eval_A(j, i) * u[j];
    }
    v[i] = sum;
  }
}

fun eval_AtA_times_u(n, u, v, w) {
  eval_A_times_u(n, u, w);
  eval_At_times_u(n, w, v);
}

var n = 250;
var u = [];
var v = [];
var w = [];
for (var i = 0; i < n; i = i + 1) {
  u.push(1.0);
  v.push(0.0);
  w.push(0.0);
}

for (var i = 0; i < 10; i = i + 1) {
  eval_AtA_times_u(n, u, v, w);
  eval_AtA_times_u(n, v, u, w);
}

var vBv = 0.0;
var vv = 0.0;
for (var i = 0; i < n; i = i + 1) {
  vBv = vBv + u[i] * v[i];
  vv = vv + v[i] * v[i];
}

var result = math.floor(math.sqrt(vBv / vv) * 10000000);
print(result);

