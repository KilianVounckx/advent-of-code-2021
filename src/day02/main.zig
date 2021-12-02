const std = @import("std");
const mem = std.mem;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

pub const Submarine = struct {
    const Self = @This();

    depth: i32 = 0,
    horizontal: i32 = 0,

    pub fn parseCommand(self: *Self, command: []const u8) void {
        const direction = command[0 .. command.len - 2];
        const digit = command[command.len - 1];
        const number = @intCast(i32, digit - '0');

        if (mem.eql(u8, direction, "forward")) {
            self.horizontal += number;
        } else if (mem.eql(u8, direction, "down")) {
            self.depth += number;
        } else if (mem.eql(u8, direction, "up")) {
            self.depth -= number;
        }
    }
};

pub fn main() !void {
    var submarine = Submarine{};

    var it = mem.tokenize(u8, file, "\n");
    while (it.next()) |line| {
        submarine.parseCommand(line);
    }

    const result = submarine.depth * submarine.horizontal;

    try stdout.print("{d}\n", .{result});
}
