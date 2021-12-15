const std = @import("std");
const math = std.math;
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const AutoHashMap = std.AutoHashMap;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

const Polymer = struct {
    const Self = @This();

    allocator: Allocator,
    rules: StringHashMap(u8),
    polymer: ArrayList(u8),

    pub fn parse(allocator: Allocator, string: []const u8) !Self {
        var it = mem.tokenize(u8, string, "\n");

        var polymer = ArrayList(u8).init(allocator);
        errdefer polymer.deinit();
        try polymer.appendSlice(it.next() orelse return error.InvalidPolymer);

        var rules = StringHashMap(u8).init(allocator);
        errdefer {
            var key_it = rules.iterator();
            while (key_it.next()) |entry| allocator.free(entry.key_ptr.*);
            rules.deinit();
        }

        while (it.next()) |line| {
            const index = mem.indexOf(u8, line, " -> ") orelse return error.InvalidPolymer;

            const key = try allocator.dupe(u8, line[0..index]);
            errdefer allocator.free(key);

            const value = line[index + 4];

            try rules.put(key, value);
        }

        return Self{
            .allocator = allocator,
            .rules = rules,
            .polymer = polymer,
        };
    }

    pub fn deinit(self: *Self) void {
        self.polymer.deinit();
        var it = self.rules.iterator();
        while (it.next()) |entry| self.allocator.free(entry.key_ptr.*);
        self.rules.deinit();
    }

    pub fn react(self: *Self) !void {
        var index: usize = 0;
        while (index < self.polymer.items.len - 1) : (index += 1) {
            const pair = self.polymer.items[index .. index + 2];
            if (self.rules.get(pair)) |char| {
                try self.polymer.insert(index + 1, char);
                index += 1;
            }
        }
    }

    pub fn maxMinDiff(self: Self) !u32 {
        var counts = AutoHashMap(u8, u32).init(self.allocator);
        defer counts.deinit();

        for (self.polymer.items) |char| {
            var res = try counts.getOrPut(char);
            if (!res.found_existing) {
                res.value_ptr.* = 0;
            }
            res.value_ptr.* += 1;
        }

        var min: u32 = math.maxInt(u32);
        var max: u32 = 0;
        var it = counts.valueIterator();
        while (it.next()) |value| {
            if (value.* < min) min = value.*;
            if (value.* > max) max = value.*;
        }

        return max - min;
    }
};

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var polymer = try Polymer.parse(allocator, file);
    defer polymer.deinit();

    for ([_]u0{0} ** 10) |_| try polymer.react();

    try stdout.print("{d}\n", .{try polymer.maxMinDiff()});
}
