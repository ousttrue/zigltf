const std = @import("std");
const format_helper = @import("format_helper.zig");
pub const Material = @This();

pub const PbrMetallicRoughness = struct {
    baseColorFactor: ?struct { f32, f32, f32, f32 } = null,
    baseColorTexture: ?struct {
        index: u32,
        texCoord: ?u32,
    } = null,

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("pbr{{\n", .{});
        try format_helper.number4_field(
            writer,
            4,
            "baseColorFactor",
            self.baseColorFactor,
            .{},
        );
        try format_helper.textureinfo_field(
            writer,
            4,
            "baseColorTexture",
            self.baseColorTexture,
            .{},
        );
        try writer.print("  }}", .{});
    }
};

pub const default = Material{
    .name = "gltf_default",
};

name: ?[]const u8 = null,
pbrMetallicRoughness: ?PbrMetallicRoughness = null,

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
    if (self.pbrMetallicRoughness) |pbr| {
        try writer.print("  {any}\n", .{pbr});
    }
    try writer.print("}}", .{});
}
