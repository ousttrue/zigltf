const std = @import("std");
const builtin = @import("builtin");
const sokol_tool = @import("sokol_tool.zig");
const emsdk_zig = @import("emsdk-zig");

const debug_flags = [_][]const u8{
    "-sASSERTIONS",
    // "-g4",
    "-gsource-map",
};

const release_flags = [_][]const u8{};

const emcc_extra_args = [_][]const u8{
    // default 64MB
    "-sSTACK_SIZE=128MB",
    // must TOTAL_MEMORY > STACK_SIZE
    "-sTOTAL_MEMORY=512MB",
    "-sALLOW_MEMORY_GROWTH=0",
    "-sUSE_OFFSET_CONVERTER=1",
    "-sSTB_IMAGE=1",
} ++ (if (builtin.mode == .Debug) debug_flags else release_flags);

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

    // asset
    {
        const test_models = b.dependency("gltf-test-models", .{});
        const asset_wf = b.addNamedWriteFiles("glTF-Sample-Assets");
        {
            const wf = test_models.namedWriteFiles("glTF-Sample-Assets");
            _ = asset_wf.addCopyDirectory(wf.getDirectory(), "", .{});
        }
        b.default_step.dependOn(&asset_wf.step);
    }
    {
        const test_models = b.dependency("univrm", .{});
        const asset_wf = b.addNamedWriteFiles("UniVRM");
        {
            // const wf = test_models.namedWriteFiles("UniVRM");
            _ = asset_wf.addCopyFile(
                test_models.path("Tests/Models/Alicia_vrm-0.51/AliciaSolid_vrm-0.51.vrm"),
                "AliciaSolid_vrm-0.51.vrm",
            );
        }
        b.default_step.dependOn(&asset_wf.step);
    }

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
    if (!target.result.isWasm()) {
        const stb_dep = b.dependency("stb", .{});
        sample_framework.addIncludePath(stb_dep.path(""));
        sample_framework.addCSourceFile(.{
            .file = b.path("sample_framework/stb/stb.c"),
        });
    }

    // create a build step which invokes the Emscripten linker
    var emsdk_dep_: ?*std.Build.Dependency = null;
    if (target.result.isWasm()) {
        const emsdk_zig_dep = b.dependency("emsdk-zig", .{});
        const emsdk_dep = emsdk_zig_dep.builder.dependency("emsdk", .{});
        emsdk_dep_ = emsdk_dep;
    }
    const wasm_wf = b.addNamedWriteFiles("wasm");
    b.default_step.dependOn(&wasm_wf.step);

    for (samples) |sample| {
        const compiled = if (target.result.isWasm()) block: {
            const lib = b.addStaticLibrary(.{
                .target = target,
                .optimize = optimize,
                .name = sample.name,
                .root_source_file = b.path(sample.root_source_file),
            });
            break :block lib;
        } else block: {
            const exe = b.addExecutable(.{
                .target = target,
                .optimize = optimize,
                .name = sample.name,
                .root_source_file = b.path(sample.root_source_file),
            });

            // install artifact
            const install = b.addInstallArtifact(exe, .{});
            b.getInstallStep().dependOn(&install.step);

            break :block exe;
        };

        compiled.root_module.addImport("sokol", sokol_dep.module("sokol"));
        compiled.root_module.addImport("rowmath", rowmath_dep.module("rowmath"));
        compiled.root_module.addImport("zigltf", zigltf_dep.module("zigltf"));
        compiled.root_module.addImport("framework", &sample_framework.root_module);
        compiled.step.dependOn(&sample_framework.step);

        if (target.result.isWasm()) {
            // create a build step which invokes the Emscripten linker
            const emsdk_dep = emsdk_dep_.?;
            const emcc = try emsdk_zig.emLinkCommand(b, emsdk_dep, .{
                .lib_main = compiled,
                .target = target,
                .optimize = optimize,
                .use_webgl2 = true,
                .use_emmalloc = true,
                .use_filesystem = true,
                .shell_file_path = sokol_dep.path("src/sokol/web/shell.html").getPath(b),
                .release_use_closure = false,
                .extra_before = &emcc_extra_args,
            });

            emcc.addArg("-o");
            const out_file = emcc.addOutputFileArg(b.fmt("{s}.html", .{compiled.name}));

            // copy wasm to namedWriteFiles
            _ = wasm_wf.addCopyDirectory(out_file.dirname(), "web", .{});
            wasm_wf.step.dependOn(&emcc.step);

            const emsdk_incl_path = emsdk_dep.path(
                "upstream/emscripten/cache/sysroot/include",
            );
            compiled.addSystemIncludePath(emsdk_incl_path);
        }
    }
}

const Sample = struct {
    name: []const u8,
    root_source_file: []const u8,
};

pub const samples = [_]Sample{
    .{
        .name = "minimal",
        .root_source_file = "tutorials/minimal/main.zig",
    },
    .{
        .name = "sparse",
        .root_source_file = "tutorials/sparse/main.zig",
    },
    .{
        .name = "animation",
        .root_source_file = "tutorials/animation/main.zig",
    },
    .{
        .name = "simple_meshes",
        .root_source_file = "tutorials/simple_meshes/main.zig",
    },
    .{
        .name = "simple_material",
        .root_source_file = "tutorials/simple_material/main.zig",
    },
    .{
        .name = "simple_texture",
        .root_source_file = "tutorials/simple_texture/main.zig",
    },
    //
    .{
        .name = "glb",
        .root_source_file = "glb/main.zig",
    },
    .{
        .name = "gltf",
        .root_source_file = "gltf/main.zig",
    },
    .{
        .name = "draco",
        .root_source_file = "draco/main.zig",
    },
    .{
        .name = "vrm0",
        .root_source_file = "vrm0/main.zig",
    },
};
