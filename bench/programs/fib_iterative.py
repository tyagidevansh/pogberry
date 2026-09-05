def fib_iter(n: int) -> int:
    a = 0
    b = 1
    for _ in range(n):
        c = a + b
        a = b
        b = c
    return a


def main():
    total = 0
    for _ in range(200000):
        total = (total + fib_iter(30)) % 1000000007
    print(total)


if __name__ == "__main__":
    main()

