const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

pub fn parseFile(allocator: *Allocator, string: []const u8) ![]u32 {
    var result = ArrayList(u32).init(allocator);
    errdefer result.deinit();

    var it = mem.tokenize(u8, string, "\n");
    while (it.next()) |line| try result.append(try fmt.parseUnsigned(u32, line, 10));

    return result.toOwnedSlice();
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const numbers = try parseFile(&gpa.allocator, file);
    defer gpa.allocator.free(numbers);

    var result: u32 = 0;
    for (numbers[1..]) |n2, i| {
        const n1 = numbers[i];
        if (n1 < n2) {
            result += 1;
        }
    }
    try stdout.print("{d}\n", .{result});
}
