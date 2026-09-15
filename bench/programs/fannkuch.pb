fun fannkuch(n) {
  let p = [];
  let q = [];
  let s = [];
  let sign = 1;
  let max_flips = 0;
  let sum = 0;

  for (let i = 0; i < n; i = i + 1) {
    p.push(i);
    q.push(i);
    s.push(i);
  }

  while (true) {
    let q0 = p[0];
    if (q0 != 0) {
      for (let i = 0; i < n; i = i + 1) {
        q[i] = p[i];
      }
      let flips = 1;
      while (true) {
        let qq = q[q0];
        if (qq == 0) {
          sum = sum + sign * flips;
          if (flips > max_flips) max_flips = flips;
          break;
        }
        q[q0] = q0;
        if (q0 >= 3) {
          let i = 1;
          let j = q0 - 1;
          while (true) {
            let t = q[i];
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
      let t = p[1];
      p[1] = p[0];
      p[0] = t;
      sign = -1;
    } else {
      let t = p[1];
      p[1] = p[2];
      p[2] = t;
      sign = 1;
      let i = 2;
      while (true) {
        let sx = s[i];
        if (sx != 0) {
          s[i] = sx - 1;
          break;
        }
        if (i == n - 1) {
          return max_flips;
        }
        s[i] = i;
        let p0 = p[0];
        for (let j = 0; j <= i; j = j + 1) {
          p[j] = p[j + 1];
        }
        p[i + 1] = p0;
        i = i + 1;
      }
    }
  }
}

print(fannkuch(9));

