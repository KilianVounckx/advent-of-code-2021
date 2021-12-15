const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = mem.Allocator;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

pub const Point = struct {
    const Self = @This();

    x: i32,
    y: i32,

    pub fn parse(string: []const u8) !Self {
        const index = mem.indexOf(u8, string, ",") orelse return error.InvalidNumber;

        const x = try fmt.parseInt(i32, string[0..index], 10);
        const y = try fmt.parseInt(i32, string[index + 1 ..], 10);

        return Self{ .x = x, .y = y };
    }
};

pub const Line = struct {
    const Self = @This();

    p1: Point,
    p2: Point,

    pub fn parse(string: []const u8) !Self {
        const index = mem.indexOf(u8, string, " -> ") orelse return error.InvalidLine;

        const p1 = try Point.parse(string[0..index]);
        const p2 = try Point.parse(string[index + 4 ..]);

        return Self{ .p1 = p1, .p2 = p2 };
    }

    pub fn points(self: Self, allocator: Allocator) ![]Point {
        var result = ArrayList(Point).init(allocator);
        errdefer result.deinit();

        if (self.p1.x < self.p2.x) {
            var px = self.p1.x;
            if (self.p1.y < self.p2.y) {
                var py = self.p1.y;
                while (px <= self.p2.x and py <= self.p2.y) : ({
                    px += 1;
                    py += 1;
                }) try result.append(.{ .x = px, .y = py });
            }
            if (self.p1.y > self.p2.y) {
                var py = self.p1.y;
                while (px <= self.p2.x and py >= self.p2.y) : ({
                    px += 1;
                    py -= 1;
                }) try result.append(.{ .x = px, .y = py });
            } else {
                while (px <= self.p2.x) : (px += 1) try result.append(.{ .x = px, .y = self.p1.y });
            }
        } else if (self.p1.x > self.p2.x) {
            var px = self.p1.x;
            if (self.p1.y < self.p2.y) {
                var py = self.p1.y;
                while (px >= self.p2.x and py <= self.p2.y) : ({
                    px -= 1;
                    py += 1;
                }) try result.append(.{ .x = px, .y = py });
            }
            if (self.p1.y > self.p2.y) {
                var py = self.p1.y;
                while (px >= self.p2.x and py >= self.p2.y) : ({
                    px -= 1;
                    py -= 1;
                }) try result.append(.{ .x = px, .y = py });
            } else {
                while (px >= self.p2.x) : (px -= 1) try result.append(.{ .x = px, .y = self.p1.y });
            }
        } else {
            if (self.p1.y < self.p2.y) {
                var py = self.p1.y;
                while (py <= self.p2.y) : (py += 1) try result.append(.{ .x = self.p1.x, .y = py });
            } else if (self.p1.y > self.p2.y) {
                var py = self.p1.y;
                while (py >= self.p2.y) : (py -= 1) try result.append(.{ .x = self.p1.x, .y = py });
            } else {
                try result.append(.{ .x = self.p1.x, .y = self.p1.y });
            }
        }

        return result.toOwnedSlice();
    }
};

pub fn parseFile(allocator: Allocator, string: []const u8) ![]Line {
    var lines = ArrayList(Line).init(allocator);
    errdefer lines.deinit();

    var it = mem.tokenize(u8, string, "\n");
    while (it.next()) |line| try lines.append(try Line.parse(line));

    return lines.toOwnedSlice();
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try parseFile(allocator, file);
    defer allocator.free(lines);

    var counts = AutoHashMap(Point, u32).init(allocator);
    defer counts.deinit();

    for (lines) |line| {
        const points = try line.points(allocator);
        defer allocator.free(points);

        for (points) |point| {
            var res = try counts.getOrPut(point);
            if (res.found_existing) {
                res.value_ptr.* += 1;
            } else {
                res.value_ptr.* = 1;
            }
        }
    }

    var result: u32 = 0;
    var it = counts.valueIterator();
    while (it.next()) |value| if (value.* >= 2) {
        result += 1;
    };

    try stdout.print("{d}\n", .{result});
}
