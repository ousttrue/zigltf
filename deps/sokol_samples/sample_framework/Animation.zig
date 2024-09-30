const std = @import("std");
const rowmath = @import("rowmath");
const Vec3 = rowmath.Vec3;
const Quat = rowmath.Quat;

const TimeSection = union(enum) {
    index: usize,
    range: struct {
        begin: usize,
        factor: f32,
    },
};

pub fn TimeValues(T: type) type {
    return struct {
        input: []const f32,
        output: []const T,
        pub fn duration(self: @This()) f32 {
            return self.input[self.input.len - 1];
        }

        pub fn getTimeSection(self: @This(), time: f32) TimeSection {
            if (time <= self.input[0]) {
                return .{ .index = 0 };
            }

            if (time >= self.input[self.input.len - 1]) {
                return .{ .index = self.input.len - 1 };
            }

            for (self.input, 0..) |end, i| {
                if (end >= time) {
                    const begin = self.input[i - 1];
                    return .{ .range = .{
                        .begin = i - 1,
                        .factor = (time - begin) / (end - begin),
                    } };
                }
            }

            unreachable;
        }
    };
}

pub const Vec3Curve = struct {
    values: TimeValues(Vec3),
    pub fn sample(self: @This(), time: f32) Vec3 {
        switch (self.values.getTimeSection(time)) {
            .index => |i| {
                return self.values.output[i];
            },
            .range => |range| {
                // todo: learp, slserp... etc
                return self.values.output[range.begin];
            },
        }
    }
};

pub const QuatCurve = struct {
    values: TimeValues(Quat),
    pub fn sample(self: @This(), time: f32) Quat {
        switch (self.values.getTimeSection(time)) {
            .index => |i| {
                return self.values.output[i];
            },
            .range => |range| {
                // todo: learp, slserp... etc
                return self.values.output[range.begin];
            },
        }
    }
};

pub const FloatCurve = struct {
    values: TimeValues(f32),
    pub fn sample(self: @This(), time: f32) []f32 {
        _ = self;
        _ = time;
        unreachable;
        // return [0]f32{};
    }
};

pub const Target = union(enum) {
    translation: Vec3Curve,
    rotation: QuatCurve,
    scale: Vec3Curve,
    weights: FloatCurve,
};

pub const Curve = struct {
    node_index: u32,

    target: Target,
};

curves: []Curve,
duration: f32,

pub fn loopTime(self: @This(), time: f32) f32 {
    return @mod(time, self.duration);
}
