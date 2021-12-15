const std = @import("std");
const math = std.math;
const mem = std.mem;
const Allocator = mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

const Polymer = struct {
    const Self = @This();

    allocator: Allocator,
    pairs: AutoHashMap([2]u8, u64),
    chars: AutoHashMap(u8, u64),
    rules: AutoHashMap([2]u8, u8),

    pub fn parse(allocator: Allocator, string: []const u8) !Self {
        var it = mem.tokenize(u8, string, "\n");

        // Count chars
        var chars = AutoHashMap(u8, u64).init(allocator);
        errdefer chars.deinit();

        const first_line = it.next() orelse return error.InvalidPolymer;
        for (first_line) |char| {
            var res = try chars.getOrPut(char);
            if (!res.found_existing) res.value_ptr.* = 0;
            res.value_ptr.* += 1;
        }

        // Count pairs
        var pairs = AutoHashMap([2]u8, u64).init(allocator);
        errdefer pairs.deinit();

        for (first_line[1..]) |_, i| {
            const pair = [_]u8{ first_line[i], first_line[i + 1] };
            var res = try pairs.getOrPut(pair);
            if (!res.found_existing) res.value_ptr.* = 0;
            res.value_ptr.* += 1;
        }

        // Parse rules
        var rules = AutoHashMap([2]u8, u8).init(allocator);
        errdefer rules.deinit();

        while (it.next()) |line| {
            const key = [_]u8{ line[0], line[1] };
            const value = line[line.len - 1];
            try rules.put(key, value);
        }

        return Self{
            .allocator = allocator,
            .rules = rules,
            .pairs = pairs,
            .chars = chars,
        };
    }

    pub fn deinit(self: *Self) void {
        self.rules.deinit();
        self.pairs.deinit();
        self.chars.deinit();
    }

    pub fn react(self: *Self) !void {
        var new_pairs = AutoHashMap([2]u8, u64).init(self.allocator);
        defer new_pairs.deinit();
        var old_pairs = AutoHashMap([2]u8, u64).init(self.allocator);
        defer old_pairs.deinit();

        var pairs_it = self.pairs.iterator();
        while (pairs_it.next()) |pair_entry| {
            const pair = pair_entry.key_ptr.*;
            const total = pair_entry.value_ptr.*;

            const new_char = self.rules.get(pair) orelse continue;
            const left = [_]u8{ pair[0], new_char };
            const right = [_]u8{ new_char, pair[1] };

            var char_res = try self.chars.getOrPut(new_char);
            if (!char_res.found_existing) char_res.value_ptr.* = 0;
            char_res.value_ptr.* += total;

            var left_res = try new_pairs.getOrPut(left);
            if (!left_res.found_existing) left_res.value_ptr.* = 0;
            left_res.value_ptr.* += total;

            var right_res = try new_pairs.getOrPut(right);
            if (!right_res.found_existing) right_res.value_ptr.* = 0;
            right_res.value_ptr.* += total;

            var old_res = try old_pairs.getOrPut(pair);
            if (!old_res.found_existing) old_res.value_ptr.* = 0;
            old_res.value_ptr.* += total;
        }

        var new_pairs_it = new_pairs.iterator();
        while (new_pairs_it.next()) |new_pair_entry| {
            var res = try self.pairs.getOrPut(new_pair_entry.key_ptr.*);
            if (!res.found_existing) res.value_ptr.* = 0;
            res.value_ptr.* += new_pair_entry.value_ptr.*;
        }

        var old_pairs_it = old_pairs.iterator();
        while (old_pairs_it.next()) |old_pair_entry| {
            const pair_ptr = self.pairs.getPtr(old_pair_entry.key_ptr.*) orelse return error.WHAAT;
            pair_ptr.* -= old_pair_entry.value_ptr.*;
        }
    }

    pub fn minMaxDiff(self: Self) u64 {
        var min: u64 = math.maxInt(u64);
        var max: u64 = 0;

        var it = self.chars.valueIterator();
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

    for ([_]u0{0} ** 40) |_| try polymer.react();

    try stdout.print("{d}\n", .{polymer.minMaxDiff()});
}
