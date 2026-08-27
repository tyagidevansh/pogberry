def make_accumulator(start):
    total = start

    def add(n):
        nonlocal total
        total += n
        return total

    return add


def main():
    accumulators = []
    for i in range(10):
        accumulators.append(make_accumulator(i))

    total = 0
    for i in range(10):
        acc = accumulators[i]
        last = 0
        for j in range(10000):
            last = acc(1)
        total += last

    print(f"{total:g}")


if __name__ == "__main__":
    main()
