const std = @import("std");
const sokol = @import("sokol");
const rowmath = @import("rowmath");
const zigltf = @import("zigltf");

const GltfCallback = fn (
    gltf: std.json.Parsed(zigltf.Gltf),
    binmap: std.StringHashMap([]const u8),
) void;

const Task = union(enum) {
    gltf: struct {
        path: []const u8,
        callback: *const GltfCallback,
    },
    image: struct {
        index: u32,
        callback: *const GltfCallback,
    },
    buffer: struct {
        index: u32,
        callback: *const GltfCallback,
    },
};

pub const state = struct {
    var allocator: std.mem.Allocator = undefined;
    pub var status: [:0]const u8 = "fetch gltf...";
    var status_buffer: [1024]u8 = undefined;
    var tasks: [32]Task = undefined;
    var task_count: u32 = 0;
    var fetch_buffer: [1024 * 1024 * 32]u8 = undefined;
    //
    var json: ?std.json.Parsed(zigltf.Gltf) = null;
    var binmap: std.StringHashMap([]const u8) = undefined;
};

pub fn init(allocator: std.mem.Allocator) void {
    state.allocator = allocator;
    state.binmap = std.StringHashMap([]const u8).init(allocator);

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
    defer state.task_count += 1;

    _ = sokol.fetch.send(.{
        .path = &path[0],
        .callback = fetch_callback,
        .buffer = sokol.fetch.asRange(&state.fetch_buffer),
        .user_data = sokol.fetch.asRange(&state.tasks[state.task_count]),
    });
}

fn fetch_image(index: u32, on_gltf: *const GltfCallback) !void {
    const parsed = state.json orelse {
        return error.no_gltf;
    };

    if (index >= parsed.value.images.len) {
        on_gltf(parsed, state.binmap);
    } else {
        // fetch next
        const image = parsed.value.images[index];

        if (image.uri) |uri| {
            state.status = std.fmt.bufPrintZ(
                &state.status_buffer,
                "fetch image[{}]: {s}\n",
                .{ index, uri },
            ) catch @panic("bufPrintZ");

            state.tasks[state.task_count] = .{
                .image = .{
                    .index = index,
                    .callback = on_gltf,
                },
            };
            defer state.task_count += 1;

            const uriz = try std.fmt.allocPrintZ(state.allocator, "{s}", .{uri});

            _ = sokol.fetch.send(.{
                .path = &uriz[0],
                .callback = fetch_callback,
                .buffer = sokol.fetch.asRange(&state.fetch_buffer),
                .user_data = sokol.fetch.asRange(&state.tasks[state.task_count]),
            });
        } else {
            try fetch_image(index + 1, on_gltf);
        }
    }
}

fn to_slice(ptr: [*]const u8, size: usize) []const u8 {
    return ptr[0..size];
}

fn get_glb(gltf_or_glb: []const u8) zigltf.Glb {
    if (zigltf.Glb.parse(gltf_or_glb)) |glb| {
        return glb;
    } else {
        return .{ .json_bytes = gltf_or_glb };
    }
}

pub fn set_gltf(
    parsed: std.json.Parsed(zigltf.Gltf),
    _bin: ?[]const u8,
    callback: *const GltfCallback,
) !void {
    state.json = parsed;
    if (_bin) |bin| {
        try state.binmap.put("", bin);
    }

    try fetch_image(0, callback);
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

                const bytes = to_slice(
                    @ptrCast(response.*.data.ptr),
                    response.*.data.size,
                );

                const glb = get_glb(bytes);

                if (std.json.parseFromSlice(
                    zigltf.Gltf,
                    state.allocator,
                    glb.json_bytes,
                    .{
                        .ignore_unknown_fields = true,
                    },
                )) |parsed| {
                    set_gltf(parsed, glb.bin, gltf_task.callback) catch @panic("set_gltf");
                } else |e| {
                    state.status = std.fmt.bufPrintZ(
                        &state.status_buffer,
                        "fail to parse: {s}",
                        .{@errorName(e)},
                    ) catch @panic("bufPrintZ");
                }
            },
            .image => |image_task| {
                const bytes = to_slice(
                    @ptrCast(response.*.data.ptr),
                    response.*.data.size,
                );

                const parsed = state.json orelse {
                    @panic("no gltf");
                };

                const image = parsed.value.images[image_task.index];
                const uri = image.uri orelse {
                    @panic("no uri");
                };

                state.binmap.put(uri, bytes) catch @panic("put");

                fetch_image(image_task.index + 1, image_task.callback) catch @panic("fetch_image");
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
