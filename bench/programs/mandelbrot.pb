fun mandelbrot(width, height, maxIter) {
  let x0 = -2.0;
  let x1 = 0.5;
  let y0 = -1.25;
  let y1 = 1.25;

  let dx = (x1 - x0) / width;
  let dy = (y1 - y0) / height;

  var totalIter = 0;

  for (var y = 0; y < height; y = y + 1) {
    let ci = y0 + y * dy;
    for (var x = 0; x < width; x = x + 1) {
      let cr = x0 + x * dx;
      var zr = 0.0;
      var zi = 0.0;
      var iter = 0;

      while (zr * zr + zi * zi <= 4.0 and iter < maxIter) {
        let tr = zr * zr - zi * zi + cr;
        zi = 2.0 * zr * zi + ci;
        zr = tr;
        iter = iter + 1;
      }

      totalIter = totalIter + iter;
    }
  }

  return totalIter;
}

fun main() {
  let result = mandelbrot(150, 150, 100);
  print(result);
}

main();

