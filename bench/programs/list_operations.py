def main():
    a = []
    for i in range(50000):
        a.append(i)

    sum1 = 0
    for i in range(len(a)):
        sum1 += a[i]

    for i in range(25000):
        a.pop()

    sum2 = 0
    for i in range(len(a)):
        sum2 += a[i]

    print(f"{sum1:g}")
    print(f"{sum2:g}")


if __name__ == "__main__":
    main()
