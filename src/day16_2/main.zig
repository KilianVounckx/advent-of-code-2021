const std = @import("std");
const math = std.math;
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

const Packet = struct {
    fn hexToBin(h: u8) [4]u8 {
        if (h == '0') return .{ '0', '0', '0', '0' };
        if (h == '1') return .{ '0', '0', '0', '1' };
        if (h == '2') return .{ '0', '0', '1', '0' };
        if (h == '3') return .{ '0', '0', '1', '1' };
        if (h == '4') return .{ '0', '1', '0', '0' };
        if (h == '5') return .{ '0', '1', '0', '1' };
        if (h == '6') return .{ '0', '1', '1', '0' };
        if (h == '7') return .{ '0', '1', '1', '1' };
        if (h == '8') return .{ '1', '0', '0', '0' };
        if (h == '9') return .{ '1', '0', '0', '1' };
        if (h == 'A') return .{ '1', '0', '1', '0' };
        if (h == 'B') return .{ '1', '0', '1', '1' };
        if (h == 'C') return .{ '1', '1', '0', '0' };
        if (h == 'D') return .{ '1', '1', '0', '1' };
        if (h == 'E') return .{ '1', '1', '1', '0' };
        if (h == 'F') return .{ '1', '1', '1', '1' };
        unreachable;
    }

    const Self = @This();

    allocator: Allocator,
    version: u3,
    type_id: u3,
    content: union(enum) {
        operator: []Packet,
        literal: u64,
    },

    pub fn parse(allocator: Allocator, string: []const u8) !Self {
        var bits = try allocator.alloc(u8, string.len * 4);
        defer allocator.free(bits);
        for (string) |h, i| {
            const bs = hexToBin(h);
            for (bs) |b, j| bits[i * 4 + j] = b;
        }
        return try parseBits(allocator, bits);
    }

    fn parseBits(allocator: Allocator, bits: []const u8) !Self {
        var length: usize = undefined;
        const result = try parseWithReturnLength(allocator, bits, &length);
        errdefer result.deinit();
        if (length == bits.len) return result;
        for (bits[length..]) |bit| if (bit != '0') return error.InvalidPacket;
        return result;
    }

    fn parseWithReturnLength(
        allocator: Allocator,
        bits: []const u8,
        length: *usize,
    ) (Allocator.Error || std.fmt.ParseIntError || error{InvalidPacket})!Self {
        const version = try std.fmt.parseUnsigned(u3, bits[0..3], 2);
        const type_id = try std.fmt.parseUnsigned(u3, bits[3..6], 2);

        if (type_id == 4) {
            // literal
            var literal_bits = ArrayList(u8).init(allocator);
            defer literal_bits.deinit();

            var index: usize = 6;

            while (true) : (index += 5) {
                try literal_bits.appendSlice(bits[index + 1 .. index + 5]);

                if (bits[index] == '0') break;
                if (bits[index] == '1') continue;
                unreachable;
            }

            const literal = try std.fmt.parseUnsigned(u64, literal_bits.items, 2);

            length.* = index + 5;
            return Self{
                .allocator = allocator,
                .version = version,
                .type_id = type_id,
                .content = .{ .literal = literal },
            };
        }

        const length_type_id = bits[6];
        if (length_type_id == '0') {
            // next 15 bits represent total number of bits of subpackets
            const max_length = try std.fmt.parseUnsigned(usize, bits[7..22], 2);

            var total_length: usize = 0;
            var subpackets = ArrayList(Self).init(allocator);
            errdefer {
                for (subpackets.items) |packet| packet.deinit();
                subpackets.deinit();
            }

            while (true) {
                var sub_length: usize = undefined;
                const subpacket = try parseWithReturnLength(
                    allocator,
                    bits[22 + total_length ..],
                    &sub_length,
                );
                errdefer subpacket.deinit();

                total_length += sub_length;

                try subpackets.append(subpacket);

                if (total_length >= max_length) break;
            }

            length.* = 22 + total_length;
            return Self{
                .allocator = allocator,
                .version = version,
                .type_id = type_id,
                .content = .{ .operator = subpackets.toOwnedSlice() },
            };
        }

        if (length_type_id == '1') {
            // next 11 bits represent number of subpackets
            const number_packets = try std.fmt.parseUnsigned(u64, bits[7..18], 2);

            var total_length: usize = 0;
            var subpackets = ArrayList(Self).init(allocator);
            errdefer {
                for (subpackets.items) |packet| packet.deinit();
                subpackets.deinit();
            }

            var i: u64 = 0;
            while (i < number_packets) : (i += 1) {
                var sub_length: usize = undefined;
                const subpacket = try parseWithReturnLength(
                    allocator,
                    bits[18 + total_length ..],
                    &sub_length,
                );
                errdefer subpacket.deinit();

                try subpackets.append(subpacket);

                total_length += sub_length;
            }

            length.* = 18 + total_length;
            return Self{
                .allocator = allocator,
                .version = version,
                .type_id = type_id,
                .content = .{ .operator = subpackets.toOwnedSlice() },
            };
        }

        return error.InvalidPacket;
    }

    pub fn deinit(self: Self) void {
        switch (self.content) {
            .operator => |subpackets| {
                for (subpackets) |packet| packet.deinit();
                self.allocator.free(subpackets);
            },
            .literal => {},
        }
    }

    pub fn calculate(self: Self) u64 {
        switch (self.content) {
            .literal => |literal| return literal,
            .operator => |subpackets| {
                switch (self.type_id) {
                    0 => {
                        var result: u64 = 0;
                        for (subpackets) |packet| result += packet.calculate();
                        return result;
                    },
                    1 => {
                        var result: u64 = 1;
                        for (subpackets) |packet| result *= packet.calculate();
                        return result;
                    },
                    2 => {
                        var result: u64 = math.maxInt(u64);
                        for (subpackets) |packet| result = math.min(result, packet.calculate());
                        return result;
                    },
                    3 => {
                        var result: u64 = 0;
                        for (subpackets) |packet| result = math.max(result, packet.calculate());
                        return result;
                    },
                    4 => unreachable,
                    5 => {
                        std.debug.assert(subpackets.len == 2);
                        return if (subpackets[0].calculate() > subpackets[1].calculate()) 1 else 0;
                    },
                    6 => {
                        std.debug.assert(subpackets.len == 2);
                        return if (subpackets[0].calculate() < subpackets[1].calculate()) 1 else 0;
                    },
                    7 => {
                        std.debug.assert(subpackets.len == 2);
                        return if (subpackets[0].calculate() == subpackets[1].calculate()) 1 else 0;
                    },
                }
            },
        }
    }
};

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const packet = try Packet.parse(allocator, file[0 .. file.len - 1]);
    defer packet.deinit();

    try stdout.print("{d}\n", .{packet.calculate()});
}
