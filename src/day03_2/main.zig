const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

pub fn parseFile(allocator: Allocator, string: []const u8) ![]?[]const u8 {
    var result = ArrayList(?[]const u8).init(allocator);
    errdefer {
        for (result.items) |maybe_line| if (maybe_line) |line| allocator.free(line);
        result.deinit();
    }

    var it = mem.tokenize(u8, string, "\n");
    while (it.next()) |line| try result.append(try allocator.dupe(u8, line));

    return result.toOwnedSlice();
}

pub fn countChars(lines: []?[]const u8, char: u8, index: usize) u32 {
    var result: u32 = 0;
    for (lines) |maybe_line| if (maybe_line) |line| if (line[index] == char) {
        result += 1;
    };
    return result;
}

pub fn filterO2(allocator: Allocator, lines: []?[]const u8, index: usize) void {
    const ones = countChars(lines, '1', index);
    const zeros = countChars(lines, '0', index);

    for (lines) |*maybe_line| if (maybe_line.*) |line| {
        if (ones >= zeros) {
            if (line[index] != '1') {
                // remove 1;
                allocator.free(maybe_line.*.?);
                maybe_line.* = null;
            }
        } else {
            if (line[index] != '0') {
                // remove 0;
                allocator.free(maybe_line.*.?);
                maybe_line.* = null;
            }
        }
    };
}

pub fn filterCo2(allocator: Allocator, lines: []?[]const u8, index: usize) void {
    const ones = countChars(lines, '1', index);
    const zeros = countChars(lines, '0', index);

    for (lines) |*maybe_line| if (maybe_line.*) |line| {
        if (zeros <= ones) {
            if (line[index] != '0') {
                // remove 1;
                allocator.free(maybe_line.*.?);
                maybe_line.* = null;
            }
        } else {
            if (line[index] != '1') {
                // remove 0;
                allocator.free(maybe_line.*.?);
                maybe_line.* = null;
            }
        }
    };
}

pub fn countNonNull(lines: []?[]const u8) u32 {
    var result: u32 = 0;
    for (lines) |maybe_line| if (maybe_line != null) {
        result += 1;
    };
    return result;
}

pub fn firstNonNull(lines: []?[]const u8) ?[]const u8 {
    for (lines) |maybe_line| if (maybe_line) |line| return line;
    return null;
}

pub fn o2Rating(allocator: Allocator) !u32 {
    var lines = try parseFile(allocator, file);
    defer {
        for (lines) |maybe_line| if (maybe_line) |line| allocator.free(line);
        allocator.free(lines);
    }

    var index: usize = 0;
    while (true) {
        if (countNonNull(lines) == 0) unreachable;
        if (countNonNull(lines) == 1) return try fmt.parseUnsigned(u32, firstNonNull(lines).?, 2);

        filterO2(allocator, lines, index);
        index += 1;
    }
}

pub fn co2Rating(allocator: Allocator) !u32 {
    var lines = try parseFile(allocator, file);
    defer {
        for (lines) |maybe_line| if (maybe_line) |line| allocator.free(line);
        allocator.free(lines);
    }

    var index: usize = 0;
    while (true) {
        if (countNonNull(lines) == 0) unreachable;
        if (countNonNull(lines) == 1) return try fmt.parseUnsigned(u32, firstNonNull(lines).?, 2);

        filterCo2(allocator, lines, index);
        index += 1;
    }
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const o2_rating = try o2Rating(allocator);
    const co2_rating = try co2Rating(allocator);

    const result = o2_rating * co2_rating;

    try stdout.print("{d}\n", .{result});
}
