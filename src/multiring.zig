// SPDX-FileCopyrightText: Copyright 2022-2024 OK Ryoko
// SPDX-License-Identifier: MIT

/// Hierarchical, forwardly linked and circularly linked abstract data type
///
pub fn MultiRing(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Types of node
        ///
        pub const NodeTag = enum {
            head,
            data,
        };

        /// Either a pointer to a head node or a pointer to a data node
        ///
        pub const Node = union(NodeTag) {
            head: *HeadNode,
            data: *DataNode,

            /// Determine whether this node is a head node
            ///
            pub fn isHead(self: Node) bool {
                return self == .head;
            }

            /// Determine whether this node is a data node
            ///
            pub fn isData(self: Node) bool {
                return self == .data;
            }

            /// Return the last data node in this ring
            ///
            /// If this node is a head node and this ring is empty, then return null
            ///
            pub fn findLast(self: Node) ?*DataNode {
                return switch (self) {
                    inline else => |s| s.findLast(),
                };
            }

            /// Return the next head node in this multiring after this node if it can be found and
            /// null otherwise
            ///
            pub fn findHeadZ(self: Node) ?*HeadNode {
                return switch (self) {
                    inline else => |s| s.findHeadZ(),
                };
            }

            /// Return the root of this multiring
            ///
            /// If this node is a data node in an open ring or if any superring of the ring
            /// containing this node is open, then return null
            ///
            pub fn findRoot(self: Node) ?*HeadNode {
                return switch (self) {
                    inline else => |s| s.findRoot(),
                };
            }

            /// Return the next data node in this ring
            ///
            /// If this ring is empty or this is the last data node in this ring, then return null
            ///
            pub fn step(self: Node) ?*DataNode {
                return switch (self) {
                    inline else => |s| s.step(),
                };
            }

            /// Return the next data node in this multiring
            ///
            /// If this node is:
            ///
            ///   - the root of an empty multiring;
            ///   - the last data node in this multiring, or
            ///   - any head node after the last data node in this multiring...
            ///
            /// ... then return null
            ///
            pub fn stepZ(self: Node) ?*DataNode {
                return switch (self) {
                    inline else => |s| s.stepZ(),
                };
            }

            /// Insert a data node immediately after this node
            ///
            /// Closes this ring if it is empty
            ///
            pub fn insertAfter(self: Node, node: *DataNode) void {
                switch (self) {
                    inline else => |s| s.insertAfter(node),
                }
            }

            /// Insert many data nodes immediately after this node
            ///
            /// Closes this ring if it is empty
            ///
            pub fn insertManyAfter(self: Node, nodes: []DataNode) void {
                switch (self) {
                    inline else => |s| s.insertManyAfter(nodes),
                }
            }

            /// Remove and return the next data node in this ring
            ///
            /// If this ring is empty or this is the last data node in this ring, then return null
            ///
            pub fn popNext(self: Node) ?*DataNode {
                return switch (self) {
                    inline else => |s| s.popNext(),
                };
            }
        };

        /// The first and defining node of a ring, containing:
        ///
        ///   - an optional link to the first data node in the ring (`next`), and
        ///   - an optional link to the next node in this ring's superring (`next_above`)
        ///
        /// For any head node `h`, always assume that:
        ///
        ///   - if the expression `h.next_above == .head` is equal to `true`, then the expression
        ///     `h.next_above.? != h` is equal to `true`
        ///
        /// For any pair of distinct head nodes `h1` and `h2` in a multiring, always assume that the
        /// following expressions are equal to `true`:
        ///
        ///     `h1.next.? != h2.next.?`
        ///     `h1.next_above != h2.next_above`
        ///
        pub const HeadNode = struct {
            next: ?*DataNode = null,
            next_above: ?Node = null,

            /// Determine whether this head node is the root of this multiring
            ///
            pub fn isRoot(this: *HeadNode) bool {
                return this.next_above == null;
            }

            /// Determine whether this ring is empty
            ///
            pub fn isEmpty(this: *HeadNode) bool {
                return this.next == null;
            }

            /// Determine whether this ring comprises a null-terminated sequence of data nodes,
            /// i.e., a conventional linked list
            ///
            /// If this ring is empty, then return null
            ///
            pub fn isOpen(this: *HeadNode) ?bool {
                return if (this.next) |first| first.findHead() == null else null;
            }

            /// Return the number of data nodes in this ring
            ///
            pub fn count(this: *HeadNode) usize {
                return if (this.next) |first| first.countAfter() + 1 else 0;
            }

            /// Return the number of data nodes after this ring in this multiring
            ///
            pub fn countAbove(this: *HeadNode) usize {
                var result: usize = 0;
                var it = this;
                while (it.next_above) |n| {
                    switch (n) {
                        .head => |h| it = h,
                        .data => |d| {
                            result += d.countAfterZ() + 1;
                            break;
                        },
                    }
                }
                return result;
            }

            /// Return the number of data nodes in the multiring rooted at this head node
            ///
            pub fn countBelow(this: *HeadNode) usize {
                var result: usize = 0;
                var it = this.next;
                while (it) |n| {
                    result += 1;
                    it = n.stepUntilHeadZ(this);
                }
                return result;
            }

            /// Return the last data node in this ring
            ///
            /// If this ring is empty, then return null
            ///
            pub fn findLast(this: *HeadNode) ?*DataNode {
                return if (this.next) |first| first.findLast() else null;
            }

            /// Return the last data node after this ring in this multiring
            ///
            /// If there is no such data node, then return null
            ///
            pub fn findLastAbove(this: *HeadNode) ?*DataNode {
                var result: ?*DataNode = null;
                var it = this;
                while (it.next_above) |n| {
                    switch (n) {
                        .head => |h| it = h,
                        .data => |d| {
                            result = d.findLastZ();
                            break;
                        },
                    }
                }
                return result;
            }

            /// Return the last data node in the multiring rooted at this head node
            ///
            /// If this ring is empty, then return null
            ///
            pub fn findLastBelow(this: *HeadNode) ?*DataNode {
                var result: ?*DataNode = null;
                var it = this.findLast();
                while (it) |d| {
                    result = d;
                    const h = d.next_below orelse break;
                    it = h.findLast();
                }
                return result;
            }

            /// Return the next head node in this multiring after this ring
            ///
            /// If this head node is the root of this multiring, then return null
            ///
            pub fn findHeadAbove(this: *HeadNode) ?*HeadNode {
                return if (this.next_above) |n| switch (n) {
                    .head => |h| h,
                    .data => |d| d.findHead(),
                } else null;
            }

            /// Return the next head node in this multiring after this head node
            ///
            /// If this head node:
            ///
            ///   - is the last head node in the multiring;
            ///   - is the root of an empty multiring;
            ///   - defines an empty subring of an open superring, or
            ///   - defines an open nonempty ring that contains no subrings...
            ///
            /// ... then return null
            ///
            pub fn findHeadZ(this: *HeadNode) ?*HeadNode {
                return if (this.next) |first| blk: {
                    break :blk first.findHeadZ();
                } else if (this.findHeadAbove()) |h| blk: {
                    break :blk h;
                } else this;
            }

            /// Return the root of this multiring
            ///
            /// If any superring of this ring is open, then return null
            ///
            pub fn findRoot(this: *HeadNode) ?*HeadNode {
                var it = this;
                while (it.next_above) |n| {
                    switch (n) {
                        .head => |h| it = h,
                        .data => |d| {
                            if (d.findHead()) |h| {
                                it = h;
                            } else {
                                return null;
                            }
                        },
                    }
                }
                return it;
            }

            /// Return the first data node in this ring
            ///
            /// If this ring is empty, then return null
            ///
            pub fn step(this: *HeadNode) ?*DataNode {
                return if (this.next) |first| first else null;
            }

            /// Return the next data node in a superring of this ring
            ///
            /// If:
            ///
            ///   - this head node is the root of this multiring, or
            ///   - there are no data nodes after this ring in this multiring...
            ///
            /// ... then return null
            ///
            pub fn stepAbove(this: *HeadNode) ?*DataNode {
                var it = this;
                while (it.next_above) |n| {
                    switch (n) {
                        .head => |h| it = h,
                        .data => |d| return d,
                    }
                }
                return null;
            }

            /// Return the next data node in a superring of this ring before `head`
            ///
            /// If:
            ///
            ///   - this head node is equal to `head`;
            ///   - this head node is the root of this multiring, or
            ///   - there are no data nodes after this ring in this multiring...
            ///
            /// ... then return null
            ///
            pub fn stepAboveUntilHead(this: *HeadNode, head: *HeadNode) ?*DataNode {
                if (this == head) {
                    return null;
                }
                var it = this;
                while (it.next_above) |n| {
                    switch (n) {
                        .head => |h| {
                            if (h == head) {
                                break;
                            }
                            it = h;
                        },
                        .data => |d| return d,
                    }
                }
                return null;
            }

            /// Return the next data node in this multiring
            ///
            /// If:
            ///
            ///   - this head node is the root of an empty multiring, or
            ///   - there are no data nodes after this head node in this multiring...
            ///
            /// ... then return null
            ///
            pub fn stepZ(this: *HeadNode) ?*DataNode {
                return if (this.next) |first| first else this.stepAbove();
            }

            /// Unlink the last data node in this ring from this head node
            ///
            pub fn open(this: *HeadNode) void {
                if (this.findLast()) |last| {
                    last.next = null;
                    if (last.next_below) |h| {
                        h.next_above = null;
                    }
                }
            }

            /// Link the last data node in this ring to this head node
            ///
            pub fn close(this: *HeadNode) void {
                if (this.findLast()) |last| {
                    last.next = .{ .head = this };
                    if (last.next_below) |h| {
                        h.next_above = .{ .head = this };
                    }
                }
            }

            /// Rotate the data nodes in this ring by one position such that the first data node
            /// before the operation is the last data node after the operation
            ///
            pub fn rotate(this: *HeadNode) void {
                if (this.next) |first| {
                    var last = first.findLast();
                    if (first.next) |n| {
                        switch (n) {
                            .head => {},
                            .data => {
                                const d = this.popNext().?;
                                last.insertAfter(d);
                            },
                        }
                    }
                }
            }

            /// Reverse the data nodes in this ring
            ///
            pub fn reverse(this: *HeadNode) void {
                if (this.findLast()) |last| {
                    var first = this.next.?;
                    while (first != last) : (first = this.next.?) {
                        _ = this.popNext().?;
                        last.insertAfter(first);
                    }
                }
            }

            /// Insert a data node immediately after this head node
            ///
            /// Closes this ring if it is empty
            ///
            pub fn insertAfter(this: *HeadNode, node: *DataNode) void {
                node.next = if (this.next) |first| .{ .data = first } else .{ .head = this };
                this.next = node;
            }

            /// Insert many data nodes immediately after this head node
            ///
            /// Closes this ring if it is empty
            ///
            pub fn insertManyAfter(this: *HeadNode, nodes: []DataNode) void {
                if (nodes.len > 0) {
                    this.insertAfter(&nodes[0]);
                    var it = &nodes[0];
                    for (nodes[1..]) |*n| {
                        it.insertAfter(n);
                        it = n;
                    }
                }
            }

            /// Insert a data node immediately after the last data node in this ring
            ///
            /// If this ring is empty, then insert the data node immediately after this head node
            /// and close this ring
            ///
            pub fn append(this: *HeadNode, node: *DataNode) void {
                if (this.findLast()) |last| {
                    last.insertAfter(node);
                } else {
                    this.insertAfter(node);
                }
            }

            /// Insert many data nodes immediately after the last data node in this ring
            ///
            /// If this ring is empty, then insert the data nodes immediately after this head node
            /// and close this ring
            ///
            pub fn extend(this: *HeadNode, nodes: []DataNode) void {
                if (this.findLast()) |last| {
                    last.insertManyAfter(nodes);
                } else {
                    this.insertManyAfter(nodes);
                }
            }

            /// Remove and return the first data node in this ring
            ///
            /// If this ring is empty, then return null
            ///
            pub fn popNext(this: *HeadNode) ?*DataNode {
                if (this.next) |first| {
                    this.next = if (first.next) |n| switch (n) {
                        .head => null,
                        .data => |d| d,
                    } else null;
                    first.next = null;
                    if (first.next_below) |h| {
                        h.next_above = null;
                    }
                    return first;
                }
                return null;
            }

            /// Remove a data node from this ring, returning true if the node was found and
            /// removed and false otherwise
            ///
            pub fn remove(this: *HeadNode, node: *DataNode) bool {
                if (this.next) |first| {
                    if (first == node) {
                        _ = this.popNext().?;
                        return true;
                    }
                    return first.removeAfter(node);
                }
                return false;
            }

            /// Remove a data node from this multiring after this ring, returning true if the node
            /// was found and removed and false otherwise
            ///
            pub fn removeAbove(this: *HeadNode, node: *DataNode) bool {
                var it = this;
                while (it.next_above) |n| {
                    switch (n) {
                        .head => |h| it = h,
                        .data => |d| {
                            if (d == node) {
                                if (d.findHead()) |h| {
                                    return h.remove(node);
                                }
                                return false;
                            }
                            return d.removeAfterZ(node);
                        },
                    }
                }
                return false;
            }

            /// Remove a data node from the multiring rooted at this head node, returning true if
            /// the node was found and removed and false otherwise
            ///
            pub fn removeBelow(this: *HeadNode, node: *DataNode) bool {
                if (this.next) |first| {
                    if (first == node) {
                        _ = this.popNext().?;
                        return true;
                    }
                    var it: ?*DataNode = first;
                    while (it) |n| {
                        if (n == node) {
                            if (n.findHead()) |h| {
                                return h.remove(node);
                            }
                            return false;
                        }
                        if (n.next) |next| {
                            switch (next) {
                                .head => {},
                                .data => |d| {
                                    if (d == node) {
                                        _ = n.popNext().?;
                                        return true;
                                    }
                                },
                            }
                        }
                        if (n.next_below) |h| {
                            if (h.next) |d| {
                                if (d == node) {
                                    _ = h.popNext().?;
                                    return true;
                                }
                            }
                        }
                        it = n.stepUntilHeadZ(this);
                    }
                }
                return false;
            }

            /// Remove all data nodes from this ring
            ///
            pub fn clear(this: *HeadNode) void {
                if (this.findLast()) |last| {
                    last.next = null;
                    if (last.next_below) |h| {
                        h.next_above = null;
                    }
                    this.next = null;
                }
            }
        };

        /// An element of a ring, containing:
        ///
        ///   - an optional link to the next node in the ring (`next`);
        ///   - an optional link to the head node of another ring (a subring) (`next_below`), and
        ///   - data of a compile time-known type (`data`)
        ///
        /// For any data node `d`, always assume that:
        ///
        ///   - if the expression `d.next == .head` is equal to `true`, then `d.next` is equal to a
        ///     pointer to the head node defining the ring of which `d` is an element
        ///
        /// For any pair of distinct data nodes `d1` and `d2` in a multiring, always assume that the
        /// following expressions are equal to `true`:
        ///
        ///     `d1.next.? != d2.next.?`
        ///     `d1.next_below.? != d2.next_below.?`
        ///
        pub const DataNode = struct {
            next: ?Node = null,
            next_below: ?*HeadNode = null,
            data: T,

            pub const Data = T;

            /// Return the number of data nodes after this data node in this ring
            ///
            pub fn countAfter(this: *DataNode) usize {
                var result: usize = 0;
                var it = this;
                while (it.next) |n| {
                    switch (n) {
                        .head => break,
                        .data => |d| {
                            result += 1;
                            it = d;
                        },
                    }
                }
                return result;
            }

            /// Return the number of data nodes after this data node in this multiring
            ///
            pub fn countAfterZ(this: *DataNode) usize {
                var result: usize = 0;
                var it = this;
                while (it.stepZ()) |d| : (it = d) {
                    result += 1;
                }
                return result;
            }

            /// Return the last data node in this ring
            ///
            pub fn findLast(this: *DataNode) *DataNode {
                var it = this;
                while (it.next) |n| {
                    switch (n) {
                        .head => break,
                        .data => |d| it = d,
                    }
                }
                return it;
            }

            /// Return the last data node in this multiring
            ///
            pub fn findLastZ(this: *DataNode) *DataNode {
                var it = this;
                while (it.stepZ()) |d| : (it = d) {}
                return it;
            }

            /// Return the head node of this ring
            ///
            /// If this ring is open, then return null
            ///
            pub fn findHead(this: *DataNode) ?*HeadNode {
                var it = this;
                while (it.next) |n| {
                    switch (n) {
                        .head => |h| return h,
                        .data => |d| it = d,
                    }
                }
                return null;
            }

            /// Return the next head node in this multiring after this data node
            ///
            /// If this ring is open and neither this data node nor any of the remaining data nodes
            /// has a subring, then return null
            ///
            pub fn findHeadZ(this: *DataNode) ?*HeadNode {
                if (this.next_below) |h| {
                    return h;
                }
                var it = this;
                while (it.next) |n| {
                    switch (n) {
                        .head => |h| return h,
                        .data => |d| {
                            if (d.next_below) |h| {
                                return h;
                            }
                            it = d;
                        },
                    }
                }
                return null;
            }

            /// Return the root of this multiring
            ///
            /// If this ring or any superring of this ring is open, then return null
            ///
            pub fn findRoot(this: *DataNode) ?*HeadNode {
                return if (this.findHead()) |h| h.findRoot() else null;
            }

            /// Return the next data node in this ring
            ///
            /// If this data node is the last data node in this ring, then return null
            ///
            pub fn step(this: *DataNode) ?*DataNode {
                return if (this.next) |n| switch (n) {
                    .head => null,
                    .data => |d| d,
                } else null;
            }

            /// Return the first data node in the subring at this data node
            ///
            /// If there is no nonempty subring at this data node, then return null
            ///
            pub fn stepBelow(this: *DataNode) ?*DataNode {
                if (this.next_below) |h| {
                    if (h.next) |n| {
                        return n;
                    }
                }
                return null;
            }

            /// Return the next data node in this multiring
            ///
            /// If this data node is the last data node in an open ring or in this multiring, then
            /// return null
            ///
            pub fn stepZ(this: *DataNode) ?*DataNode {
                if (this.stepBelow()) |d| {
                    return d;
                }
                return if (this.next) |n| switch (n) {
                    .head => |h| h.stepAbove(),
                    .data => |d| d,
                } else null;
            }

            /// Return the next data node in this multiring before `head`
            ///
            /// If this data node is the last data node in an open ring or in this multiring, then
            /// return null
            ///
            pub fn stepUntilHeadZ(this: *DataNode, head: *HeadNode) ?*DataNode {
                if (this.stepBelow()) |d| {
                    return d;
                }
                return if (this.next) |n| switch (n) {
                    .head => |h| h.stepAboveUntilHead(head),
                    .data => |d| d,
                } else null;
            }

            /// Insert a data node immediately after this data node
            ///
            pub fn insertAfter(this: *DataNode, node: *DataNode) void {
                node.next = this.next;
                this.next = .{ .data = node };
                if (this.next_below) |h| {
                    h.next_above = .{ .data = node };
                }
            }

            /// Insert many data nodes immediately after this data node
            ///
            pub fn insertManyAfter(this: *DataNode, nodes: []DataNode) void {
                if (nodes.len > 0) {
                    var it = this;
                    for (nodes) |*n| {
                        it.insertAfter(n);
                        it = n;
                    }
                }
            }

            /// Remove and return the next data node in this ring
            ///
            /// If this data node is the last data node in this ring, then return null
            ///
            pub fn popNext(this: *DataNode) ?*DataNode {
                if (this.next) |n| {
                    switch (n) {
                        .head => {},
                        .data => |d| {
                            this.next = d.next;
                            if (this.next_below) |h| {
                                h.next_above = d.next;
                            }
                            d.next = null;
                            if (d.next_below) |h| {
                                h.next_above = null;
                            }
                            return d;
                        },
                    }
                }
                return null;
            }

            /// Remove a data node from this ring after this data node, returning true if the node
            /// was found and removed and false otherwise
            ///
            pub fn removeAfter(this: *DataNode, node: *DataNode) bool {
                var it = this;
                while (it.next) |n| {
                    switch (n) {
                        .head => break,
                        .data => |d| {
                            if (d == node) {
                                _ = it.popNext().?;
                                return true;
                            }
                            it = d;
                        },
                    }
                }
                return false;
            }

            /// Remove a data node from this multiring after this data node, returning true if the
            /// node was found and removed and false otherwise
            ///
            pub fn removeAfterZ(this: *DataNode, node: *DataNode) bool {
                if (this.next) |next| {
                    var it = switch (next) {
                        .head => |h| h.stepAbove(),
                        .data => |d| d,
                    };
                    while (it) |n| {
                        if (n == node) {
                            if (n.findHead()) |h| {
                                return h.remove(node);
                            }
                            return false;
                        }
                        if (n.next) |next_next| {
                            switch (next_next) {
                                .head => {},
                                .data => |d| {
                                    if (d == node) {
                                        _ = n.popNext().?;
                                        return true;
                                    }
                                },
                            }
                        }
                        if (n.next_below) |h| {
                            if (h.next) |d| {
                                if (d == node) {
                                    _ = h.popNext().?;
                                    return true;
                                }
                            }
                        }
                        it = n.stepZ();
                    }
                }
                return false;
            }

            /// Link a multiring to this data node
            ///
            pub fn attachMultiRing(this: *DataNode, head: *HeadNode) void {
                this.next_below = head;
                head.next_above = this.next;
            }

            /// Remove and return the multiring below this data node
            ///
            /// Return null if there is no such multiring
            ///
            pub fn detachMultiRing(node: *DataNode) ?*HeadNode {
                return if (node.next_below) |h| blk: {
                    node.next_below = null;
                    h.next_above = null;
                    break :blk h;
                } else null;
            }
        };

        /// The unique head node in this multiring
        ///
        /// Always assume that the expression `root.next_above == null` is equal to `true`
        ///
        root: ?*HeadNode = null,

        /// Determine whether this multiring is empty
        ///
        pub fn isEmpty(self: *Self) bool {
            return if (self.root) |r| r.isEmpty() else true;
        }

        /// Return the number of data nodes in this multiring
        ///
        pub fn len(self: *Self) usize {
            var result: usize = 0;
            if (self.root) |r| {
                if (r.next) |first| {
                    result += first.countAfterZ() + 1;
                }
            }
            return result;
        }

        /// Return the last data node in this multiring
        ///
        /// If this multiring is empty or rootless, then return null
        ///
        pub fn findLast(self: *Self) ?*DataNode {
            return if (self.root) |r| r.findLastBelow() else null;
        }

        /// Insert a data node immediately after the last data node in this multiring
        ///
        /// If this multiring is empty, then insert the data node immediately after the root
        ///
        /// If this multiring is rootless, then do nothing
        ///
        pub fn append(self: *Self, node: *DataNode) void {
            if (self.findLast()) |l| {
                l.insertAfter(node);
            } else if (self.root) |r| {
                r.insertAfter(node);
            }
        }

        /// Insert many data nodes immediately after the last data node in this multiring
        ///
        /// If this multiring is empty, then insert the data nodes immediately after the root
        ///
        /// If this multiring is rootless, then do nothing
        ///
        pub fn extend(self: *Self, nodes: []DataNode) void {
            if (self.root) |r| {
                if (r.findLastBelow()) |l| {
                    l.insertManyAfter(nodes);
                } else {
                    r.insertManyAfter(nodes);
                }
            }
        }

        /// Remove a data node from this multiring, returning true if the node was found and
        /// removed and false otherwise
        ///
        pub fn remove(self: *Self, node: *DataNode) bool {
            return if (self.root) |r| r.removeBelow(node) else false;
        }

        /// Remove all data nodes from this multiring
        ///
        pub fn clear(self: *Self) void {
            if (self.root) |r| {
                r.clear();
            }
        }
    };
}
