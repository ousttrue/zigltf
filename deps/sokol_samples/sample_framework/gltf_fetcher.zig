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
    var path: []const u8 = undefined;
    var json: std.json.Parsed(zigltf.Gltf) = undefined;
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
    state.path = path;
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

fn fetch_buffer(index: u32, on_gltf: *const GltfCallback) !void {
    const parsed = state.json;

    if (index >= parsed.value.buffers.len) {
        try fetch_image(0, on_gltf);
    } else {
        // fetch next
        const buffer = parsed.value.buffers[index];

        if (buffer.uri) |uri| {
            if (zigltf.Buffer.base64DecodeSize(uri)) |_| {
                try fetch_buffer(index + 1, on_gltf);
            } else {
                state.status = std.fmt.bufPrintZ(
                    &state.status_buffer,
                    "fetch buffer[{}]: {s}\n",
                    .{ index, uri },
                ) catch @panic("bufPrintZ");

                state.tasks[state.task_count] = .{
                    .buffer = .{
                        .index = index,
                        .callback = on_gltf,
                    },
                };
                defer state.task_count += 1;

                // const base = ;
                const uriz = if (std.fs.path.dirname(state.path)) |dir|
                    try std.fmt.allocPrintZ(state.allocator, "{s}/{s}", .{ dir, uri })
                else
                    try std.fmt.allocPrintZ(state.allocator, "{s}", .{uri});

                _ = sokol.fetch.send(.{
                    .path = &uriz[0],
                    .callback = fetch_callback,
                    .buffer = sokol.fetch.asRange(&state.fetch_buffer),
                    .user_data = sokol.fetch.asRange(&state.tasks[state.task_count]),
                });
            }
        } else {
            try fetch_buffer(index + 1, on_gltf);
        }
    }
}

fn fetch_image(index: u32, on_gltf: *const GltfCallback) !void {
    const parsed = state.json;

    if (index >= parsed.value.images.len) {
        on_gltf(parsed, state.binmap);
    } else {
        // fetch next
        const image = parsed.value.images[index];

        if (image.uri) |uri| {
            if (zigltf.Buffer.base64DecodeSize(uri)) |_| {
                try fetch_image(index + 1, on_gltf);
            } else {
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

                // const base = ;
                const uriz = if (std.fs.path.dirname(state.path)) |dir|
                    try std.fmt.allocPrintZ(state.allocator, "{s}/{s}", .{ dir, uri })
                else
                    try std.fmt.allocPrintZ(state.allocator, "{s}", .{uri});

                _ = sokol.fetch.send(.{
                    .path = &uriz[0],
                    .callback = fetch_callback,
                    .buffer = sokol.fetch.asRange(&state.fetch_buffer),
                    .user_data = sokol.fetch.asRange(&state.tasks[state.task_count]),
                });
            }
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
    path: []const u8,
    parsed: std.json.Parsed(zigltf.Gltf),
    _bin: ?[]const u8,
    callback: *const GltfCallback,
) !void {
    state.path = path;
    state.json = parsed;
    if (_bin) |bin| {
        try state.binmap.put("", bin);
    }

    try fetch_buffer(0, callback);
}

export fn fetch_callback(response: [*c]const sokol.fetch.Response) void {
    std.debug.print("fetch_callback\n", .{});
    if (response.*.fetched) {
        const _bytes = to_slice(
            @ptrCast(response.*.data.ptr),
            response.*.data.size,
        );
        // copy fetch buffer to allocated
        const copy = state.allocator.dupe(u8, _bytes) catch @panic("dupe");

        const user: *const Task = @ptrCast(@alignCast(response.*.user_data));
        switch (user.*) {
            .gltf => |gltf_task| {
                state.status = std.fmt.bufPrintZ(
                    &state.status_buffer,
                    "{}bytes\n",
                    .{response.*.data.size},
                ) catch @panic("bufPrintZ");

                const glb = get_glb(copy);

                if (std.json.parseFromSlice(
                    zigltf.Gltf,
                    state.allocator,
                    glb.json_bytes,
                    .{
                        .ignore_unknown_fields = true,
                    },
                )) |parsed| {
                    set_gltf(state.path, parsed, glb.bin, gltf_task.callback) catch @panic("set_gltf");
                } else |e| {
                    state.status = std.fmt.bufPrintZ(
                        &state.status_buffer,
                        "fail to parse: {s}",
                        .{@errorName(e)},
                    ) catch @panic("bufPrintZ");
                }
            },
            .buffer => |task| {
                const parsed = state.json;

                const buffer = parsed.value.buffers[task.index];
                const uri = buffer.uri orelse {
                    @panic("no uri");
                };

                state.binmap.put(uri, copy) catch @panic("put");

                fetch_buffer(task.index + 1, task.callback) catch @panic("fetch_image");
            },
            .image => |task| {
                const parsed = state.json;

                const image = parsed.value.images[task.index];
                const uri = image.uri orelse {
                    @panic("no uri");
                };

                state.binmap.put(uri, copy) catch @panic("put");

                fetch_image(task.index + 1, task.callback) catch @panic("fetch_image");
            },
        }
    } else if (response.*.failed) {
        state.status = "fetch fail";
    }
}
