const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;

const title = "animation";
const zigltf = @import("zigltf");
const rowmath = @import("rowmath");
const framework = @import("framework");
// const utils = @import("utils");
const Scene = framework.Scene;
// const gltf_fetcher = @import("gltf_fetcher.zig");

// https://github.khronos.org/glTF-Tutorials/gltfTutorial/gltfTutorial_003_MinimalGltfFile.html
const minimal_gltf =
    \\{
    \\  "scene": 0,
    \\  "scenes" : [
    \\    {
    \\      "nodes" : [ 0 ]
    \\    }
    \\  ],
    \\  
    \\  "nodes" : [
    \\    {
    \\      "mesh" : 0,
    \\      "rotation" : [ 0.0, 0.0, 0.0, 1.0 ]
    \\    }
    \\  ],
    \\  
    \\  "meshes" : [
    \\    {
    \\      "primitives" : [ {
    \\        "attributes" : {
    \\          "POSITION" : 1
    \\        },
    \\        "indices" : 0
    \\      } ]
    \\    }
    \\  ],
    \\  
    \\  "animations": [
    \\    {
    \\      "samplers" : [
    \\        {
    \\          "input" : 2,
    \\          "interpolation" : "LINEAR",
    \\          "output" : 3
    \\        }
    \\      ],
    \\      "channels" : [ {
    \\        "sampler" : 0,
    \\        "target" : {
    \\          "node" : 0,
    \\          "path" : "rotation"
    \\        }
    \\      } ]
    \\    }
    \\  ],
    \\
    \\  "buffers" : [
    \\    {
    \\      "uri" : "data:application/octet-stream;base64,AAABAAIAAAAAAAAAAAAAAAAAAAAAAIA/AAAAAAAAAAAAAAAAAACAPwAAAAA=",
    \\      "byteLength" : 44
    \\    },
    \\    {
    \\      "uri" : "data:application/octet-stream;base64,AAAAAAAAgD4AAAA/AABAPwAAgD8AAAAAAAAAAAAAAAAAAIA/AAAAAAAAAAD0/TQ/9P00PwAAAAAAAAAAAACAPwAAAAAAAAAAAAAAAPT9ND/0/TS/AAAAAAAAAAAAAAAAAACAPw==",
    \\      "byteLength" : 100
    \\    }
    \\  ],
    \\  "bufferViews" : [
    \\    {
    \\      "buffer" : 0,
    \\      "byteOffset" : 0,
    \\      "byteLength" : 6,
    \\      "target" : 34963
    \\    },
    \\    {
    \\      "buffer" : 0,
    \\      "byteOffset" : 8,
    \\      "byteLength" : 36,
    \\      "target" : 34962
    \\    },
    \\    {
    \\      "buffer" : 1,
    \\      "byteOffset" : 0,
    \\      "byteLength" : 100
    \\    }
    \\  ],
    \\  "accessors" : [
    \\    {
    \\      "bufferView" : 0,
    \\      "byteOffset" : 0,
    \\      "componentType" : 5123,
    \\      "count" : 3,
    \\      "type" : "SCALAR",
    \\      "max" : [ 2 ],
    \\      "min" : [ 0 ]
    \\    },
    \\    {
    \\      "bufferView" : 1,
    \\      "byteOffset" : 0,
    \\      "componentType" : 5126,
    \\      "count" : 3,
    \\      "type" : "VEC3",
    \\      "max" : [ 1.0, 1.0, 0.0 ],
    \\      "min" : [ 0.0, 0.0, 0.0 ]
    \\    },
    \\    {
    \\      "bufferView" : 2,
    \\      "byteOffset" : 0,
    \\      "componentType" : 5126,
    \\      "count" : 5,
    \\      "type" : "SCALAR",
    \\      "max" : [ 1.0 ],
    \\      "min" : [ 0.0 ]
    \\    },
    \\    {
    \\      "bufferView" : 2,
    \\      "byteOffset" : 20,
    \\      "componentType" : 5126,
    \\      "count" : 5,
    \\      "type" : "VEC4",
    \\      "max" : [ 0.0, 0.0, 1.0, 1.0 ],
    \\      "min" : [ 0.0, 0.0, 0.0, -0.707 ]
    \\    }
    \\  ],
    \\  
    \\  "asset" : {
    \\    "version" : "2.0"
    \\  }
    \\  
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
    sokol.time.setup();
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

    // build
    state.scene.load(parsed, &.{}) catch |e| {
        std.debug.print("{s}\n", .{@errorName(e)});
        @panic("Scene.load");
    };
}

export fn frame() void {
    state.input.screen_width = sokol.app.widthf();
    state.input.screen_height = sokol.app.heightf();
    state.orbit.frame(state.input);
    state.input.mouse_wheel = 0;

    const now = sokol.time.now();
    const sec: f32 = @floatCast(sokol.time.sec(now));

    sokol.debugtext.canvas(sokol.app.widthf() * 0.5, sokol.app.heightf() * 0.5);
    sokol.debugtext.pos(0.5, 0.5);
    sokol.debugtext.puts(title);
    sokol.debugtext.puts("\n");
    var buf: [32]u8 = undefined;

    {
        const formated = std.fmt.bufPrintZ(
            &buf,
            "now {d:.2} sec\n",
            .{sec},
        ) catch @panic("bufPrintZ");
        sokol.debugtext.puts(formated);
    }

    if (state.scene.update(sec)) |looptime| {
        const formated = std.fmt.bufPrintZ(
            &buf,
            "loop {d:.2} sec\n",
            .{looptime},
        ) catch @panic("bufPrintZ");
        sokol.debugtext.puts(formated);
    }

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
