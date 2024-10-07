const std = @import("std");
const format_helper = @import("format_helper.zig");
pub const Texture = @This();

pub const KhrTextureBasisu = struct {
    source: u32,
};

name: ?[]const u8 = null,
source: ?u32 = null,
sampler: ?u32 = null,
extensions: ?struct {
    KHR_texture_basisu: ?KhrTextureBasisu,
} = null,

pub fn format(
    self: @This(),
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;
    try format_helper.string_value(writer, self.name, .{});
    try writer.print("{{\n", .{});
    if (self.extensions) |extensions| {
        if (extensions.KHR_texture_basisu) |basisu| {
            try writer.print("[basisu] => image#{}\n", .{basisu.source});
        }
    } else {
        if (self.source) |source| {
            try writer.print("=> image#{}\n", .{source});
        } else {
            try writer.print("[no source]\n", .{});
        }
    }
    // if (self.uri) |uri| {
    //     try writer.print("  => {s}\n", .{uri});
    // } else if (self.bufferView) |bufferView| {
    //     if (self.mimeType) |mimeType| {
    //         try writer.print("  {s} => #{}\n", .{ mimeType, bufferView });
    //     } else {
    //         try writer.print("  [no mime]? => #{}\n", .{bufferView});
    //     }
    // } else {
    //     try writer.print("  [error] uri nor bufferView\n", .{});
    // }
    try writer.print("}}", .{});
}
