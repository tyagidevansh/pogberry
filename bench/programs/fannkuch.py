def fannkuch(n: int) -> int:
    p = list(range(n))
    q = list(range(n))
    s = list(range(n))
    sign = 1
    max_flips = 0
    sum_ = 0

    while True:
        q0 = p[0]
        if q0 != 0:
            for i in range(n):
                q[i] = p[i]
            flips = 1
            while True:
                qq = q[q0]
                if qq == 0:
                    sum_ += sign * flips
                    if flips > max_flips:
                        max_flips = flips
                    break
                q[q0] = q0
                if q0 >= 3:
                    i = 1
                    j = q0 - 1
                    while True:
                        q[i], q[j] = q[j], q[i]
                        i += 1
                        j -= 1
                        if i >= j:
                            break
                q0 = qq
                flips += 1

        if sign == 1:
            p[0], p[1] = p[1], p[0]
            sign = -1
        else:
            p[1], p[2] = p[2], p[1]
            sign = 1
            i = 2
            while True:
                sx = s[i]
                if sx != 0:
                    s[i] = sx - 1
                    break
                if i == n - 1:
                    return max_flips
                s[i] = i
                p0 = p[0]
                for j in range(i + 1):
                    p[j] = p[j + 1]
                p[i + 1] = p0
                i += 1


def main():
    print(fannkuch(9))


if __name__ == "__main__":
    main()

