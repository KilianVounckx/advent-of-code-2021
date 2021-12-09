const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

pub const HeightMap = struct {
    const Self = @This();

    allocator: *Allocator,
    values: [][]const u32,

    pub fn parse(allocator: *Allocator, string: []const u8) !Self {
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

    pub fn lowestPointValues(self: Self, allocator: *Allocator) ![]u32 {
        var result = ArrayList(u32).init(allocator);
        errdefer result.deinit();

        for (self.values) |row, y| for (row) |value, x| {
            if (x > 0) if (self.values[y][x - 1] <= value) continue;
            if (y > 0) if (self.values[y - 1][x] <= value) continue;
            if (x < row.len - 1) if (self.values[y][x + 1] <= value) continue;
            if (y < self.values.len - 1) if (self.values[y + 1][x] <= value) continue;

            try result.append(value);
        };

        return result.toOwnedSlice();
    }

    pub fn lowestPointsRiskSum(self: Self) !u32 {
        const lowest = try self.lowestPointValues(self.allocator);
        defer self.allocator.free(lowest);

        var result: u32 = 0;
        for (lowest) |value| result += value + 1;
        return result;
    }
};

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const map = try HeightMap.parse(&gpa.allocator, file);
    defer map.deinit();

    try stdout.print("{d}\n", .{try map.lowestPointsRiskSum()});
}
