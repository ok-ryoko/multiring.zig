const std = @import("std");
const testing = std.testing;

const multiring = @import("multiring.zig");
const MultiRing = multiring.MultiRing;
const MultiRingError = multiring.MultiRingError;

test "empty multirings" {
    const M = MultiRing(u8);

    var m0 = M{ .root = null };
    try testing.expectEqual(@as(?*M.DataNode, null), m0.findLast());

    var g0 = M.GateNode{};
    var m1 = M{ .root = &g0 };
    try testing.expectEqual(@as(?*M.DataNode, null), m1.findLast());
    try testing.expectEqual(@as(?*M.DataNode, null), m1.root.?.step());
    try testing.expectEqual(@as(?*M.DataNode, null), m1.root.?.stepLocal());
    try testing.expectEqual(@as(?*M.DataNode, null), m1.root.?.popNext());
}

test "fundamental operations" {
    const M = MultiRing(u8);
    var g0 = M.GateNode{};
    var m0 = M{ .root = &g0 };

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
    try m0.attachSubring(&r0_data_nodes[0], &g1);
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

    try m0.attachSubring(&r0_data_nodes[2], &g2);

    var g3 = M.GateNode{};
    var r3_data_nodes = [_]M.DataNode{
        .{ .data = 6 },
        .{ .data = 0 },
        .{ .data = 4 },
    };
    g3.insertAfter(&r3_data_nodes[0]);
    r3_data_nodes[0].insertAfter(&r3_data_nodes[1]);
    r3_data_nodes[1].insertAfter(&r3_data_nodes[2]);

    try m0.attachSubring(&r2_data_nodes[1], &g3);

    var g4 = M.GateNode{};
    try m0.attachSubring(&r2_data_nodes[3], &g4);

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

    // find the last data node in the m0
    try testing.expectEqual(&r0_data_nodes[3], m0.findLast().?);

    // find the last data node in r1
    try testing.expectEqual(&r1_data_nodes[5], g1.findLastLocal().?);
    try testing.expectEqual(&r1_data_nodes[5], r1_data_nodes[0].findLastLocal());

    // find the last data node in r4 (there isn't one)
    try testing.expectEqual(@as(?*M.DataNode, null), g4.findLastLocal());

    // remove a data node in the m0 (in r3)
    try testing.expect(m0.remove(&r3_data_nodes[2]));
    try testing.expectEqual(M.Node{ .gate = &g3 }, r3_data_nodes[1].next.?);
    try testing.expectEqual(@as(?M.Node, null), r3_data_nodes[2].next);

    // try to remove a data node that isn't in the m0
    var d = M.DataNode{ .data = 0 };
    try testing.expect(!m0.remove(&d));
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

    // append a new node to the end of the m0
    var r = M.DataNode{ .data = 0 };
    m0.append(&r);
    try testing.expectEqual(&r, m0.findLast().?);

    // append a new node to the end of r1
    var s = M.DataNode{ .data = 1 };
    g1.append(&s);
    try testing.expectEqual(&s, g1.findLastLocal().?);

    // try to attach subrings inappropriately
    try testing.expectError(
        MultiRingError.DataNodeAlreadyHasChild,
        m0.attachSubring(&r0_data_nodes[0], &g3),
    );
    try testing.expectError(
        MultiRingError.GateNodeAlreadyHasParent,
        m0.attachSubring(&r1_data_nodes[0], &g2),
    );
    try testing.expectError(
        MultiRingError.UnsafeLoopCreationAttempt,
        m0.attachSubring(&r1_data_nodes[0], &g0),
    );
}

test "ring skips" {
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

    var m0 = M{ .root = &g0 };
    try m0.attachSubring(&d0, &g1);
    try m0.attachSubring(&d1, &g2);

    try testing.expectEqual(&d0, d2.step());
    try testing.expectEqual(&d2, m0.findLast().?);
}
