// SPDX-FileCopyrightText: Copyright 2022-2024 OK Ryoko
// SPDX-License-Identifier: MIT

/// Hierarchical, forwardly linked and circularly linked abstract data type
///
/// At all times, assume that:
///
///   - no node in a multiring points to itself
///   - every node in a multiring represents a unique location in memory
///   - there are no more than two nodes in a multiring pointing to any node in the multiring
///
pub fn MultiRing(comptime T: type) type {
    return struct {
        const Self = @This();

        /// A node is either a head node or data node
        ///
        pub const NodeTag = enum {
            head,
            data,
        };

        /// Node is a pointer to either a head node or data node
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

            /// Return the last data node in this ring; if this is a head node and this ring is
            /// empty, then return null
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
            pub fn findRoot(self: Node) ?*HeadNode {
                return switch (self) {
                    inline else => |s| s.findRoot(),
                };
            }

            /// Return the next data node in this ring; if this ring is empty or this is the last
            /// data node in this ring, then return null
            ///
            pub fn step(self: Node) ?*DataNode {
                return switch (self) {
                    inline else => |s| s.step(),
                };
            }

            /// Return the next data node in this multiring; return null if this is...
            ///
            ///   - ... the root of an empty multiring
            ///   - ... the last data node in a multiring
            ///   - ... any head node after the last data node in a multiring
            ///
            pub fn stepZ(self: Node) ?*DataNode {
                return switch (self) {
                    inline else => |s| s.stepZ(),
                };
            }

            /// Insert a data node immediately after this node, closing this ring if it is empty;
            /// assume that `node` is not already in this multiring
            ///
            pub fn insertAfter(self: Node, node: *DataNode) void {
                switch (self) {
                    inline else => |s| s.insertAfter(node),
                }
            }

            /// Insert many data nodes immediately after this node, closing this ring if it is
            /// empty; assume that none of `nodes` is already in this multiring
            ///
            pub fn insertManyAfter(self: Node, nodes: []DataNode) void {
                switch (self) {
                    inline else => |s| s.insertManyAfter(nodes),
                }
            }

            /// Remove and return the next data node in this ring; if this ring is empty or this is
            /// the last data node in this ring, then return null
            ///
            pub fn popNext(self: Node) ?*DataNode {
                return switch (self) {
                    inline else => |s| s.popNext(),
                };
            }
        };

        /// A head node is the first node of a ring and contains:
        ///
        ///   - an optional link to the first data node in the ring (`next`)
        ///   - an optional link to the next node in this ring's superring (`next_above`)
        ///
        /// Given a head node `h`, we say that:
        ///
        ///   - the ring defined by h is empty when `h.next` is null
        ///   - h is the root of a multiring when `h.next_above` is null
        ///
        pub const HeadNode = struct {
            next: ?*DataNode = null,
            next_above: ?Node = null,

            /// Determine whether this head node is the root of a multiring
            ///
            pub fn isRoot(this: *HeadNode) bool {
                return this.next_above == null;
            }

            /// Determine whether this ring is empty
            ///
            pub fn isEmpty(this: *HeadNode) bool {
                return this.next == null;
            }

            /// If this ring is empty, then return null; otherwise determine whether this ring
            /// comprises a null-terminated sequence of data nodes
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

            /// If this ring is empty, then return null; otherwise return the last data node in
            /// this ring
            ///
            pub fn findLast(this: *HeadNode) ?*DataNode {
                return if (this.next) |first| first.findLast() else null;
            }

            /// Return the last data node in this multiring after this ring if there is one and
            /// otherwise null
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

            /// If this ring is empty, then return null; otherwise return the last data node in the
            /// multiring rooted at this head node
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

            /// If this head node is the root of a multiring, then return null; otherwise return
            /// the first head node above this head node
            ///
            pub fn findHeadAbove(this: *HeadNode) ?*HeadNode {
                return if (this.next_above) |n| switch (n) {
                    .head => |h| h,
                    .data => |d| d.findHead(),
                } else null;
            }

            /// Return the next head node in this multiring after this node if it can be found and
            /// null otherwise
            pub fn findHeadZ(this: *HeadNode) ?*HeadNode {
                return if (this.next) |first| blk: {
                    break :blk first.findHeadZ();
                } else if (this.findHeadAbove()) |h| blk: {
                    break :blk h;
                } else this;
            }

            /// Return the root of this multiring if it can be found and null otherwise
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

            /// If this ring is empty, then return null; otherwise return the first data node in
            /// this ring
            ///
            pub fn step(this: *HeadNode) ?*DataNode {
                return if (this.next) |first| first else null;
            }

            /// If this ring is empty or this head node is the root of a multiring, then return
            /// null; otherwise return either the first next data node in a superring of this ring
            /// if it exists or null
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

            /// Return null if this is `head` or the root of a multiring; otherwise return either
            /// the next data node in a superring of this ring before `head` or null if said data
            /// node does not exist
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

            /// If this head node is the root of an empty multiring, then return null; otherwise
            /// return either the first data node in this ring if this ring is non-empty, or the
            /// next data node in a superring of this ring if there are data nodes still left in
            /// the sequence, or null
            ///
            pub fn stepZ(this: *HeadNode) ?*DataNode {
                return if (this.next) |first| first else this.stepAbove();
            }

            /// Unlink the last data node in this ring from this head node
            ///
            pub fn open(this: *HeadNode) void {
                if (this.next) |first| {
                    const last = first.findLast();
                    last.next = null;
                    if (last.next_below) |h| {
                        h.next_above = null;
                    }
                }
            }

            /// Link the last data node in this ring to this head node
            ///
            pub fn close(this: *HeadNode) void {
                if (this.next) |first| {
                    const last = first.findLast();
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

            /// Insert a data node immediately after this head node, closing this ring if it is
            /// empty; assume that `node` is not already in this multiring
            ///
            pub fn insertAfter(this: *HeadNode, node: *DataNode) void {
                node.next = if (this.next) |first| .{ .data = first } else .{ .head = this };
                this.next = node;
            }

            /// Insert many data nodes immediately after this head node, closing this ring if it is
            /// empty; assume that none of `nodes` is already in this multiring
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

            /// If this ring is empty, then append a data node to this head node and close this
            /// ring; otherwise insert a data node immediately after this ring's last data node;
            /// assume that `node` is not already in this multiring
            ///
            pub fn append(this: *HeadNode, node: *DataNode) void {
                if (this.next) |first| {
                    const last = first.findLast();
                    last.insertAfter(node);
                } else {
                    this.insertAfter(node);
                }
            }

            /// If this ring is empty, then append many data nodes to this head node and close this
            /// ring; otherwise insert many data nodes immediately after this ring's last data node;
            /// assume that none of `nodes` is already in this multiring
            ///
            pub fn extend(this: *HeadNode, nodes: []DataNode) void {
                if (this.next) |first| {
                    const last = first.findLast();
                    last.insertManyAfter(nodes);
                } else {
                    this.insertManyAfter(nodes);
                }
            }

            /// Remove and return the first data node in this ring or null if this ring is empty
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

        /// A data node is an element of a ring and contains:
        ///
        ///   - an optional link to the next node in the ring (`next`)
        ///   - an optional link to the head node of another ring (a subring) (`next_below`)
        ///   - data of a compile time-known type (`data`)
        ///
        /// At all times, assume that:
        ///
        ///   - if the next node in this ring is a head node, then that head
        ///     node is equal to the head node immediately upstream of this data node
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

            /// If this ring is open, then return null; otherwise return the head node of this
            /// ring
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

            /// Return the next head node in this multiring after this data node if it can be found
            /// and null otherwise
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

            /// Return the root of this multiring if it can be found and null otherwise
            ///
            pub fn findRoot(this: *DataNode) ?*HeadNode {
                return if (this.findHead()) |h| h.findRoot() else null;
            }

            /// If this is the last data node in this ring, then return null; otherwise return the
            /// next data node in this ring
            ///
            pub fn step(this: *DataNode) ?*DataNode {
                return if (this.next) |n| switch (n) {
                    .head => null,
                    .data => |d| d,
                } else null;
            }

            /// If there is no non-empty subring at this data node, then return null; otherwise
            /// return the first data node in the subring
            ///
            pub fn stepBelow(this: *DataNode) ?*DataNode {
                if (this.next_below) |h| {
                    if (h.next) |n| {
                        return n;
                    }
                }
                return null;
            }

            /// If this is the last data node in an open ring or the last data node in this
            /// multiring, then return null; otherwise return the next data node in this multiring
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

            /// If this is the last data node in an open ring or the last data node in this
            /// multiring before `head`, then return null; otherwise return the next data node in
            /// this multiring
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

            /// Insert a data node immediately after this data node; assume that `node` is not
            /// already in this multiring
            ///
            pub fn insertAfter(this: *DataNode, node: *DataNode) void {
                node.next = this.next;
                this.next = .{ .data = node };
                if (this.next_below) |h| {
                    h.next_above = .{ .data = node };
                }
            }

            /// Insert many data nodes imediately after this data node; assume that none of `nodes`
            /// is already in this multiring
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

            /// If this is the last data node in this ring, then return null; otherwise remove and
            /// return the next data node in this ring
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

            /// Link a multiring to this data node; assume that:
            ///
            ///   - there is not already a multiring attached to `this`, and
            ///   - `head` is not already in this multiring
            ///
            pub fn attachMultiRing(this: *DataNode, head: *HeadNode) void {
                this.next_below = head;
                head.next_above = this.next;
            }

            /// Remove and return the multiring linked to this data node or null if there is no
            /// such multiring
            ///
            pub fn detachMultiRing(node: *DataNode) ?*HeadNode {
                return if (node.next_below) |h| blk: {
                    node.next_below = null;
                    h.next_above = null;
                    break :blk h;
                } else null;
            }
        };

        /// At all times, assume that `root` is the unique head node in this multiring with
        /// `root.next_above` equal to null
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

        /// If this multiring is empty or rootless, then return null; otherwise return the last
        /// data node in this multiring
        ///
        pub fn findLast(self: *Self) ?*DataNode {
            return if (self.root) |r| r.findLastBelow() else null;
        }

        /// If this multiring is rootless, then do nothing; otherwise insert a data node
        /// immediately after either the root node, if this multiring is empty, or the last data
        /// node in this multiring; assume that `node` is not already in this multiring
        ///
        pub fn append(self: *Self, node: *DataNode) void {
            if (self.findLast()) |l| {
                l.insertAfter(node);
            } else if (self.root) |r| {
                r.insertAfter(node);
            }
        }

        /// If no data nodes are passed or this multiring is rootless, then do nothing; otherwise
        /// insert many data nodes immediately after either the root node, if this multiring is
        /// empty, or the last data node in this multiring; assume that none of `nodes` is already
        /// in this multiring
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
