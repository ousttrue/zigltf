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
                const begin = self.values.output[range.begin];
                const end = self.values.output[range.begin + 1];
                return .{
                    .x = std.math.lerp(begin.x, end.x, range.factor),
                    .y = std.math.lerp(begin.y, end.y, range.factor),
                    .z = std.math.lerp(begin.z, end.z, range.factor),
                };
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
                const begin = self.values.output[range.begin];
                const end = self.values.output[range.begin + 1];
                return Quat.slerp(begin, end, range.factor);
            },
        }
    }
};

pub const FloatCurve = struct {
    values: TimeValues(f32),
    target_count: u32,
    buffer: []f32,
    pub fn sample(self: @This(), time: f32) []const f32 {
        switch (self.values.getTimeSection(time)) {
            .index => |i| {
                const begin = i * self.target_count;
                return self.values.output[begin .. begin + self.target_count];
            },
            .range => |range| {
                const begin_start = range.begin * self.target_count;
                const end_start = begin_start + self.target_count;
                const begin = self.values.output[begin_start..end_start];
                const end = self.values.output[end_start .. end_start + self.target_count];
                for (begin, end, 0..) |b, e, i| {
                    self.buffer[i] = std.math.lerp(b, e, range.factor);
                }
                return self.buffer;
            },
        }
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
