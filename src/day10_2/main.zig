const std = @import("std");
const mem = std.mem;
const sort = std.sort;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

pub fn findCompletion(allocator: *Allocator, line: []const u8) ![]u8 {
    var stack = ArrayList(u8).init(allocator);
    errdefer stack.deinit();

    for (line) |character| switch (character) {
        '(', '{', '<', '[' => try stack.append(character),
        ')', '}', '>', ']' => if (stack.items.len == 0) {
            return error.Corrupt;
        } else {
            switch (stack.items[stack.items.len - 1]) {
                '(' => if (character == ')') {
                    _ = stack.pop();
                } else {
                    return error.Corrupt;
                },

                '{' => if (character == '}') {
                    _ = stack.pop();
                } else {
                    return error.Corrupt;
                },

                '<' => if (character == '>') {
                    _ = stack.pop();
                } else {
                    return error.Corrupt;
                },

                '[' => if (character == ']') {
                    _ = stack.pop();
                } else {
                    return error.Corrupt;
                },

                else => return error.Corrupt,
            }
        },
        else => return error.Corrupt,
    };

    if (stack.items.len == 0) unreachable;

    mem.reverse(u8, stack.items);

    return stack.toOwnedSlice();
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var scores = ArrayList(u64).init(&gpa.allocator);
    defer scores.deinit();

    var it = mem.tokenize(u8, file, "\n");
    while (it.next()) |line| {
        const completion = findCompletion(&gpa.allocator, line) catch continue;
        defer gpa.allocator.free(completion);

        var score: u64 = 0;
        for (completion) |character| {
            score *= 5;
            switch (character) {
                '(' => score += 1,
                '[' => score += 2,
                '{' => score += 3,
                '<' => score += 4,
                else => unreachable,
            }
        }

        try scores.append(score);
    }

    sort.sort(u64, scores.items, {}, comptime sort.asc(u64));

    try stdout.print("{d}\n", .{scores.items[scores.items.len / 2]});
}
