const std = @import("std");
const math = std.math;
const mem = std.mem;
const meta = std.meta;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

const Cavern = struct {
    pub const Coordinate = struct {
        x: usize,
        y: usize,
    };

    const Self = @This();

    allocator: Allocator,
    risks: [][]const u32,

    pub fn parse(allocator: Allocator, string: []const u8) !Self {
        var risks = ArrayList([]const u32).init(allocator);
        errdefer {
            for (risks.items) |row| allocator.free(row);
            risks.deinit();
        }

        var it = mem.tokenize(u8, string, "\n");
        while (it.next()) |line| {
            var row = try allocator.alloc(u32, line.len);
            errdefer allocator.free(row);

            for (line) |char, i| row[i] = char - '0';
            try risks.append(row);
        }

        return Self{
            .allocator = allocator,
            .risks = risks.toOwnedSlice(),
        };
    }

    pub fn deinit(self: Self) void {
        for (self.risks) |row| self.allocator.free(row);
        self.allocator.free(self.risks);
    }

    pub fn findPath(self: Self, allocator: Allocator) ![]Coordinate {
        return self.findPathStartEnd(
            allocator,
            .{ .x = 0, .y = 0 },
            .{ .x = self.risks[self.risks.len - 1].len - 1, .y = self.risks.len - 1 },
        );
    }

    pub fn findPathStartEnd(
        self: Self,
        allocator: Allocator,
        start: Coordinate,
        end: Coordinate,
    ) ![]Coordinate {
        var open_set = AutoHashMap(Coordinate, void).init(allocator);
        defer open_set.deinit();
        try open_set.put(start, {});

        var came_from = AutoHashMap(Coordinate, Coordinate).init(allocator);
        defer came_from.deinit();

        var f_score = AutoHashMap(Coordinate, u32).init(allocator);
        defer f_score.deinit();
        try f_score.put(start, self.risks[start.y][start.x]);

        while (open_set.count() != 0) {
            const current = lowestInSetByScore(open_set, f_score);
            if (meta.eql(current, end)) return try reconstructPath(allocator, came_from, current);

            _ = open_set.remove(current);

            const neighbors_ = try self.neighbors(allocator, current);
            defer allocator.free(neighbors_);
            for (neighbors_) |neighbor| {
                const tentative_score = (f_score.get(current) orelse math.maxInt(u32)) +
                    self.distance(neighbor);
                if (tentative_score < (f_score.get(neighbor) orelse math.maxInt(u32))) {
                    try came_from.put(neighbor, current);
                    try f_score.put(neighbor, tentative_score);
                    try open_set.put(neighbor, {});
                }
            }
        }

        return error.FailedToFindPath;
    }

    fn lowestInSetByScore(
        open_set: AutoHashMap(Coordinate, void),
        f_score: AutoHashMap(Coordinate, u32),
    ) Coordinate {
        var min_score: u32 = math.maxInt(u32);
        var min_coord: Coordinate = undefined;

        var it = open_set.keyIterator();
        while (it.next()) |key| {
            if (f_score.get(key.*)) |score| if (score < min_score) {
                min_score = score;
                min_coord = key.*;
            };
        }

        return min_coord;
    }

    fn distance(self: Self, c2: Coordinate) u32 {
        return self.risks[c2.y][c2.x];
    }

    fn reconstructPath(
        allocator: Allocator,
        came_from: AutoHashMap(Coordinate, Coordinate),
        current: Coordinate,
    ) ![]Coordinate {
        var result = ArrayList(Coordinate).init(allocator);
        errdefer result.deinit();

        try result.append(current);

        var current_ = current;
        while (came_from.get(current_)) |from| : (current_ = from) {
            try result.append(from);
        }

        mem.reverse(Coordinate, result.items);
        return result.toOwnedSlice();
    }

    fn neighbors(self: Self, allocator: Allocator, c: Coordinate) ![]Coordinate {
        var result = ArrayList(Coordinate).init(allocator);
        errdefer result.deinit();

        var y_off: isize = -1;
        while (y_off <= 1) : (y_off += 1) {
            if (c.y == 0 and y_off == -1) continue;
            if (c.y == self.risks.len - 1 and y_off == 1) continue;

            const y = @intCast(usize, @intCast(isize, c.y) + y_off);

            try result.append(.{ .x = c.x, .y = y });
        }

        var x_off: isize = -1;
        while (x_off <= 1) : (x_off += 1) {
            if (c.x == 0 and x_off == -1) continue;
            if (c.x == self.risks[c.y].len - 1 and x_off == 1) continue;

            const x = @intCast(usize, @intCast(isize, c.x) + x_off);

            try result.append(.{ .x = x, .y = c.y });
        }

        return result.toOwnedSlice();
    }

    fn riskSum(self: Self, path: []Coordinate) u32 {
        var result: u32 = 0;
        for (path[1..]) |c| result += self.risks[c.y][c.x];
        return result;
    }
};

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    errdefer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const cavern = try Cavern.parse(allocator, file);
    defer cavern.deinit();

    const path = try cavern.findPath(allocator);
    defer allocator.free(path);

    try stdout.print("{d}\n", .{cavern.riskSum(path)});
}
