const stb = @import("stb/stb.zig");

pub const Image = @This();
width: u32,
height: u32,
channels: u32,
pixels: []const u8,

pub const white = Image{
    .width = 2,
    .height = 2,
    .channels = 4,
    .pixels = &.{
        255, 255, 255, 255,
        255, 255, 255, 255,
        255, 255, 255, 255,
        255, 255, 255, 255,
    },
};

pub fn init(data: []const u8) ?@This() {
    var img_width: c_int = undefined;
    var img_height: c_int = undefined;
    var num_channels: c_int = undefined;
    const desired_channels = 4;
    const pixels = stb.image.stbi_load_from_memory(
        @ptrCast(&data[0]),
        @intCast(data.len),
        &img_width,
        &img_height,
        &num_channels,
        desired_channels,
    ) orelse {
        return null;
    };
    return .{
        .width = @intCast(img_width),
        .height = @intCast(img_height),
        .channels = @intCast(num_channels),
        .pixels = pixels[0..@intCast(img_width * img_height * num_channels)],
    };
}

pub fn deinit(self: @This()) void {
    stb.image.stbi_image_free(&self.pixels[0]);
}

pub fn byteLength(self: @This()) u32 {
    return self.width * self.height * 4;
}
