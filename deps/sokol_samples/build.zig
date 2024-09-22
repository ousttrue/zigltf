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

    for (samples) |sample| {
        const exe = b.addExecutable(.{
            .target = target,
            .optimize = optimize,
            .name = sample.name,
            .root_source_file = b.path(sample.root_source_file),
        });
        const install = b.addInstallArtifact(exe, .{});
        b.getInstallStep().dependOn(&install.step);

        // generate .glsl.zig
        const shdc = sokol_tool.runShdcCommand(
            b,
            target,
            b.path(sample.sokol_shader).getPath(b),
        );
        exe.step.dependOn(&shdc.step);

        exe.root_module.addImport("sokol", sokol_dep.module("sokol"));
        exe.root_module.addImport("rowmath", rowmath_dep.module("rowmath"));
        exe.root_module.addImport("zigltf", zigltf_dep.module("zigltf"));
    }
}

const Sample = struct {
    name: []const u8,
    root_source_file: []const u8,
    sokol_shader: []const u8,
};

pub const samples = [_]Sample{
    .{
        .name = "minimal",
        .root_source_file = "minimal/main.zig",
        .sokol_shader = "minimal/gltf.glsl",
    },
};
