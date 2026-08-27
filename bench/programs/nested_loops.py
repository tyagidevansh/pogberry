def main():
    total = 0
    for i in range(200):
        for j in range(200):
            for k in range(250):
                total += i * j + k

    print(f"{total:g}")


if __name__ == "__main__":
    main()
