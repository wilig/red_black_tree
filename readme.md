# Red Black Tree Implementation in Odin

A simple red black tree implementation straight from [Introduction to Algorithms](https://en.wikipedia.org/wiki/Introduction_to_Algorithms).  Color information is encoded in the LSB of the parent pointer to conserve memory.


### No warranty expressed or implied, use at your own risk.


## Example Usage

```Odin
package main

import rbt "./red_black_tree"
import "core:fmt"

main :: proc() {
	tree := rbt.init(string, string)

	rbt.insert_node(tree, "Mal", "Captain")
	rbt.insert_node(tree, "Zoe", "First Mate")
	rbt.insert_node(tree, "Wash", "Pilot")
	rbt.insert_node(tree, "Inara", "Consort")
	rbt.insert_node(tree, "Jayne", "Muscle")
	rbt.insert_node(tree, "Kaylee", "Mechanic")
	rbt.insert_node(tree, "Simon", "Doctor")
	rbt.insert_node(tree, "River", "Secret Weapon")
	rbt.insert_node(tree, "Book", "Preacher")

	// Duplicates are not allowed
	assert(!rbt.insert_node(tree, "Mal", "Can't have two captains"))

	// Visitor fun
	fmt.println("\nThe Crew:")
	print_values :: proc(value: string) {
		fmt.printf("\t%s\n", value)
	}
	rbt.visit_all_sub_nodes(tree, tree.root, print_values)

	 
    // Build a graphvis file of the tree
    // -
    // Requires having VISUALIZATIONS defined during the build
    // odin build . -define:VISUALIZATIONS=true
	// -
	// Can be turned into an image with `dot rbt-vis.dot -Tpng > rbt-vis.png`
	// -
    // Uncomment the following line:
	// rbt.tree_to_graphvis(tree, "./rbt-vis.dot")

	// :-(
	rbt.remove_node(tree, "Wash")

	// Find a known key
	p, ok := rbt.find(tree, "Mal")
	if ok {
		fmt.printf("Mal is the %s\n", p)
	}

	//Try to find a non - existent key
	p, ok = rbt.find(tree, "Ravager")
	if !ok {
		fmt.println("No ravagers onboard.")
	}
}
```

## Debugging

When the Odin `-debug` flag during compilation, the parent pointer and color attribute will be store independently so debuggers can easy inspect them.

## Copyright

This code is placed in the public domain.  Do with it what you please.  If you find it worthwile I'd appreciate an attribution.
