pub const AnimationSampler = @This();

input: u32,
output: u32,

/// "LINEAR" / "STEP" / "CUBICSPLINE"
interpolation: []const u8 = "LINEAR",
