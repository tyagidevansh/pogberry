class Node {
    init(value) {
        this.value = value;
        this.left = nil;
        this.right = nil;
    }

    setLeft(node) {
        this.left = node;
    }

    setRight(node) {
        this.right = node;
    }
}

class BinaryTree {
    init(root) {
        this.root = root;
    }

    inorder(node) {
        if (node == nil) {
            return;
        }

        this.inorder(node.left);

        print(node.value);

        this.inorder(node.right);
    }

    startInorder() {
        this.inorder(this.root);
    }
}

// Create nodes
let root = Node(5);
let node1 = Node(3);
let node2 = Node(7);
let node3 = Node(2);
let node4 = Node(4);
let node5 = Node(6);
let node6 = Node(8);

// Build tree structure
root.setLeft(node1);
root.setRight(node2);
node1.setLeft(node3);
node1.setRight(node4);
node2.setLeft(node5);
node2.setRight(node6);

// Create tree and traverse inorder
let tree = BinaryTree(root);
tree.startInorder();

// Expected Output (Inorder Traversal):
// 2
// 3
// 4
// 5
// 6
// 7
// 8
