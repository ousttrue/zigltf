const sokol = @import("sokol");
const sg = sokol.gfx;
const shader = @import("gltf.glsl.zig");
const stb = @import("stb/stb.zig");

pub const Vertex = struct {
    position: [3]f32,
    normal: [3]f32,
    uv: [2]f32,
};

pub const Image = struct {
    width: u32,
    height: u32,
    channels: u32,
    pixels: []const u8,

    pub const white = Image{
        .width = 2,
        .height = 2,
        .channels = 4,
        .pixels = &.{
            255, 255, 255, 255,
            255, 255, 255, 255,
            255, 255, 255, 255,
            255, 255, 255, 255,
        },
    };

    pub fn init(data: []const u8) ?@This() {
        var img_width: c_int = undefined;
        var img_height: c_int = undefined;
        var num_channels: c_int = undefined;
        const desired_channels = 4;
        const pixels = stb.image.stbi_load_from_memory(
            @ptrCast(&data[0]),
            @intCast(data.len),
            &img_width,
            &img_height,
            &num_channels,
            desired_channels,
        ) orelse {
            return null;
        };
        return .{
            .width = @intCast(img_width),
            .height = @intCast(img_height),
            .channels = @intCast(num_channels),
            .pixels = pixels[0..@intCast(img_width * img_height * num_channels)],
        };
    }

    pub fn deinit(self: @This()) void {
        stb.image.stbi_image_free(&self.pixels[0]);
    }

    pub fn byteLength(self: @This()) u32 {
        return self.width * self.height * 4;
    }
};

pub const Texture = struct {
    fs: sg.StageBindings = sg.StageBindings{},

    pub fn init(image: Image, _sampler: ?sg.SamplerDesc) @This() {
        // init sokol
        var texture = Texture{};
        texture.fs.images[shader.SLOT_colorTexture2D] = sg.allocImage();
        texture.fs.samplers[shader.SLOT_colorTextureSmp] = sg.allocSampler();
        sg.initSampler(
            texture.fs.samplers[shader.SLOT_colorTextureSmp],
            if (_sampler) |sampler|
                sampler
            else
                sg.SamplerDesc{
                    .wrap_u = .REPEAT,
                    .wrap_v = .REPEAT,
                    .min_filter = .LINEAR,
                    .mag_filter = .LINEAR,
                    .compare = .NEVER,
                },
        );

        // initialize the sokol-gfx texture
        var img_desc = sg.ImageDesc{
            .width = @intCast(image.width),
            .height = @intCast(image.height),
            // set pixel_format to RGBA8 for WebGL
            .pixel_format = .RGBA8,
        };
        img_desc.data.subimage[0][0] = .{
            .ptr = &image.pixels[0],
            .size = image.byteLength(),
        };
        sg.initImage(texture.fs.images[shader.SLOT_colorTexture2D], img_desc);

        return texture;
    }
};
pub const Submesh = struct {
    submesh_params: shader.SubmeshParams,
    draw_count: u32,
    color_texture: Texture,
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
