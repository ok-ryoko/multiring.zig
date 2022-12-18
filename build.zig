const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const lib = b.addStaticLibrary("multiring", "src/multiring.zig");
    lib.setBuildMode(mode);
    lib.setTarget(target);
    lib.install();

    const tests = b.addTest("src/multiring.zig");
    tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&tests.step);
}
