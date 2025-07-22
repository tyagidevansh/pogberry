fun reverse(str) {
    var result = "";
    for (var i = str.size() - 1; i >= 0; i = i - 1) {
        result = result + str[i];
    }
    return result;
}

print(reverse("pogberry"));