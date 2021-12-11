const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

pub fn findIllegalCharacter(allocator: *Allocator, line: []const u8) !?u8 {
    var stack = ArrayList(u8).init(allocator);
    defer stack.deinit();

    for (line) |character| switch (character) {
        '(', '{', '<', '[' => try stack.append(character),
        ')', '}', '>', ']' => if (stack.items.len == 0) {
            return character;
        } else {
            switch (stack.items[stack.items.len - 1]) {
                '(' => if (character == ')') {
                    _ = stack.pop();
                } else {
                    return character;
                },

                '{' => if (character == '}') {
                    _ = stack.pop();
                } else {
                    return character;
                },

                '<' => if (character == '>') {
                    _ = stack.pop();
                } else {
                    return character;
                },

                '[' => if (character == ']') {
                    _ = stack.pop();
                } else {
                    return character;
                },

                else => |opening| return opening,
            }
        },
        else => return character,
    };

    return null;
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var result: u32 = 0;

    var it = mem.tokenize(u8, file, "\n");
    while (it.next()) |line| {
        if (try findIllegalCharacter(&gpa.allocator, line)) |character| switch (character) {
            ')' => result += 3,
            ']' => result += 57,
            '}' => result += 1197,
            '>' => result += 25137,
            else => unreachable,
        };
    }

    try stdout.print("{d}\n", .{result});
}
