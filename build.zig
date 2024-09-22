const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zigltf_dep = b.dependency("zigltf", .{
        .target = target,
        .optimize = optimize,
    });
    _ = b.addModule("zigltf", .{
        .root_source_file = zigltf_dep.module("zigltf").root_source_file,
        .target = target,
        .optimize = optimize,
    });

    if (b.option(bool, "sokol", "build sokol samples") orelse false) {
        const sokol_build = @import("sokol_samples");
        const sokol_deps = b.dependency("sokol_samples", .{
            .target = target,
            .optimize = optimize,
        });

        for (sokol_build.samples) |sample| {
            const artifact = sokol_deps.artifact(sample.name);

            const install = b.addInstallArtifact(artifact, .{});
            b.getInstallStep().dependOn(&install.step);

            const run = b.addRunArtifact(artifact);
            run.step.dependOn(&install.step);

            b.step(
                b.fmt("run-{s}", .{sample.name}),
                b.fmt("run sokol_samples {s}", .{sample.name}),
            ).dependOn(&run.step);
        }
    }

    // if (b.option(bool, "test", "build tests") orelse false) {}
}
