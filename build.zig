const std = @import("std");

pub fn build(b: *std.Build) void {
    const module = b.addModule("multiring", .{
        .source_file = .{ .path = "src/multiring.zig" },
    });

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/multiring_test.zig" },
    });
    tests.addModule("multiring", module);

    const test_step = b.step("test", "Run module tests");
    var run = b.addRunArtifact(tests);
    test_step.dependOn(&run.step);
}
