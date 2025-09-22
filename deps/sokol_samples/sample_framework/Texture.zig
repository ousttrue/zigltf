const sokol = @import("sokol");
const sg = sokol.gfx;
const shader = @import("gltf.glsl.zig");
const Image = @import("Image.zig");

pub const Texture = @This();
fs_views: [28]sg.View = [_]sg.View{.{}} ** 28,
fs_samplers: [16]sg.Sampler = [_]sg.Sampler{.{}} ** 16,

pub fn init(image: Image, _sampler: ?sg.SamplerDesc) @This() {
    // init sokol
    var texture = Texture{};
    texture.fs_views[shader.VIEW_colorTexture2D] = sg.allocView();
    texture.fs_samplers[shader.SMP_colorTextureSmp] = sg.allocSampler();
    sg.initSampler(
        texture.fs_samplers[shader.SMP_colorTextureSmp],
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
    img_desc.data.mip_levels[0] = .{
        .ptr = &image.pixels[0],
        .size = image.byteLength(),
    };

    const img = sg.makeImage(img_desc);
    // state.allocator.free(state.pixels);
    // state.pixels = &.{};
    sg.initView(texture.fs_views[shader.VIEW_colorTexture2D], .{
        .texture = .{ .image = img },
    });

    return texture;
}
