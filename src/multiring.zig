pub const MultiRingError = error{
    DataNodeAlreadyHasChild,
    GateNodeAlreadyHasParent,
    UnsafeLoopCreationAttempt,
};

/// Singly linked, cyclic and hierarchical abstract data type
pub fn MultiRing(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Node = union(enum) {
            gate: *GateNode,
            data: *DataNode,

            /// Insert a new data node after the current node
            pub fn insertAfter(self: Node, new_node: *DataNode) void {
                switch (self) {
                    inline else => |s| {
                        s.insertAfter(new_node);
                    },
                }
            }

            /// Remove and return the next data node from the current ring;
            /// return null when the next node is a gate node, i.e., the ring
            /// is empty
            pub fn popNext(self: Node) ?*DataNode {
                return switch (self) {
                    inline else => |s| s.popNext(),
                };
            }

            /// Step forward by one node, traversing only the data nodes of
            /// the multiring as if it were a cyclic linked list
            pub fn step(self: Node) ?*DataNode {
                return switch (self) {
                    inline else => |s| s.step(),
                };
            }

            /// Same as Node.step() but never leaves the current ring
            pub fn stepLocal(self: Node) ?*DataNode {
                return switch (self) {
                    inline else => |s| s.stepLocal(),
                };
            }

            /// Find the last data node in the current ring; return null if the
            /// ring is empty
            pub fn findLastLocal(self: Node) ?*DataNode {
                return switch (self) {
                    inline else => |s| s.findLastLocal(),
                };
            }
        };

        /// Sentinel node that acts as a waypoint into and out of a possibly
        /// empty ring
        pub const GateNode = struct {
            next: ?*DataNode = null,
            parent: ?*DataNode = null,

            pub fn insertAfter(node: *GateNode, new_node: *DataNode) void {
                if (node.next) |next_node| {
                    new_node.next = .{ .data = next_node };
                } else {
                    // The gate is the only node in the ring, so connect the
                    // new node back to the gate
                    //
                    new_node.next = .{ .gate = node };
                }
                node.next = new_node;
            }

            /// Insert a data node after the last data node in the current ring
            pub fn append(node: *GateNode, new_node: *DataNode) void {
                if (node.next) |next_node| {
                    const last = next_node.findLastLocal();
                    last.insertAfter(new_node);
                } else {
                    node.insertAfter(new_node);
                }
            }

            pub fn popNext(node: *GateNode) ?*DataNode {
                const next_node = node.next orelse return null;
                node.next = switch (next_node.next.?) {
                    .gate => null,
                    .data => |next_next_node| next_next_node,
                };
                return next_node;
            }

            pub fn step(node: *GateNode) ?*DataNode {
                if (node.next) |next_node| {
                    return next_node;
                } else if (node.parent != null) {
                    var gate_it = node;
                    while (true) {
                        if (gate_it.parent) |gate_parent| {
                            switch (gate_parent.next.?) {
                                .gate => |g| {
                                    gate_it = g;
                                },
                                .data => |d| {
                                    return d;
                                },
                            }
                        } else {
                            // We've reached the root node, so return the
                            // first data node
                            //
                            return gate_it.next.?;
                        }
                    }
                } else {
                    return null;
                }
            }

            pub fn stepLocal(node: *GateNode) ?*DataNode {
                return if (node.next) |next_node| next_node else null;
            }

            pub fn findLastLocal(node: *GateNode) ?*DataNode {
                if (node.next) |next_node| {
                    return next_node.findLastLocal();
                } else {
                    return null;
                }
            }
        };

        /// Node that holds data and can be an attachment point for a subring
        pub const DataNode = struct {
            next: ?Node = null,
            child: ?*GateNode = null,
            data: T,

            pub const Data = T;

            pub fn insertAfter(node: *DataNode, new_node: *DataNode) void {
                new_node.next = node.next;
                node.next = .{ .data = new_node };
            }

            pub fn popNext(node: *DataNode) ?*DataNode {
                switch (node.next.?) {
                    .gate => {
                        return null;
                    },
                    .data => |next_node| {
                        node.next = next_node.next;
                        return next_node;
                    },
                }
            }

            pub fn step(node: *DataNode) *DataNode {
                // If this node has a child gate node of a ring containing at
                // least one data node, then go to the first data node in the
                // subring; otherwise, go to the next data node
                //
                const child = node.child;
                if (child != null and child.?.next != null) {
                    return child.?.next.?;
                } else {
                    switch (node.next.?) {
                        .gate => |*gate_it| {
                            while (true) {
                                if (gate_it.*.parent) |parent| {
                                    switch (parent.next.?) {
                                        .gate => |g| {
                                            gate_it.* = g;
                                        },
                                        .data => |d| {
                                            return d;
                                        },
                                    }
                                } else {
                                    return gate_it.*.next.?;
                                }
                            }
                        },
                        .data => |next_node| {
                            return next_node;
                        },
                    }
                }
            }

            pub fn stepLocal(node: *DataNode) *DataNode {
                switch (node.next.?) {
                    .gate => |next_node| {
                        return next_node.next.?;
                    },
                    .data => |next_node| {
                        return next_node;
                    },
                }
            }

            pub fn findLastLocal(node: *DataNode) *DataNode {
                var it = node;
                while (true) {
                    switch (it.next.?) {
                        .gate => {
                            return it;
                        },
                        .data => {
                            it = it.stepLocal();
                        },
                    }
                }
            }

            /// Remove and return the subring attached to this data node;
            /// return null when there's no subring
            pub fn popSubring(node: *DataNode) ?*GateNode {
                return if (node.child) |gate_node| blk: {
                    node.child = null;
                    gate_node.parent = null;
                    break :blk gate_node;
                } else null;
            }
        };

        root: ?*GateNode = null,

        /// Append a data node to the end of the multiring
        pub fn append(ring: *Self, node: *DataNode) void {
            const last = ring.findLast();
            if (last != null) {
                last.?.insertAfter(node);
            } else {
                ring.root.?.insertAfter(node);
            }
        }

        /// Remove a data node from the ring; return true if the node was
        /// found and removed and otherwise false
        pub fn remove(ring: *Self, node: *DataNode) bool {
            if (ring.root.?.next.? == node) {
                switch (node.next.?) {
                    .gate => {
                        ring.root.?.next = null;
                    },
                    .data => |next_node| {
                        ring.root.?.next = next_node;
                    },
                }
                return true;
            }

            var it = ring.root.?.next.?;
            while (true) {
                switch (it.next.?) {
                    .gate => |next_node| {
                        if (next_node == ring.root.?) {
                            return false;
                        }
                    },
                    .data => |next_node| {
                        if (next_node == node) {
                            it.next = node.next;
                            next_node.next = null;
                            return true;
                        }
                    },
                }
                it = it.step();
            }
        }

        /// Find the last data node in the multiring; return null if the
        /// multiring is empty
        pub fn findLast(ring: *Self) ?*DataNode {
            var it = ring.root.?.findLastLocal();
            while ((it != null) and (it.?.child != null)) {
                it = it.?.child.?.findLastLocal();
            }
            return it;
        }

        /// Link a gate node with no parent to a data node with no child;
        /// the gate node must not be the root node
        pub fn attachSubring(ring: *Self, node: *DataNode, gate: *GateNode) !void {
            if (node.child != null) {
                return MultiRingError.DataNodeAlreadyHasChild;
            } else if (gate.parent != null) {
                return MultiRingError.GateNodeAlreadyHasParent;
            } else if (gate == ring.root) {
                return MultiRingError.UnsafeLoopCreationAttempt;
            }

            node.child = gate;
            gate.parent = node;
        }
    };
}

test "fundamental operations" {
    const std = @import("std");
    const testing = std.testing;

    const M = MultiRing(u8);
    var g0 = M.GateNode{};
    var multiring = M{ .root = &g0 };

    var r0_data_nodes = [_]M.DataNode{
        .{ .data = 1 },
        .{ .data = 7 },
        .{ .data = 5 },
        .{ .data = 8 },
    };
    g0.insertAfter(&r0_data_nodes[0]);
    try testing.expectEqual(&r0_data_nodes[0], g0.next.?);
    try testing.expectEqual(M.Node{ .gate = &g0 }, r0_data_nodes[0].next.?);

    r0_data_nodes[0].insertAfter(&r0_data_nodes[1]);
    try testing.expectEqual(M.Node{ .data = &r0_data_nodes[1] }, r0_data_nodes[0].next.?);
    try testing.expectEqual(M.Node{ .gate = &g0 }, r0_data_nodes[1].next.?);

    r0_data_nodes[1].insertAfter(&r0_data_nodes[2]);
    r0_data_nodes[2].insertAfter(&r0_data_nodes[3]);

    var g1 = M.GateNode{};
    var r1_data_nodes = [_]M.DataNode{
        .{ .data = 9 },
        .{ .data = 0 },
        .{ .data = 9 },
        .{ .data = 1 },
        .{ .data = 2 },
        .{ .data = 2 },
    };
    g1.insertAfter(&r1_data_nodes[0]);

    comptime var i = 0;
    inline while (i < 5) : (i += 1) {
        r1_data_nodes[i].insertAfter(&r1_data_nodes[i + 1]);
    }

    // attach subring r1 to ring r0
    try multiring.attachSubring(&r0_data_nodes[0], &g1);
    try testing.expectEqual(&g1, r0_data_nodes[0].child.?);
    try testing.expectEqual(&r0_data_nodes[0], g1.parent.?);

    var g2 = M.GateNode{};
    var r2_data_nodes = [_]M.DataNode{
        .{ .data = 9 },
        .{ .data = 8 },
        .{ .data = 2 },
        .{ .data = 2 },
        .{ .data = 7 },
    };
    g2.insertAfter(&r2_data_nodes[0]);

    comptime var j = 0;
    inline while (j < 4) : (j += 1) {
        r2_data_nodes[j].insertAfter(&r2_data_nodes[j + 1]);
    }

    try multiring.attachSubring(&r0_data_nodes[2], &g2);

    var g3 = M.GateNode{};
    var r3_data_nodes = [_]M.DataNode{
        .{ .data = 6 },
        .{ .data = 0 },
        .{ .data = 4 },
    };
    g3.insertAfter(&r3_data_nodes[0]);
    r3_data_nodes[0].insertAfter(&r3_data_nodes[1]);
    r3_data_nodes[1].insertAfter(&r3_data_nodes[2]);

    try multiring.attachSubring(&r2_data_nodes[1], &g3);

    var g4 = M.GateNode{};
    try multiring.attachSubring(&r2_data_nodes[3], &g4);

    // step forward to the first data node
    try testing.expectEqual(&r0_data_nodes[0], g0.step().?);

    // descend into subring r1
    try testing.expectEqual(&r1_data_nodes[0], r0_data_nodes[0].step());

    // skip over an empty subring (r4)
    try testing.expectEqual(&r2_data_nodes[4], r2_data_nodes[3].step());

    // loop back from the last data node to the first data node
    try testing.expectEqual(&r0_data_nodes[0], r0_data_nodes[3].step());

    // step forward from the 1st data node to the 2nd data node in r1
    try testing.expectEqual(&r1_data_nodes[1], r1_data_nodes[0].stepLocal());

    // loop back from the last data node to the first data node in r1
    try testing.expectEqual(&r1_data_nodes[0], r1_data_nodes[5].stepLocal());

    // find the last data node in the multiring
    try testing.expectEqual(&r0_data_nodes[3], multiring.findLast().?);

    // find the last data node in r1
    try testing.expectEqual(&r1_data_nodes[5], g1.findLastLocal().?);
    try testing.expectEqual(&r1_data_nodes[5], r1_data_nodes[0].findLastLocal());

    // find the last data node in r4 (there isn't one)
    try testing.expectEqual(@as(?*M.DataNode, null), g4.findLastLocal());

    // remove a data node in the multiring (in r3)
    try testing.expect(multiring.remove(&r3_data_nodes[2]));
    try testing.expectEqual(M.Node{ .gate = &g3 }, r3_data_nodes[1].next.?);
    try testing.expectEqual(@as(?M.Node, null), r3_data_nodes[2].next);

    // try to remove a data node that isn't in the multiring
    var d = M.DataNode{ .data = 0 };
    try testing.expect(!multiring.remove(&d));
    try testing.expectEqual(@as(?M.Node, null), d.next);

    // pop a data node from a data node in r3
    try testing.expectEqual(&r3_data_nodes[1], r3_data_nodes[0].popNext().?);
    try testing.expectEqual(M.Node{ .gate = &g3 }, r3_data_nodes[0].next.?);

    // pop a data node from the r3 gate node
    try testing.expectEqual(&r3_data_nodes[0], g3.popNext().?);
    try testing.expectEqual(@as(?*M.DataNode, null), g3.next);

    // try to pop the next data node from g3 (there isn't one)
    try testing.expectEqual(@as(?*M.DataNode, null), g3.popNext());
    try testing.expectEqual(@as(?*M.DataNode, null), g3.next);

    // pop r3 (now empty) from r2
    try testing.expectEqual(&g3, r2_data_nodes[1].popSubring().?);
    try testing.expectEqual(@as(?*M.GateNode, null), r2_data_nodes[1].child);
    try testing.expectEqual(@as(?*M.DataNode, null), g3.parent);
    try testing.expectEqual(&r2_data_nodes[2], r2_data_nodes[1].step());

    // append a new node to the end of the multiring
    var r = M.DataNode{ .data = 0 };
    multiring.append(&r);
    try testing.expectEqual(&r, multiring.findLast().?);

    // append a new node to the end of r1
    var s = M.DataNode{ .data = 1 };
    g1.append(&s);
    try testing.expectEqual(&s, g1.findLastLocal().?);

    // try to attach subrings inappropriately
    try testing.expectError(
        MultiRingError.DataNodeAlreadyHasChild,
        multiring.attachSubring(&r0_data_nodes[0], &g3),
    );
    try testing.expectError(
        MultiRingError.GateNodeAlreadyHasParent,
        multiring.attachSubring(&r1_data_nodes[0], &g2),
    );
    try testing.expectError(
        MultiRingError.UnsafeLoopCreationAttempt,
        multiring.attachSubring(&r1_data_nodes[0], &g0),
    );
}

test "ring skips" {
    const std = @import("std");
    const testing = std.testing;

    const M = MultiRing(u8);

    var g0 = M.GateNode{};
    var d0: M.DataNode = .{ .data = 0 };
    g0.insertAfter(&d0);

    var g1 = M.GateNode{};
    var d1: M.DataNode = .{ .data = 1 };
    g1.insertAfter(&d1);

    var g2 = M.GateNode{};
    var d2: M.DataNode = .{ .data = 2 };
    g2.insertAfter(&d2);

    var multiring = M{ .root = &g0 };
    try multiring.attachSubring(&d0, &g1);
    try multiring.attachSubring(&d1, &g2);

    try testing.expectEqual(&d0, d2.step());
    try testing.expectEqual(&d2, multiring.findLast().?);
}
