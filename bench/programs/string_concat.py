def main():
    s = ""
    for i in range(50000):
        s += str(i % 10)
    print(len(s))


if __name__ == "__main__":
    main()
