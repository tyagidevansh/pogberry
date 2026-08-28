class TreeNode:
    __slots__ = ("item", "left", "right")

    def __init__(self, item, left, right):
        self.item = item
        self.left = left
        self.right = right


def bottom_up_tree(item, depth):
    if depth > 0:
        return TreeNode(
            item,
            bottom_up_tree(2 * item - 1, depth - 1),
            bottom_up_tree(2 * item, depth - 1),
        )
    return TreeNode(item, None, None)


def item_check(node):
    if node.left is None:
        return node.item
    return node.item + item_check(node.left) - item_check(node.right)


def main():
    min_depth = 4
    max_depth = 12
    stretch_depth = max_depth + 1

    stretch_tree = bottom_up_tree(0, stretch_depth)
    stretch_check = item_check(stretch_tree)

    long_lived_tree = bottom_up_tree(0, max_depth)

    total_check = stretch_check
    for depth in range(min_depth, max_depth + 1, 2):
        iterations = 1 << (max_depth - depth + min_depth)
        check = 0
        for i in range(1, iterations + 1):
            check += item_check(bottom_up_tree(i, depth))
            check += item_check(bottom_up_tree(-i, depth))
        total_check += check

    total_check += item_check(long_lived_tree)
    print(f"{float(total_check):g}")


if __name__ == "__main__":
    main()

