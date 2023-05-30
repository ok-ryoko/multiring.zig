# Design of multiring.zig

This document describes the design of *multiring.zig*. It neither is a formal specification nor attempts to be rigorous. Instead, it aims to capture the how and why of the project at a high level.

## Objective

Extend the singly linked list with hierarchical properties using a purely linked approach

## Concepts

### Rings

A **node** is either a *head node* or a *data node*.

A **link** is a connection between two nodes.

A **ring** comprises exactly one head node and zero or more data nodes. The nodes in a ring are linked sequentially.

The **length** of a ring is the number of data nodes in the ring.

A ring is **empty** if it has zero length.

A nonempty ring is **closed** if the last data node has a link to the ring’s head node. A nonempty ring that isn’t closed is **open**.

A ring may contain zero or more rings. A ring contained by another ring is a **subring** of the containing ring; the containing ring is the **superring** of the contained ring.

Every ring contains itself and so is a subring and superring of itself. (This property is helpful when determining the lowest common superring of any two rings in a multiring.)

A **multiring** is a collection of rings containing one another. The superring of all a multiring’s rings is the **root ring**. The head node of the root ring is the **root** of the multiring.

The **length** of a multiring is the number of data nodes in the multiring.

A multiring is **empty** if it has zero length.

The **depth** or *level* of a ring in a multiring is the number of superring–subring links separating the ring from the root ring. The **height** of a multiring is the maximum depth of the multiring’s rings.

### Nodes

A **head node** is an object bearing:

- an optional link to the first data node in the ring defined by the head node, and
- an optional link to the next node in the ring’s superring.

A **data node** is an object bearing:

- an optional link to the next node in the ring;
- an optional link to the head node of a subring, and
- data of a compile time-known type.
