const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const shader = @import("gltf.glsl.zig");
const rowmath = @import("rowmath");
const Vec3 = rowmath.Vec3;
const Mat4 = rowmath.Mat4;
const Mesh = @import("Mesh.zig");

pub const Morph = struct {};

pub const Skin = struct {
    pub const Joint = struct {
        node_index: u32,
        bind_matrix: Mat4,
    };
    joints: []const Joint,

    pub fn skinning(
        self: @This(),
        weight: f32,
        joint_index: u32,
        node_matrices: []const Mat4,
    ) ?Mat4 {
        if (weight <= 0) {
            return null;
        }
        const joint = self.joints[joint_index];
        var m = joint.bind_matrix.mul(node_matrices[joint.node_index]);
        for (0..16) |i| {
            m.m[i] *= weight;
        }
        return m;
    }
};

pub const Deform = @This();

bind: sg.Bindings = sg.Bindings{},
deform_vertices: []Mesh.Vertex = &.{},
morph: ?Morph = null,
skin: ?Skin = null,

pub fn init(
    self: *@This(),
    allocator: std.mem.Allocator,
    mesh: *const Mesh,
) !void {
    self.deform_vertices = try allocator.dupe(Mesh.Vertex, mesh.vertices);
    self.bind.vertex_buffers[shader.ATTR_vs_aPos] = sg.makeBuffer(.{
        .size = @sizeOf(Mesh.Vertex) * mesh.vertices.len,
        .usage = .STREAM,
        .label = "deform-vertices",
    });
    self.bind.index_buffer = mesh.bind.index_buffer;
}

pub fn update(
    self: *@This(),
    base_vertices: []const Mesh.Vertex,
    skinning_vertices: ?[]const Mesh.SkinVertex,
    node_matrices: []const Mat4,
) void {
    std.mem.copyForwards(Mesh.Vertex, self.deform_vertices, base_vertices);

    if (self.skin) |skin| {
        for (self.deform_vertices, 0..) |*v, i| {
            const joints_weigts = skinning_vertices.?[i];
            var m = Mat4.zero;
            if (skin.skinning(joints_weigts.weights.x, joints_weigts.jonts.x, node_matrices)) |skinning_matrix| {
                m = m.add(skinning_matrix);
            }
            if (skin.skinning(joints_weigts.weights.y, joints_weigts.jonts.y, node_matrices)) |skinning_matrix| {
                m = m.add(skinning_matrix);
            }
            if (skin.skinning(joints_weigts.weights.z, joints_weigts.jonts.z, node_matrices)) |skinning_matrix| {
                m = m.add(skinning_matrix);
            }
            if (skin.skinning(joints_weigts.weights.w, joints_weigts.jonts.w, node_matrices)) |skinning_matrix| {
                m = m.add(skinning_matrix);
            }
            v.position = m.transformPoint(v.position);
            v.normal = m.transformDirection(v.normal);
        }
    }
}
