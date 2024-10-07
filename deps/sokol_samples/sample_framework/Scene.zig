const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const shader = @import("gltf.glsl.zig");

const zigltf = @import("zigltf");
const rowmath = @import("rowmath");
const Camera = rowmath.Camera;
const Mat4 = rowmath.Mat4;
const Vec3 = rowmath.Vec3;
const Vec4 = rowmath.Vec4;
const Vec2 = rowmath.Vec2;
const Quat = rowmath.Quat;

const Mesh = @import("Mesh.zig");
const Texture = @import("Texture.zig");
const Image = @import("Image.zig");
const Deform = @import("Deform.zig");
const Animation = @import("Animation.zig");
pub const Scene = @This();

const light_pos = [3]f32{ -10, -10, -10 };
const light_color = [3]f32{ 1, 1, 1 };
const ambient = [3]f32{ 0.2, 0.2, 0.2 };

allocator: std.mem.Allocator = undefined,
meshes: []Mesh = &.{},
pip: sg.Pipeline = undefined,
gltf: ?std.json.Parsed(zigltf.Gltf) = null,
white_texture: Texture = undefined,
animations: []Animation = &.{},
current_animation: ?usize = null,
node_matrices: []Mat4 = &.{},
node_deforms: []Deform = &.{},

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

    self.white_texture = Texture.init(Image.white, null);
}

pub fn deinit(self: *@This()) void {
    self.allocator.free(self.meshes);
}

pub fn load(
    self: *@This(),
    json: std.json.Parsed(zigltf.Gltf),
    binmap: ?std.StringHashMap([]const u8),
) !void {
    std.debug.print("{s}\n", .{json.value});
    self.gltf = json;

    var gltf_buffer = zigltf.GltfBuffer.init(
        self.allocator,
        json.value,
        binmap orelse std.StringHashMap([]const u8).init(self.allocator),
    );
    defer gltf_buffer.deinit();

    try self.load_mesh(json.value, &gltf_buffer);
    try self.load_animation(json.value, &gltf_buffer);
}

fn load_mesh(
    self: *@This(),
    gltf: zigltf.Gltf,
    gltf_buffer: *zigltf.GltfBuffer,
) !void {
    self.meshes = try self.allocator.alloc(Mesh, gltf.meshes.len);

    var submeshes = std.ArrayList(Mesh.Submesh).init(self.allocator);
    defer submeshes.deinit();
    var mesh_vertices = std.ArrayList(Mesh.Vertex).init(self.allocator);
    defer mesh_vertices.deinit();
    var skin_vertices = std.ArrayList(Mesh.SkinVertex).init(self.allocator);
    defer skin_vertices.deinit();
    var mesh_indices = std.ArrayList(u16).init(self.allocator);
    defer mesh_indices.deinit();
    var targets = std.ArrayList(Mesh.MorphTarget).init(self.allocator);
    defer targets.deinit();

    self.node_deforms = try self.allocator.alloc(Deform, gltf.nodes.len);
    self.node_matrices = try self.allocator.alloc(Mat4, gltf.nodes.len);

    for (gltf.meshes, 0..) |gltf_mesh, mesh_index| {
        var vertex_count: u32 = 0;
        var index_count: u32 = 0;
        for (gltf_mesh.primitives) |primitive| {
            const pos_accessor = gltf.accessors[primitive.attributes.POSITION];
            const index_accessor = gltf.accessors[primitive.indices.?];
            vertex_count += pos_accessor.count;
            index_count += index_accessor.count;
        }
        try mesh_vertices.resize(vertex_count);
        try skin_vertices.resize(0);
        try mesh_indices.resize(index_count);

        var vertex_offset: u32 = 0;
        var index_offset: u32 = 0;
        var target_count: ?u32 = null;
        for (gltf_mesh.primitives) |primitive| {
            const pos_accessor = gltf.accessors[primitive.attributes.POSITION];

            {
                const positions = try gltf_buffer.getAccessorBytes(
                    Vec3,
                    primitive.attributes.POSITION,
                );
                for (positions, 0..) |pos, i| {
                    mesh_vertices.items[vertex_offset + i].position = pos;
                }
            }
            if (primitive.attributes.NORMAL) |normal_accessor_index| {
                const normals = try gltf_buffer.getAccessorBytes(
                    Vec3,
                    normal_accessor_index,
                );
                for (normals, 0..) |normal, i| {
                    mesh_vertices.items[vertex_offset + i].normal = normal;
                }
            }
            if (primitive.attributes.TEXCOORD_0) |tex0_accessor_index| {
                const tex0s = try gltf_buffer.getAccessorBytes(
                    Vec2,
                    tex0_accessor_index,
                );
                for (tex0s, 0..) |tex0, i| {
                    mesh_vertices.items[vertex_offset + i].uv = tex0;
                }
            }

            // skinning
            if (primitive.attributes.JOINTS_0) |joints0_accessor_index| {
                if (primitive.attributes.WEIGHTS_0) |weights0_accessor_index| {
                    if (skin_vertices.items.len != vertex_count) {
                        try skin_vertices.resize(vertex_count);
                    }
                    const joints = try gltf_buffer.getAccessorBytes(
                        Mesh.UShort4,
                        joints0_accessor_index,
                    );
                    const weights = try gltf_buffer.getAccessorBytes(
                        Vec4,
                        weights0_accessor_index,
                    );
                    for (joints, weights, 0..) |j, w, i| {
                        skin_vertices.items[vertex_offset + i] = .{
                            .jonts = j,
                            .weights = w,
                        };
                    }
                }
            }

            if (primitive.indices) |indices_accessor_index| {
                // indies
                const index_accessor = gltf.accessors[indices_accessor_index];
                if (!std.mem.eql(u8, index_accessor.type, "SCALAR")) {
                    return error.IndexNotScalar;
                }
                switch (index_accessor.componentType) {
                    .byte => {
                        const indices = try gltf_buffer.getAccessorBytes(
                            u8,
                            indices_accessor_index,
                        );
                        for (indices, 0..) |index, i| {
                            mesh_indices.items[index_offset + i] = @as(
                                u16,
                                @intCast(index),
                            ) + @as(
                                u16,
                                @intCast(vertex_offset),
                            );
                        }
                    },
                    .ushort => {
                        const indices = try gltf_buffer.getAccessorBytes(
                            u16,
                            indices_accessor_index,
                        );
                        for (indices, 0..) |index, i| {
                            mesh_indices.items[index_offset + i] = index + @as(
                                u16,
                                @intCast(vertex_offset),
                            );
                        }
                    },
                    .uint => {
                        const indices = try gltf_buffer.getAccessorBytes(
                            u32,
                            indices_accessor_index,
                        );
                        for (indices, 0..) |index, i| {
                            mesh_indices.items[index_offset + i] = @as(
                                // TODO
                                u16,
                                @intCast(index),
                            ) + @as(
                                u16,
                                @intCast(vertex_offset),
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
                        if (getSourceOrKtx(texture)) |source| {
                            const image_bytes = try gltf_buffer.getImageBytes(source);
                            const sampler = if (texture.sampler) |sampler_index| gltf.samplers[sampler_index] else null;
                            if (Image.init(image_bytes)) |image| {
                                defer image.deinit();
                                color_texture = Texture.init(
                                    image,
                                    to_sokol_sampler(sampler),
                                );
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
                index_offset += index_accessor.count;
            } else {
                unreachable;
            }

            if (primitive.targets.len > 0) {
                if (target_count) |count| {
                    if (primitive.targets.len != count) {
                        @panic("primitive has diffrent targets");
                    }
                } else {
                    target_count = @intCast(primitive.targets.len);
                    for (0..primitive.targets.len) |_| {
                        try targets.append(.{
                            .positions = try self.allocator.alloc(Vec3, vertex_count),
                        });
                    }
                }

                for (primitive.targets, targets.items) |gltf_target, *target| {
                    const positions = try gltf_buffer.getAccessorBytes(
                        Vec3,
                        gltf_target.POSITION,
                    );
                    for (positions, 0..) |pos, i| {
                        target.positions[vertex_offset + i] = pos;
                    }
                }
            }

            vertex_offset += pos_accessor.count;
        }

        self.meshes[mesh_index] = Mesh.init(
            try mesh_vertices.toOwnedSlice(),
            if (skin_vertices.items.len > 0) try skin_vertices.toOwnedSlice() else null,
            mesh_indices.items,
            try submeshes.toOwnedSlice(),
            try targets.toOwnedSlice(),
        );
    }

    for (gltf.nodes, 0..) |node, i| {
        self.node_matrices[i] = Mat4.identity;
        self.node_deforms[i] = .{};
        if (node.mesh) |mesh_index| {
            const deform = &self.node_deforms[i];
            const mesh = &self.meshes[mesh_index];
            if (mesh.targets.len > 0) {
                deform.morph = .{};
            }

            if (node.skin) |skin_index| {
                const gltf_skin = gltf.skins[skin_index];
                const inversed = if (gltf_skin.inverseBindMatrices) |inversed_index|
                    try gltf_buffer.getAccessorBytes(
                        Mat4,
                        inversed_index,
                    )
                else blk: {
                    const inversed = try self.allocator.alloc(Mat4, gltf_skin.joints.len);
                    for (0..inversed.len) |j| inversed[j] = Mat4.identity;
                    break :blk inversed;
                };

                var joints = try self.allocator.alloc(Deform.Skin.Joint, gltf_skin.joints.len);
                for (gltf_skin.joints, 0..) |node_index, joint_index| {
                    joints[joint_index] = .{
                        .node_index = @intCast(node_index),
                        .bind_matrix = inversed[joint_index],
                    };
                }

                deform.skin = Deform.Skin{ .joints = joints };
            }

            if (deform.skin != null or deform.morph != null) {
                try deform.init(
                    self.allocator,
                    mesh,
                );
            }
        }
    }
}

fn getSourceOrKtx(texture: zigltf.Texture) ?u32 {
    if (texture.extensions) |extensions| {
        if (extensions.KHR_texture_basisu) |basisu| {
            return basisu.source;
        }
    }
    return texture.source;
}

fn load_animation(
    self: *@This(),
    gltf: zigltf.Gltf,
    gltf_buffer: *zigltf.GltfBuffer,
) !void {
    if (gltf.animations.len > 0) {
        var animations = std.ArrayList(Animation).init(self.allocator);

        for (gltf.animations) |gltf_animation| {
            var curves = std.ArrayList(Animation.Curve).init(self.allocator);
            var duration: f32 = 0;

            for (gltf_animation.channels) |channel| {
                const sampler = gltf_animation.samplers[channel.sampler];
                const node_index = channel.target.node;
                if (std.mem.eql(u8, channel.target.path, "translation")) {
                    const curve = Animation.Vec3Curve{
                        .values = .{
                            .input = try gltf_buffer.getAccessorBytes(f32, sampler.input),
                            .output = try gltf_buffer.getAccessorBytes(Vec3, sampler.output),
                        },
                    };
                    duration = @max(duration, curve.values.duration());
                    try curves.append(.{
                        .node_index = node_index,
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
                        .node_index = node_index,
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
                        .node_index = node_index,
                        .target = .{ .scale = curve },
                    });
                } else if (std.mem.eql(u8, channel.target.path, "weights")) {
                    const node = gltf.nodes[node_index];
                    const mesh_index = node.mesh orelse {
                        @panic("no mesh");
                    };
                    const input = try gltf_buffer.getAccessorBytes(f32, sampler.input);
                    const output = try gltf_buffer.getAccessorBytes(f32, sampler.output);
                    const target_count = self.meshes[mesh_index].targets.len;
                    if (target_count * input.len != output.len) {
                        @panic("target_count * input.len != output.len");
                    }
                    const curve = Animation.FloatCurve{
                        .target_count = @intCast(target_count),
                        .values = .{
                            .input = input,
                            .output = output,
                        },
                        .buffer = try self.allocator.alloc(f32, target_count),
                    };
                    duration = @max(duration, curve.values.duration());
                    try curves.append(.{
                        .node_index = node_index,
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
        self.current_animation = 0;
    }

    _ = self.update(0);
}

fn to_sokol_sampler(_src: ?zigltf.Sampler) ?sg.SamplerDesc {
    if (_src) |src| {
        return .{
            .wrap_u = if (src.wrapS) |wrapS| to_sokol_wrap(wrapS) else .REPEAT,
            .wrap_v = if (src.wrapT) |wrapT| to_sokol_wrap(wrapT) else .REPEAT,
            .min_filter = if (src.minFilter) |minFilter|
                to_sokol_minFilter(minFilter)
            else
                .LINEAR,
            .mag_filter = if (src.magFilter) |magFilter|
                to_sokol_magFilter(magFilter)
            else
                .LINEAR,
            .compare = .NEVER,
        };
    } else {
        return null;
    }
}

fn to_sokol_wrap(src: zigltf.Sampler.WrapMode) sg.Wrap {
    return switch (src) {
        .CLAMP_TO_EDGE => .CLAMP_TO_EDGE,
        .MIRRORED_REPEAT => .MIRRORED_REPEAT,
        .REPEAT => .REPEAT,
    };
}
fn to_sokol_minFilter(src: zigltf.Sampler.MinFilter) sg.Filter {
    return switch (src) {
        .NEAREST => .NEAREST,
        .LINEAR => .LINEAR,
        .NEAREST_MIPMAP_NEAREST => .NEAREST, //.NEAREST_MIPMAP_NEAREST,
        .LINEAR_MIPMAP_NEAREST => .LINEAR, //.LINEAR_MIPMAP_NEAREST,
        .NEAREST_MIPMAP_LINEAR => .NEAREST, //.NEAREST_MIPMAP_LINEAR,
        .LINEAR_MIPMAP_LINEAR => .LINEAR, //.LINEAR_MIPMAP_LINEAR,
    };
}
fn to_sokol_magFilter(src: zigltf.Sampler.MagFilter) sg.Filter {
    return switch (src) {
        .NEAREST => .NEAREST,
        .LINEAR => .LINEAR,
    };
}

pub const MinFilter = enum(u32) {};

pub fn update(self: *@This(), time: f32) ?f32 {
    const gltf = self.gltf orelse {
        return null;
    };

    // update animation
    var _looptime: ?f32 = null;
    if (self.current_animation) |current| {
        if (current < self.animations.len) {
            const animation = &self.animations[current];
            const looptime = animation.loopTime(time);
            _looptime = looptime;
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
                        const w = values.sample(looptime);
                        gltf.value.nodes[curve.node_index].weights = w;
                    },
                }
            }
        }
    }

    // calc world matrix
    for (gltf.value.scenes[0].nodes) |root_node_index| {
        self.update_node_matrix(
            gltf.value,
            root_node_index,
            Mat4.identity,
        );
    }

    // update mesh deform
    for (gltf.value.nodes, 0..) |node, node_index| {
        if (node.mesh) |mesh_index| {
            const base_mesh = &self.meshes[mesh_index];
            const deform = &self.node_deforms[node_index];
            if (deform.skin != null or deform.morph != null) {
                deform.update(
                    base_mesh,
                    self.node_matrices,
                    node.weights,
                );
            }
        }
    }

    return _looptime;
}

fn update_node_matrix(
    self: *@This(),
    gltf: zigltf.Gltf,
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
        break :block Mat4.fromTrs(.{ .t = t, .r = r, .s = s });
    };
    const model_matrix = local_matrix.mul(parent_matrix);
    self.node_matrices[node_index] = model_matrix;

    for (node.children) |child_node_index| {
        self.update_node_matrix(gltf, child_node_index, model_matrix);
    }
}

pub fn draw(self: *@This(), camera: Camera) void {
    if (self.gltf) |json| {
        sg.applyPipeline(self.pip);
        const vp = camera.viewProjectionMatrix();
        for (0..json.value.nodes.len) |i| {
            self.draw_node(json.value, vp, @intCast(i));
        }
    }
}

fn draw_node(
    self: *@This(),
    gltf: zigltf.Gltf,
    vp: Mat4,
    node_index: u32,
) void {
    const node = gltf.nodes[node_index];

    const model_matrix = self.node_matrices[node_index];
    if (node.mesh) |mesh_index| {
        self.draw_mesh(node_index, mesh_index, vp, model_matrix);
    }
}

fn draw_mesh(
    self: *@This(),
    node_index: u32,
    mesh_index: u32,
    vp: Mat4,
    model: Mat4,
) void {
    var base_mesh = &self.meshes[mesh_index];
    var deform = &self.node_deforms[node_index];
    var bind = if (deform.morph == null and deform.skin == null)
        &base_mesh.bind
    else blk: {
        sg.updateBuffer(deform.bind.vertex_buffers[0], .{
            .ptr = &deform.deform_vertices[0],
            .size = @sizeOf(Mesh.Vertex) * deform.deform_vertices.len,
        });
        break :blk &deform.bind;
    };

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

    var offset: u32 = 0;
    for (base_mesh.submeshes) |*submesh| {
        sg.applyUniforms(
            .FS,
            shader.SLOT_submesh_params,
            sg.asRange(&submesh.submesh_params),
        );

        bind.fs = submesh.color_texture.fs;
        sg.applyBindings(bind.*);

        sg.draw(offset, submesh.draw_count, 1);

        offset += submesh.draw_count;
    }
}
