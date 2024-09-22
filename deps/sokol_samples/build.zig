const std = @import("std");
const sokol_tool = @import("sokol_tool.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zigltf_dep = b.dependency("zigltf", .{});

    const sokol_dep = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
        // .with_sokol_imgui = true,
    });

    const rowmath_dep = b.dependency("rowmath", .{
        .target = target,
        .optimize = optimize,
    });

    const test_models = b.dependency("gltf-test-models", .{});
    const wf = test_models.namedWriteFiles("glTF-Sample-Assets");

    const out_wf = b.addNamedWriteFiles("glTF-Sample-Assets");
    _ = out_wf.addCopyDirectory(wf.getDirectory(), "", .{});
    b.default_step.dependOn(&out_wf.step);

    // sample_framework
    const sample_framework = b.addStaticLibrary(.{
        .target = target,
        .optimize = optimize,
        .name = "sample_framework",
        .root_source_file = b.path("sample_framework/main.zig"),
    });
    // generate .glsl.zig
    const shdc = sokol_tool.runShdcCommand(
        b,
        target,
        b.path("sample_framework/gltf.glsl").getPath(b),
    );
    sample_framework.step.dependOn(&shdc.step);
    sample_framework.root_module.addImport("sokol", sokol_dep.module("sokol"));
    sample_framework.root_module.addImport("zigltf", zigltf_dep.module("zigltf"));
    sample_framework.root_module.addImport("rowmath", rowmath_dep.module("rowmath"));

    for (samples) |sample| {
        const exe = b.addExecutable(.{
            .target = target,
            .optimize = optimize,
            .name = sample.name,
            .root_source_file = b.path(sample.root_source_file),
        });
        const install = b.addInstallArtifact(exe, .{});
        b.getInstallStep().dependOn(&install.step);

        exe.root_module.addImport("sokol", sokol_dep.module("sokol"));
        exe.root_module.addImport("rowmath", rowmath_dep.module("rowmath"));
        exe.root_module.addImport("zigltf", zigltf_dep.module("zigltf"));
        exe.root_module.addImport("framework", &sample_framework.root_module);
        exe.step.dependOn(&sample_framework.step);
    }
}

const Sample = struct {
    name: []const u8,
    root_source_file: []const u8,
};

// .sokol_shader = "minimal/gltf.glsl",

pub const samples = [_]Sample{
    .{
        .name = "minimal",
        .root_source_file = "minimal/main.zig",
    },
};
