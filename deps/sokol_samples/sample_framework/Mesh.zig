const sokol = @import("sokol");
const sg = sokol.gfx;
const shader = @import("gltf.glsl.zig");
const Texture = @import("Texture.zig");
const rowmath = @import("rowmath");
const Vec3 = rowmath.Vec3;
const Vec2 = rowmath.Vec2;

pub const Vertex = struct {
    position: Vec3,
    normal: Vec3,
    uv: Vec2,
};
const Vec4 = rowmath.Vec4;
pub const UShort4 = struct {
    x: u16,
    y: u16,
    z: u16,
    w: u16,
};
pub const SkinVertex = struct {
    jonts: UShort4,
    weights: Vec4,
};

pub const Submesh = struct {
    submesh_params: shader.SubmeshParams,
    draw_count: u32,
    color_texture: Texture,
};

pub const Mesh = @This();

bind: sg.Bindings,
vertices: []Vertex,
skin_vertices: ?[]const SkinVertex,
submeshes: []Submesh,
vertex_count: u32,

pub fn init(
    vertices: []Vertex,
    skin_vertices: ?[]const SkinVertex,
    _indices: ?[]u16,
    submeshes: []Submesh,
) @This() {
    var mesh = Mesh{
        .bind = sg.Bindings{},
        .vertices = vertices,
        .skin_vertices = skin_vertices,
        .submeshes = submeshes,
        .vertex_count = @intCast(vertices.len),
    };
    mesh.bind.vertex_buffers[shader.ATTR_vs_aPos] = sg.makeBuffer(.{
        .data = sg.asRange(vertices),
        .label = "base-vertices",
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
