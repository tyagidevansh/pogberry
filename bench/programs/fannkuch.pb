fun fannkuch(n) {
  var p = [];
  var q = [];
  var s = [];
  var sign = 1;
  var max_flips = 0;
  var sum = 0;

  for (var i = 0; i < n; i = i + 1) {
    p.push(i);
    q.push(i);
    s.push(i);
  }

  while (true) {
    var q0 = p[0];
    if (q0 != 0) {
      for (var i = 0; i < n; i = i + 1) {
        q[i] = p[i];
      }
      var flips = 1;
      while (true) {
        var qq = q[q0];
        if (qq == 0) {
          sum = sum + sign * flips;
          if (flips > max_flips) max_flips = flips;
          break;
        }
        q[q0] = q0;
        if (q0 >= 3) {
          var i = 1;
          var j = q0 - 1;
          while (true) {
            var t = q[i];
            q[i] = q[j];
            q[j] = t;
            i = i + 1;
            j = j - 1;
            if (i >= j) break;
          }
        }
        q0 = qq;
        flips = flips + 1;
      }
    }

    if (sign == 1) {
      var t = p[1];
      p[1] = p[0];
      p[0] = t;
      sign = -1;
    } else {
      var t = p[1];
      p[1] = p[2];
      p[2] = t;
      sign = 1;
      var i = 2;
      while (true) {
        var sx = s[i];
        if (sx != 0) {
          s[i] = sx - 1;
          break;
        }
        if (i == n - 1) {
          return max_flips;
        }
        s[i] = i;
        var p0 = p[0];
        for (var j = 0; j <= i; j = j + 1) {
          p[j] = p[j + 1];
        }
        p[i + 1] = p0;
        i = i + 1;
      }
    }
  }
}

print(fannkuch(9));

