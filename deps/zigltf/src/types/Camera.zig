pub const Orthographic = struct {
    xmag: f32,
    ymag: f32,
    zfar: f32,
    znear: f32,
};

pub const Perspective = struct {
    aspectRatio: ?f32 = null,
    yfov: f32,
    zfar: ?f32 = null,
    znear: f32,
};

pub const Camera = @This();

name: ?[]const u8 = null,
orthographic: ?Orthographic = null,
perspective: ?Perspective = null,

// "perspective" or "orthographic"
type: []const u8,
