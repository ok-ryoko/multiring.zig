# multiring.zig

The *multiring* is a singly linked, cyclic and hierarchical [abstract data type] (ADT). This pointer-based [Zig] implementation is intended to expose a rich set of methods that preserve the structural integrity of the multiring.

## Concepts

<picture>
  <source
    media="(prefers-color-scheme: dark)"
    srcset="./docs/img/multiring-github-dark.png"
  >
  <source
    media="(prefers-color-scheme: light)"
    srcset="./docs/img/multiring-github-light.png"
  >
  <img
    title="multiring"
    img alt=""
    src="./docs/img/multiring-github-light.png"
    align="right"
    height="120"
  >
</picture>

A **singly [linked list]** is a sequence of one or more data nodes. Each **data node** contains data (an int, struct, etc.) and an optional pointer to another data node.

Suppose, for whatever reason, that we want to cyclize a singly linked list into a **ring.** In other words, we want to connect the tail node to the head node. Doing so directly results in an ADT in which there are no intrinsic notions of beginning and end. If we wanted a reproducible traversal of the ring’s data nodes, then we would have to manage an extra pointer into the ring.

An alternative solution is to come up with the idea of a **gate node,** which consists entirely of one optional pointer to a data node. We then redefine the **ring** as a sequence of one gate node and zero or more data nodes. A ring that has zero data nodes is an **empty ring.** The gate node in an empty ring doesn’t point to any node. In a non-empty ring, the gate node points to the first data node and the last data node points to the gate node. Thus, we have a ring ADT for which traversal is reproducible and managed by the implementation.

To further increase the flexibility of this ADT (again, for whatever reason), we can introduce hierarchical properties by allowing every data node to know about a child gate node and every gate node to know about a parent data node. This new **multiring** ADT allows us to “descend into” and “ascend from” subrings. Traversing a multiring feels like traversing both a cyclic linked list and a [tree], as illustrated by the following animation. Here, yellow and blue spheres represent gate and data nodes, respectively. The counter-clockwise orientation of traversal is arbitrary; we obtain it by having the normal to the plane of each ring point up and applying the [right-hand rule].

https://user-images.githubusercontent.com/59705845/208020172-4040b8f7-288c-4360-8e41-86f8dc51ea2e.mp4

We stipulate that the first gate node (the **root node**) may not have a parent data node who is also one of its descendents. This restriction prevents the creation of internal traversal loops, which would have the effect of removing arbitrarily many nodes from the multiring.

## Usage

Please see the unit tests in [*multiring.zig*][source]. The `MultiRing` API is still unstable; its basic usage is presently too verbose for high-level documentation. [Ryoko] doesn’t recommend using this module in production.

## Applications

multiring.zig has no known applications. Ryoko wrote it to practice Zig, have fun and show linked lists some love. If you have used multiring.zig successfully in your project(s), please let us know by [starting a discussion][discussions]. (Please take time to read the [code of conduct] before starting a discussion.)

## License

multiring.zig is free and open source software [licensed under the MIT license][license].

## Acknowledgements

The implementation is inspired by the [`std.SinglyLinkedList`][std.SinglyLinkedList] implementation in Zig 0.9.1.

[abstract data type]: https://en.wikipedia.org/wiki/Abstract_data_type
[code of conduct]: ./CODE_OF_CONDUCT.md
[discussions]: https://github.com/ok-ryoko/multiring.zig/discussions
[license]: ./LICENSE.txt
[linked list]: https://en.wikipedia.org/wiki/Linked_list
[right-hand rule]: https://en.wikipedia.org/wiki/Right-hand_rule
[Ryoko]: https://github.com/ok-ryoko
[source]: ./src/multiring.zig
[std.SinglyLinkedList]: https://github.com/ziglang/zig/blob/0.9.1/lib/std/linked_list.zig
[tree]: https://en.wikipedia.org/wiki/Tree_(data_structure)
[Zig]: https://ziglang.org/
