const std = @import("std");
const base64_decoder = std.base64.standard.Decoder;
const Gltf = @import("types/Gltf.zig");
const Buffer = @import("types/Buffer.zig");
pub const GltfBuffer = @This();

allocator: std.mem.Allocator,
gltf: Gltf,
uriMap: std.StringHashMap([]const u8),

pub fn init(
    allocator: std.mem.Allocator,
    gltf: Gltf,
    binmap: std.StringHashMap([]const u8),
) @This() {
    return .{
        .allocator = allocator,
        .gltf = gltf,
        .uriMap = binmap,
    };
}

pub fn deinit(self: *@This()) void {
    // TODO:
    self.uriMap.deinit();
}

pub fn getImageBytes(self: *@This(), image_index: u32) ![]const u8 {
    const image = self.gltf.images[image_index];
    if (image.bufferView) |bufferView_index| {
        return try self.getBufferViewBytes(bufferView_index);
    } else if (image.uri) |uri| {
        if (self.uriMap.getPtr(uri)) |bytes| {
            return bytes.*;
        } else {
            @panic("image.uri not implemented");
        }
    } else {
        unreachable;
    }
}

pub fn getAccessorBytes(self: *@This(), T: type, accessor_index: u32) ![]const T {
    const accessor = self.gltf.accessors[accessor_index];
    if (@sizeOf(T) != accessor.stride()) {
        return error.AccessorStrideNotEquals;
    }

    if (accessor.sparse) |sparse| {
        if (accessor.bufferView) |bufferView_index| {
            const bufferViewBytes = try self.getBufferViewBytes(bufferView_index);
            const bytes = bufferViewBytes[accessor.byteOffset .. accessor.byteOffset + accessor.count * accessor.stride()];
            const slice: []const T = @alignCast(std.mem.bytesAsSlice(T, bytes));
            var buffer = try self.allocator.alloc(T, accessor.count);
            std.mem.copyForwards(T, buffer, slice[0..accessor.count]);

            switch (sparse.indices.componentType) {
                5121 => {
                    // u8
                    std.debug.assert(sparse.indices.byteOffset == 0);
                    const indices = try self.getBufferViewBytes(sparse.indices.bufferView);
                    std.debug.assert(sparse.values.byteOffset == 0);
                    const values = try self.getBufferViewBytes(sparse.values.bufferView);
                    const values_t: []const T = @alignCast(std.mem.bytesAsSlice(T, values));
                    for (indices, 0..) |index, i| {
                        buffer[index] = values_t[i];
                    }
                },
                5123 => {
                    // u16
                    std.debug.assert(sparse.indices.byteOffset == 0);
                    const indices = try self.getBufferViewBytes(sparse.indices.bufferView);
                    const indices_t: []const u16 = @alignCast(std.mem.bytesAsSlice(u16, indices));
                    std.debug.assert(sparse.values.byteOffset == 0);
                    const values = try self.getBufferViewBytes(sparse.values.bufferView);
                    const values_t: []const T = @alignCast(std.mem.bytesAsSlice(T, values));
                    for (indices_t, 0..) |index, i| {
                        buffer[index] = values_t[i];
                    }
                },
                5125 => {
                    // u32
                    @panic("u32 sparse indices");
                },
                else => {
                    unreachable;
                },
            }
            return buffer;
        } else {
            @panic("zero sparse not impl");
        }
    } else {
        if (accessor.bufferView) |bufferView_index| {
            const bufferViewBytes = try self.getBufferViewBytes(bufferView_index);
            const bufferView = self.gltf.bufferViews[bufferView_index];
            const begin = accessor.byteOffset;
            const end = accessor.byteOffset + accessor.count * accessor.stride();
            const bytes = bufferViewBytes[begin..end];

            const same_stride = if (bufferView.byteStride) |stride|
                stride == accessor.stride()
            else
                true;

            if (same_stride) {
                return @alignCast(std.mem.bytesAsSlice(T, bytes));
            } else {
                var buffer = try self.allocator.alloc(T, accessor.count);
                var p = &bytes[0];
                const stride = bufferView.byteStride.?;
                for (0..accessor.count) |vertex_index| {
                    const ptr: *const T = @ptrCast(@alignCast(p));
                    buffer[vertex_index] = ptr.*;
                    p = @ptrFromInt(@intFromPtr(p) + stride);
                }
                return buffer;
            }
        } else {
            unreachable;
        }
    }
}

pub fn getBufferViewBytes(self: *@This(), bufferView_index: u32) ![]const u8 {
    const bufferView = self.gltf.bufferViews[bufferView_index];
    const buffer_bytes = try self.getBufferBytes(bufferView.buffer);
    return buffer_bytes[bufferView.byteOffset .. bufferView.byteOffset + bufferView.byteLength];
}

pub fn getBufferBytes(self: *@This(), buffer_index: u32) ![]const u8 {
    const buffer = self.gltf.buffers[buffer_index];
    if (buffer.uri) |uri| {
        return try self.getUriBytes(uri);
    } else {
        return try self.getUriBytes("");
    }
}

pub fn getUriBytes(self: *@This(), uri: []const u8) ![]const u8 {
    if (self.uriMap.getPtr(uri)) |ptr| {
        return ptr.*;
    }

    if (Buffer.base64FromUri(uri)) |base64| {
        // std.debug.print("{s}\n", .{base64});
        const len = base64_decoder.calcSizeForSlice(base64) catch |e| {
            return e;
        };
        const buf = try self.allocator.alloc(u8, len);
        // TODO: free
        try base64_decoder.decode(buf, base64);
        try self.uriMap.put(uri, buf);
        return buf;
    } else {
        unreachable;
    }
}
