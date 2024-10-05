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
        const samples_build = @import("sokol_samples");
        const samples_deps = b.dependency("sokol_samples", .{
            .target = target,
            .optimize = optimize,
        });

        const asset_wf = samples_deps.namedWriteFiles("assets");
        const asset_install = b.addInstallDirectory(.{
            .source_dir = asset_wf.getDirectory(),
            .install_dir = .prefix,
            .install_subdir = "web",
        });

        if (target.result.isWasm()) {
            const wasm_wf = samples_deps.namedWriteFiles("wasm");
            const wasm_install = b.addInstallDirectory(.{
                .source_dir = wasm_wf.getDirectory(),
                .install_dir = .prefix,
                .install_subdir = "",
            });
            b.getInstallStep().dependOn(&wasm_install.step);
            b.getInstallStep().dependOn(&asset_install.step);
        } else {
            for (samples_build.samples) |sample| {
                const artifact = samples_deps.artifact(sample.name);

                const install = b.addInstallArtifact(artifact, .{});
                install.step.dependOn(&asset_install.step);
                b.getInstallStep().dependOn(&install.step);

                const run = b.addRunArtifact(artifact);
                run.step.dependOn(&install.step);
                run.setCwd(b.path("zig-out/web"));

                b.step(
                    b.fmt("run-{s}", .{sample.name}),
                    b.fmt("run sokol_samples {s}", .{sample.name}),
                ).dependOn(&run.step);
            }
        }
    }

    // if (b.option(bool, "test", "build tests") orelse false) {}
}
