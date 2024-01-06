package red_black_tree

import "core:fmt"
import "core:intrinsics"
import "core:math/rand"
import "core:mem"
import "core:testing"

Color :: enum {
	Black,
	Red,
}

Node :: struct($Key, $Value: typeid) where intrinsics.type_is_comparable(Key) {
	left, right, parent: ^Node(Key, Value),
	color:               Color,
	key:                 Key,
	value:               Value,
}

Tree :: struct($Key, $Value: typeid) where intrinsics.type_is_comparable(Key) {
	allocator: mem.Allocator,
	sentinel:  Node(Key, Value),
	root:      ^Node(Key, Value),
}

@(private)
init_node :: proc(tree: ^Tree($Key, $Value), key: Key, value: Value) -> ^Node(Key, Value) {
	node := new(Node(Key, Value), tree.allocator)
	node.key = key
	node.value = value
	node.color = Color.Red
	node.parent = &tree.sentinel
	node.left = &tree.sentinel
	node.right = &tree.sentinel
	return node
}

@(private)
rotate_right :: proc(tree: ^$Tree, node: ^$Node) {
	sibling := node.left
	node.left = sibling.right

	// Turn siblings right subtree into nodes left subtree
	if sibling.right != &tree.sentinel {
		sibling.right.parent = node
	}
	sibling.parent = node.parent
	if node.parent == &tree.sentinel {
		tree.root = sibling
	} else {
		if node == node.parent.right {
			node.parent.right = sibling
		} else {
			node.parent.left = sibling
		}
	}
	sibling.right = node
	node.parent = sibling
}

@(private)
rotate_left :: proc(tree: ^$Tree, node: ^$Node) {
	sibling := node.right
	node.right = sibling.left

	// Turn siblings left subtree into nodes right subtree
	if sibling.left != &tree.sentinel {
		sibling.left.parent = node
	}
	sibling.parent = node.parent
	if node.parent == &tree.sentinel {
		tree.root = sibling
	} else {
		if node == node.parent.left {
			node.parent.left = sibling
		} else {
			node.parent.right = sibling
		}
	}
	sibling.left = node
	node.parent = sibling
}

@(private)
rebalance_after_insert :: proc(tree: ^$Tree, node: ^$Node) {
	node := node
	uncle: ^Node
	for (node != tree.root && node.parent.color == Color.Red) {
		// Rebalancing cases
		if node.parent.parent != &tree.sentinel && node.parent == node.parent.parent.left {
			uncle = node.parent.parent.right
			if uncle != &tree.sentinel && uncle.color == Color.Red {
				node.parent.color = Color.Black
				uncle.color = Color.Black
				node.parent.parent.color = Color.Red
				node = node.parent.parent
			} else {
				if node == node.parent.right {
					// Case 2
					node = node.parent
					rotate_left(tree, node)
				}
				// Case 3
				node.parent.color = Color.Black
				node.parent.parent.color = Color.Red
				rotate_right(tree, node.parent.parent)
			}
		} else if node.parent.parent != &tree.sentinel {
			uncle = node.parent.parent.left
			if uncle != &tree.sentinel && uncle.color == Color.Red {
				node.parent.color = Color.Black
				uncle.color = Color.Black
				node.parent.parent.color = Color.Red
				node = node.parent.parent
			} else {
				if node == node.parent.left {
					// Case 2
					node = node.parent
					rotate_right(tree, node)
				}
				// Case 3
				node.parent.color = Color.Black
				node.parent.parent.color = Color.Red
				rotate_left(tree, node.parent.parent)
			}
		}
	}
	tree.root.color = Color.Black
}

@(private)
maximum_node :: proc(tree: ^$Tree, node: ^$TreeNode) -> ^TreeNode {
	node := node
	for node.right != &tree.sentinel {
		node = node.right
	}
	return node
}

@(private)
minimum_node :: proc(tree: ^$Tree, node: ^$TreeNode) -> ^TreeNode {
	node := node
	for node.left != &tree.sentinel {
		node = node.left
	}
	return node
}

@(private)
find_successor :: proc(tree: ^$Tree, node: ^$Node) -> ^Node {
	assert(node != nil)
	node := node
	if node.left.color == Color.Red {
		return maximum_node(tree, node.left)
	} else if node.right != &tree.sentinel {
		return minimum_node(tree, node.right)
	}
	parent := node.parent
	for parent != &tree.sentinel && node == parent.right {
		node = parent
		parent = node.parent
	}
	return parent
}

@(private)
rebalance_after_removal :: proc(tree: ^$Tree, node: ^$Node) {
	node := node
	sibling: ^Node
	for tree.root != node && node.color == Color.Black {
		if node == node.parent.left {
			sibling = node.parent.right
			if sibling.color == Color.Red {
				sibling.color = Color.Black
				node.parent.color = Color.Red
				rotate_left(tree, node.parent)
				sibling = node.parent.right
			}
			if sibling.right.color == Color.Black && sibling.left.color == Color.Black {
				sibling.color = Color.Red
				node = node.parent
			} else {
				if sibling.right.color == Color.Black {
					sibling.color = Color.Red
					sibling.left.color = Color.Black
					rotate_right(tree, sibling)
					sibling = node.parent.right
				}
				sibling.color = node.parent.color
				node.parent.color = Color.Black
				sibling.right.color = Color.Black
				rotate_left(tree, node.parent)
				node = tree.root
			}
		} else {
			sibling = node.parent.left
			if sibling.color == Color.Red {
				sibling.color = Color.Black
				node.parent.color = Color.Red
				rotate_right(tree, node.parent)
				sibling = node.parent.left
			}
			if sibling.right.color == Color.Black && sibling.left.color == Color.Black {
				sibling.color = Color.Red
				node = node.parent
			} else {
				if sibling.left.color == Color.Black {
					sibling.color = Color.Red
					sibling.right.color = Color.Black
					rotate_left(tree, sibling)
					sibling = node.parent.left
				}
				sibling.color = node.parent.color
				node.parent.color = Color.Black
				sibling.left.color = Color.Black
				rotate_right(tree, node.parent)
				node = tree.root
			}
		}
	}
	node.color = Color.Black
}

@(private)
find_node :: proc(tree: ^Tree($Key, $Value), key: Key) -> (^Node(Key, Value), bool) {
	node := tree.root
	for node != &tree.sentinel {
		switch {
		case key == node.key:
			return node, true
		case key > node.key:
			node = node.right
		case key < node.key:
			node = node.left
		}
	}
	return nil, false
}

@(private)
free_all_nodes :: proc(tree: ^$Tree, node: ^$Node) {
	if node == &tree.sentinel {
		return
	}
	free_all_nodes(tree, node.left)
	free(node, tree.allocator)
	free_all_nodes(tree, node.right)
}


// Public interface

init :: proc(
	$Key, $Value: typeid,
	allocator: mem.Allocator = context.allocator,
) -> ^Tree(Key, Value) {
	tree := new(Tree(Key, Value), allocator)
	tree.sentinel = Node(Key, Value){}
	tree.allocator = allocator
	tree.root = &tree.sentinel
	return tree
}

destroy :: proc(tree: ^Tree($Key, $Value)) {
	free_all_nodes(tree, tree.root)
	free(tree, tree.allocator)
}

remove_node :: proc(tree: ^Tree($Key, $Value), key: Key) -> (Value, bool) {
	child, successor: ^Node(Key, Value)

	if node_to_delete, ok := find_node(tree, key); ok {
		defer free(successor, tree.allocator)
		if node_to_delete.left == &tree.sentinel || node_to_delete.right == &tree.sentinel {
			successor = node_to_delete
		} else {
			successor = find_successor(tree, node_to_delete)
		}
		if successor.left != &tree.sentinel {
			child = successor.left
		} else {
			child = successor.right
		}
		child.parent = successor.parent
		if successor.parent == &tree.sentinel {
			tree.root = child
		} else if successor == successor.parent.left {
			successor.parent.left = child
		} else {
			successor.parent.right = child
		}
		if successor != node_to_delete {
			key_to_be_deleted := node_to_delete.key
			value_to_be_deleted := node_to_delete.value
			node_to_delete.key = successor.key
			node_to_delete.value = successor.value
			successor.key = key_to_be_deleted
			successor.value = value_to_be_deleted
		}
		if successor.color == Color.Black {
			rebalance_after_removal(tree, child)
		}
		return successor.value, true
	}
	return Value{}, false
}

insert_node :: proc(tree: ^Tree($Key, $Value), key: Key, value: Value) -> bool {
	parent := tree.root
	if parent == &tree.sentinel {
		tree.root = init_node(tree, key, value)
		rebalance_after_insert(tree, tree.root)
	} else {
		for {
			if parent.key == key { 	// Duplicate
				return false
			} else if (parent.key > key) {
				if (parent.left == &tree.sentinel) {
					node := init_node(tree, key, value)
					parent.left = node
					node.parent = parent
					rebalance_after_insert(tree, node)
					break
				} else {
					parent = parent.left
				}
			} else {
				if (parent.right == &tree.sentinel) {
					node := init_node(tree, key, value)
					parent.right = node
					node.parent = parent
					rebalance_after_insert(tree, node)
					break
				} else {
					parent = parent.right
				}
			}
		}
	}
	return true
}

visit_all_sub_nodes :: proc(
	tree: ^Tree($Key, $Value),
	node: ^Node(Key, Value),
	visitor: proc(value: Value),
) {
	if node == &tree.sentinel {
		return
	}
	visit_all_sub_nodes(tree, node.left, visitor)
	visitor(node.value)
	visit_all_sub_nodes(tree, node.right, visitor)
}

find :: proc(tree: ^Tree($Key, $Value), key: Key) -> (Value, bool) {
	if node, ok := find_node(tree, key); ok {
		return node.value, true
	} else {
		return Value{}, false
	}
}

@(test)
test_large_tree :: proc(t: ^testing.T) {
	tree := init(int, int, context.allocator)
	defer destroy(tree)

	my_rand: rand.Rand
	rand.init_as_system(&my_rand)
	for i := 0; i < 100000; i += 1 {
		rfnum := rand.float32(&my_rand)
		rnum := int(rfnum * 100000)
		insert_node(tree, rnum, rnum + 0xDEADBEEF)
	}

	for i := 0; i < 20000; i += 1 {
		rfnum := rand.float32(&my_rand)
		rnum := int(rfnum * 100000)
		remove_node(tree, rnum)
	}
}

@(test)
test_simple_tree :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	tree := init(string, string, mem.tracking_allocator(&track))
	defer {
		destroy(tree)
		if len(track.allocation_map) > 0 {
			fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
			for _, entry in track.allocation_map {
				fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
			}
		}
		if len(track.bad_free_array) > 0 {
			fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
			for entry in track.bad_free_array {
				fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
			}
		}
		mem.tracking_allocator_destroy(&track)
	}

	testing.expect(t, insert_node(tree, "Mal", "Captain"))
	testing.expect(t, insert_node(tree, "Zoe", "First Mate"))
	testing.expect(t, insert_node(tree, "Wash", "Pilot"))
	testing.expect(t, insert_node(tree, "Inara", "Consort"))
	testing.expect(t, insert_node(tree, "Jayne", "Muscle"))
	testing.expect(t, insert_node(tree, "Kaylee", "Mechanic"))
	testing.expect(t, insert_node(tree, "Simon", "Doctor"))
	testing.expect(t, insert_node(tree, "River", "Secret Weapon"))
	testing.expect(t, insert_node(tree, "Book", "Preacher"))

	// Duplicates are not allowed
	testing.expect(t, !insert_node(tree, "Mal", "Can't have two captains"))

	testing.expect(
		t,
		tree.root.key == "Mal",
		fmt.tprintf("Incorrect root node, expected 'Mal' got %v\n", tree.root.key),
	)

	// :-(
	wash, ok := remove_node(tree, "Wash")
	testing.expect(t, ok)
	testing.expect(t, wash == "Pilot")
	// Prove it's removed
	_, ok = find(tree, "Wash")
	testing.expect(t, !ok)

	// Lookup some values
	_, ok = find(tree, "Mal")
	testing.expect(t, ok)
	_, ok = find(tree, "River")
	testing.expect(t, ok)
	_, ok = find(tree, "Zoe")
	testing.expect(t, ok)
	_, ok = find(tree, "Kaylee")
	testing.expect(t, ok)
	_, ok = find(tree, "Jayne")
	testing.expect(t, ok)

	// Try to find a non-existent key
	_, ok = find(tree, "Ravager")
	testing.expect(t, !ok)
}
