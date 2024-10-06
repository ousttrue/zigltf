const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;

const title = "skin";
const zigltf = @import("zigltf");
const rowmath = @import("rowmath");
const framework = @import("framework");
const Scene = framework.Scene;

const minimal_gltf =
    \\{
    \\  "scene" : 0,
    \\  "scenes" : [ {
    \\    "nodes" : [ 0, 1 ]
    \\  } ],
    \\  
    \\  "nodes" : [ {
    \\    "skin" : 0,
    \\    "mesh" : 0
    \\  }, {
    \\    "children" : [ 2 ]
    \\  }, {
    \\    "translation" : [ 0.0, 1.0, 0.0 ],
    \\    "rotation" : [ 0.0, 0.0, 0.0, 1.0 ]
    \\  } ],
    \\  
    \\  "meshes" : [ {
    \\    "primitives" : [ {
    \\      "attributes" : {
    \\        "POSITION" : 1,
    \\        "JOINTS_0" : 2,
    \\        "WEIGHTS_0" : 3
    \\      },
    \\      "indices" : 0
    \\    } ]
    \\  } ],
    \\
    \\  "skins" : [ {
    \\    "inverseBindMatrices" : 4,
    \\    "joints" : [ 1, 2 ]
    \\  } ],
    \\  
    \\  "animations" : [ {
    \\    "channels" : [ {
    \\      "sampler" : 0,
    \\      "target" : {
    \\        "node" : 2,
    \\        "path" : "rotation"
    \\      }
    \\    } ],
    \\    "samplers" : [ {
    \\      "input" : 5,
    \\      "interpolation" : "LINEAR",
    \\      "output" : 6
    \\    } ]
    \\  } ],
    \\  
    \\  "buffers" : [ {
    \\    "uri" : "data:application/gltf-buffer;base64,AAABAAMAAAADAAIAAgADAAUAAgAFAAQABAAFAAcABAAHAAYABgAHAAkABgAJAAgAAAAAvwAAAAAAAAAAAAAAPwAAAAAAAAAAAAAAvwAAAD8AAAAAAAAAPwAAAD8AAAAAAAAAvwAAgD8AAAAAAAAAPwAAgD8AAAAAAAAAvwAAwD8AAAAAAAAAPwAAwD8AAAAAAAAAvwAAAEAAAAAAAAAAPwAAAEAAAAAA",
    \\    "byteLength" : 168
    \\  }, {
    \\    "uri" : "data:application/gltf-buffer;base64,AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAgD8AAAAAAAAAAAAAAAAAAIA/AAAAAAAAAAAAAAAAAABAPwAAgD4AAAAAAAAAAAAAQD8AAIA+AAAAAAAAAAAAAAA/AAAAPwAAAAAAAAAAAAAAPwAAAD8AAAAAAAAAAAAAgD4AAEA/AAAAAAAAAAAAAIA+AABAPwAAAAAAAAAAAAAAAAAAgD8AAAAAAAAAAAAAAAAAAIA/AAAAAAAAAAA=",
    \\    "byteLength" : 320
    \\  }, {
    \\    "uri" : "data:application/gltf-buffer;base64,AACAPwAAAAAAAAAAAAAAAAAAAAAAAIA/AAAAAAAAAAAAAAAAAAAAAAAAgD8AAAAAAAAAAAAAAAAAAAAAAACAPwAAgD8AAAAAAAAAAAAAAAAAAAAAAACAPwAAAAAAAAAAAAAAAAAAAAAAAIA/AAAAAAAAAAAAAIC/AAAAAAAAgD8=",
    \\    "byteLength" : 128
    \\  }, {
    \\    "uri" : "data:application/gltf-buffer;base64,AAAAAAAAAD8AAIA/AADAPwAAAEAAACBAAABAQAAAYEAAAIBAAACQQAAAoEAAALBAAAAAAAAAAAAAAAAAAACAPwAAAAAAAAAAkxjEPkSLbD8AAAAAAAAAAPT9ND/0/TQ/AAAAAAAAAAD0/TQ/9P00PwAAAAAAAAAAkxjEPkSLbD8AAAAAAAAAAAAAAAAAAIA/AAAAAAAAAAAAAAAAAACAPwAAAAAAAAAAkxjEvkSLbD8AAAAAAAAAAPT9NL/0/TQ/AAAAAAAAAAD0/TS/9P00PwAAAAAAAAAAkxjEvkSLbD8AAAAAAAAAAAAAAAAAAIA/",
    \\    "byteLength" : 240
    \\  } ],
    \\  
    \\  "bufferViews" : [ {
    \\    "buffer" : 0,
    \\    "byteLength" : 48,
    \\    "target" : 34963
    \\  }, {
    \\    "buffer" : 0,
    \\    "byteOffset" : 48,
    \\    "byteLength" : 120,
    \\    "target" : 34962
    \\  }, {
    \\    "buffer" : 1,
    \\    "byteLength" : 320,
    \\    "byteStride" : 16
    \\  }, {
    \\    "buffer" : 2,
    \\    "byteLength" : 128
    \\  }, {
    \\    "buffer" : 3,
    \\    "byteLength" : 240
    \\  } ],
    \\
    \\  "accessors" : [ {
    \\    "bufferView" : 0,
    \\    "componentType" : 5123,
    \\    "count" : 24,
    \\    "type" : "SCALAR"
    \\  }, {
    \\    "bufferView" : 1,
    \\    "componentType" : 5126,
    \\    "count" : 10,
    \\    "type" : "VEC3",
    \\    "max" : [ 0.5, 2.0, 0.0 ],
    \\    "min" : [ -0.5, 0.0, 0.0 ]
    \\  }, {
    \\    "bufferView" : 2,
    \\    "componentType" : 5123,
    \\    "count" : 10,
    \\    "type" : "VEC4"
    \\  }, {
    \\    "bufferView" : 2,
    \\    "byteOffset" : 160,
    \\    "componentType" : 5126,
    \\    "count" : 10,
    \\    "type" : "VEC4"
    \\  }, {
    \\    "bufferView" : 3,
    \\    "componentType" : 5126,
    \\    "count" : 2,
    \\    "type" : "MAT4"
    \\  }, {
    \\    "bufferView" : 4,
    \\    "componentType" : 5126,
    \\    "count" : 12,
    \\    "type" : "SCALAR",
    \\    "max" : [ 5.5 ],
    \\    "min" : [ 0.0 ]
    \\  }, {
    \\    "bufferView" : 4,
    \\    "byteOffset" : 48,
    \\    "componentType" : 5126,
    \\    "count" : 12,
    \\    "type" : "VEC4",
    \\    "max" : [ 0.0, 0.0, 0.707, 1.0 ],
    \\    "min" : [ 0.0, 0.0, -0.707, 0.707 ]
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
    state.scene.load(parsed, null) catch |e| {
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
