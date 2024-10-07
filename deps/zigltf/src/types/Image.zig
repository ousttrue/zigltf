const std = @import("std");
const format_helper = @import("format_helper.zig");
pub const Image = @This();

name: ?[]const u8 = null,
uri: ?[]const u8 = null,
bufferView: ?u32 = null,
mimeType: ?[]const u8 = null,

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
    if (self.uri) |uri| {
        try writer.print("  uri: {s}\n", .{uri});
    } else if (self.bufferView) |bufferView| {
        if (self.mimeType) |mimeType| {
            try writer.print("  [{s}] #{}\n", .{ mimeType, bufferView });
        } else {
            try writer.print("  [no mime]? => #{}\n", .{bufferView});
        }
    } else {
        try writer.print("  [error] uri nor bufferView\n", .{});
    }
    try writer.print("}}", .{});
}
