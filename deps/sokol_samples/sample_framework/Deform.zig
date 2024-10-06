const sokol = @import("sokol");
const sg = sokol.gfx;

pub const Morph = struct {};
pub const Skin = struct {};

pub const Deform = @This();

bind: sg.Bindings = sg.Bindings{},
morph: ?Morph = null,
skin: ?Skin = null,
