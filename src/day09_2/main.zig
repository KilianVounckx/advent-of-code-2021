const std = @import("std");
const mem = std.mem;
const meta = std.meta;
const sort = std.sort;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

pub const HeightMap = struct {
    pub const Point = struct {
        x: usize,
        y: usize,

        pub fn format(
            self: Point,
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;

            try writer.print("({d}, {d})", .{ self.x, self.y });
        }

        pub fn isLess(_: void, self: Point, other: Point) bool {
            if (self.x < other.x) return true;
            if (self.x > other.x) return false;
            if (self.y < other.y) return true;
            if (self.y > other.y) return false;
            return false;
        }

        pub fn in(self: Point, slice: []Point) bool {
            for (slice) |other| if (meta.eql(self, other)) return true;
            return false;
        }

        pub fn sliceIn(points: []Point, slice: [][]Point) bool {
            for (slice) |others| {
                if (points.len != others.len) continue;
                for (points) |point, i| {
                    if (!meta.eql(point, others[i])) break;
                } else {
                    return true;
                }
            }
            return false;
        }
    };

    const Self = @This();

    allocator: Allocator,
    values: [][]const u32,

    pub fn parse(allocator: Allocator, string: []const u8) !Self {
        var result = ArrayList([]u32).init(allocator);
        errdefer {
            for (result.items) |row| allocator.free(row);
            result.deinit();
        }

        var line_it = mem.tokenize(u8, string, "\n");
        while (line_it.next()) |line| {
            var row = try allocator.alloc(u32, line.len);
            errdefer allocator.free(row);

            for (line) |char, i| row[i] = @intCast(u32, char - '0');
            try result.append(row);
        }

        return Self{
            .allocator = allocator,
            .values = result.toOwnedSlice(),
        };
    }

    pub fn deinit(self: Self) void {
        for (self.values) |row| self.allocator.free(row);
        self.allocator.free(self.values);
    }

    pub fn basin(
        self: Self,
        so_far: *ArrayList(Point),
        x: usize,
        y: usize,
    ) mem.Allocator.Error!void {
        if ((Point{ .x = x, .y = y }).in(so_far.items)) return;

        if (self.values[y][x] == 9) return;
        try so_far.append(.{ .x = x, .y = y });

        if (y > 0) try self.basin(so_far, x, y - 1);
        if (y < self.values.len - 1) try self.basin(so_far, x, y + 1);
        if (x > 0) try self.basin(so_far, x - 1, y);
        if (x < self.values[y].len - 1) try self.basin(so_far, x + 1, y);
    }

    pub fn basins(self: Self, allocator: Allocator) ![][]Point {
        var result = ArrayList([]Point).init(allocator);
        errdefer {
            for (result.items) |basin_| allocator.free(basin_);
            result.deinit();
        }

        for (self.values) |row, y| for (row) |_, x| {
            var basin_ = ArrayList(Point).init(allocator);
            errdefer basin_.deinit();

            try self.basin(&basin_, x, y);

            sort.sort(Point, basin_.items, {}, Point.isLess);
            if (Point.sliceIn(basin_.items, result.items)) {
                basin_.deinit();
                continue;
            }

            try result.append(basin_.toOwnedSlice());
        };

        var to_remove = ArrayList(usize).init(allocator);
        defer to_remove.deinit();
        for (result.items) |basin_, i| if (basin_.len == 0) try to_remove.append(i);
        for (to_remove.items) |index| _ = result.orderedRemove(index);

        return result.toOwnedSlice();
    }
};

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const map = try HeightMap.parse(allocator, file);
    defer map.deinit();

    const basins = try map.basins(allocator);
    defer {
        for (basins) |basin| allocator.free(basin);
        allocator.free(basins);
    }

    var sizes = try allocator.alloc(usize, basins.len);
    defer allocator.free(sizes);
    for (basins) |basin, i| sizes[i] = basin.len;

    sort.sort(usize, sizes, {}, comptime sort.desc(usize));

    const result = sizes[0] * sizes[1] * sizes[2];

    try stdout.print("{d}\n", .{result});
}
