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
                    inline else => |s| s.insertAfter(new_node),
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
                                .gate => |g| gate_it = g,
                                .data => |d| return d,
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
                    .gate => return null,
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
                                        .gate => |g| gate_it.* = g,
                                        .data => |d| return d,
                                    }
                                } else {
                                    return gate_it.*.next.?;
                                }
                            }
                        },
                        .data => |next_node| return next_node,
                    }
                }
            }

            pub fn stepLocal(node: *DataNode) *DataNode {
                return switch (node.next.?) {
                    .gate => |next_node| next_node.next.?,
                    .data => |next_node| next_node,
                };
            }

            pub fn findLastLocal(node: *DataNode) *DataNode {
                var it = node;
                while (true) {
                    switch (it.next.?) {
                        .gate => return it,
                        .data => it = it.stepLocal(),
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
                    .gate => ring.root.?.next = null,
                    .data => |next_node| ring.root.?.next = next_node,
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
            var it: ?*DataNode = null;
            if (ring.root) |root| {
                it = root.findLastLocal();
                while ((it != null) and (it.?.child != null)) {
                    it = it.?.child.?.findLastLocal();
                }
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
