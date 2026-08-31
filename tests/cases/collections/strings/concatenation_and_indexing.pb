var word = "pogberry";
print(word[0]);
print(word[7]);
print("hello " + "world");
print("score: " + str(12));
print(len(word));
print("" == "");
print(join(["alpha", "beta", "gamma"], ", "));
print(join(["a", 1, true], "-"));
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|p
//|y
//|hello world
//|score: 12
//|8
//|true
//|alpha, beta, gamma
//|a-1-true
// END EXPECTED OUTPUT
