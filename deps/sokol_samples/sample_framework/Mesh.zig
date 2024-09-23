const sokol = @import("sokol");
const sg = sokol.gfx;

pub const Vertex = struct {
    position: [3]f32,
    normal: [3]f32,
};

pub const Submesh = struct {
    material_index: ?u32,
    draw_count: u32,
};

pub const Mesh = @This();

bind: sg.Bindings,
submeshes: []Submesh,

pub fn init(
    vertices: []Vertex,
    _indices: ?[]u16,
    submeshes: []Submesh,
) @This() {
    var mesh = Mesh{
        .bind = sg.Bindings{},
        .submeshes = submeshes,
    };
    mesh.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(vertices),
        .label = "gltf-vertices",
    });
    if (_indices) |indices| {
        mesh.bind.index_buffer = sg.makeBuffer(.{
            .type = .INDEXBUFFER,
            .data = sg.asRange(indices),
            .label = "gltf-indices",
        });
    }
    return mesh;
}

pub fn deinit(self: @This()) void {
    self.vertices.deinit();
    self.indices.deinit();
    self.submeshes.deinit();
}

pub fn draw(self: *const @This()) void {
    sg.applyBindings(self.bind);

    var offset: u32 = 0;
    for (self.submeshes) |submesh| {
        sg.draw(offset, submesh.draw_count, 1);
        offset += submesh.draw_count;
    }
}
