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

    allocator: Allocator,
    dots: ArrayList(Coordinate),
    size_x: usize,
    size_y: usize,

    pub fn parse(allocator: Allocator, string: []const u8) !Self {
        var dots = ArrayList(Coordinate).init(allocator);
        errdefer dots.deinit();

        var max_x: usize = 0;
        var max_y: usize = 0;

        var it = mem.tokenize(u8, string, "\n");
        while (it.next()) |line| {
            const index = mem.indexOfScalar(u8, line, ',').?;
            const x = try fmt.parseUnsigned(usize, line[0..index], 10);
            if (x > max_x) max_x = x;
            const y = try fmt.parseUnsigned(usize, line[index + 1 ..], 10);
            if (y > max_y) max_y = y;

            try dots.append(.{ .x = x, .y = y });
        }

        return Self{
            .allocator = allocator,
            .dots = dots,
            .size_x = max_x,
            .size_y = max_y,
        };
    }

    pub fn deinit(self: Self) void {
        self.dots.deinit();
    }

    pub fn format(
        self: Self,
        comptime fmt_: []const u8,
        options: fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt_;
        _ = options;

        var y: usize = 0;
        while (y < self.size_y) : (y += 1) {
            if (y != 0) try writer.print("\n", .{});

            var x: usize = 0;
            while (x <= self.size_x) : (x += 1) {
                for (self.dots.items) |dot| {
                    if (dot.x == x and dot.y == y) {
                        try writer.print("#", .{});
                        break;
                    }
                } else {
                    try writer.print(".", .{});
                }
            }
        }
    }

    pub fn doFold(self: *Self, fold: Fold) !void {
        var to_remove = ArrayList(usize).init(self.allocator);
        defer to_remove.deinit();

        switch (fold.direction) {
            .horizontal => self.size_x = fold.distance,
            .vertical => self.size_y = fold.distance,
        }

        for (self.dots.items) |*dot, i| {
            var changed = false;

            switch (fold.direction) {
                .horizontal => if (dot.*.x > fold.distance) {
                    dot.*.x = fold.distance - (dot.*.x - fold.distance);
                    changed = true;
                },
                .vertical => if (dot.*.y > fold.distance) {
                    dot.*.y = fold.distance - (dot.*.y - fold.distance);
                    changed = true;
                },
            }

            if (!changed) continue;

            for (self.dots.items) |other, j| {
                if (i == j) continue;

                if (meta.eql(dot.*, other)) {
                    try to_remove.append(i);
                    break;
                }
            }
        }

        for (to_remove.items) |_, j|
            _ = self.dots.orderedRemove(to_remove.items[to_remove.items.len - j - 1]);
    }
};

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const index = mem.indexOf(u8, file, "\n\n").?;

    var paper = try Paper.parse(allocator, file[0..index]);
    defer paper.deinit();

    var it = mem.tokenize(u8, file[index + 2 ..], "\n");
    while (it.next()) |line| {
        const fold = try Paper.Fold.parse(line);
        try paper.doFold(fold);
    }
    try stdout.print("{}\n", .{paper});
}
