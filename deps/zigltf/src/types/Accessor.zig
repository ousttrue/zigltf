const std = @import("std");
const format_helper = @import("format_helper.zig");
pub const AccessorSparse = @import("AccessorSparse.zig");

pub const ComponentType = enum(u32) {
    sbyte = 5120,
    byte = 5121,
    short = 5122,
    ushort = 5123,
    uint = 5125,
    float = 5126,

    pub fn byteSize(componentType: @This()) u32 {
        return switch (componentType) {
            .byte => 1,
            .sbyte => 1,
            .short => 2,
            .ushort => 2,
            .uint => 4,
            .float => 4,
        };
    }
};

pub const Accessor = @This();

name: ?[]const u8 = null,
componentType: ComponentType,
type: []const u8,
count: u32,
bufferView: ?u32 = null,
byteOffset: u32 = 0,
sparse: ?AccessorSparse = null,

fn typeToSuffix(type_: []const u8) []const u8 {
    if (std.mem.eql(u8, "SCALAR", type_)) {
        return "";
    } else if (std.mem.eql(u8, "VEC2", type_)) {
        return "2";
    } else if (std.mem.eql(u8, "VEC3", type_)) {
        return "3";
    } else if (std.mem.eql(u8, "VEC4", type_)) {
        return "4";
    } else if (std.mem.eql(u8, "MAT2", type_)) {
        return "4";
    } else if (std.mem.eql(u8, "MAT3", type_)) {
        return "9";
    } else if (std.mem.eql(u8, "MAT4", type_)) {
        return "16";
    } else {
        return type_;
    }
}

pub fn format(
    self: @This(),
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;
    if (self.name) |name| {
        try writer.print("{s}:", .{name});
    }
    try writer.print("{s}{s}[{}]", .{
        @tagName(self.componentType),
        typeToSuffix(self.type),
        self.count,
    });
    if (self.sparse) |sparse| {
        if (self.bufferView) |bufferView| {
            try writer.print(" => bufferView#{} + sparse[{}]", .{
                bufferView,
                sparse.count,
            });
        } else {
            // the sparse accessor is initialized as an array of zeros of size (size of the accessor element) * (accessor.count) bytes.
            try writer.print(" => + sparse[{}]", .{
                sparse.count,
            });
        }
    } else {
        if (self.bufferView) |bufferView| {
            try writer.print(" => bufferView#{}", .{bufferView});
            if (self.byteOffset > 0) {
                try writer.print("+{}", .{self.byteOffset});
            }
        }
    }
}

fn typeCount(type_: []const u8) u32 {
    if (std.mem.eql(u8, "SCALAR", type_)) {
        return 1;
    } else if (std.mem.eql(u8, "VEC2", type_)) {
        return 2;
    } else if (std.mem.eql(u8, "VEC3", type_)) {
        return 3;
    } else if (std.mem.eql(u8, "VEC4", type_)) {
        return 4;
    } else if (std.mem.eql(u8, "MAT2", type_)) {
        return 4;
    } else if (std.mem.eql(u8, "MAT3", type_)) {
        return 9;
    } else if (std.mem.eql(u8, "MAT4", type_)) {
        return 16;
    } else {
        unreachable;
    }
}

pub fn stride(self: @This()) u32 {
    return self.componentType.byteSize() * typeCount(self.type);
}
