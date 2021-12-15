const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const ArrayList = std.ArrayList;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

const Fish = struct {
    const Self = @This();

    timer: u8 = 8,

    pub fn grow(self: *Self) ?Self {
        if (self.timer == 0) {
            self.timer = 6;
            return Self{};
        }

        self.timer -= 1;
        return null;
    }
};

pub fn parseFile(allocator: Allocator, string: []const u8) !ArrayList(Fish) {
    var result = ArrayList(Fish).init(allocator);
    errdefer result.deinit();

    var index: usize = 0;
    while (index < string.len) : (index += 2) {
        try result.append(.{ .timer = string[index] - '0' });
    }

    return result;
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var fish = try parseFile(allocator, file);
    defer fish.deinit();

    const n: u32 = 80;
    var i: u32 = 0;
    while (i < n) : (i += 1) {
        var growing = ArrayList(Fish).init(allocator);
        defer growing.deinit();

        for (fish.items) |*f| if (f.grow()) |new| try growing.append(new);
        for (growing.items) |new| try fish.append(new);
    }

    const result = fish.items.len;

    try stdout.print("{d}\n", .{result});
}
