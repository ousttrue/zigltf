const std = @import("std");

pub const glb_magic: u32 = 0x46546C67;

pub const GlbChunkType = enum(u32) {
    JSON = 0x4E4F534A,
    BIN = 0x004E4942,
};

pub const GlbChunk = struct {
    type: GlbChunkType,
    bytes: []const u8,
};

pub const Glb = @This();

json_bytes: []const u8,
bin: ?[]const u8 = null,

const Reader = struct {
    bytes: []const u8,
    pos: usize = 0,
    fn init(bytes: []const u8) @This() {
        return .{
            .bytes = bytes,
        };
    }

    fn readU32(self: *@This()) ?u32 {
        if (self.pos + 4 > self.bytes.len) {
            return null;
        }
        defer self.pos += 4;
        return (@as(*const u32, @ptrCast(@alignCast(&self.bytes[self.pos])))).*;
    }

    fn readBytes(self: *@This(), length: usize) ?[]const u8 {
        if (self.pos + length > self.bytes.len) {
            return null;
        }
        defer self.pos += length;
        return self.bytes[self.pos .. self.pos + length];
    }

    fn readChunk(self: *@This()) ?struct {
        type: GlbChunkType,
        data: []const u8,
    } {
        const chunkLength = self.readU32() orelse {
            return null;
        };
        const chunkType = self.readU32() orelse {
            return null;
        };
        const chunkData = self.readBytes(chunkLength) orelse {
            return null;
        };
        return .{
            .type = @enumFromInt(chunkType),
            .data = chunkData,
        };
    }
};

pub fn parse(bytes: []const u8) ?Glb {
    var r = Reader.init(bytes);
    if (r.readU32() != glb_magic) {
        return null;
    }

    const version = r.readU32() orelse {
        return null;
    };
    if (version != 2) {
        std.debug.print("unknown version: {}\n", .{version});
        return null;
    }
    const length = r.readU32() orelse {
        return null;
    };
    if (length > bytes.len) {
        std.debug.print("glb length {} > bytes.len {}\n", .{ length, bytes.len });
        return null;
    }

    const json_chunk = r.readChunk() orelse {
        return null;
    };
    const bin_chunk = r.readChunk();

    std.debug.assert(r.pos == length);

    return .{
        .json_bytes = json_chunk.data,
        .bin = if (bin_chunk) |chunk| chunk.data else null,
    };
}
