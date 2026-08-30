def main():
    count = 15000
    checksum = 0
    words = ["alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta"]

    tags = []
    for i in range(count):
        tag = "record:" + str(i % 100) + ":" + words[i % 8] + "#" + str(i)
        tags.append(tag)
        checksum += len(tag)

    matches = 0
    for i in range(count):
        s = tags[i]
        if s == "record:10:gamma#10" or s == "record:20:epsilon#20" or s == "record:50:alpha#50":
            matches += 1
    checksum += matches * 1000

    delimiter_count = 0
    for i in range(3000):
        s = tags[i]
        slen = len(s)
        for j in range(slen):
            ch = s[j]
            if ch == ":" or ch == "#":
                delimiter_count += 1
    checksum += delimiter_count

    total_block_len = 0
    for p in range(300):
        paragraph = ""
        for w in range(30):
            if w > 0:
                paragraph += " "
            paragraph += words[(p + w) % 8]
        total_block_len += len(paragraph)
    checksum += total_block_len

    print(checksum)


if __name__ == "__main__":
    main()

