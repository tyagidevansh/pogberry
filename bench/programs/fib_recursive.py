def fib(n):
    if n < 2:
        return n
    return fib(n - 1) + fib(n - 2)


def main():
    print(f"{float(fib(32)):g}")


if __name__ == "__main__":
    main()
