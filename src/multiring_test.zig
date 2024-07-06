// SPDX-FileCopyrightText: Copyright 2023, 2024 OK Ryoko
// SPDX-License-Identifier: MIT

const std = @import("std");
const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;

const MultiRing = @import("multiring").MultiRing;

fn expectNull(actual: anytype) !void {
    switch (@typeInfo(@TypeOf(actual))) {
        .Optional => try expectEqual(null, actual),
        else => @compileError("expected optional type, found " ++ @typeName(@TypeOf(actual))),
    }
}

test "node" {
    const M = MultiRing(u8);
    {
        var h = M.HeadNode{};
        var n = M.Node{ .head = &h };
        try expect(n.isHead() and !n.isData());
    }
    {
        var d = M.DataNode{ .data = 0xAA };
        var n = M.Node{ .data = &d };
        try expect(!n.isHead() and n.isData());
    }
}

test "empty ring" {
    const M = MultiRing(u8);
    var h = M.HeadNode{};
    var x = M.DataNode{ .data = 0xAA };
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
    try expectNull(h.findHeadBelow());
    try expectNull(h.findHeadZ());
    try expectEqual(&h, h.findRoot().?);
    try expectNull(h.step());
    try expectNull(h.stepAbove());
    try expectNull(h.stepAboveUntilHead(&h));
    try expectNull(h.stepZ());
    try expectNull(h.popNext());
    try expect(!h.remove(&x));
    try expect(!h.removeAbove(&x));
    try expect(!h.removeBelow(&x));
}

test "nonempty ring" {
    const M = MultiRing(u8);
    var h = M.HeadNode{};
    var ds = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
    };
    h.next = &ds[0];
    ds[0].next = .{ .data = &ds[1] };
    ds[1].next = .{ .head = &h };
    try expect(!h.isEmpty());
    try expectEqual(&ds[0], h.step().?);
    try expectEqual(&ds[1], ds[0].step().?);
    try expectNull(ds[1].step());
    try expectEqual(@as(usize, 1), ds[0].countAfter());
    try expectEqual(@as(usize, 2), h.count());
    try expectEqual(&ds[1], ds[0].findLast());
    try expectEqual(&ds[1], h.findLast());
    try expectEqual(&h, ds[0].findHead());
    try expectEqual(&h, ds[0].findRoot());
    try expect(!h.isOpen().?);
}

test "ring assembly" {
    const M = MultiRing(u8);
    var h = M.HeadNode{};
    var ds = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
        .{ .data = 3 },
        .{ .data = 4 },
        .{ .data = 5 },
        .{ .data = 6 },
        .{ .data = 7 },
        .{ .data = 8 },
    };

    // {} -> { 2 }
    //
    h.insertAfter(&ds[2]);
    try expect(!h.isEmpty());
    try expectEqual(&ds[2], h.step().?);
    try expectNull(ds[2].step());
    try expectEqual(@as(usize, 1), h.count());

    // { 2 } -> { 2 5 }
    //
    ds[2].insertAfter(&ds[5]);
    try expect(!h.isEmpty());
    try expectEqual(&ds[5], ds[2].step().?);
    try expectNull(ds[5].step());
    try expectEqual(@as(usize, 2), h.count());

    // { 2 5 } -> { 0 1 2 5 }
    //
    h.insertManyAfter(ds[0..2]);
    try expect(!h.isEmpty());
    try expectEqual(&ds[0], h.step().?);
    try expectEqual(&ds[1], ds[0].step().?);
    try expectEqual(&ds[2], ds[1].step().?);
    try expectEqual(@as(usize, 4), h.count());

    // { 0 1 2 5 } -> { 0 1 2 3 4 5 }
    //
    ds[2].insertManyAfter(ds[3..5]);
    try expect(!h.isEmpty());
    try expectEqual(&ds[3], ds[2].step().?);
    try expectEqual(&ds[4], ds[3].step().?);
    try expectEqual(@as(usize, 6), h.count());

    // { 0 1 2 3 4 5 } -> { 0 1 2 3 4 5 6 }
    //
    h.append(&ds[6]);
    try expect(!h.isEmpty());
    try expectEqual(&ds[6], ds[5].step().?);
    try expectNull(ds[6].step());
    try expectEqual(@as(usize, 7), h.count());

    // { 0 1 2 3 4 5 6 } -> { 0 1 2 3 4 5 6 7 8 }
    //
    h.extend(ds[7..]);
    try expect(!h.isEmpty());
    try expectEqual(&ds[7], ds[6].step().?);
    try expectEqual(&ds[8], ds[7].step().?);
    try expectNull(ds[8].step());
    try expectEqual(@as(usize, 9), h.count());
}

test "ring disassembly" {
    const M = MultiRing(u8);
    var h = M.HeadNode{};
    var ds = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
        .{ .data = 3 },
        .{ .data = 4 },
        .{ .data = 5 },
    };

    // {} -> { 0 1 2 3 4 5 }
    //
    h.extend(&ds);
    try expectEqual(@as(usize, 6), h.count());

    // { 0 1 2 3 4 5 } -> { 1 2 3 4 5 }
    //
    try expectEqual(&ds[0], h.popNext().?);
    try expectEqual(&ds[1], h.step().?);
    try expectEqual(@as(usize, 5), h.count());

    // { 1 2 3 4 5 } -> { 1 3 4 5 }
    //
    try expectEqual(&ds[2], ds[1].popNext().?);
    try expectEqual(&ds[3], ds[1].step().?);
    try expectEqual(@as(usize, 4), h.count());

    // { 1 3 4 5 } -> { 1 3 4 5 }
    //
    try expectNull(ds[5].popNext());
    try expectNull(ds[5].step());
    try expectEqual(@as(usize, 4), h.count());

    // { 1 3 4 5 } -> { 1 3 5 }
    //
    try expect(ds[1].removeAfter(&ds[4]));
    try expectEqual(&ds[5], ds[3].step());
    try expectEqual(@as(usize, 3), h.count());

    // { 1 3 5 } -> { 1 3 5 }
    //
    try expect(!ds[1].removeAfter(&ds[4]));
    try expectEqual(@as(usize, 3), h.count());

    // { 1 3 5 } -> { 1 5 }
    //
    try expect(h.remove(&ds[3]));
    try expectEqual(&ds[5], ds[1].step());
    try expectEqual(@as(usize, 2), h.count());

    // { 1 5 } -> { 1 5 }
    //
    try expect(!h.remove(&ds[3]));
    try expectEqual(@as(usize, 2), h.count());

    // { 1 5 } -> {}
    //
    h.clear();
    try expect(h.isEmpty());
    try expectEqual(@as(usize, 0), h.count());
}

test "ring rotation" {
    const M = MultiRing(u8);
    var h = M.HeadNode{};
    var ds = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
    };

    // {} -> {}
    //
    h.rotate();

    // {} -> { 0 1 2 }
    //
    h.extend(&ds);

    // { 0 1 2 } -> { 1 2 0 }
    //
    h.rotate();
    var it = h.step();
    var i: usize = 0;
    while (it) |d| : (it = d.step()) {
        try expectEqual((i + 1) % 3, d.data);
        i += 1;
    }
}

test "ring reversal" {
    const M = MultiRing(u8);
    var h = M.HeadNode{};
    var ds = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
    };

    // {} -> {}
    //
    h.reverse();

    // {} -> { 0 1 2 }
    //
    h.extend(&ds);

    // { 0 1 2 } -> { 2 1 0 }
    //
    h.reverse();
    var it = h.step();
    var i: usize = 3;
    while (it) |d| : (it = d.step()) {
        try expectEqual(i - 1, d.data);
        i -= 1;
    }
}

fn cmp_u8(a: *const u8, b: *const u8) bool {
    return a.* < b.*;
}

test "ring sort" {
    const M = MultiRing(u8);
    var h = M.HeadNode{};
    var it: ?*M.DataNode = undefined;
    var i: usize = 0;

    // {} -> {}
    //
    h.sort(&cmp_u8);

    // {} -> { 0 1 2 3 4 5 6 7 8 }
    //
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
        .{ .data = 3 },
        .{ .data = 4 },
        .{ .data = 5 },
        .{ .data = 6 },
        .{ .data = 7 },
        .{ .data = 8 },
    };
    h.extend(&ds0);

    // { 0 1 2 3 4 5 6 7 8 } -> { 0 1 2 3 4 5 6 7 8 }
    //
    h.sort(&cmp_u8);
    it = h.step();
    while (it) |d| : (it = d.step()) {
        try expectEqual(i, d.data);
        i += 1;
    }

    // { 0 1 2 3 4 5 6 7 8 } -> {}
    //
    h.clear();

    // {} -> { 8 7 6 5 4 3 2 1 0 }
    //
    var ds1 = [_]M.DataNode{
        .{ .data = 8 },
        .{ .data = 7 },
        .{ .data = 6 },
        .{ .data = 5 },
        .{ .data = 4 },
        .{ .data = 3 },
        .{ .data = 2 },
        .{ .data = 1 },
        .{ .data = 0 },
    };
    h.extend(&ds1);

    // { 8 7 6 5 4 3 2 1 0 } -> { 0 1 2 3 4 5 6 7 8 }
    //
    h.sort(&cmp_u8);
    it = h.step();
    i = 0;
    while (it) |d| : (it = d.step()) {
        try expectEqual(i, d.data);
        i += 1;
    }

    // { 0 1 2 3 4 5 6 7 8 } -> {}
    //
    h.clear();

    // {} -> { 4 3 1 5 6 8 7 0 2 }
    //
    var ds2 = [_]M.DataNode{
        .{ .data = 4 },
        .{ .data = 3 },
        .{ .data = 1 },
        .{ .data = 5 },
        .{ .data = 6 },
        .{ .data = 8 },
        .{ .data = 7 },
        .{ .data = 0 },
        .{ .data = 2 },
    };
    h.extend(&ds2);

    // { 4 3 1 5 6 8 7 0 2 } -> { 0 1 2 3 4 5 6 7 8 }
    //
    h.sort(&cmp_u8);
    it = h.step();
    i = 0;
    while (it) |d| : (it = d.step()) {
        try expectEqual(i, d.data);
        i += 1;
    }
}

test "linked list (nonempty open ring)" {
    const M = MultiRing(u8);
    var h = M.HeadNode{};
    var ds = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
    };
    h.next = &ds[0];
    ds[0].next = .{ .data = &ds[1] };
    try expect(h.isOpen().?);
    try expectNull(ds[1].step());
    try expectEqual(@as(usize, 2), h.count());
    try expectEqual(@as(usize, 1), ds[0].countAfter());
    try expectEqual(&ds[1], ds[0].findLast());
    try expectEqual(&ds[1], h.findLast());
    try expectNull(ds[0].findHead());
    try expectNull(ds[0].findRoot());
}

test "linked list assembly" {
    const M = MultiRing(u8);
    var h = M.HeadNode{};
    var ds = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
        .{ .data = 3 },
        .{ .data = 4 },
        .{ .data = 5 },
        .{ .data = 6 },
    };

    // {} -> { 0 .
    //
    h.next = &ds[0];

    // { 0 . -> { 0 1 .
    //
    ds[0].insertAfter(&ds[1]);
    try expectEqual(&ds[1], ds[0].step().?);
    try expectNull(ds[1].step());
    try expect(h.isOpen().?);
    try expectEqual(@as(usize, 2), h.count());

    // { 0 1 . -> { 0 1 2 3 .
    //
    ds[1].insertManyAfter(ds[2..4]);
    try expectEqual(&ds[2], ds[1].step().?);
    try expectEqual(&ds[3], ds[2].step().?);
    try expectNull(ds[3].step());
    try expect(h.isOpen().?);
    try expectEqual(@as(usize, 4), h.count());

    // { 0 1 2 3 . -> { 0 1 2 3 4 .
    //
    h.append(&ds[4]);
    try expectEqual(&ds[4], ds[3].step().?);
    try expectNull(ds[4].step());
    try expect(h.isOpen().?);
    try expectEqual(@as(usize, 5), h.count());

    // { 0 1 2 3 4 . -> { 0 1 2 3 4 5 6 .
    //
    h.extend(ds[5..]);
    try expectEqual(&ds[5], ds[4].step().?);
    try expectEqual(&ds[6], ds[5].step().?);
    try expectNull(ds[6].step());
    try expect(h.isOpen().?);
    try expectEqual(@as(usize, 7), h.count());
}

test "linked list disassembly" {
    const M = MultiRing(u8);
    var h = M.HeadNode{};
    var ds = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
        .{ .data = 3 },
    };

    // {} -> { 0 1 2 3 .
    //
    h.next = &ds[0];
    ds[0].insertManyAfter(ds[1..]);

    // { 0 1 2 3 . -> { 0 1 2 3 .
    //
    try expectNull(ds[3].popNext());
    try expect(h.isOpen().?);
    try expectEqual(@as(usize, 4), h.count());

    // { 0 1 2 3 . -> { 0 1 2 .
    //
    try expectEqual(&ds[3], ds[2].popNext().?);
    try expectNull(ds[2].step());
    try expect(h.isOpen().?);
    try expectEqual(@as(usize, 3), h.count());

    // { 0 1 2 . -> { 0 1 .
    //
    try expect(ds[0].removeAfter(&ds[2]));
    try expectNull(ds[1].step());
    try expect(h.isOpen().?);
    try expectEqual(@as(usize, 2), h.count());

    // { 0 1 . -> { 0 1 .
    //
    try expect(!ds[0].removeAfter(&ds[2]));
    try expect(h.isOpen().?);
    try expectEqual(@as(usize, 2), h.count());

    // { 0 1 . -> { 0 .
    //
    try expect(h.remove(&ds[1]));
    try expectNull(ds[0].step());
    try expect(h.isOpen().?);
    try expectEqual(@as(usize, 1), h.count());

    // { 0 . -> { 0 .
    //
    try expect(!h.remove(&ds[1]));
    try expect(h.isOpen().?);
    try expectEqual(@as(usize, 1), h.count());
}

test "ring opening and closing" {
    const M = MultiRing(u8);
    var h = M.HeadNode{};
    var ds = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
    };

    // {} -> { 0 1 }
    //
    h.extend(&ds);
    try expect(!h.isOpen().?);

    // { 0 1 } -> { 0 1 }
    //
    h.close();
    try expect(!h.isOpen().?);

    // { 0 1 } -> { 0 1 .
    //
    h.open();
    try expect(h.isOpen().?);

    // { 0 1 . -> { 0 1 .
    //
    h.open();
    try expect(h.isOpen().?);

    // { 0 1 . -> { 0 1 }
    //
    h.close();
    try expect(!h.isOpen().?);
}

test "linked list rotation" {
    const M = MultiRing(u8);
    var h = M.HeadNode{};
    var ds = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
    };

    // {} -> { 0 1 2 .
    //
    h.next = &ds[0];
    ds[0].insertManyAfter(ds[1..]);

    // { 0 1 2 . -> { 1 2 0 .
    //
    h.rotate();
    try expect(h.isOpen().?);
    var it = h.step();
    var i: usize = 0;
    while (it) |d| : (it = d.step()) {
        try expectEqual((i + 1) % 3, d.data);
        i += 1;
    }
}

test "linked list reversal" {
    const M = MultiRing(u8);
    var h = M.HeadNode{};
    var ds = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
    };

    // {} -> { 0 1 2 .
    //
    h.next = &ds[0];
    ds[0].insertManyAfter(ds[1..]);

    // { 0 1 2 . -> { 2 1 0 .
    //
    h.reverse();
    try expect(h.isOpen().?);
    var it = h.step();
    var i: usize = 3;
    while (it) |d| : (it = d.step()) {
        try expectEqual(i - 1, d.data);
        i -= 1;
    }
}

test "linked list sort" {
    const M = MultiRing(u8);
    var h = M.HeadNode{};
    var ds = [_]M.DataNode{
        .{ .data = 8 },
        .{ .data = 7 },
        .{ .data = 6 },
        .{ .data = 5 },
        .{ .data = 4 },
        .{ .data = 3 },
        .{ .data = 2 },
        .{ .data = 1 },
        .{ .data = 0 },
    };

    // {} -> { 8 7 6 5 4 3 2 1 0 .
    //
    h.extend(&ds);
    h.open();

    // { 8 7 6 5 4 3 2 1 0 . -> { 0 1 2 3 4 5 6 7 8 }
    //
    h.sort(&cmp_u8);
    try expect(!h.isOpen().?);
    var it = h.step();
    var i: usize = 0;
    while (it) |d| : (it = d.step()) {
        try expectEqual(i, d.data);
        i += 1;
    }
}

test "multiring assembly and disassembly" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var d0 = M.DataNode{ .data = 0 };
    var h1 = M.HeadNode{};
    var d1 = M.DataNode{ .data = 1 };

    // {} {} -> { 0 } { 1 }
    //
    h0.append(&d0);
    h1.append(&d1);

    // { 0 } { 1 } -> { 0 { 1 } }
    //
    d0.attachMultiRing(&h1);
    try expectEqual(&h1, d0.next_below);
    try expectEqual(M.Node{ .head = &h0 }, h1.next_above);

    // { 0 { 1 } } -> { 0 } { 1 }
    //
    try expectEqual(&h1, d0.detachMultiRing().?);
    try expectNull(d0.next_below);
    try expectNull(h1.next_above);

    // { 0 } { 1 } -> { 0 } { 1 }
    //
    try expectNull(d0.detachMultiRing());
}

test "MultiRing(u8).DataNode.findHeadZ" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
    };
    var h1 = M.HeadNode{};

    // {} {} -> { 0 {} 1 }
    //
    h0.extend(&ds0);
    ds0[0].attachMultiRing(&h1);
    try expectEqual(&h1, ds0[0].findHeadZ().?);
    try expectEqual(&h0, ds0[1].findHeadZ().?);

    // { 0 {} 1 } -> { 0 {} 1 .
    //
    h0.open();
    try expectNull(ds0[1].findHeadZ());
}

test "MultiRing(u8).HeadNode.findHead{Above,Below}" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
    };
    var h1 = M.HeadNode{};
    var h2 = M.HeadNode{};

    // {} {} {} -> { 0 1 } {} {}
    //
    h0.extend(&ds0);
    try expectNull(h0.findHeadBelow());

    // { 0 1 } {} {} -> { 0 {} 1 {} }
    //
    ds0[0].attachMultiRing(&h1);
    ds0[1].attachMultiRing(&h2);
    try expectEqual(&h1, h0.findHeadBelow().?);
    try expectEqual(&h2, h1.findHeadAbove().?);
    try expectEqual(&h0, h2.findHeadAbove().?);

    // { 0 {} 1 {} } -> { 0 {} 1 {} .
    //
    h0.open();
    try expectNull(h2.findHeadAbove());
}

test "MultiRing(u8).HeadNode.findHeadZ" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 3 },
        .{ .data = 5 },
    };
    var h1 = M.HeadNode{};
    var h2 = M.HeadNode{};
    var d2 = M.DataNode{ .data = 2 };
    var h3 = M.HeadNode{};
    var d3 = M.DataNode{ .data = 4 };
    var h4 = M.HeadNode{};
    var h5 = M.HeadNode{};

    // {} {} {} {} {} {} -> { 0 {} 1 { 2 } 3 { 4 {} } 5 {} }
    //
    h0.extend(&ds0);
    ds0[0].attachMultiRing(&h1);
    ds0[1].attachMultiRing(&h2);
    h2.append(&d2);
    ds0[2].attachMultiRing(&h3);
    h3.append(&d3);
    d3.attachMultiRing(&h4);
    ds0[3].attachMultiRing(&h5);
    try expectEqual(&h1, h0.findHeadZ().?);
    try expectEqual(&h2, h1.findHeadZ().?);
    try expectEqual(&h3, h2.findHeadZ().?);
    try expectEqual(&h4, h3.findHeadZ().?);
    try expectEqual(&h3, h4.findHeadZ().?);
    try expectEqual(&h0, h5.findHeadZ().?);

    // { 0 {} 1 { 2 } 3 { 4 {} } 5 {} } -> { 0 {} 1 { 2 . 3 { 4 {} } 5 {} }
    //
    h2.open();
    try expectNull(h2.findHeadZ());

    // { 0 {} 1 { 2 . 3 { 4 {} } 5 {} } -> { 0 {} 1 { 2 . 3 { 4 {} . 5 {} }
    //
    h3.open();
    try expectNull(h4.findHeadZ());
}

test "MultiRing(u8).{Head,Data}Node.findRoot" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
    };
    var h1 = M.HeadNode{};
    var h2 = M.HeadNode{};
    var d2 = M.DataNode{ .data = 2 };
    var h3 = M.HeadNode{};

    // {} {} {} {} -> { 0 {} 1 { 2 {} } }
    //
    h0.extend(&ds0);
    ds0[0].attachMultiRing(&h1);
    ds0[1].attachMultiRing(&h2);
    h2.append(&d2);
    d2.attachMultiRing(&h3);
    try expectEqual(&h0, h1.findRoot().?);
    try expectEqual(&h0, h3.findRoot().?);
    try expectEqual(&h0, ds0[0].findRoot().?);

    // { 0 {} 1 { 2 {} } } -> { 0 {} 1 { 2 {} } .
    //
    h0.open();
    try expectNull(h1.findRoot());
    try expectNull(ds0[0].findRoot());
}

test "MultiRing(u8).HeadNode.stepAboveUntilHead" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 3 },
    };
    var h1 = M.HeadNode{};
    var h2 = M.HeadNode{};
    var d2 = M.DataNode{ .data = 2 };
    var h3 = M.HeadNode{};
    var h4 = M.HeadNode{};

    // {} {} {} {} {} -> { 0 {} 1 { 2 {} } 3 {} }
    //
    h0.extend(&ds0);
    ds0[0].attachMultiRing(&h1);
    ds0[1].attachMultiRing(&h2);
    h2.append(&d2);
    d2.attachMultiRing(&h3);
    ds0[2].attachMultiRing(&h4);
    try expectNull(h1.stepAboveUntilHead(&h1));
    try expectEqual(&ds0[1], h1.stepAboveUntilHead(&h0));
    try expectNull(h3.stepAboveUntilHead(&h2));
    try expectEqual(&ds0[2], h3.stepAboveUntilHead(&h0));
    try expectNull(h4.stepAboveUntilHead(&h1));

    // { 0 {} 1 { 2 {} } 3 {} } -> { 0 {} 1 { 2 {} . 3 {} }
    //
    h2.open();
    try expectNull(h3.stepAboveUntilHead(&h0));
}

test "MultiRing(u8).DataNode.stepBelow" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var d0 = M.DataNode{ .data = 0 };
    var h1 = M.HeadNode{};
    var d1 = M.DataNode{ .data = 1 };

    // {} {} -> { 0 { 1 } }
    //
    h0.append(&d0);
    d0.attachMultiRing(&h1);
    h1.append(&d1);
    try expectEqual(&d1, d0.stepBelow().?);
    try expectNull(d1.stepBelow());
}

test "MultiRing(u8).DataNode.stepUntilHeadZ" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 3 },
    };
    var h1 = M.HeadNode{};
    var d1 = M.DataNode{ .data = 2 };

    // {} {} -> { 0 1 { 2 } 3 }
    //
    h0.extend(&ds0);
    ds0[1].attachMultiRing(&h1);
    h1.append(&d1);
    try expectEqual(&ds0[1], ds0[0].stepUntilHeadZ(&h1).?);
    try expectNull(ds0[1].stepUntilHeadZ(&h1));
    try expectEqual(&d1, ds0[1].stepUntilHeadZ(&h0).?);
    try expectNull(d1.stepUntilHeadZ(&h1));
    try expectEqual(&ds0[2], d1.stepUntilHeadZ(&h0).?);
    try expectNull(ds0[2].stepUntilHeadZ(&h1));

    // { 0 1 { 2 } 3 } -> { 0 1 { 2 . 3 }
    //
    h1.open();
    try expectNull(ds0[2].stepUntilHeadZ(&h0));
}

test "MultiRing(u8).HeadNode.countBelow" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 2 },
    };
    var h1 = M.HeadNode{};
    var d1 = M.DataNode{ .data = 1 };

    // {} {} -> { 0 { 1 } 2 }
    //
    h0.extend(&ds0);
    ds0[0].attachMultiRing(&h1);
    h1.append(&d1);
    try expectEqual(@as(usize, 3), h0.countBelow());
    try expectEqual(@as(usize, 1), h1.countBelow());

    // { 0 { 1 } 2 } -> { 0 { 1 . 2 }
    //
    h1.open();
    try expectEqual(@as(usize, 2), h0.countBelow());
}

test "MultiRing(u8).HeadNode.step{Above,Z}" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
    };
    var h1 = M.HeadNode{};
    var h2 = M.HeadNode{};
    var d2 = M.DataNode{ .data = 3 };
    var h3 = M.HeadNode{};
    var h4 = M.HeadNode{};

    // {} {} {} {} {} -> { 0 {} 1 { 3 {} } 2 {} }
    //
    h0.extend(&ds0);
    ds0[0].attachMultiRing(&h1);
    ds0[1].attachMultiRing(&h2);
    h2.append(&d2);
    d2.attachMultiRing(&h3);
    ds0[2].attachMultiRing(&h4);
    try expectEqual(&ds0[0], h0.stepZ().?);
    try expectEqual(&ds0[1], h1.stepAbove().?);
    try expectEqual(&ds0[1], h1.stepZ().?);
    try expectEqual(&ds0[2], h3.stepAbove().?);
    try expectEqual(&ds0[2], h3.stepZ().?);
    try expectNull(h4.stepAbove());
    try expectNull(h4.stepZ());
}

test "MultiRing(u8).DataNode.{step,countAfter}Z" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
        .{ .data = 4 },
    };
    var h1 = M.HeadNode{};
    var h2 = M.HeadNode{};
    var d2 = M.DataNode{ .data = 3 };

    // {} {} {} -> { 0 1 {} 2 { 3 } 4 }
    //
    h0.extend(&ds0);
    ds0[1].attachMultiRing(&h1);
    ds0[2].attachMultiRing(&h2);
    h2.append(&d2);
    try expectEqual(&ds0[1], ds0[0].stepZ().?);
    try expectEqual(&ds0[2], ds0[1].stepZ().?);
    try expectEqual(&d2, ds0[2].stepZ().?);
    try expectEqual(&ds0[3], d2.stepZ().?);
    try expectNull(ds0[3].stepZ());
    try expectEqual(@as(usize, 4), ds0[0].countAfterZ());

    // { 0 1 {} 2 { 3 } 4 } -> { 0 1 {} 2 { 3 } 4 .
    //
    h0.open();
    try expectNull(ds0[3].stepZ());

    // { 0 1 {} 2 { 3 } 4 . -> { 0 1 {} 2 { 3 . 4 .
    //
    h2.open();
    try expectEqual(@as(usize, 0), d2.countAfterZ());
}

test "MultiRing(u8).HeadNode.countAbove" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 3 },
    };
    var h1 = M.HeadNode{};
    var h2 = M.HeadNode{};
    var d2 = M.DataNode{ .data = 2 };
    var h3 = M.HeadNode{};
    var h4 = M.HeadNode{};

    // {} {} {} {} {} -> { 0 {} 1 { 2 {} } 3 {} }
    //
    h0.extend(&ds0);
    ds0[0].attachMultiRing(&h1);
    ds0[1].attachMultiRing(&h2);
    h2.append(&d2);
    d2.attachMultiRing(&h3);
    ds0[2].attachMultiRing(&h4);
    try expectEqual(@as(usize, 3), h1.countAbove());
    try expectEqual(@as(usize, 1), h2.countAbove());
    try expectEqual(@as(usize, 1), h3.countAbove());
    try expectEqual(@as(usize, 0), h4.countAbove());

    // { 0 {} 1 { 2 {} } 3 {} } -> { 0 {} 1 { 2 {} . 3 {} }
    //
    h2.open();
    try expectEqual(@as(usize, 2), h1.countAbove());
}

test "MultiRing(u8).DataNode.findLastZ" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 2 },
    };
    var h1 = M.HeadNode{};
    var d1 = M.DataNode{ .data = 1 };

    // {} {} -> { 0 } {}
    //
    h0.append(&ds0[0]);
    try expectEqual(&ds0[0], ds0[0].findLastZ());

    // { 0 } {} -> { 0 { 1 } }
    //
    ds0[0].attachMultiRing(&h1);
    h1.append(&d1);
    try expectEqual(&d1, ds0[0].findLastZ());
    try expectEqual(&d1, d1.findLastZ());

    // { 0 { 1 } } -> { 0 { 1 } 2 }
    //
    h0.append(&ds0[1]);
    try expectEqual(&ds0[1], ds0[0].findLastZ());
    try expectEqual(&ds0[1], d1.findLastZ());

    // { 0 { 1 } 2 } -> { 0 { 1 . 2 }
    //
    h1.open();
    try expectEqual(&d1, ds0[0].findLastZ());
    try expectEqual(&d1, d1.findLastZ());
}

test "MultiRing(u8).HeadNode.findLast{Above,Below}" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 4 },
    };
    var h1 = M.HeadNode{};
    var h2 = M.HeadNode{};
    var d2 = M.DataNode{ .data = 2 };
    var h3 = M.HeadNode{};
    var d3 = M.DataNode{ .data = 3 };

    // {} {} {} {} -> { 0 {} 1 { 2 { 3 } } }
    //
    h0.extend(ds0[0..2]);
    ds0[0].attachMultiRing(&h1);
    ds0[1].attachMultiRing(&h2);
    h2.append(&d2);
    d2.attachMultiRing(&h3);
    h3.append(&d3);
    try expectEqual(&d3, h1.findLastAbove().?);
    try expectNull(h2.findLastAbove());
    try expectNull(h3.findLastAbove());
    try expectEqual(&d3, h0.findLastBelow().?);

    // { 0 {} 1 { 2 { 3 } } } -> { 0 {} 1 { 2 { 3 } . 4 }
    //
    h0.append(&ds0[2]);
    h2.open();
    try expectEqual(&ds0[2], h0.findLastBelow().?);
    try expectNull(h3.findLastAbove());
}

test "MultiRing(u8).DataNode.removeAfterZ" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
        .{ .data = 7 },
        .{ .data = 8 },
    };
    var h1 = M.HeadNode{};
    var ds1 = [_]M.DataNode{
        .{ .data = 3 },
        .{ .data = 4 },
        .{ .data = 6 },
    };
    var h2 = M.HeadNode{};
    var d2 = M.DataNode{ .data = 5 };

    // {} {} {} -> { 0 1 2 { 3 4 { 5 } 6 } 7 8 }
    //
    h0.extend(&ds0);
    ds0[2].attachMultiRing(&h1);
    h1.extend(&ds1);
    ds1[1].attachMultiRing(&h2);
    h2.append(&d2);
    try expectEqual(@as(usize, 9), h0.countBelow());

    // { 0 1 2 { 3 4 { 5 } 6 } 7 8 } -> { 0 1 2 { 3 4 { 5 } 6 } 7 8 }
    //
    try expect(!ds0[0].removeAfterZ(&ds0[0]));
    try expectEqual(@as(usize, 9), h0.countBelow());

    // { 0 1 2 { 3 4 { 5 } 6 } 7 8 } -> { 0 2 { 3 4 { 5 } 6 } 7 8 }
    //
    try expect(ds0[0].removeAfterZ(&ds0[1]));
    try expectEqual(&ds0[2], ds0[0].step().?);
    try expectEqual(@as(usize, 8), h0.countBelow());

    // { 0 2 { 3 4 { 5 } 6 } 7 8 } -> { 0 2 { 3 4 { 5 . 6 } 7 8 }
    //
    h2.open();
    try expectEqual(@as(usize, 5), h0.countBelow());

    // { 0 2 { 3 4 { 5 . 6 } 7 8 } -> { 0 2 { 3 4 { 5 . } 7 8 }
    //
    try expect(ds1[0].removeAfterZ(&ds1[2]));
    try expectNull(ds1[1].step());
    try expectEqual(@as(usize, 5), h0.countBelow());

    // { 0 2 { 3 4 { 5 . } 7 8 } -> { 0 2 { 3 4 { 5 } } 7 8 }
    //
    h2.close();
    try expectEqual(@as(usize, 7), h0.countBelow());

    // { 0 2 { 3 4 { 5 } } 7 8 } -> { 0 2 { 4 { 5 } } 7 8 }
    //
    try expect(ds0[2].removeAfterZ(&ds1[0]));
    try expectEqual(&ds1[1], h1.step().?);
    try expectEqual(@as(usize, 6), h0.countBelow());

    // { 0 2 { 4 { 5 } } 7 8 } -> { 0 2 { 4 { 5 } } 7 }
    //
    try expect(d2.removeAfterZ(&ds0[4]));
    try expectNull(ds0[3].step());
    try expectEqual(@as(usize, 5), h0.countBelow());

    // { 0 2 { 4 { 5 } } 7 } -> { 0 2 { 4 { 5 } . 7 }
    //
    h1.open();
    try expect(!d2.removeAfterZ(&ds0[3]));
    try expectEqual(@as(usize, 4), h0.countBelow());

    // { 0 2 { 4 { 5 } . 7 } -> { 0 2 { 4 { 5 . . 7 }
    //
    h2.open();
    try expect(!d2.removeAfterZ(&ds0[3]));
    try expectEqual(@as(usize, 4), h0.countBelow());
}

test "MultiRing(u8).HeadNode.removeAbove" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 4 },
        .{ .data = 5 },
    };
    var h1 = M.HeadNode{};
    var h2 = M.HeadNode{};
    var d2 = M.DataNode{ .data = 2 };
    var h3 = M.HeadNode{};
    var d3 = M.DataNode{ .data = 3 };

    // {} {} {} {} -> { 0 {} 1 { 2 { 3 } } 4 5 }
    //
    h0.extend(&ds0);
    ds0[0].attachMultiRing(&h1);
    ds0[1].attachMultiRing(&h2);
    h2.append(&d2);
    d2.attachMultiRing(&h3);
    h3.append(&d3);
    try expectEqual(@as(usize, 6), h0.countBelow());

    // { 0 {} 1 { 2 { 3 } } 4 5 } -> { 0 {} 1 { 2 { 3 } } 4 5 }
    //
    try expect(!h1.removeAbove(&ds0[0]));
    try expectEqual(@as(usize, 6), h0.countBelow());

    // { 0 {} 1 { 2 { 3 } } 4 5 } -> { 0 {} 1 { 2 {} } 4 5 }
    //
    try expect(h1.removeAbove(&d3));
    try expectNull(h3.step());
    try expectEqual(@as(usize, 5), h0.countBelow());

    // { 0 {} 1 { 2 {} } 4 5 } -> { 0 {} 1 { 2 {} } 4 }
    //
    try expect(h3.removeAbove(&ds0[3]));
    try expectNull(ds0[2].step());
    try expectEqual(@as(usize, 4), h0.countBelow());

    // { 0 {} 1 { 2 {} } 4 } -> { 0 {} 1 { 2 {} . 4 }
    //
    h2.open();
    try expect(!h3.removeAbove(&ds0[2]));
    try expectEqual(@as(usize, 3), h0.countBelow());
}

test "MultiRing(u8).HeadNode.removeBelow" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var ds0 = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
    };
    var h1 = M.HeadNode{};
    var ds1 = [_]M.DataNode{
        .{ .data = 2 },
        .{ .data = 4 },
        .{ .data = 5 },
    };
    var h2 = M.HeadNode{};
    var d2 = M.DataNode{ .data = 3 };

    // {} {} {} -> { 0 1 { 2 { 3 } 4 5 } }
    //
    h0.extend(&ds0);
    ds0[1].attachMultiRing(&h1);
    h1.extend(&ds1);
    ds1[0].attachMultiRing(&h2);
    h2.append(&d2);
    try expectEqual(@as(usize, 6), h0.countBelow());

    // { 0 1 { 2 { 3 } 4 5 } } -> { 1 { 2 { 3 } 4 5 } }
    //
    try expect(h0.removeBelow(&ds0[0]));
    try expectEqual(&ds0[1], h0.step().?);
    try expectEqual(@as(usize, 5), h0.countBelow());

    // { 1 { 2 { 3 } 4 5 } } -> { 1 { 2 { 3 } 4 5 } }
    //
    try expect(!h1.removeBelow(&ds0[1]));
    try expectEqual(@as(usize, 5), h0.countBelow());

    // { 1 { 2 { 3 } 4 5 } } -> { 1 { 2 { 3 . 4 5 } }
    //
    h2.open();
    try expect(!h1.removeBelow(&ds1[2]));
    try expectEqual(@as(usize, 3), h0.countBelow());

    // { 1 { 2 { 3 . 4 5 } } -> { 1 { 2 { 3 . 5 } }
    //
    try expect(h1.removeBelow(&ds1[1]));
    try expectEqual(&ds1[2], ds1[0].step().?);
    try expectEqual(@as(usize, 3), h0.countBelow());

    // { 1 { 2 { 3 . 5 } } -> { 1 { 2 { 3 } 5 } }
    //
    h2.close();
    try expectEqual(@as(usize, 4), h0.countBelow());

    // { 1 { 2 { 3 } 5 } } -> { 1 { 2 { 3 } } }
    //
    try expect(h1.removeBelow(&ds1[2]));
    try expectEqual(&ds1[0], h1.step().?);
    try expectEqual(@as(usize, 3), h0.countBelow());

    // { 1 { 2 { 3 } } } -> { 1 { 2 {} } }
    //
    try expect(h1.removeBelow(&d2));
    try expectNull(h2.step());
    try expectEqual(@as(usize, 2), h0.countBelow());
}

test "rootless multiring" {
    const M = MultiRing(u8);
    var x = M.DataNode{ .data = 0xAA };
    var m = M{};
    try expect(m.isEmpty());
    try expectEqual(@as(usize, 0), m.len());
    try expectNull(m.findLast());
    try expect(!m.remove(&x));
}

test "multiring comprising one nonempty ring" {
    const M = MultiRing(u8);
    var h = M.HeadNode{};
    var ds = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
    };
    var m = M{ .root = &h };

    // {} -> { 0 }
    //
    m.append(&ds[0]);
    try expect(!m.isEmpty());
    try expectEqual(@as(usize, 1), m.len());
    try expectEqual(&ds[0], m.findLast().?);

    // { 0 } -> {}
    //
    try expect(m.remove(&ds[0]));
    try expect(m.isEmpty());
    try expectEqual(@as(usize, 0), m.len());
    try expectNull(m.findLast());

    // {} -> { 0 1 }
    //
    m.extend(&ds);
    try expect(!m.isEmpty());
    try expectEqual(@as(usize, 2), m.len());
    try expectEqual(&ds[1], m.findLast().?);

    // { 0 1 } -> {}
    //
    m.clear();
    try expect(m.isEmpty());
    try expectEqual(@as(usize, 0), m.len());
}

test "multiring extension" {
    const M = MultiRing(u8);
    var h0 = M.HeadNode{};
    var h1 = M.HeadNode{};
    var h2 = M.HeadNode{};
    var h3 = M.HeadNode{};
    var ds = [_]M.DataNode{
        .{ .data = 0 },
        .{ .data = 1 },
        .{ .data = 2 },
        .{ .data = 3 },
        .{ .data = 4 },
        .{ .data = 5 },
        .{ .data = 6 },
    };
    var m = M{ .root = &h0 };

    // {} {} {} {} -> { 0 { 1 } } {} {}
    //
    h0.append(&ds[0]);
    ds[0].attachMultiRing(&h1);
    h1.append(&ds[1]);
    try expectEqual(@as(usize, 2), m.len());

    // { 0 { 1 } } {} {} -> { 0 { 1 2 } } {} {}
    //
    m.append(&ds[2]);
    try expectEqual(&ds[2], ds[1].step().?);
    try expectEqual(@as(usize, 3), m.len());

    // { 0 { 1 2 } } {} {} -> { 0 { 1 2 } 3 { 4 {} } }
    //
    h0.append(&ds[3]);
    ds[3].attachMultiRing(&h2);
    h2.append(&ds[4]);
    ds[4].attachMultiRing(&h3);
    try expectEqual(@as(usize, 5), m.len());

    // { 0 { 1 2 } 3 { 4 {} } } -> { 0 { 1 2 } 3 { 4 {} 5 6 } }
    //
    m.extend(ds[5..]);
    try expectEqual(&ds[5], ds[4].step().?);
    try expectEqual(&ds[6], ds[5].step().?);
    try expectEqual(@as(usize, 7), m.len());
}
