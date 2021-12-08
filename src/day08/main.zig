const std = @import("std");
const mem = std.mem;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

pub fn main() !void {
    var result: u32 = 0;

    var line_it = mem.tokenize(u8, file, "\n");
    while (line_it.next()) |line| {
        const bar_index = mem.indexOf(u8, line, " | ").?;
        const important = line[bar_index + 3 ..];

        var pattern_it = mem.tokenize(u8, important, " ");
        while (pattern_it.next()) |pattern| {
            const length = pattern.len;
            if (length == 2 or length == 3 or length == 4 or length == 7) result += 1;
        }
    }

    try stdout.print("{d}\n", .{result});
}
