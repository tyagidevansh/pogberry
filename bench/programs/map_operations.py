def main():
    m = {}
    for i in range(50000):
        m[str(i)] = i

    for i in range(50000):
        _ = str(i) in m

    for i in range(25000):
        del m[str(i)]

    total = 0
    for i in range(25000, 50000):
        total += m[str(i)]

    checksum = total + len(m)
    print(f"{checksum:g}")


if __name__ == "__main__":
    main()
