// SPDX-FileCopyrightText: Copyright 2023, 2024 OK Ryoko
// SPDX-License-Identifier: MIT

const std = @import("std");
const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;

const MultiRing = @import("multiring").MultiRing;

fn expectNull(actual: anytype) !void {
    switch (@typeInfo(@TypeOf(actual))) {
        .Optional => try expectEqual(@as(@TypeOf(actual), null), actual),
        else => @compileError("expected optional type, found " ++ @typeName(@TypeOf(actual))),
    }
}

test "node" {
    const M = MultiRing(u8);

    var h = M.HeadNode{};
    var hn = M.Node{ .head = &h };
    try expect(hn.isHead());
    try expect(!hn.isData());

    var d = M.DataNode{ .data = 0 };
    var dn = M.Node{ .data = &d };
    try expect(!dn.isHead());
    try expect(dn.isData());
}

test "empty ring" {
    const M = MultiRing(u8);

    var h = M.HeadNode{};
    var x = M.DataNode{ .data = 255 };

    try expect(h.isRoot());
    try expect(h.isEmpty());
    try expectNull(h.isOpen());
    try expectEqual(@as(usize, 0), h.count());
    try expectEqual(@as(usize, 0), h.countAbove());
    try expectEqual(@as(usize, 0), h.countBelow());
    try expectNull(h.findLast());
    try expectNull(h.findLastAbove());
    try expectNull(h.findLastBelow());
    try expectNull(h.findHeadAbove());
    try expectNull(h.findHeadZ());
    try expectEqual(&h, h.findRoot().?);
    try expectNull(h.step());
    try expectNull(h.stepAbove());
    try expectNull(h.stepZ());
    try expectNull(h.popNext());
    try expect(!h.removeBelow(&x));
    try expect(!h.remove(&x));
}

test "non-empty ring" {
    const M = MultiRing(u8);

    var h = M.HeadNode{};
    var d = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
        .{ .data = 3 },
        .{ .data = 4 },
    };
    var x = M.DataNode{ .data = 255 };

    try expect(h.isRoot());

    h.insertAfter(&d[0]);

    try expect(!h.isEmpty());
    try expect(!h.isOpen().?);
    try expectEqual(@as(usize, 1), h.count());
    try expectEqual(@as(usize, 1), h.countBelow());
    try expectEqual(@as(usize, 0), h.countAbove());
    try expectEqual(&d[0], h.findLast().?);
    try expectEqual(&d[0], h.findLastBelow().?);
    try expectNull(h.findLastAbove());
    try expectNull(h.findHeadAbove());
    try expectNull(h.findHeadZ());
    try expectEqual(&h, h.findRoot().?);
    try expectEqual(&d[0], h.step().?);
    try expectNull(h.stepAbove());
    try expectEqual(&d[0], h.stepZ().?);

    try expectEqual(@as(usize, 0), d[0].countAfter());
    try expectEqual(&d[0], d[0].findLast());
    try expectEqual(&h, d[0].findHead().?);
    try expectEqual(&h, d[0].findHeadZ().?);
    try expectEqual(&h, d[0].findRoot().?);
    try expectNull(d[0].step());
    try expectNull(d[0].stepBelow());
    try expectNull(d[0].stepZ());

    try expect(!h.remove(&x));
    try expect(!h.removeBelow(&x));

    try expect(h.remove(&d[0]));
    try expect(h.isEmpty());
    try expectEqual(@as(usize, 0), h.count());
    try expectNull(h.findLast());

    h.append(&d[0]);

    try expect(!h.isEmpty());
    try expectEqual(@as(usize, 1), h.count());
    try expectEqual(&d[0], h.findLast().?);

    try expectNull(d[0].popNext());
    try expectEqual(&d[0], h.popNext().?);

    try expect(h.isEmpty());
    try expectEqual(@as(usize, 0), h.count());
    try expectNull(h.findLast());

    h.extend(&d);

    try expect(!h.isEmpty());
    try expect(!h.isOpen().?);
    try expectEqual(@as(usize, 5), h.count());
    try expectEqual(@as(usize, 5), h.countBelow());
    try expectEqual(&d[4], h.findLast().?);
    try expectEqual(&d[4], h.findLastBelow().?);
    try expectEqual(&d[0], h.step().?);

    try expectEqual(@as(usize, 4), d[0].countAfter());
    try expectEqual(&d[1], d[0].step().?);
    try expectEqual(&d[2], d[1].step().?);
    try expectEqual(&d[3], d[2].step().?);
    try expectEqual(&d[4], d[3].step().?);
    try expectNull(d[4].step());

    d[2].insertAfter(&x);
    try expectEqual(@as(usize, 5), d[0].countAfter());
    try expectEqual(&x, d[2].stepZ().?);
    try expectEqual(&x, d[2].popNext().?);
    try expectEqual(@as(usize, 4), d[0].countAfter());

    h.rotate();

    try expectEqual(&d[1], h.stepZ().?);
    try expectEqual(&d[0], h.findLastBelow().?);

    h.clear();

    try expect(h.isEmpty());
    try expectNull(d[0].step());
}

test "reverse a non-empty ring" {
    const M = MultiRing(u8);

    var h = M.HeadNode{};
    var d = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
        .{ .data = 3 },
        .{ .data = 4 },
    };
    h.extend(&d);

    h.reverse();
    var it = h.step();
    var i: usize = 5;
    while (it) |_it| {
        try expectEqual(i - 1, _it.data);
        i -= 1;
        it = _it.step();
    }
}

test "non-empty open ring (linked list)" {
    const M = MultiRing(u8);

    var h = M.HeadNode{};
    var d = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
        .{ .data = 3 },
        .{ .data = 4 },
    };

    h.extend(&d);
    h.open();
    try expect(h.isOpen().?);
    try expectNull(h.findHeadAbove());
    try expectNull(h.findHeadZ());
    try expectEqual(&h, h.findRoot().?);
    try expectEqual(@as(usize, 5), h.count());
    try expectEqual(@as(usize, 4), d[0].countAfter());
    try expectEqual(&d[4], d[0].findLast());
    try expectNull(d[0].findHead());
    try expectNull(d[0].findHeadZ());
    try expectNull(d[0].findRoot());

    var x = M.DataNode{ .data = 255 };
    try expect(!h.remove(&x));
    try expect(!d[0].removeAfter(&x));

    try expect(h.remove(&d[4]));
    try expectEqual(@as(usize, 4), h.count());
    try expect(h.isOpen().?);

    try expect(d[0].removeAfter(&d[3]));
    try expectEqual(@as(usize, 3), h.count());
    try expect(h.isOpen().?);

    try expectEqual(&d[2], d[1].popNext().?);
    try expectEqual(@as(usize, 2), h.count());
    try expect(h.isOpen().?);

    try expectEqual(&d[0], h.popNext().?);
    try expectEqual(@as(usize, 1), h.count());
    try expect(h.isOpen().?);

    try expectEqual(&d[1], h.findLast().?);
    d[1].insertManyAfter(d[2..]);
    try expect(h.isOpen().?);
    try expectEqual(@as(usize, 4), h.count());

    h.close();
    try expect(!h.isOpen().?);
}

test "non-empty ring containing subrings" {
    const M = MultiRing(u8);

    var h0 = M.HeadNode{};
    var d0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
        .{ .data = 3 },
        .{ .data = 4 },
    };
    h0.extend(&d0);

    var h1 = M.HeadNode{};
    d0[0].attachMultiRing(&h1);

    try expectEqual(@as(usize, 5), h0.countBelow());
    try expectEqual(&h1, h0.findHeadZ().?);
    try expectEqual(&h1, h0.findHeadBelow().?);
    try expectNull(h1.findHeadBelow());

    try expectEqual(@as(usize, 4), d0[0].countAfterZ());
    try expectEqual(@as(usize, 0), d0[4].countAfterZ());
    try expectEqual(&h0, d0[0].findHead().?);
    try expectEqual(&h1, d0[0].findHeadZ().?);
    try expectEqual(&d0[1], d0[0].step().?);
    try expectNull(d0[0].stepBelow());
    try expectEqual(&d0[1], d0[0].stepZ().?);

    try expectNull(h1.step());
    try expect(!h1.isRoot());
    try expectEqual(@as(usize, 4), h1.countAbove());
    try expectEqual(&d0[4], h1.findLastAbove().?);
    try expectEqual(&h0, h1.findHeadZ().?);
    try expectEqual(&h0, h1.findRoot().?);
    try expectEqual(&d0[1], h1.stepAbove().?);
    try expectEqual(&d0[1], h1.stepZ().?);

    var h2 = M.HeadNode{};
    var d2 = M.DataNode{ .data = 5 };
    h2.append(&d2);
    d0[2].attachMultiRing(&h2);

    try expectEqual(@as(usize, 5), h0.count());
    try expectEqual(@as(usize, 6), h0.countBelow());
    try expectEqual(&d0[4], h0.findLast().?);
    try expectEqual(&d0[4], h0.findLastBelow().?);

    try expectEqual(&h2, d0[1].findHeadZ().?);
    try expectEqual(&d0[3], d0[2].step().?);
    try expectEqual(&d2, d0[2].stepBelow().?);
    try expectEqual(&d2, d0[2].stepZ().?);

    try expectEqual(@as(usize, 2), h2.countAbove());
    try expectEqual(&d0[4], d2.findLastZ());
    try expectEqual(&d0[4], h2.findLastAbove().?);

    try expectEqual(&h0, h2.findHeadAbove().?);
    try expectEqual(&d2, h2.step().?);
    try expectEqual(&d0[3], h2.stepAbove().?);
    try expectEqual(&d2, h2.stepZ().?);

    try expectEqual(@as(usize, 2), d2.countAfterZ());
    try expectEqual(&h2, d2.findHead().?);
    try expectEqual(&h2, d2.findHeadZ().?);
    try expectEqual(&h0, d2.findRoot().?);
    try expectEqual(&d0[3], d2.stepZ().?);

    var h3 = M.HeadNode{};
    var d3 = M.DataNode{ .data = 6 };
    h3.append(&d3);
    d0[4].attachMultiRing(&h3);

    try expectEqual(@as(usize, 5), h0.count());
    try expectEqual(@as(usize, 7), h0.countBelow());
    try expectEqual(&d0[4], h0.findLast().?);
    try expectEqual(&d3, h0.findLastBelow().?);

    try expectEqual(@as(usize, 6), h1.countAbove());
    try expectEqual(@as(usize, 3), h2.countAbove());
    try expectEqual(@as(usize, 0), h3.countAbove());

    try expectEqual(&d3, h2.findLastAbove().?);

    try expectNull(h3.findLastAbove());
    try expectEqual(&h0, h3.findHeadAbove().?);
    try expectNull(h3.findHeadZ());
    try expectEqual(&h0, h3.findRoot().?);
    try expectNull(h3.stepAbove());
    try expectEqual(&d3, h3.stepZ().?);
    try expectNull(d3.stepZ());

    try expectEqual(&d3, d0[0].findLastZ());
    try expectEqual(@as(usize, 6), d0[0].countAfterZ());
    try expectEqual(@as(usize, 1), d0[4].countAfterZ());
    try expectEqual(@as(usize, 0), d3.countAfterZ());

    try expect(!h0.remove(&d2));
    try expectEqual(@as(usize, 7), h0.countBelow());

    try expect(h0.remove(&d0[3]));
    try expectEqual(@as(usize, 4), h0.count());
    try expectEqual(&d0[4], d0[2].step().?);
    try expectEqual(&d0[4], h2.stepAbove().?);

    var d1 = [_]M.DataNode{
        .{ .data = 7 },
        .{ .data = 8 },
        .{ .data = 9 },
    };
    h1.insertManyAfter(&d1);
    try expectEqual(@as(usize, 3), h1.count());
    try expectEqual(@as(usize, 9), h0.countBelow());

    try expectEqual(&h1, d0[0].detachMultiRing().?);
    try expectEqual(@as(usize, 3), h1.count());
    try expectEqual(@as(usize, 6), h0.countBelow());

    try expect(h0.removeBelow(&d3));
    try expect(h3.isEmpty());
    try expectEqual(@as(usize, 5), h0.countBelow());

    var x = M.DataNode{ .data = 255 };
    var y = M.DataNode{ .data = 255 };

    d0[4].insertAfter(&x);
    h0.append(&y);
    try expectEqual(&x, h3.stepAbove().?);
    try expectEqual(@as(usize, 6), h0.count());

    try expectEqual(&x, d0[4].popNext().?);
    try expectEqual(&y, h3.stepAbove().?);
    try expect(h2.removeAbove(&y));
    try expectNull(h3.stepAbove());
    try expectEqual(@as(usize, 4), h0.count());

    try expectEqual(&h3, d0[4].detachMultiRing().?);
    try expect(h3.isRoot());
    try expectEqual(@as(usize, 4), h0.count());
    try expectEqual(@as(usize, 5), h0.countBelow());
    try expectEqual(&d0[4], h0.findLast().?);
    try expectEqual(&d0[4], h0.findLastBelow().?);

    try expect(d2.removeAfterZ(&d0[4]));
    try expectEqual(@as(usize, 4), h0.countBelow());
    try expectNull(d0[3].stepZ());

    try expectEqual(&d0[2], d0[1].popNext().?);
    try expectEqual(@as(usize, 2), h0.countBelow());
    try expect(h2.isRoot());
    try expect(!d2.removeAfterZ(&d0[4]));
}

test "rootless multiring" {
    const M = MultiRing(u8);

    var m = M{};
    var x = M.DataNode{ .data = 255 };

    try expect(m.isEmpty());
    try expectEqual(@as(usize, 0), m.len());
    try expectNull(m.findLast());
    try expect(!m.remove(&x));
}

test "multiring comprising exactly one ring" {
    const M = MultiRing(u8);

    var h = M.HeadNode{};
    var m = M{ .root = &h };
    var d = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
        .{ .data = 3 },
        .{ .data = 4 },
    };

    m.append(&d[0]);
    try expect(!m.isEmpty());
    try expectEqual(@as(usize, 1), m.len());
    try expectEqual(&d[0], m.findLast().?);

    try expect(m.remove(&d[0]));
    try expect(m.isEmpty());
    try expectEqual(@as(usize, 0), m.len());
    try expectNull(m.findLast());

    m.extend(&d);
    try expect(!m.isEmpty());
    try expectEqual(@as(usize, 5), m.len());
    try expectEqual(&d[4], m.findLast().?);

    m.clear();
    try expect(m.isEmpty());
}
