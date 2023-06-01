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

## Constraints

Constraints are important because they:

- help to define the personality of the project;
- encourage simplicity, and
- may require us to discover creative ways to solve problems.

### Programming language choice set

The implementation shall be expressed using exactly one of [ANSI C], [Go] and [Zig]—all simple, compiled and statically typed languages featuring imperative programming and raw pointers.

### No dynamic memory allocation

The implementation shall neither allocate any memory on the heap nor deallocate any memory from the heap.

### No sequential types

The implementation shall not depend on any type backed by contiguous memory.

### No dependence on any external package, module or library

The implementation shall have no external dependencies. However, supporting code (build, tests, etc.) may depend on the chosen language’s standard library. Supporting tools such as [Make] are also permitted.

## Choice of programming language

When handling nodes, there will be some contexts in which the type of node is important and others in which it is not. Thus, our chosen language should make it easy for us to achieve polymorphism, preferably over a fixed finite set of types. (There are only and exactly two types of node.) Zig’s [tagged union] is a perfect match. Go gives us [interfaces], but they are too powerful—we don’t need to be able to define arbitrarily many types of node. Moreover, Go has no native enum type (enums are emulated using [iota]). C gives us only plain enums to work with.

Zig equips us with [unreachable code] as well as capture syntax for dereferencing optional pointers. C and Go don’t provide equivalent features.

C and Zig require us to manage dynamically allocated memory manually. We should therefore be able to guarantee that our implementation doesn’t interact with the heap by writing zero lines of memory management code. Providing the same guarantee is more difficult in a garbage-collected language like Go.

We value maintainability, so we believe that our chosen language should grace us with a robust development experience. Go tells the strongest narrative through the `go` CLI, exposing commands for formatting, linting, building and testing Go code as well as managing Go modules. Zig’s story is similarly compelling although incomplete—there’s no dedicated static analysis tool and the package manager isn’t yet stable. On the other hand, C doesn’t provide standardized developer tools, leaving us to mix and match the components we need, down to the implementation of the language itself. Do we use the [GNU Compiler Collection], [Clang]/[LLVM] or something else? Such questions impose a relatively expensive research burden for a language that we may not end up using.

C is over 50 years old and stable, having seen ubiquitous use as well as a series of international standards and competing toolchains. As of May 2023, it takes 2nd place on the [TIOBE Index]. Go is not as mature as C (it’s over 10 years old) but is stable and widely used, ranking 12th on the TIOBE Index. Go has carved a niche out for itself in the web, container and command-line utility ecosystems. In contrast, Zig is neither stable nor widely used. Choosing Zig over C and Go means allocating development resources to staying in step with the latest stable release of the language and taking on the risk of breaking changes. It also means diminishing the accessibility of the project.

On the basis of these considerations, the repository owner chose to implement the multiring in Zig.

## Type definitions

When defining our types, we’ll be using optional (nullable) pointers. Where possible, we’ll attach semantic meaning to the null pointer so that it isn’t just an artifact of our implementation.

### Node

```zig
pub const Node = union(enum) {
    head: *HeadNode,
    data: *DataNode,

    // ...
};
```

Defining `Node` as a tagged union enables us to achieve polymorphism over a finite set of types.

### Head node

```zig
pub const HeadNode = struct {
    next: ?*DataNode = null,
    next_above: ?Node = null,

    // ...
};
```

`next` represents a link to the first data node in the ring. When `next` is `null`, the ring is empty; otherwise, the ring is nonempty. `next_above` represents a link to the next node in the superring. When `next_above` is null, the ring is the root ring; otherwise, the ring is a subring of a superring. Both `next` and `next_above` are optional, so we can instantiate a head node without any links (equivalent to an empty root ring).

### Data node

```zig
pub const DataNode = struct {
    next: ?Node = null,
    next_below: ?*HeadNode = null,
    data: T,

    // ...
};
```

`next` represents a link to the next node in the ring. When `next` is null, the ring is open. `next_below` represents a link to the head node of a subring. When `next_below` is null, there is no subring at the data node. Since both fields are optional, we can instantiate a data node simply by populating the `data` field, which is of a parametrized and compile time-known type, `T`.

### Multiring

```zig
pub fn MultiRing(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Node = union(enum) {
            // ...
        };

        pub const HeadNode = struct {
            // ...
        };

        pub const DataNode = struct {
            // ...
        };

        root: ?*HeadNode = null,

        // ...
    };
}
```

To finish, we aggregate our node definitions into a compile-time generic and define a root. We should be able to use the head node interface to discover the remainder of the structure from the root. Since `root` is optional, we’re able to instantiate an empty multiring, deferring node creation and ring assembly.

### Ring

Every head node already defines a ring implicitly, so we don’t define a dedicated ring type. This helps us to limit the complexity of the code base.

## Undefined behavior

There are several invariants we can’t express easily in our definitions:

- For any head node `h`, `h.next` represents a link to none other than the first data node in the ring defined by `h`, and `h.next_above` represents a link to none other than the next node in the ring’s superring
- For any pair of distinct head nodes `h1` and `h2` in a multiring, `h1.next.? != h2.next.?` is `true` and `h1.next_above != h2.next_above` is `true`
- For any data node `d`, `d.next` represents a link to none other than either the next data node in the ring of which `d` is a member (if `d` isn’t the last data node in the ring) or the head node of the ring, and `d.next_below` represents a link to none other than the head node of the subring at `d`
- For any pair of distinct data nodes `d1` and `d2` in a multiring, `d1.next.? != d2.next.?` is `true` and `d1.next_below.? != d2.next_below.?` is `true`

Constraints that we can’t articulate in our chosen language are sources of undefined behavior. Examples of undefined behavior include:

- Linking any node to itself
- Linking a data node in one ring to a data node in another ring
- Inserting one or more data nodes already in the multiring
- Attaching a subring that already has a superring to a data node
- Attaching a subring to a data node that already has a subring

We could try addressing some of these constraints by inserting new types and logic at the cost of increasing the complexity of the design. Instead, we opt to trust users and bestow them with extra power, while also providing interfaces that make it possible for client code to avoid undefined behavior altogether.

[ANSI C]: https://en.wikipedia.org/wiki/ANSI_C
[Clang]: https://clang.llvm.org/
[GNU Compiler Collection]: https://gcc.gnu.org/
[Go]: https://go.dev/
[interfaces]: https://go.dev/ref/spec#Interface_types
[iota]: https://go.dev/ref/spec#Iota
[LLVM]: https://www.llvm.org/
[Make]: https://www.gnu.org/software/make/
[tagged union]: https://ziglang.org/documentation/master/#Tagged-union
[TIOBE Index]: https://www.tiobe.com/tiobe-index/
[unreachable code]: https://ziglang.org/documentation/master/#unreachable
[Zig]: https://ziglang.org/
