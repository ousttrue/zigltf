const sokol = @import("sokol");
const sg = sokol.gfx;
const shader = @import("gltf.glsl.zig");
const Image = @import("Image.zig");

pub const Texture = @This();
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
