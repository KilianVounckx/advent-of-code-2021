const std = @import("std");
const mem = std.mem;
const sort = std.sort;
const math = std.math;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const stdout = std.io.getStdOut().writer();
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;

const file = @embedFile("input.txt");

pub const Display = struct {
    const one = [_]u8{ 2, 5 };
    const two = [_]u8{ 0, 2, 3, 4, 6 };
    const three = [_]u8{ 0, 2, 3, 5, 6 };
    const four = [_]u8{ 1, 2, 3, 5 };
    const five = [_]u8{ 0, 1, 3, 5, 6 };
    const six = [_]u8{ 0, 1, 3, 4, 5, 6 };
    const seven = [_]u8{ 0, 2, 5 };
    const eight = [_]u8{ 0, 1, 2, 3, 4, 5, 6 };
    const nine = [_]u8{ 0, 1, 2, 3, 5, 6 };
    const zero = [_]u8{ 0, 1, 2, 4, 5, 6 };

    const Self = @This();

    segments: [7]u8,

    pub fn parseDigit(self: Self, allocator: *Allocator, lit: []const u8) !u32 {
        var actual = try allocator.alloc(u8, lit.len);
        defer allocator.free(actual);

        for (lit) |segment, i| {
            actual[i] = @intCast(u8, mem.indexOf(u8, &self.segments, &.{segment - 'a'}).?);
        }

        sort.sort(u8, actual, {}, comptime sort.asc(u8));

        if (std.mem.eql(u8, &one, actual)) return 1;
        if (std.mem.eql(u8, &two, actual)) return 2;
        if (std.mem.eql(u8, &three, actual)) return 3;
        if (std.mem.eql(u8, &four, actual)) return 4;
        if (std.mem.eql(u8, &five, actual)) return 5;
        if (std.mem.eql(u8, &six, actual)) return 6;
        if (std.mem.eql(u8, &seven, actual)) return 7;
        if (std.mem.eql(u8, &eight, actual)) return 8;
        if (std.mem.eql(u8, &nine, actual)) return 9;
        if (std.mem.eql(u8, &zero, actual)) return 0;

        return error.Invalidsegments;
    }
};

pub const Entry = struct {
    const Self = @This();

    allocator: *Allocator,
    displays: [10][]const u8,
    output: [4][]const u8,

    pub fn parse(allocator: *Allocator, string: []const u8) !Self {
        const bar_index = mem.indexOf(u8, string, " | ") orelse return error.NoBar;
        const displays_part = string[0..bar_index];
        const output_part = string[bar_index + 3 ..];

        var displays: [10][]const u8 = undefined;
        var displays_index: usize = 0;
        errdefer for (displays[0..displays_index]) |pattern| allocator.free(pattern);
        var displays_it = mem.tokenize(u8, displays_part, " ");
        while (displays_it.next()) |pattern| {
            displays[displays_index] = try allocator.dupe(u8, pattern);
            displays_index += 1;
        }

        var output: [4][]const u8 = undefined;
        var output_index: usize = 0;
        errdefer for (output[0..output_index]) |pattern| allocator.free(pattern);
        var output_it = mem.tokenize(u8, output_part, " ");
        while (output_it.next()) |pattern| {
            output[output_index] = try allocator.dupe(u8, pattern);
            output_index += 1;
        }

        return Self{
            .allocator = allocator,
            .displays = displays,
            .output = output,
        };
    }

    pub fn deinit(self: Self) void {
        for (self.displays) |pattern| self.allocator.free(pattern);
        for (self.output) |pattern| self.allocator.free(pattern);
    }

    pub fn solveDisplays(self: Self) !Display {
        var segments: [7]u8 = undefined;

        var four_segments: [2]u8 = undefined;
        for (self.displays) |display1| if (display1.len == 2) {
            for (self.displays) |display7| if (display7.len == 3) {
                for (display7) |char| if (display1[0] != char and display1[1] != char) {
                    segments[0] = char;
                };
            };
            for (self.displays) |display4| if (display4.len == 4) {
                var index: usize = 0;
                for (display4) |char| if (display1[0] != char and display1[1] != char) {
                    four_segments[index] = char;
                    index += 1;
                };
            };
        };

        var counts = AutoHashMap(u8, u32).init(self.allocator);
        defer counts.deinit();

        for (self.displays) |display| for (display) |char| {
            if (char == segments[0]) continue;
            var res = try counts.getOrPut(char);
            if (res.found_existing) {
                res.value_ptr.* += 1;
            } else {
                res.value_ptr.* = 1;
            }
        };

        var it = counts.iterator();
        while (it.next()) |pair| {
            switch (pair.value_ptr.*) {
                6 => segments[1] = pair.key_ptr.*, // b
                8 => segments[2] = pair.key_ptr.*, // c
                4 => segments[4] = pair.key_ptr.*, // e
                9 => segments[5] = pair.key_ptr.*, // f
                7 => if (four_segments[0] == pair.key_ptr.* or four_segments[1] == pair.key_ptr.*) {
                    segments[3] = pair.key_ptr.*; // d
                } else {
                    segments[6] = pair.key_ptr.*; // g
                },
                else => unreachable,
            }
        }

        for (segments) |*segment| segment.* -= 'a';

        return Display{ .segments = segments };
    }

    pub fn parseOutput(self: Self) !u32 {
        const display = try self.solveDisplays();

        var result: u32 = 0;
        for (self.output) |digit, i| {
            const parsed = try display.parseDigit(self.allocator, digit);
            result += math.pow(u32, 10, 3 - @intCast(u32, i)) * parsed;
        }

        return result;
    }
};

pub fn parseFile(allocator: *Allocator, string: []const u8) ![]Entry {
    var result = ArrayList(Entry).init(allocator);
    errdefer {
        for (result.items) |entry| entry.deinit();
        result.deinit();
    }

    var it = mem.tokenize(u8, string, "\n");
    while (it.next()) |line| try result.append(try Entry.parse(allocator, line));

    return result.toOwnedSlice();
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const entries = try parseFile(&gpa.allocator, file);
    defer {
        for (entries) |entry| entry.deinit();
        gpa.allocator.free(entries);
    }

    var result: u32 = 0;
    for (entries) |entry| {
        result += try entry.parseOutput();
    }

    try stdout.print("{d}\n", .{result});
}
