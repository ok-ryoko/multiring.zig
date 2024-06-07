// Copyright 2023 OK Ryoko
// SPDX-License-Identifier: MIT

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const AutoHashMapUnmanaged = std.AutoHashMapUnmanaged;
const math = std.math;

const MultiRing = @import("multiring").MultiRing;

const MultiRingError = error{
    NoMoreRoom,
    NoSuchNode,
    OverwriteAttempt,
    RingIsOpen,
};

/// Minimal example of an append-only, ring-level and data-centric interface to
/// the `MultiRing` type with automatic memory management.
///
/// Operations that would produce undefined behavior in the underlying
/// multiring return a `MultiRingError` instead.
///
/// All rings are kept closed and there are no free rings.
///
pub fn AutoMultiRing(comptime T: type) type {
    return struct {
        const Self = @This();
        const M = MultiRing(T);
        const Nodes = AutoHashMapUnmanaged(Node, M.Node);
        const Rings = AutoHashMapUnmanaged(HeadNode, ArrayListUnmanaged(DataNode));
        const Id = u32;

        pub const Node = union(M.NodeTag) {
            head: HeadNode,
            data: DataNode,
        };
        pub const HeadNode = Id;
        pub const DataNode = Id;

        comptime root: Id = 0,

        inner: M = undefined,
        key: Id = 0,

        // Storage for all nodes. The active tag in each key must be equal to
        // the active tag in the corresponding value.
        //
        nodes: Nodes = undefined,

        // Map from head nodes to data nodes. Every key must have a
        // corresponding key in `nodes` with tag `.head`.
        //
        rings: Rings = undefined,

        alloc: Allocator = undefined,

        /// Initialize an AutoMultiRing containing an empty root ring.
        ///
        pub fn init(allocator: Allocator) !Self {
            const root_id = 0;

            const root_ptr = try allocator.create(M.HeadNode);
            errdefer allocator.destroy(root_ptr);
            root_ptr.* = M.HeadNode{};

            var nodes = Nodes{};
            errdefer nodes.deinit(allocator);
            try nodes.putNoClobber(allocator, Node{ .head = root_id }, M.Node{ .head = root_ptr });

            var rings = Rings{};
            errdefer rings.deinit(allocator);
            var data_ids = ArrayListUnmanaged(DataNode){};
            errdefer data_ids.deinit(allocator);
            try rings.putNoClobber(allocator, root_id, data_ids);

            return .{
                .root = root_id,
                .inner = M{ .root = root_ptr },
                .key = 1,
                .nodes = nodes,
                .rings = rings,
                .alloc = allocator,
            };
        }

        /// Release all memory allocated for this multiring.
        ///
        pub fn deinit(self: *Self) void {
            {
                var it = self.rings.valueIterator();
                while (it.next()) |data_ids| {
                    data_ids.deinit(self.alloc);
                }
            }
            self.rings.deinit(self.alloc);

            {
                var it = self.nodes.valueIterator();
                while (it.next()) |node| {
                    switch (node.*) {
                        inline else => |n| self.alloc.destroy(n),
                    }
                }
            }
            self.nodes.deinit(self.alloc);

            self.* = undefined;
        }

        /// Determine whether this multiring is empty.
        ///
        pub fn isEmpty(self: *Self) bool {
            return self.inner.isEmpty();
        }

        /// Determine whether a ring is empty, asserting that the ring is in
        /// this multiring.
        ///
        pub fn isRingEmpty(self: *Self, head_id: HeadNode) !bool {
            if (!self.rings.contains(head_id)) {
                return MultiRingError.NoSuchNode;
            }
            return self.rings.getPtr(head_id).?.items.len == 0;
        }

        /// Return the number of data nodes in this multiring.
        ///
        pub fn len(self: *Self) usize {
            var it = self.rings.valueIterator();
            var count: usize = 0;
            while (it.next()) |data| {
                count += data.items.len;
            }
            return count;
        }

        /// Return the number of data nodes in a ring, asserting that the ring
        /// is in this multiring.
        ///
        pub fn lenRing(self: *Self, head_id: HeadNode) !usize {
            if (!self.rings.contains(head_id)) {
                return MultiRingError.NoSuchNode;
            }
            return self.rings.getPtr(head_id).?.items.len;
        }

        /// Create a ring from zero or more data items and link it to the data
        /// node represented by `data_id`, asserting that:
        ///
        /// - there is sufficient storage in this multiring, and
        /// - there isn't already a ring linked to the data node.
        ///
        fn createRing(self: *Self, data_id: DataNode, items: ?[]const T) !HeadNode {
            if (self.key + 1 >= math.maxInt(Id)) {
                return MultiRingError.NoMoreRoom;
            }

            if (items != null and self.key + items.?.len + 1 >= math.maxInt(Id)) {
                return MultiRingError.NoMoreRoom;
            }

            const head_ptr = try self.alloc.create(M.HeadNode);
            errdefer self.alloc.destroy(head_ptr);
            head_ptr.* = M.HeadNode{};

            const head_id = try self.incrementGetKey();
            try self.nodes.putNoClobber(self.alloc, Node{ .head = head_id }, M.Node{ .head = head_ptr });
            errdefer {
                _ = self.nodes.remove(Node{ .head = head_id });
            }

            try self.attachRing(head_id, data_id);

            var data_ids = ArrayListUnmanaged(DataNode){};
            errdefer data_ids.deinit(self.alloc);
            try self.rings.putNoClobber(self.alloc, head_id, data_ids);

            if (items) |data| {
                try self.extendRing(head_id, data);
            }

            return head_id;
        }

        /// Link (the head node of) a ring to a data node in this multiring,
        /// asserting that:
        ///
        /// - `head_id` represents a free ring and
        /// - `data_id` represents a data node that is in this multiring and to
        ///   which no ring is already linked.
        ///
        fn attachRing(self: *Self, head_id: HeadNode, data_id: DataNode) !void {
            const head_node = Node{ .head = head_id };
            if (!self.nodes.contains(head_node)) {
                return MultiRingError.NoSuchNode;
            }
            const head_ptr = switch (self.nodes.get(head_node).?) {
                .head => |h| h,
                .data => unreachable,
            };
            if (head_ptr.next_above) |_| {
                return MultiRingError.OverwriteAttempt;
            }

            const data_node = Node{ .data = data_id };
            if (!self.nodes.contains(data_node)) {
                return MultiRingError.NoSuchNode;
            }
            const data_ptr = switch (self.nodes.get(data_node).?) {
                .head => unreachable,
                .data => |d| d,
            };
            if (data_ptr.next_below) |_| {
                return MultiRingError.OverwriteAttempt;
            }

            data_ptr.attachMultiRing(head_ptr);
        }

        /// Extend a ring with one or more data items, asserting that:
        ///
        /// - the ring is in this multiring,
        /// - there is at least one data item to append to the ring, and
        /// - there is sufficient storage in this multiring.
        ///
        /// Assumes that `self.rings` is in sync with `self.nodes`. Invalidates
        /// all iterators into the ring.
        ///
        pub fn extendRing(self: *Self, head_id: HeadNode, items: []const T) !void {
            if (!self.nodes.contains(Node{ .head = head_id })) {
                return MultiRingError.NoSuchNode;
            }

            if (items.len == 0) {
                return;
            }

            if (self.key + items.len >= math.maxInt(Id)) {
                return MultiRingError.NoMoreRoom;
            }

            const data_ids = self.rings.getPtr(head_id).?;

            var last_node = switch (self.nodes.get(Node{ .head = head_id }).?) {
                .head => |h| M.Node{ .head = h },
                .data => unreachable,
            };

            if (data_ids.items.len > 0) {
                const last_data_id = data_ids.items[data_ids.items.len - 1];
                switch (self.nodes.get(Node{ .data = last_data_id }).?) {
                    .head => unreachable,
                    .data => |d| {
                        last_node = M.Node{ .data = d };
                    },
                }
            }

            for (items) |item| {
                const data_ptr = try self.alloc.create(M.DataNode);
                errdefer self.alloc.destroy(data_ptr);
                data_ptr.* = M.DataNode{ .data = item };

                const data_id = try self.incrementGetKey();
                try self.nodes.putNoClobber(self.alloc, Node{ .data = data_id }, M.Node{ .data = data_ptr });
                errdefer {
                    _ = self.nodes.remove(Node{ .data = data_id });
                }

                try data_ids.append(self.alloc, data_id);
                switch (last_node) {
                    inline else => |last_ptr| last_ptr.insertAfter(data_ptr),
                }
                last_node = M.Node{ .data = data_ptr };
            }
        }

        /// Return a copy of the data items in this multiring that satisfy the
        /// given predicate.
        ///
        /// The subring of any data node that doesn't satisfy the predicate is
        /// skipped.
        ///
        /// Assumes that the root node exists.
        ///
        /// Asserts that every ring is closed.
        ///
        pub fn filter(self: *Self, allocator: Allocator, predicate: *const fn (T) bool) ![]T {
            if (self.isEmpty()) {
                return &.{};
            }

            const root_ptr = switch (self.nodes.get(Node{ .head = self.root }).?) {
                .head => |r| r,
                .data => unreachable,
            };

            var result = ArrayListUnmanaged(T){};

            var it = root_ptr.step();
            while (it) |data_ptr| {
                if (data_ptr.next == null) {
                    return MultiRingError.RingIsOpen;
                }

                if (predicate(data_ptr.data)) {
                    try result.append(allocator, data_ptr.data);
                    it = data_ptr.stepZ();
                    continue;
                }

                switch (data_ptr.next.?) {
                    .head => |h| it = h.stepAbove(),
                    .data => it = data_ptr.step(),
                }
            }

            return result.toOwnedSlice(allocator);
        }

        /// Return the result of folding every data item in this multiring into
        /// an accumulator using the given function.
        ///
        /// Assumes that the root node exists.
        ///
        /// Asserts that every ring is closed.
        ///
        pub fn fold(self: *Self, accumulator: T, func: *const fn (T, T) T) !T {
            if (self.isEmpty()) {
                return accumulator;
            }

            const root_ptr = switch (self.nodes.get(Node{ .head = self.root }).?) {
                .head => |h| h,
                .data => unreachable,
            };

            var result = accumulator;

            var it = root_ptr.step();
            while (it) |data_ptr| {
                if (data_ptr.next == null) {
                    return MultiRingError.RingIsOpen;
                }
                result = func(result, data_ptr.data);
                it = data_ptr.stepZ();
            }

            return result;
        }

        /// Update this multiring in place by applying the given function to
        /// every data item.
        ///
        /// Assumes that the root node exists.
        ///
        /// Asserts that every ring is closed.
        ///
        pub fn map(self: *Self, func: *const fn (T) T) !void {
            if (self.isEmpty()) {
                return;
            }

            const root_ptr = switch (self.nodes.get(Node{ .head = self.root }).?) {
                .head => |h| h,
                .data => unreachable,
            };

            var it = root_ptr.step();
            while (it) |data_ptr| {
                if (data_ptr.next == null) {
                    return MultiRingError.RingIsOpen;
                }
                data_ptr.data = func(data_ptr.data);
                it = data_ptr.stepZ();
            }
        }

        /// Return a copy of the data item stored in the node represented by
        /// `data_id`, asserting that the node is in this multiring.
        ///
        pub fn getData(self: *Self, data_id: DataNode) !T {
            const data_node = Node{ .data = data_id };
            if (!self.nodes.contains(data_node)) {
                return MultiRingError.NoSuchNode;
            }
            return switch (self.nodes.get(data_node).?) {
                .head => unreachable,
                .data => |d| d.data,
            };
        }

        /// Return an iterator over the data nodes in a ring, asserting that
        /// the ring is in this multiring.
        ///
        pub fn iterateRing(self: *Self, head_id: HeadNode) !RingIterator {
            if (!self.rings.contains(head_id)) {
                return MultiRingError.NoSuchNode;
            }
            const data_ids = self.rings.getPtr(head_id).?;

            return if (data_ids.items.len > 0) .{
                .items = data_ids.items,
                .count = data_ids.items.len,
            } else .{
                .items = undefined,
                .count = 0,
            };
        }

        pub const RingIterator = struct {
            items: []DataNode,
            count: usize,

            pub fn next(self: *RingIterator) ?DataNode {
                if (self.count > 0) {
                    const node = self.items[self.items.len - self.count];
                    self.count -= 1;
                    return node;
                }
                return null;
            }
        };

        /// Increment the storage key, asserting that the operation will not
        /// result in integer overflow.
        ///
        fn incrementGetKey(self: *Self) !Id {
            if (self.key == math.maxInt(Id)) {
                return MultiRingError.NoMoreRoom;
            }
            self.key += 1;
            return self.key;
        }
    };
}

test "empty multiring" {
    const testing = std.testing;
    const a = testing.allocator;

    const M = AutoMultiRing(u8);
    var m = try M.init(a);
    defer m.deinit();

    try testing.expect(m.isEmpty());
    try testing.expect(try m.isRingEmpty(m.root));
    try testing.expectError(MultiRingError.NoSuchNode, m.isRingEmpty(1));

    try testing.expectEqual(@as(usize, 0), m.len());
    try testing.expectEqual(@as(usize, 0), try m.lenRing(m.root));
    try testing.expectError(MultiRingError.NoSuchNode, m.lenRing(1));

    var it = try m.iterateRing(m.root);
    try testing.expectEqual(@as(?M.DataNode, null), it.next());

    {
        const sum: u8 = 0;
        try testing.expectEqual(sum, try m.fold(sum, add));
    }

    {
        const empty = try m.filter(a, isEven);
        defer a.free(empty);
        try testing.expectEqual(@as(usize, 0), empty.len);
    }
}

test "runtime multiring construction, filter and map" {
    const testing = std.testing;
    const a = testing.allocator;

    var m = try AutoMultiRing(u8).init(a);
    defer m.deinit();

    const root_data = [_]u8{ 0, 1, 2, 3, 4 };
    try m.extendRing(m.root, &root_data);

    try testing.expect(!m.isEmpty());
    try testing.expect(!(try m.isRingEmpty(m.root)));

    try testing.expectEqual(@as(usize, 5), m.len());
    try testing.expectEqual(@as(usize, 5), try m.lenRing(m.root));

    {
        var ring_data = ArrayListUnmanaged(u8){};
        defer ring_data.deinit(a);

        var it = try m.iterateRing(m.root);
        while (it.next()) |data_id| {
            const d = try m.getData(data_id);

            for (root_data[0..d]) |i| {
                try ring_data.append(a, i);
            }

            const slice = try ring_data.toOwnedSlice(a);
            defer a.free(slice);

            const head_id = try m.createRing(data_id, slice);
            try testing.expectEqual(@as(usize, d), try m.lenRing(head_id));
        }
    }

    try testing.expectEqual(@as(usize, 15), m.len());

    {
        var it = try m.iterateRing(m.root);
        try testing.expectError(MultiRingError.OverwriteAttempt, m.createRing(it.next().?, null));
    }

    {
        const expected = [_]u8{ 0, 2, 0, 4, 0, 2 };
        const actual = try m.filter(a, isEven);
        defer a.free(actual);
        try testing.expectEqualSlices(u8, &expected, actual);
    }
    try testing.expectEqual(@as(usize, 15), m.len());

    {
        const sum = try m.fold(@as(u8, 0), add);
        try testing.expectEqual(@as(u8, 20), sum);
    }
    try testing.expectEqual(@as(usize, 15), m.len());

    try m.map(double);
    {
        var sum: u8 = 0;
        sum = try m.fold(sum, add);
        try testing.expectEqual(@as(u8, 40), sum);
    }
    try testing.expectEqual(@as(usize, 15), m.len());
}

fn isEven(n: u8) bool {
    return n % 2 == 0;
}

fn double(n: u8) u8 {
    return 2 * n;
}

fn add(accumulator: u8, item: u8) u8 {
    return accumulator + item;
}
