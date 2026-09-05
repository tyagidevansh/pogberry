import math


def eval_A(i: int, j: int) -> float:
    return 1.0 / (((i + j) * (i + j + 1)) // 2 + i + 1)


def eval_A_times_u(n: int, u: list[float], v: list[float]):
    for i in range(n):
        s = 0.0
        for j in range(n):
            s += eval_A(i, j) * u[j]
        v[i] = s


def eval_At_times_u(n: int, u: list[float], v: list[float]):
    for i in range(n):
        s = 0.0
        for j in range(n):
            s += eval_A(j, i) * u[j]
        v[i] = s


def eval_AtA_times_u(n: int, u: list[float], v: list[float], w: list[float]):
    eval_A_times_u(n, u, w)
    eval_At_times_u(n, w, v)


def main():
    n = 250
    u = [1.0] * n
    v = [0.0] * n
    w = [0.0] * n

    for _ in range(10):
        eval_AtA_times_u(n, u, v, w)
        eval_AtA_times_u(n, v, u, w)

    vBv = 0.0
    vv = 0.0
    for i in range(n):
        vBv += u[i] * v[i]
        vv += v[i] * v[i]

    result = math.floor(math.sqrt(vBv / vv) * 10000000)
    print(int(result))


if __name__ == "__main__":
    main()

