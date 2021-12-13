const std = @import("std");
const fmt = std.fmt;
const meta = std.meta;
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

pub const Paper = struct {
    pub const Coordinate = struct {
        x: usize,
        y: usize,
    };

    pub const Fold = struct {
        distance: usize,
        direction: enum {
            horizontal,
            vertical,
        },

        pub fn parse(string: []const u8) !Fold {
            const index = "fold along ".len;
            const distance = try fmt.parseUnsigned(usize, string[index + 2 ..], 10);
            if (string[index] == 'x')
                return Fold{ .distance = distance, .direction = .horizontal };
            if (string[index] == 'y')
                return Fold{ .distance = distance, .direction = .vertical };
            unreachable;
        }
    };

    const Self = @This();

    allocator: *Allocator,
    dots: ArrayList(Coordinate),

    pub fn parse(allocator: *Allocator, string: []const u8) !Self {
        var dots = ArrayList(Coordinate).init(allocator);
        errdefer dots.deinit();

        var it = mem.tokenize(u8, string, "\n");
        while (it.next()) |line| {
            const index = mem.indexOfScalar(u8, line, ',').?;
            const x = try fmt.parseUnsigned(usize, line[0..index], 10);
            const y = try fmt.parseUnsigned(usize, line[index + 1 ..], 10);

            try dots.append(.{ .x = x, .y = y });
        }

        return Self{
            .allocator = allocator,
            .dots = dots,
        };
    }

    pub fn deinit(self: Self) void {
        self.dots.deinit();
    }

    pub fn doFold(self: *Self, fold: Fold) !void {
        var to_remove = ArrayList(usize).init(self.allocator);
        defer to_remove.deinit();

        for (self.dots.items) |*dot, i| {
            var new_dot = dot.*;
            var changed = false;

            switch (fold.direction) {
                .horizontal => if (new_dot.x > fold.distance) {
                    new_dot.x = fold.distance - (new_dot.x - fold.distance);
                    changed = true;
                },
                .vertical => if (new_dot.y > fold.distance) {
                    new_dot.y = fold.distance - (new_dot.y - fold.distance);
                    changed = true;
                },
            }

            if (!changed) continue;

            for (self.dots.items) |other, j| {
                if (i == j) continue;

                if (meta.eql(new_dot, other)) {
                    try to_remove.append(i);
                    break;
                }
            }
        }

        for (to_remove.items) |_, j|
            _ = self.dots.orderedRemove(to_remove.items[to_remove.items.len - j - 1]);
    }

    pub fn countDots(self: Self) usize {
        return self.dots.items.len;
    }
};

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const index = mem.indexOf(u8, file, "\n\n").?;

    var paper = try Paper.parse(&gpa.allocator, file[0..index]);
    defer paper.deinit();

    var it = mem.tokenize(u8, file[index + 2 ..], "\n");
    const fold = try Paper.Fold.parse(it.next().?);

    try paper.doFold(fold);

    try stdout.print("{d}\n", .{paper.countDots()});
}
