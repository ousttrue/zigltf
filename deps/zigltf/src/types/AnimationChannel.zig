const AnimationTarget = @import("AnimationTarget.zig");
pub const AnimationChannel = @This();

sampler: u32,
target: AnimationTarget,
