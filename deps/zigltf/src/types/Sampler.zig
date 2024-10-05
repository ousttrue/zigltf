pub const MagFilter = enum(u32) {
    NEAREST = 9728,
    LINEAR = 9729,
};

pub const MinFilter = enum(u32) {
    NEAREST = 9728,
    LINEAR = 9729,
    NEAREST_MIPMAP_NEAREST = 9984,
    LINEAR_MIPMAP_NEAREST = 9985,
    NEAREST_MIPMAP_LINEAR = 9986,
    LINEAR_MIPMAP_LINEAR = 9987,
};

pub const WrapMode = enum(u32) {
    CLAMP_TO_EDGE = 33071,
    MIRRORED_REPEAT = 33648,
    REPEAT = 10497,
};

pub const Sampler = @This();

magFilter: ?MagFilter = null,
minFilter: ?MinFilter = null,
wrapS: ?WrapMode = null,
wrapT: ?WrapMode = null,
