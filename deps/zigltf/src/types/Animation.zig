const AnimationChannel = @import("AnimationChannel.zig");
const AnimationSampler = @import("AnimationSampler.zig");
pub const Animation = @This();

name: ?[]const u8 = null,
channels: []AnimationChannel,
samplers: []AnimationSampler,
