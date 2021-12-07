const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const math = std.math;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

pub fn parseFile(allocator: *Allocator, string: []const u8) ![]u32 {
    var result = ArrayList(u32).init(allocator);
    errdefer result.deinit();

    var it = mem.tokenize(u8, string, ",\n");
    while (it.next()) |number| {
        try result.append(try fmt.parseUnsigned(u32, number, 10));
    }

    return result.toOwnedSlice();
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const numbers = try parseFile(&gpa.allocator, file);
    defer gpa.allocator.free(numbers);

    var min = mem.min(u32, numbers);
    const max = mem.max(u32, numbers);

    var position: u32 = min;
    var least_fuel: u32 = math.maxInt(u32);
    while (min <= max) : (min += 1) {
        var total_fuel: u32 = 0;
        for (numbers) |number| {
            const fuel = if (number >= min) number - min else min - number;
            total_fuel += fuel;
        }
        if (total_fuel < least_fuel) {
            least_fuel = total_fuel;
            position = min;
        }
    }

    try stdout.print("{d}\n", .{least_fuel});
}
