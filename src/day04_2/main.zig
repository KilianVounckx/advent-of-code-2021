const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const FormatOptions = fmt.FormatOptions;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

pub fn parseOrder(allocator: Allocator, line: []const u8) ![]u32 {
    var result = std.ArrayList(u32).init(allocator);
    errdefer result.deinit();

    var it = mem.tokenize(u8, line, ",");
    while (it.next()) |number| try result.append(try fmt.parseUnsigned(u32, number, 10));

    return result.toOwnedSlice();
}

pub const Bingo = struct {
    pub const Number = struct {
        number: u32,
        drawn: bool = false,

        pub fn format(
            self: Number,
            comptime _fmt: []const u8,
            options: FormatOptions,
            writer: anytype,
        ) !void {
            _ = _fmt;
            _ = options;

            if (self.drawn)
                try writer.print("<{d:2}>", .{self.number})
            else
                try writer.print("[{d:2}]", .{self.number});
        }
    };

    const Self = @This();

    numbers: [25]Number,

    pub fn parse(string: []const u8) !Self {
        var self: Self = undefined;

        var index: usize = 0;
        var it = mem.tokenize(u8, string, " \n");
        while (it.next()) |number| {
            self.numbers[index] = .{ .number = try fmt.parseUnsigned(u32, number, 10) };
            index += 1;
        }

        return self;
    }

    pub fn parseMultiple(allocator: Allocator, string: []const u8) !ArrayList(Self) {
        var bingos = ArrayList(Bingo).init(allocator);
        errdefer bingos.deinit();

        var it = mem.split(u8, string, "\n\n");
        while (it.next()) |bingo| try bingos.append(try Self.parse(bingo));

        return bingos;
    }

    pub fn format(
        self: Self,
        comptime _fmt: []const u8,
        options: FormatOptions,
        writer: anytype,
    ) !void {
        _ = _fmt;
        _ = options;

        for (self.numbers) |number, i| {
            if (i != 0 and i % 5 == 0) try writer.print("\n", .{});
            try writer.print("{} ", .{number});
        }
    }

    pub fn draw(self: *Self, n: u32) void {
        for (self.numbers) |*number| if (number.number == n) {
            number.*.drawn = true;
        };
    }

    pub fn checkRow(self: Self, row: usize) bool {
        var col: usize = 0;
        while (col < 5) : (col += 1) {
            const index = row * 5 + col;
            if (!self.numbers[index].drawn) return false;
        }
        return true;
    }

    pub fn getRow(self: Self, row: usize) [5]u32 {
        var result: [5]u32 = undefined;
        for (result) |*number, col| {
            const index = row * 5 + col;
            number.* = self.numbers[index].number;
        }
        return result;
    }

    pub fn checkCol(self: Self, col: usize) bool {
        var row: usize = 0;
        while (row < 5) : (row += 1) {
            const index = row * 5 + col;
            if (!self.numbers[index].drawn) return false;
        }
        return true;
    }

    pub fn getCol(self: Self, col: usize) [5]u32 {
        var result: [5]u32 = undefined;
        for (result) |*number, row| {
            const index = row * 5 + col;
            number.* = self.numbers[index].number;
        }
        return result;
    }

    pub fn sumUnmarked(self: Self) u32 {
        var result: u32 = 0;
        for (self.numbers) |number| if (!number.drawn) {
            result += number.number;
        };
        return result;
    }

    pub fn checkWin(self: Self) ?u32 {
        var row: usize = 0;
        while (row < 5) : (row += 1) {
            if (self.checkRow(row)) {
                return self.sumUnmarked();
            }
        }

        var col: usize = 0;
        while (col < 5) : (col += 1) {
            if (self.checkCol(col)) {
                return self.sumUnmarked();
            }
        }

        return null;
    }
};

pub fn solve(order: []const u32, bingos: *ArrayList(Bingo)) u32 {
    var index: usize = 0;
    while (true) {
        var i: usize = bingos.items.len - 1;
        while (true) {
            const bingo = bingos.items[i];
            var win: u32 = undefined;
            if (bingo.checkWin()) |cw| {
                win = cw * order[index - 1];
                _ = bingos.orderedRemove(i);
            }

            if (bingos.items.len == 0) {
                return win;
            }

            if (i == 0) break;
            i -= 1;
        }

        for (bingos.items) |*bingo| bingo.draw(order[index]);
        index += 1;
    }
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var end_order_index = mem.indexOf(u8, file, "\n\n").?;

    const order = try parseOrder(allocator, file[0..end_order_index]);
    defer allocator.free(order);

    var bingos = try Bingo.parseMultiple(allocator, file[end_order_index + 1 ..]);
    defer bingos.deinit();

    const result = solve(order, &bingos);

    try stdout.print("{d}\n", .{result});
}
