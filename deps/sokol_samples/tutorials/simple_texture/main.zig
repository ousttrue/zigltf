const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;

const title = "simple_texture";
const zigltf = @import("zigltf");
const rowmath = @import("rowmath");
const framework = @import("framework");
const Scene = framework.Scene;

const minimal_gltf =
    \\{
    \\  "scene": 0,
    \\  "scenes" : [ {
    \\    "nodes" : [ 0 ]
    \\  } ],
    \\  "nodes" : [ {
    \\    "mesh" : 0
    \\  } ],
    \\  "meshes" : [ {
    \\    "primitives" : [ {
    \\      "attributes" : {
    \\        "POSITION" : 1,
    \\        "TEXCOORD_0" : 2
    \\      },
    \\      "indices" : 0,
    \\      "material" : 0
    \\    } ]
    \\  } ],
    \\
    \\  "materials" : [ {
    \\    "pbrMetallicRoughness" : {
    \\      "baseColorTexture" : {
    \\        "index" : 0
    \\      },
    \\      "metallicFactor" : 0.0,
    \\      "roughnessFactor" : 1.0
    \\    }
    \\  } ],
    \\
    \\  "textures" : [ {
    \\    "sampler" : 0,
    \\    "source" : 0
    \\  } ],
    \\  "images" : [ {
    \\    "uri" : "testTexture.png"
    \\  } ],
    \\  "samplers" : [ {
    \\    "magFilter" : 9729,
    \\    "minFilter" : 9987,
    \\    "wrapS" : 33648,
    \\    "wrapT" : 33648
    \\  } ],
    \\
    \\  "buffers" : [ {
    \\    "uri" : "data:application/gltf-buffer;base64,AAABAAIAAQADAAIAAAAAAAAAAAAAAAAAAACAPwAAAAAAAAAAAAAAAAAAgD8AAAAAAACAPwAAgD8AAAAAAAAAAAAAgD8AAAAAAACAPwAAgD8AAAAAAAAAAAAAAAAAAAAAAACAPwAAAAAAAAAA",
    \\    "byteLength" : 108
    \\  } ],
    \\  "bufferViews" : [ {
    \\    "buffer" : 0,
    \\    "byteOffset" : 0,
    \\    "byteLength" : 12,
    \\    "target" : 34963
    \\  }, {
    \\    "buffer" : 0,
    \\    "byteOffset" : 12,
    \\    "byteLength" : 96,
    \\    "byteStride" : 12,
    \\    "target" : 34962
    \\  } ],
    \\  "accessors" : [ {
    \\    "bufferView" : 0,
    \\    "byteOffset" : 0,
    \\    "componentType" : 5123,
    \\    "count" : 6,
    \\    "type" : "SCALAR",
    \\    "max" : [ 3 ],
    \\    "min" : [ 0 ]
    \\  }, {
    \\    "bufferView" : 1,
    \\    "byteOffset" : 0,
    \\    "componentType" : 5126,
    \\    "count" : 4,
    \\    "type" : "VEC3",
    \\    "max" : [ 1.0, 1.0, 0.0 ],
    \\    "min" : [ 0.0, 0.0, 0.0 ]
    \\  }, {
    \\    "bufferView" : 1,
    \\    "byteOffset" : 48,
    \\    "componentType" : 5126,
    \\    "count" : 4,
    \\    "type" : "VEC2",
    \\    "max" : [ 1.0, 1.0 ],
    \\    "min" : [ 0.0, 0.0 ]
    \\  } ],
    \\
    \\  "asset" : {
    \\    "version" : "2.0"
    \\  }
    \\}
;

const state = struct {
    var pass_action = sg.PassAction{};
    var input = rowmath.InputState{};
    var orbit = rowmath.OrbitCamera{};
    var gltf: ?std.json.Parsed(zigltf.Gltf) = null;
    var scene = Scene{};
};

export fn init() void {
    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });
    sokol.gl.setup(.{
        .logger = .{ .func = sokol.log.func },
    });

    var debugtext_desc = sokol.debugtext.Desc{
        .logger = .{ .func = sokol.log.func },
    };
    debugtext_desc.fonts[0] = sokol.debugtext.fontOric();
    sokol.debugtext.setup(debugtext_desc);

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1.0 },
    };

    state.scene.init(std.heap.c_allocator);

    // parse gltf
    const allocator = std.heap.c_allocator;
    const parsed = std.json.parseFromSlice(
        zigltf.Gltf,
        allocator,
        minimal_gltf,
        .{
            .ignore_unknown_fields = true,
        },
    ) catch |e| {
        std.debug.print("{s}\n", .{@errorName(e)});
        @panic("parseFromSlice");
    };

    framework.gltf_fetcher.init(allocator);
    framework.gltf_fetcher.set_gltf("tmp.gltf", parsed, null, &on_load) catch @panic("set_gltf");
}

fn on_load(parsed: std.json.Parsed(zigltf.Gltf), binmap: std.StringHashMap([]const u8)) void {
    // build
    state.scene.load(parsed, binmap) catch |e| {
        std.debug.print("{s}\n", .{@errorName(e)});
        @panic("Scene.load");
    };
}

export fn frame() void {
    sokol.fetch.dowork();

    state.input.screen_width = sokol.app.widthf();
    state.input.screen_height = sokol.app.heightf();
    state.orbit.frame(state.input);
    state.input.mouse_wheel = 0;

    sokol.debugtext.canvas(sokol.app.widthf() * 0.5, sokol.app.heightf() * 0.5);
    sokol.debugtext.pos(0.5, 0.5);
    sokol.debugtext.puts(title);
    sokol.debugtext.puts("\n");
    sokol.debugtext.puts(framework.gltf_fetcher.state.status);

    sg.beginPass(.{
        .action = state.pass_action,
        .swapchain = sokol.glue.swapchain(),
    });
    state.scene.draw(state.orbit.camera);
    sokol.debugtext.draw();
    sg.endPass();
    sg.commit();
}

export fn event(e: [*c]const sokol.app.Event) void {
    switch (e.*.type) {
        .MOUSE_DOWN => {
            switch (e.*.mouse_button) {
                .LEFT => {
                    state.input.mouse_left = true;
                },
                .RIGHT => {
                    state.input.mouse_right = true;
                },
                .MIDDLE => {
                    state.input.mouse_middle = true;
                },
                .INVALID => {},
            }
        },
        .MOUSE_UP => {
            switch (e.*.mouse_button) {
                .LEFT => {
                    state.input.mouse_left = false;
                },
                .RIGHT => {
                    state.input.mouse_right = false;
                },
                .MIDDLE => {
                    state.input.mouse_middle = false;
                },
                .INVALID => {},
            }
        },
        .MOUSE_MOVE => {
            state.input.mouse_x = e.*.mouse_x;
            state.input.mouse_y = e.*.mouse_y;
        },
        .MOUSE_SCROLL => {
            state.input.mouse_wheel = e.*.scroll_y;
        },
        else => {},
    }
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() void {
    sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .width = 800,
        .height = 600,
        .window_title = title,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}
