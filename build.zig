const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule(
        "multiring",
        .{ .root_source_file = b.path("src/multiring.zig") },
    );

    const test_step = b.step("test", "Run module and example tests");

    const test_paths = [_][]const u8{
        "src/multiring_test.zig",
        "examples/automultiring.zig",
    };
    for (test_paths) |root_path| {
        const test_exe = b.addTest(.{
            .root_source_file = b.path(root_path),
            .target = target,
            .optimize = optimize,
        });
        test_exe.root_module.addImport("multiring", module);

        const run_test = b.addRunArtifact(test_exe);
        test_step.dependOn(&run_test.step);
    }
}
