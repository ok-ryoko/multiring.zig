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
                return if (node.next) |next_node| blk: {
                    node.next = switch (next_node.next.?) {
                        .gate => null,
                        .data => |next_next_node| next_next_node,
                    };
                    break :blk next_node;
                } else null;
            }

            pub fn step(node: *GateNode) ?*DataNode {
                var result: ?*DataNode = null;
                if (node.next) |next_node| {
                    result = next_node;
                } else if (node.parent != null) {
                    var gate_it = node;
                    while (true) {
                        if (gate_it.parent) |gate_parent| {
                            switch (gate_parent.next.?) {
                                .gate => |g| gate_it = g,
                                .data => |d| {
                                    result = d;
                                    break;
                                },
                            }
                        } else {
                            // We've reached the root node, so return the
                            // first data node
                            //
                            result = gate_it.next.?;
                            break;
                        }
                    }
                }
                return result;
            }

            pub fn stepLocal(node: *GateNode) ?*DataNode {
                return if (node.next) |next_node| next_node else null;
            }

            pub fn findLastLocal(node: *GateNode) ?*DataNode {
                return if (node.next) |next_node| next_node.findLastLocal() else null;
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
                return switch (node.next.?) {
                    .gate => null,
                    .data => |next_node| blk: {
                        node.next = next_node.next;
                        break :blk next_node;
                    },
                };
            }

            pub fn step(node: *DataNode) *DataNode {
                // If this node has a child gate node of a ring containing at
                // least one data node, then go to the first data node in the
                // subring; otherwise, go to the next data node
                //
                var result: ?*DataNode = null;
                const child = node.child;
                if (child != null and child.?.next != null) {
                    result = child.?.next.?;
                } else {
                    switch (node.next.?) {
                        .gate => |*gate_it| {
                            while (true) {
                                if (gate_it.*.parent) |parent| {
                                    switch (parent.next.?) {
                                        .gate => |g| gate_it.* = g,
                                        .data => |d| {
                                            result = d;
                                            break;
                                        },
                                    }
                                } else {
                                    result = gate_it.*.next.?;
                                    break;
                                }
                            }
                        },
                        .data => |next_node| result = next_node,
                    }
                }
                return result.?;
            }

            pub fn stepLocal(node: *DataNode) *DataNode {
                return switch (node.next.?) {
                    .gate => |next_node| next_node.next.?,
                    .data => |next_node| next_node,
                };
            }

            pub fn findLastLocal(node: *DataNode) *DataNode {
                var result: ?*DataNode = null;
                var it = node;
                while (true) {
                    switch (it.next.?) {
                        .gate => {
                            result = it;
                            break;
                        },
                        .data => it = it.stepLocal(),
                    }
                }
                return result.?;
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
            var result = false;
            if ((ring.root != null) and (ring.root.?.next != null)) {
                const root = ring.root.?;
                const root_next = root.next.?;
                if (root_next == node) {
                    root.next = switch (node.next.?) {
                        .gate => null,
                        .data => |next_node| next_node,
                    };
                } else {
                    var it = root_next;
                    while ((it.step() != node)) {
                        if (it.step() == root_next) {
                            // We have traversed the structure without
                            // finding the given node
                            //
                            return false;
                        }
                        it = it.step();
                    }

                    if (it.child) |child| {
                        if (child.next == it.step()) {
                            child.next = switch (node.next.?) {
                                .gate => null,
                                .data => |next_node_| next_node_,
                            };
                        }
                    } else {
                        switch (it.next.?) {
                            .gate => |*gate_it| {
                                while (true) {
                                    switch (gate_it.*.parent.?.next.?) {
                                        .gate => |g| gate_it.* = g,
                                        .data => {
                                            gate_it.*.parent.?.next = node.next;
                                            break;
                                        },
                                    }
                                }
                            },
                            .data => it.next = node.next,
                        }
                    }
                }
                node.next = null;
                result = true;
            }
            return result;
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
