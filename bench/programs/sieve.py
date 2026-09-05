def count_primes(limit: int) -> int:
    flags = []
    for _ in range(limit + 1):
        flags.append(True)

    p = 2
    while p * p <= limit:
        if flags[p]:
            k = p * p
            while k <= limit:
                flags[k] = False
                k += p
        p += 1

    count = 0
    for p in range(2, limit + 1):
        if flags[p]:
            count += 1
    return count


def main():
    total = 0
    for _ in range(100):
        total += count_primes(10000)
    print(total)


if __name__ == "__main__":
    main()

