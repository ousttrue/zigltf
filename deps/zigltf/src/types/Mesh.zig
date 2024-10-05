const std = @import("std");
const format_helper = @import("format_helper.zig");
pub const Mesh = @This();

const Attributes = struct {
    POSITION: u32,
    NORMAL: ?u32 = null,
    TANGENT: ?u32 = null,
    TEXCOORD_0: ?u32 = null,
    COLOR_0: ?u32 = null,
    JOINTS_0: ?u32 = null,
    WEIGHTS_0: ?u32 = null,

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        // if (self.POSITION) |POSITION| {
        try writer.print("[POS=>#{}]", .{self.POSITION});
        // }
        if (self.NORMAL) |NORMAL| try writer.print("[NOM=>#{}]", .{NORMAL});
        if (self.TANGENT) |TANGENT| try writer.print("[TAN=>#{}]", .{TANGENT});
        if (self.TEXCOORD_0) |TEXCOORD_0| try writer.print("[TEX=>#{}]", .{TEXCOORD_0});
        if (self.COLOR_0) |COLOR_0| try writer.print("[COL=>#{}]", .{COLOR_0});
        if (self.JOINTS_0) |JOINTS_0| try writer.print("[JNT=>#{}]", .{JOINTS_0});
        if (self.WEIGHTS_0) |WEIGHTS_0| try writer.print("[WET=>#{}]", .{WEIGHTS_0});
    }
};

pub const Primitive = struct {
    pub const Mode = enum(u32) {
        POINTS = 0,
        LINES = 1,
        LINE_LOOP = 2,
        LINE_STRIP = 3,
        TRIANGLES = 4,
        TRIANGLE_STRIP = 5,
        TRIANGLE_FAN = 6,
    };

    attributes: Attributes,
    material: ?u32 = null,
    indices: ?u32 = null,
    mode: ?Mode = null,
};

name: ?[]const u8 = null,
primitives: []Primitive,

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

    try writer.print("  primitives[{}]:[\n", .{self.primitives.len});
    // attributes
    for (self.primitives, 0..) |primitive, i| {
        try writer.print("    #{}:{{", .{i});
        if (primitive.material) |material| {
            try writer.print(" => material#{}", .{material});
        }
        try writer.print("\n", .{});
        try writer.print("      {any}\n", .{primitive.attributes});
        if (primitive.indices) |indices| {
            try writer.print("      [indices=>#{}]\n", .{indices});
        } else {
            unreachable;
        }
        try writer.print("    }}\n", .{});
    }
    try writer.print("  ]\n", .{});
    try writer.print("}}", .{});
}
