package red_black_tree

import "core:fmt"
import "core:intrinsics"
import "core:mem"
import "core:os"
import "core:strings"

VISUALIZATIONS :: #config(VISUALIZATIONS, false)

when VISUALIZATIONS {

	@(private)
	node_to_graphvis :: proc(tree: ^$Tree, node: ^$Tree_Node, sb: strings.Builder, f: os.Handle) {
		sb := sb
		if node.left != &tree.sentinel {
			fmt.fprintf(f, "\t%s\n", fmt.sbprintf(&sb, "%v -> %v", node.key, node.left.key))
			strings.builder_reset(&sb)
			node_to_graphvis(tree, node.left, sb, f)
		}
		if node.right != &tree.sentinel {
			fmt.fprintf(f, "\t%s\n", fmt.sbprintf(&sb, "%v -> %v", node.key, node.right.key))
			strings.builder_reset(&sb)
			node_to_graphvis(tree, node.right, sb, f)
		}
	}

	@(private)
	node_attributes_for_graphvis :: proc(
		tree: ^$Tree,
		node: ^$Tree_Node,
		sb: strings.Builder,
		f: os.Handle,
	) {
		sb := sb
		if (node != &tree.sentinel) {
			fmt.fprintf(
				f,
				"%s [style=\"filled\" fontname=\"Arial\" fontcolor=\"white\" fillcolor=\"%s\"]\n",
				fmt.sbprint(&sb, node.key),
				node.color == Color.Red ? "red" : "black",
			)
			strings.builder_reset(&sb)
			if node.left != &tree.sentinel {
				node_attributes_for_graphvis(tree, node.left, sb, f)
			}
			if node.right != &tree.sentinel {
				node_attributes_for_graphvis(tree, node.right, sb, f)
			}
		}
	}

	tree_to_graphvis :: proc(tree: ^$Tree, filename: string) -> mem.Allocator_Error {
		f, err := os.open(filename, os.O_CREATE | os.O_RDWR | os.O_TRUNC, 0o664)
		if err != os.ERROR_NONE {
			fmt.printf("Could not open '%s'\n", filename)
			os.exit(-1)
		}
		defer os.close(f)

		sb := strings.builder_make() or_return
		defer strings.builder_destroy(&sb)
		fmt.fprintln(f, "digraph RedBlackTree {")
		if tree.root.right == &tree.sentinel && tree.root.left == &tree.sentinel {
			fmt.fprintf(f, "\t%v;\n", fmt.sbprint(&sb, tree.root.key))
		} else {
			node_attributes_for_graphvis(tree, tree.root, sb, f)
			node_to_graphvis(tree, tree.root, sb, f)
		}
		fmt.fprintln(f, "}")
		return mem.Allocator_Error.None
	}
}
