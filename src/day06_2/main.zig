const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

const Pair = struct {
    x: u64,
    y: u64,
};

pub const Fish = struct {
    const Self = @This();

    timer: u8 = 8,

    pub fn calculateChildren(self: *Self, days: u64, cache: *AutoHashMap(Pair, u64)) Allocator.Error!u64 {
        if (cache.get(.{ .x = self.timer, .y = days })) |result| return result;

        const orig_timer = self.timer;

        var result: u64 = 0;

        var i: u64 = 0;
        while (i < days) : (i += 1) {
            if (self.timer == 0) {
                result += 1;
                self.timer = 6;
                var fish = Self{};
                result += try fish.calculateChildren(days - i - 1, cache);
            } else {
                self.timer -= 1;
            }
        }

        try cache.put(.{ .x = orig_timer, .y = days }, result);

        return result;
    }
};

pub fn parseFile(allocator: Allocator, string: []const u8) !ArrayList(Fish) {
    var result = ArrayList(Fish).init(allocator);
    errdefer result.deinit();

    var index: usize = 0;
    while (index < string.len) : (index += 2) {
        try result.append(.{ .timer = string[index] - '0' });
    }

    return result;
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var fish = try parseFile(allocator, file);
    defer fish.deinit();

    var cache = AutoHashMap(Pair, u64).init(allocator);
    defer cache.deinit();

    var result: u64 = fish.items.len;
    for (fish.items) |*f| {
        result += try f.calculateChildren(256, &cache);
    }

    try stdout.print("{d}\n", .{result});
}
