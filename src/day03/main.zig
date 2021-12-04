const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

pub fn parseFile(allocator: *Allocator, string: []const u8) ![][]const u8 {
    var result = ArrayList([]const u8).init(allocator);
    errdefer {
        for (result.items) |line| allocator.free(line);
        result.deinit();
    }

    var it = mem.tokenize(u8, string, "\n");
    while (it.next()) |line| try result.append(try allocator.dupe(u8, line));

    return result.toOwnedSlice();
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const lines = try parseFile(&gpa.allocator, file);
    defer {
        for (lines) |line| gpa.allocator.free(line);
        gpa.allocator.free(lines);
    }

    var ones = try gpa.allocator.alloc(u32, lines[0].len);
    defer gpa.allocator.free(ones);

    for (ones) |*one| {
        one.* = 0;
    }

    for (lines) |line| for (line) |bit, i| if (bit == '1') {
        ones[i] += 1;
    };

    var gamma_binary = try gpa.allocator.alloc(u8, ones.len);
    defer gpa.allocator.free(gamma_binary);
    for (ones) |one, i| gamma_binary[i] = if (one > lines.len / 2) '1' else '0';
    const gamma = try fmt.parseUnsigned(u32, gamma_binary, 2);

    var epsilon_binary = try gpa.allocator.alloc(u8, ones.len);
    defer gpa.allocator.free(epsilon_binary);
    for (ones) |one, i| epsilon_binary[i] = if (one < lines.len / 2) '1' else '0';
    const epsilon = try fmt.parseUnsigned(u32, epsilon_binary, 2);

    const result = gamma * epsilon;

    try stdout.print("{d}\n", .{result});
}
