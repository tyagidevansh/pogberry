class Base:
    def __init__(self, value):
        self.value = value

    def compute(self, x):
        return self.value + x


class Middle(Base):
    def __init__(self, value):
        super().__init__(value)
        self.factor = 2

    def compute(self, x):
        return super().compute(x) * self.factor


class Leaf(Middle):
    def __init__(self, value):
        super().__init__(value)
        self.offset = 3

    def compute(self, x):
        return super().compute(x) + self.offset


def main():
    total = 0
    for i in range(100000):
        obj = Leaf(i)
        total += obj.compute(i)

    print(int(total))


if __name__ == "__main__":
    main()
