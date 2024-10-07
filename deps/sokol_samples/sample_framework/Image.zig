const std = @import("std");
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

const PNG = "\x89PNG";
const JPG = "\xFF\xD8\xFF\xE1";
const KTX = "\xABKTX";

pub const ImageType = enum {
    png,
    jpg,
    ktx,

    pub fn fromBytes(bytes: []const u8) @This() {
        if (std.mem.startsWith(u8, bytes, PNG)) {
            return .png;
        }
        if (std.mem.startsWith(u8, bytes, JPG)) {
            return .jpg;
        }
        if (std.mem.startsWith(u8, bytes, KTX)) {
            return .ktx;
        }
        unreachable;
    }
};

pub fn init(bytes: []const u8) ?@This() {
    switch (ImageType.fromBytes(bytes)) {
        .png, .jpg => {
            var img_width: c_int = undefined;
            var img_height: c_int = undefined;
            var num_channels: c_int = undefined;
            const desired_channels = 4;
            const pixels = stb.image.stbi_load_from_memory(
                @ptrCast(&bytes[0]),
                @intCast(bytes.len),
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
        },
        .ktx => {
            // transcode
            @panic("ktx not impl");
        },
    }
}

pub fn deinit(self: @This()) void {
    stb.image.stbi_image_free(&self.pixels[0]);
}

pub fn byteLength(self: @This()) u32 {
    return self.width * self.height * 4;
}
