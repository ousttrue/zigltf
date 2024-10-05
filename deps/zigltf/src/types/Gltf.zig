const std = @import("std");
const Asset = @import("Asset.zig");
const Buffer = @import("Buffer.zig");
const BufferView = @import("BufferView.zig");
const Accessor = @import("Accessor.zig");
const Image = @import("Image.zig");
const Sampler = @import("Sampler.zig");
const Texture = @import("Texture.zig");
const Material = @import("Material.zig");
const Mesh = @import("Mesh.zig");
const Node = @import("Node.zig");
const Skin = @import("Skin.zig");
const Scene = @import("Scene.zig");
const Animation = @import("Animation.zig");
pub const Gltf = @This();

asset: Asset,
buffers: []Buffer = &.{},
bufferViews: []BufferView = &.{},
accessors: []Accessor = &.{},
images: []Image = &.{},
textures: []Texture = &.{},
materials: []Material = &.{},
meshes: []Mesh = &.{},
nodes: []Node = &.{},
skins: []Skin = &.{},
scenes: []Scene = &.{},
scene: u32 = 0,
animations: []Animation = &.{},

fn print_list(writer: anytype, name: []const u8, list: anytype) !void {
    if (list.len > 0) {
        try writer.print("{s}[{}]: [\n", .{ name, list.len });
        for (list, 0..) |x, i| {
            try writer.print("#{}:{any}\n", .{ i, x });
        }
        try writer.print("]\n", .{});
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
    try writer.print("{{\n", .{});

    try writer.print("asset: {any}\n", .{self.asset});

    try print_list(writer, "buffers", self.buffers);
    try print_list(writer, "bufferViews", self.bufferViews);
    try print_list(writer, "accessors", self.accessors);
    try print_list(writer, "images", self.images);
    try print_list(writer, "textures", self.textures);
    try print_list(writer, "materials", self.materials);
    try print_list(writer, "meshes", self.meshes);
    try print_list(writer, "nodes", self.nodes);
    try print_list(writer, "skins", self.skins);
    try print_list(writer, "scenes", self.scenes);
    try print_list(writer, "animations", self.animations);

    try writer.print("}}\n", .{});
}
