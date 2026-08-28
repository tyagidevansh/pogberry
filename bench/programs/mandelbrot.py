def mandelbrot(width, height, max_iter):
    x0 = -2.0
    x1 = 0.5
    y0 = -1.25
    y1 = 1.25

    dx = (x1 - x0) / width
    dy = (y1 - y0) / height

    total_iter = 0

    for y in range(height):
        ci = y0 + y * dy
        for x in range(width):
            cr = x0 + x * dx
            zr = 0.0
            zi = 0.0
            i = 0

            while (zr * zr + zi * zi <= 4.0) and (i < max_iter):
                tr = zr * zr - zi * zi + cr
                zi = 2.0 * zr * zi + ci
                zr = tr
                i += 1

            total_iter += i

    return total_iter


def main():
    result = mandelbrot(150, 150, 100)
    print(f"{float(result):g}")


if __name__ == "__main__":
    main()

