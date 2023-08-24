const std = @import("std");

pub fn build(b: *std.Build) void {
    const module = b.addModule("multiring", .{ .source_file = .{ .path = "src/multiring.zig" } });

    const test_step = b.step("test", "Run module and example tests");

    const test_paths = [_][]const u8{
        "src/multiring_test.zig",
        "examples/automultiring.zig",
    };
    for (test_paths) |root_path| {
        const t = b.addTest(.{ .root_source_file = .{ .path = root_path } });
        t.addModule("multiring", module);
        const run = b.addRunArtifact(t);
        test_step.dependOn(&run.step);
    }
}
