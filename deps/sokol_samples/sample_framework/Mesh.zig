const sokol = @import("sokol");
const sg = sokol.gfx;

pub const Vertex = struct {
    position: [3]f32,
    normal: [3]f32,
};

pub const Mesh = @This();

bind: sg.Bindings = undefined,
draw_count: u32 = 0,

pub fn init(
    self: *@This(),
    vertices: []Vertex,
    indices: []u16,
) void {
    self.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(vertices),
        .label = "gltf-vertices",
    });
    self.bind.index_buffer = sg.makeBuffer(.{
        .type = .INDEXBUFFER,
        .data = sg.asRange(indices),
        .label = "gltf-indices",
    });
    self.draw_count = @intCast(indices.len);
}

pub fn draw(self: *const @This()) void {
    sg.applyBindings(self.bind);
    sg.draw(0, self.draw_count, 1);
}
