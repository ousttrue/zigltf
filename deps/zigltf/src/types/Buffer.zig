const std = @import("std");
const format_helper = @import("format_helper.zig");
pub const Buffer = @This();

byteLength: u32,
uri: ?[]const u8 = null,

const prefixies = [_][]const u8{
    "data:application/octet-stream;base64,",
    "data:application/gltf-buffer;base64,",
};

pub fn base64FromUri(uri: []const u8) ?[]const u8 {
    for (prefixies) |prefix| {
        if (std.mem.startsWith(u8, uri, prefix)) {
            return uri[prefix.len..];
        }
    }
    return null;
}

pub fn base64DecodeSize(uri: []const u8) ?u32 {
    const base64 = base64FromUri(uri) orelse {
        return null;
    };
    const len = std.base64.standard.Decoder.calcSizeForSlice(base64) catch {
        return null;
    };
    return @intCast(len);
}

pub fn format(
    self: @This(),
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;
    try writer.print("{}bytes", .{
        self.byteLength,
    });

    if (self.uri) |uri| {
        if (base64DecodeSize(uri)) |size| {
            // try writer.print(" => {s} ", .{uri});
            try writer.print(" =[base64]> {}bytes", .{size});
        } else {
            try writer.print(" => {s} ", .{uri});
        }
    }
}
