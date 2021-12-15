const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

const Grid = struct {
    const Self = @This();

    allocator: Allocator,
    energies: [][]?u32,

    pub fn parse(allocator: Allocator, string: []const u8) !Self {
        var energies = ArrayList([]?u32).init(allocator);
        errdefer {
            for (energies.items) |row| allocator.free(row);
            energies.deinit();
        }

        var it = mem.tokenize(u8, string, "\n");
        while (it.next()) |line| {
            var row = try allocator.alloc(?u32, line.len);
            errdefer allocator.free(row);

            for (line) |char, i| row[i] = char - '0';

            try energies.append(row);
        }

        return Self{
            .allocator = allocator,
            .energies = energies.toOwnedSlice(),
        };
    }

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        for (self.energies) |row, i| {
            if (i != 0) try writer.print("\n", .{});
            for (row) |energy| try writer.print("{d}", .{energy});
        }
    }

    pub fn deinit(self: Self) void {
        for (self.energies) |row| self.allocator.free(row);
        self.allocator.free(self.energies);
    }

    fn addOneToEach(self: *Self) void {
        for (self.energies) |*row| for (row.*) |*maybe_energy| if (maybe_energy.*) |*energy| {
            energy.* += 1;
        };
    }

    fn flashWave(self: *Self) void {
        for (self.energies) |*row, y| for (row.*) |*maybe_energy, x| if (maybe_energy.*) |*energy| {
            if (energy.* < 10) continue;

            maybe_energy.* = null;

            var y_offset: isize = -1;
            while (y_offset <= 1) : (y_offset += 1) {
                if (y == 0 and y_offset == -1) continue;
                if (y == self.energies.len - 1 and y_offset == 1) continue;
                const new_y = @intCast(usize, @intCast(isize, y) + y_offset);

                var x_offset: isize = -1;
                while (x_offset <= 1) : (x_offset += 1) {
                    if (x_offset == 0 and y_offset == 0) continue;

                    if (x == 0 and x_offset == -1) continue;
                    if (x == self.energies[new_y].len - 1 and x_offset == 1) continue;
                    const new_x = @intCast(usize, @intCast(isize, x) + x_offset);

                    if (self.energies[new_y][new_x]) |*offset_energy| offset_energy.* += 1;
                }
            }
        };
    }

    fn hasHighEnergy(self: Self) bool {
        for (self.energies) |row| for (row) |maybe_energy|
            if (maybe_energy) |energy| if (energy >= 10) return true;
        return false;
    }

    fn flashLoop(self: *Self) void {
        while (self.hasHighEnergy()) self.flashWave();
    }

    pub fn resetNull(self: *Self) void {
        for (self.energies) |*row| for (row.*) |*energy| if (energy.* == null) {
            energy.* = 0;
        };
    }

    pub fn loop(self: *Self) void {
        self.addOneToEach();
        self.flashLoop();
    }

    pub fn allNull(self: Self) bool {
        for (self.energies) |row| for (row) |energy| if (energy != null) return false;
        return true;
    }
};

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid = try Grid.parse(allocator, file);
    defer grid.deinit();

    var result: u32 = 0;
    while (true) : (result += 1) {
        grid.loop();
        if (grid.allNull()) break;
        grid.resetNull();
    }

    try stdout.print("{d}\n", .{result + 1});
}
