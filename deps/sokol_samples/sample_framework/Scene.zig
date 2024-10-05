const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const shader = @import("gltf.glsl.zig");

const zigltf = @import("zigltf");
const rowmath = @import("rowmath");
const Camera = rowmath.Camera;
const Mat4 = rowmath.Mat4;
const Vec3 = rowmath.Vec3;
const Quat = rowmath.Quat;

const Mesh = @import("Mesh.zig");
const Animation = @import("Animation.zig");
pub const Scene = @This();

const light_pos = [3]f32{ -10, -10, -10 };
const light_color = [3]f32{ 1, 1, 1 };
const ambient = [3]f32{ 0.2, 0.2, 0.2 };

allocator: std.mem.Allocator = undefined,
meshes: []Mesh = &.{},
pip: sg.Pipeline = undefined,
gltf: ?std.json.Parsed(zigltf.Gltf) = null,
white_texture: Mesh.Texture = undefined,
animations: []Animation = &.{},
currentAnimation: ?usize = null,

pub fn init(self: *@This(), allocator: std.mem.Allocator) void {
    self.allocator = allocator;

    // create pipeline object
    var pip_desc = sg.PipelineDesc{
        .shader = sg.makeShader(shader.gltfShaderDesc(sg.queryBackend())),
        .index_type = .UINT16,
        .cull_mode = .BACK,
        .face_winding = .CCW,
        .depth = .{
            .write_enabled = true,
            .compare = .LESS_EQUAL,
        },
        .label = "cube-pipeline",
    };
    // test to provide buffer stride, but no attr offsets
    // pip_desc.layout.buffers[0].stride = 28;
    pip_desc.layout.attrs[shader.ATTR_vs_aPos].format = .FLOAT3;
    pip_desc.layout.attrs[shader.ATTR_vs_aNormal].format = .FLOAT3;
    pip_desc.layout.attrs[shader.ATTR_vs_aTexCoord].format = .FLOAT2;
    self.pip = sg.makePipeline(pip_desc);

    self.white_texture = Mesh.Texture.init(Mesh.Image.white);
}

pub fn deinit(self: *@This()) void {
    self.allocator.free(self.meshes);
}

pub fn load(
    self: *@This(),
    json: std.json.Parsed(zigltf.Gltf),
    binmap: std.StringHashMap([]const u8),
) !void {
    std.debug.print("{s}\n", .{json.value});
    self.gltf = json;
    const gltf = json.value;

    var meshes = std.ArrayList(Mesh).init(self.allocator);
    defer meshes.deinit();
    var submeshes = std.ArrayList(Mesh.Submesh).init(self.allocator);
    defer submeshes.deinit();

    var mesh_vertices = std.ArrayList(Mesh.Vertex).init(self.allocator);
    defer mesh_vertices.deinit();
    var mesh_indices = std.ArrayList(u16).init(self.allocator);
    defer mesh_indices.deinit();

    var gltf_buffer = zigltf.GltfBuffer.init(
        self.allocator,
        gltf,
        binmap,
    );
    defer gltf_buffer.deinit();

    for (gltf.meshes) |gltf_mesh| {
        var vertex_count: u32 = 0;
        var index_count: u32 = 0;
        for (gltf_mesh.primitives) |primitive| {
            const pos_accessor = gltf.accessors[primitive.attributes.POSITION];
            const index_accessor = gltf.accessors[primitive.indices.?];
            vertex_count += pos_accessor.count;
            index_count += index_accessor.count;
        }
        try mesh_vertices.resize(vertex_count);
        try mesh_indices.resize(index_count);

        vertex_count = 0;
        index_count = 0;
        for (gltf_mesh.primitives) |primitive| {
            const pos_accessor = gltf.accessors[primitive.attributes.POSITION];

            {
                const positions = try gltf_buffer.getAccessorBytes(
                    [3]f32,
                    primitive.attributes.POSITION,
                );
                for (positions, 0..) |pos, i| {
                    mesh_vertices.items[vertex_count + i].position = pos;
                }
            }
            if (primitive.attributes.NORMAL) |normal_accessor_index| {
                // normal
                const normals = try gltf_buffer.getAccessorBytes(
                    [3]f32,
                    normal_accessor_index,
                );
                for (normals, 0..) |normal, i| {
                    mesh_vertices.items[vertex_count + i].normal = normal;
                }
            }
            if (primitive.attributes.TEXCOORD_0) |tex0_accessor_index| {
                // uv
                const tex0s = try gltf_buffer.getAccessorBytes(
                    [2]f32,
                    tex0_accessor_index,
                );
                for (tex0s, 0..) |tex0, i| {
                    mesh_vertices.items[vertex_count + i].uv = tex0;
                }
            }

            if (primitive.indices) |indices_accessor_index| {
                // indies
                const index_accessor = gltf.accessors[indices_accessor_index];
                if (!std.mem.eql(u8, index_accessor.type, "SCALAR")) {
                    return error.IndexNotScalar;
                }
                switch (index_accessor.componentType) {
                    5121 => {
                        // byte
                        const indices = try gltf_buffer.getAccessorBytes(
                            u8,
                            indices_accessor_index,
                        );
                        for (indices, 0..) |index, i| {
                            mesh_indices.items[index_count + i] = @as(
                                u16,
                                @intCast(index),
                            ) + @as(
                                u16,
                                @intCast(vertex_count),
                            );
                        }
                    },
                    5123 => {
                        // ushort
                        const indices = try gltf_buffer.getAccessorBytes(
                            u16,
                            indices_accessor_index,
                        );
                        for (indices, 0..) |index, i| {
                            mesh_indices.items[index_count + i] = index + @as(
                                u16,
                                @intCast(vertex_count),
                            );
                        }
                    },
                    5125 => {
                        // uint
                        const indices = try gltf_buffer.getAccessorBytes(
                            u32,
                            indices_accessor_index,
                        );
                        for (indices, 0..) |index, i| {
                            mesh_indices.items[index_count + i] = @as(
                                // TODO
                                u16,
                                @intCast(index),
                            ) + @as(
                                u16,
                                @intCast(vertex_count),
                            );
                        }
                    },
                    else => unreachable,
                }

                const material = if (primitive.material) |material_index|
                    gltf.materials[material_index]
                else
                    zigltf.Material.default;

                var color: [4]f32 = .{ 1, 1, 1, 1 };
                if (material.pbrMetallicRoughness) |pbr| {
                    if (pbr.baseColorFactor) |base_color| {
                        color = base_color;
                    }
                }

                var color_texture = self.white_texture;
                if (material.pbrMetallicRoughness) |pbr| {
                    if (pbr.baseColorTexture) |base| {
                        const texture = gltf.textures[base.index];
                        if (texture.source) |source| {
                            const image_bytes = try gltf_buffer.getImageBytes(source);
                            if (Mesh.Image.init(image_bytes)) |image| {
                                defer image.deinit();
                                color_texture = Mesh.Texture.init(image);
                            }
                        }
                    }
                }

                try submeshes.append(.{
                    .draw_count = index_accessor.count,
                    .submesh_params = .{
                        .material_rgba = color,
                    },
                    .color_texture = color_texture,
                });
                index_count += index_accessor.count;
            } else {
                unreachable;
            }

            vertex_count += pos_accessor.count;
        }

        try meshes.append(Mesh.init(
            mesh_vertices.items,
            mesh_indices.items,
            try submeshes.toOwnedSlice(),
        ));
    }
    self.meshes = try meshes.toOwnedSlice();

    if (gltf.animations.len > 0) {
        var animations = std.ArrayList(Animation).init(self.allocator);

        for (gltf.animations) |gltf_animation| {
            var curves = std.ArrayList(Animation.Curve).init(self.allocator);
            var duration: f32 = 0;

            for (gltf_animation.channels) |channel| {
                const sampler = gltf_animation.samplers[channel.sampler];
                if (std.mem.eql(u8, channel.target.path, "translation")) {
                    const curve = Animation.Vec3Curve{
                        .values = .{
                            .input = try gltf_buffer.getAccessorBytes(f32, sampler.input),
                            .output = try gltf_buffer.getAccessorBytes(Vec3, sampler.output),
                        },
                    };
                    duration = @max(duration, curve.values.duration());
                    try curves.append(.{
                        .node_index = channel.target.node,
                        .target = .{ .translation = curve },
                    });
                } else if (std.mem.eql(u8, channel.target.path, "rotation")) {
                    const curve = Animation.QuatCurve{
                        .values = .{
                            .input = try gltf_buffer.getAccessorBytes(f32, sampler.input),
                            .output = try gltf_buffer.getAccessorBytes(Quat, sampler.output),
                        },
                    };
                    duration = @max(duration, curve.values.duration());
                    try curves.append(.{
                        .node_index = channel.target.node,
                        .target = .{ .rotation = curve },
                    });
                } else if (std.mem.eql(u8, channel.target.path, "scale")) {
                    const curve = Animation.Vec3Curve{
                        .values = .{
                            .input = try gltf_buffer.getAccessorBytes(f32, sampler.input),
                            .output = try gltf_buffer.getAccessorBytes(Vec3, sampler.output),
                        },
                    };
                    duration = @max(duration, curve.values.duration());
                    try curves.append(.{
                        .node_index = channel.target.node,
                        .target = .{ .scale = curve },
                    });
                } else if (std.mem.eql(u8, channel.target.path, "weights")) {
                    const curve = Animation.FloatCurve{
                        .values = .{
                            .input = try gltf_buffer.getAccessorBytes(f32, sampler.input),
                            .output = try gltf_buffer.getAccessorBytes(f32, sampler.output),
                        },
                    };
                    duration = @max(duration, curve.values.duration());
                    try curves.append(.{
                        .node_index = channel.target.node,
                        .target = .{ .weights = curve },
                    });
                } else {
                    unreachable;
                }
            }

            try animations.append(.{
                .duration = duration,
                .curves = try curves.toOwnedSlice(),
            });
        }

        self.animations = try animations.toOwnedSlice();
        self.currentAnimation = 0;
    }
}

pub fn update(self: @This(), time: f32) ?f32 {
    const gltf = self.gltf orelse {
        return null;
    };

    const current = self.currentAnimation orelse {
        return null;
    };

    if (current >= self.animations.len) {
        return null;
    }

    const animation = &self.animations[current];
    const looptime = animation.loopTime(time);
    for (animation.curves) |curve| {
        switch (curve.target) {
            .translation => |values| {
                const t = values.sample(looptime);
                gltf.value.nodes[curve.node_index].translation = .{
                    t.x,
                    t.y,
                    t.z,
                };
            },
            .rotation => |values| {
                const r = values.sample(looptime);
                gltf.value.nodes[curve.node_index].rotation = .{
                    r.x,
                    r.y,
                    r.z,
                    r.w,
                };
            },
            .scale => |values| {
                _ = values;
                unreachable;
            },
            .weights => |values| {
                _ = values;
                unreachable;
            },
        }
    }
    return looptime;
}

pub fn draw(self: *@This(), camera: Camera) void {
    if (self.gltf) |json| {
        sg.applyPipeline(self.pip);
        for (json.value.scenes[0].nodes) |root_node_index| {
            self.draw_node(
                json.value,
                camera.viewProjectionMatrix(),
                root_node_index,
                Mat4.identity,
            );
        }
    }
}

fn draw_node(
    self: *@This(),
    gltf: zigltf.Gltf,
    vp: Mat4,
    node_index: u32,
    parent_matrix: Mat4,
) void {
    const node = gltf.nodes[node_index];
    const local_matrix = if (node.matrix) |node_matrix|
        Mat4{ .m = node_matrix }
    else block: {
        var t = Vec3.zero;
        var r = Quat.identity;
        var s = Vec3.one;
        if (node.translation) |translation| {
            t = .{
                .x = translation[0],
                .y = translation[1],
                .z = translation[2],
            };
        }
        if (node.rotation) |rotation| {
            r = .{
                .x = rotation[0],
                .y = rotation[1],
                .z = rotation[2],
                .w = rotation[3],
            };
        }
        if (node.scale) |scale| {
            s = .{
                .x = scale[0],
                .y = scale[1],
                .z = scale[2],
            };
        }
        break :block Mat4.trs(.{ .t = t, .r = r, .s = s });
    };
    const model_matrix = local_matrix.mul(parent_matrix);

    if (node.mesh) |mesh_index| {
        self.draw_mesh(mesh_index, vp, model_matrix);
    }

    for (node.children) |child_node_index| {
        self.draw_node(gltf, vp, child_node_index, model_matrix);
    }
}

fn draw_mesh(self: *@This(), mesh_index: u32, vp: Mat4, model: Mat4) void {
    const vs_params = shader.VsParams{
        // rowmath では vec * mat の乗算順なので view_projection
        // glsl では mat * vec の乗算順なので projection_view
        // memory layout は同じ
        //
        //   vec * mat と記述する場合は transpose が必要
        .projection_view = vp.m,
        .model = model.m,
    };
    sg.applyUniforms(.VS, shader.SLOT_vs_params, sg.asRange(&vs_params));

    const fs_params = shader.FsParams{
        .lightPos = light_pos,
        .lightColor = light_color,
        .ambient = ambient,
    };
    sg.applyUniforms(.FS, shader.SLOT_fs_params, sg.asRange(&fs_params));

    var mesh = &self.meshes[mesh_index];

    var offset: u32 = 0;
    for (mesh.submeshes) |*submesh| {
        sg.applyUniforms(
            .FS,
            shader.SLOT_submesh_params,
            sg.asRange(&submesh.submesh_params),
        );

        mesh.bind.fs = submesh.color_texture.fs;
        sg.applyBindings(mesh.bind);

        sg.draw(offset, submesh.draw_count, 1);

        offset += submesh.draw_count;
    }
}
