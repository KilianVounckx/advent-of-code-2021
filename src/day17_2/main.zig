const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const math = std.math;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

pub const Vector = struct {
    const Self = @This();

    x: i64 = 0,
    y: i64 = 0,

    pub fn afterNSteps(n: i64, vx: i64, vy: i64) Self {
        const y = n * vy - @divExact(n * (n - 1), 2);

        const x = if (vx <= n)
            @divExact(vx * (vx + 1), 2)
        else
            n * vx - @divExact(n * (n - 1), 2);

        return .{ .x = x, .y = y };
    }
};

pub const Area = struct {
    const Self = @This();

    left: i64,
    right: i64,
    top: i64,
    bottom: i64,

    pub fn parse(string: []const u8) !Self {
        const left_index = "target area: x=".len;
        const dot_x_index = mem.indexOf(u8, string[left_index..], "..") orelse
            return error.InvalidArea;
        const right_index = left_index + dot_x_index + "..".len;
        const comma_index = mem.indexOf(u8, string[right_index..], ", y=") orelse
            return error.InvalidArea;
        const bottom_index = right_index + comma_index + ", y=".len;
        const dot_y_index = mem.indexOf(u8, string[bottom_index..], "..") orelse
            return error.InvalidArea;
        const top_index = bottom_index + dot_y_index + "..".len;

        const left = try fmt.parseInt(i64, string[left_index .. left_index + dot_x_index], 10);
        const right = try fmt.parseInt(i64, string[right_index .. right_index + comma_index], 10);
        const bottom = try fmt.parseInt(i64, string[bottom_index .. bottom_index + dot_y_index], 10);
        const top = try fmt.parseInt(i64, string[top_index..], 10);

        return Self{
            .left = left,
            .right = right,
            .top = top,
            .bottom = bottom,
        };
    }

    pub fn contains(self: Self, point: Vector) bool {
        if (point.x < self.left) return false;
        if (point.x > self.right) return false;
        if (point.y < self.bottom) return false;
        if (point.y > self.top) return false;
        return true;
    }
};

pub fn nsFromVy(allocator: Allocator, vy: i64, l: i64, h: i64) ![]i64 {
    const d_low = math.sqrt(@intToFloat(f64, (2 * vy + 1) * (2 * vy + 1) - 8 * h));
    const low = (2.0 * @intToFloat(f64, vy) + 1.0 + d_low) / 2.0;
    const lower_bound = @floatToInt(i64, math.ceil(low));

    const d_high = math.sqrt(@intToFloat(f64, (2 * vy + 1) * (2 * vy + 1) - 8 * l));
    const high = (2.0 * @intToFloat(f64, vy) + 1.0 + d_high) / 2.0;
    const higher_bound = @floatToInt(i64, math.floor(high));

    var result = try allocator.alloc(i64, @intCast(usize, higher_bound - lower_bound + 1));
    var n: i64 = lower_bound;
    var i: usize = 0;
    while (n <= higher_bound) : ({
        n += 1;
        i += 1;
    }) {
        result[i] = n;
    }
    return result;
}

pub fn maxHeightFrom(y: i64) i64 {
    const possibility1 = Vector.afterNSteps(y, 0, y).y;
    const possibility2 = Vector.afterNSteps(y + 1, 0, y).y;

    return math.max(possibility1, possibility2);
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const area = try Area.parse(file[0 .. file.len - 1]);

    var result: u64 = 0;

    var vx: i64 = undefined;
    var vy: i64 = area.bottom;
    while (true) : (vy += 1) {
        const ns = try nsFromVy(allocator, vy, area.bottom, area.top);
        defer allocator.free(ns);

        var xs = ArrayList(i64).init(allocator);
        defer xs.deinit();

        for (ns) |n| {
            vx = 1;
            while (true) : (vx += 1) {
                if (mem.indexOfScalar(i64, xs.items, vx)) |_| continue;
                const place = Vector.afterNSteps(n, vx, vy);
                if (place.x > area.right) break;
                if (area.contains(place)) {
                    try xs.append(vx);
                    result += 1;
                }
            }
            std.debug.print("vy: {d}, result: {d}\n", .{ vy, result });
        }
    }
}
