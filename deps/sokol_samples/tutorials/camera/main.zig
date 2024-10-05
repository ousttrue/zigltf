const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;

const title = "camera";
const zigltf = @import("zigltf");
const rowmath = @import("rowmath");
const framework = @import("framework");
const Scene = framework.Scene;

const minimal_gltf =
    \\{
    \\  "scene": 0,
    \\  "scenes" : [
    \\    {
    \\      "nodes" : [ 0, 1, 2 ]
    \\    }
    \\  ],
    \\  "nodes" : [
    \\    {
    \\      "rotation" : [ -0.383, 0.0, 0.0, 0.924 ],
    \\      "mesh" : 0
    \\    },
    \\    {
    \\      "translation" : [ 0.5, 0.5, 3.0 ],
    \\      "camera" : 0
    \\    },
    \\    {
    \\      "translation" : [ 0.5, 0.5, 3.0 ],
    \\      "camera" : 1
    \\    }
    \\  ],
    \\
    \\  "cameras" : [
    \\    {
    \\      "type": "perspective",
    \\      "perspective": {
    \\        "aspectRatio": 1.0,
    \\        "yfov": 0.7,
    \\        "zfar": 100,
    \\        "znear": 0.01
    \\      }
    \\    },
    \\    {
    \\      "type": "orthographic",
    \\      "orthographic": {
    \\        "xmag": 1.0,
    \\        "ymag": 1.0,
    \\        "zfar": 100,
    \\        "znear": 0.01
    \\      }
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
    \\  "buffers" : [
    \\    {
    \\      "uri" : "data:application/octet-stream;base64,AAABAAIAAQADAAIAAAAAAAAAAAAAAAAAAACAPwAAAAAAAAAAAAAAAAAAgD8AAAAAAACAPwAAgD8AAAAA",
    \\      "byteLength" : 60
    \\    }
    \\  ],
    \\  "bufferViews" : [
    \\    {
    \\      "buffer" : 0,
    \\      "byteOffset" : 0,
    \\      "byteLength" : 12,
    \\      "target" : 34963
    \\    },
    \\    {
    \\      "buffer" : 0,
    \\      "byteOffset" : 12,
    \\      "byteLength" : 48,
    \\      "target" : 34962
    \\    }
    \\  ],
    \\  "accessors" : [
    \\    {
    \\      "bufferView" : 0,
    \\      "byteOffset" : 0,
    \\      "componentType" : 5123,
    \\      "count" : 6,
    \\      "type" : "SCALAR",
    \\      "max" : [ 3 ],
    \\      "min" : [ 0 ]
    \\    },
    \\    {
    \\      "bufferView" : 1,
    \\      "byteOffset" : 0,
    \\      "componentType" : 5126,
    \\      "count" : 4,
    \\      "type" : "VEC3",
    \\      "max" : [ 1.0, 1.0, 0.0 ],
    \\      "min" : [ 0.0, 0.0, 0.0 ]
    \\    }
    \\  ],
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
    state.scene.init(std.heap.c_allocator);
    state.scene.load(parsed, null) catch |e| {
        std.debug.print("{s}\n", .{@errorName(e)});
        @panic("Scene.load");
    };

    if (parsed.value.cameras.len > 0) {
        const camera = parsed.value.cameras[0];
        if (std.mem.eql(u8, camera.type, "perspective")) {
            const perspective = camera.perspective orelse {
                @panic("no perspective");
            };
            state.orbit.camera.projection.fov_y_radians = perspective.yfov;
            for (parsed.value.nodes, 0..) |node, i| {
                if (node.camera) |camera_index| {
                    if (camera_index == 0) {
                        const m = state.scene.node_matrices[i];
                        const transform= rowmath.Transform.fromMatrix(m) catch @panic("Transform.fromMatrix");
                        state.orbit.camera.transform.translation = transform.rigid_transform.translation;
                        state.orbit.camera.transform.rotation = transform.rigid_transform.rotation;
                        break;
                    }
                }
            }
        } else if (std.mem.eql(u8, camera.type, "orthographic")) {} else {
            unreachable;
        }
    }
}

export fn frame() void {
    state.input.screen_width = sokol.app.widthf();
    state.input.screen_height = sokol.app.heightf();
    state.orbit.frame(state.input);
    state.input.mouse_wheel = 0;

    sokol.debugtext.canvas(sokol.app.widthf() * 0.5, sokol.app.heightf() * 0.5);
    sokol.debugtext.pos(0.5, 0.5);
    sokol.debugtext.puts(title);

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
