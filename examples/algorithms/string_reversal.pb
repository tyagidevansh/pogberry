fun reverse(str) {
    var result = "";
    for (var i = len(str) - 1; i >= 0; i = i - 1) {
        result = result + str[i];
    }
    return result;
}

print(reverse("Pogberry"));
