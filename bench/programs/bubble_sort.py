def main():
    seed = 42.0
    arr = []
    for _ in range(5000):
        seed = (seed * 1103515245.0 + 12345.0) % 2147483648.0
        arr.append(seed % 100000.0)

    n = len(arr)
    for i in range(n):
        for j in range(n - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]

    total = 0.0
    for x in arr:
        total += x

    print(int(total))


if __name__ == "__main__":
    main()
