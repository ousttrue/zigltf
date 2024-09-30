const std = @import("std");
const sokol = @import("sokol");
const rowmath = @import("rowmath");
const zigltf = @import("zigltf");

const GltfCallback = fn (gltf: std.json.Parsed(zigltf.Gltf), bin: ?[]const u8) void;

const Task = union(enum) {
    gltf: struct {
        path: []const u8,
        callback: *const GltfCallback,
    },
    buffer: struct {
        path: []const u8,
        buffer_index: u32,
    },
};

pub const state = struct {
    var allocator: std.mem.Allocator = undefined;
    pub var status: [:0]const u8 = "loading...";
    var status_buffer: [1024]u8 = undefined;
    var tasks: [32]Task = undefined;
    var task_count: u32 = 0;
    var fetch_buffer: [1024 * 1024 * 32]u8 = undefined;
};

pub fn init(allocator: std.mem.Allocator) void {
    state.allocator = allocator;

    // setup sokol-fetch with 2 channels and 6 lanes per channel,
    // we'll use one channel for mesh data and the other for textures
    sokol.fetch.setup(.{
        .max_requests = 8,
        .num_channels = 1,
        .num_lanes = 8,
        .logger = .{ .func = sokol.log.func },
    });
}

pub fn fetch_gltf(path: [:0]const u8, on_gltf: *const GltfCallback) !void {
    state.tasks[state.task_count] = .{
        .gltf = .{
            .path = path,
            .callback = on_gltf,
        },
    };

    _ = sokol.fetch.send(.{
        .path = &path[0],
        .callback = fetch_callback,
        .buffer = sokol.fetch.asRange(&state.fetch_buffer),
        .user_data = sokol.fetch.asRange(&state.tasks[state.task_count]),
    });

    state.task_count += 1;
}

fn toSlice(ptr: [*]const u8, size: usize) []const u8 {
    return ptr[0..size];
}

fn getGlb(gltf_or_glb: []const u8) zigltf.Glb {
    if (zigltf.Glb.parse(gltf_or_glb)) |glb| {
        return glb;
    } else {
        return .{ .json_bytes = gltf_or_glb };
    }
}

export fn fetch_callback(response: [*c]const sokol.fetch.Response) void {
    std.debug.print("fetch_callback\n", .{});
    if (response.*.fetched) {
        const user: *const Task = @ptrCast(@alignCast(response.*.user_data));
        switch (user.*) {
            .gltf => |gltf_task| {
                state.status = std.fmt.bufPrintZ(
                    &state.status_buffer,
                    "{}bytes\n",
                    .{response.*.data.size},
                ) catch @panic("bufPrintZ");

                const bytes = toSlice(
                    @ptrCast(response.*.data.ptr),
                    response.*.data.size,
                );

                const glb = getGlb(bytes);

                if (std.json.parseFromSlice(
                    zigltf.Gltf,
                    state.allocator,
                    glb.json_bytes,
                    .{
                        .ignore_unknown_fields = true,
                    },
                )) |parsed| {
                    // defer parsed.deinit();
                    state.status = "parsed";
                    gltf_task.callback(parsed, glb.bin);
                } else |e| {
                    // std.debug.print("{s}\n", .{glb.json_bytes});
                    state.status = std.fmt.bufPrintZ(
                        &state.status_buffer,
                        "fail to parse: {s}",
                        .{@errorName(e)},
                    ) catch @panic("bufPrintZ");
                }
            },
            .buffer => |buffer_task| {
                _ = buffer_task;
                unreachable;
            },
        }
    } else if (response.*.failed) {
        state.status = "fetch fail";
    }
}
