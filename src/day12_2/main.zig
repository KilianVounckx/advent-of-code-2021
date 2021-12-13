const std = @import("std");
const ascii = std.ascii;
const mem = std.mem;
const Allocator = mem.Allocator;
const StringHashMap = std.StringHashMap;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const stdout = std.io.getStdOut().writer();

const file = @embedFile("input.txt");

//pub const PathSet = struct {
//    pub const Node = struct {
//        allocator: *Allocator,
//        value: []const u8,
//        children: ArrayList(Node),
//        final: bool,
//
//        pub fn init(allocator: *Allocator, value: []const u8) Node {
//            return .{
//                .allocator = allocator,
//                .value = value,
//                .children = ArrayList(Node).init(allocator),
//                .final = false,
//            };
//        }
//
//        pub fn deinit(self: Node) void {
//            for (self.children.items) |child| child.deinit();
//            self.children.deinit();
//        }
//
//        pub fn add(self: *Node, path: [][]const u8) Allocator.Error!void {
//            if (path.len == 0) return;
//
//            for (self.children.items) |*node| {
//                if (mem.eql(u8, node.value, path[0])) {
//                    if (path.len == 1) {
//                        node.final = true;
//                        return;
//                    }
//
//                    try node.add(path[1..]);
//                    return;
//                }
//            }
//
//            var node = Node.init(self.allocator, path[0]);
//            if (path.len == 1) {
//                node.final = true;
//            } else {
//                try node.add(path[1..]);
//            }
//            try self.children.append(node);
//        }
//
//        pub fn count(self: Node) usize {
//            var result: usize = if (self.final) 1 else 0;
//            for (self.children.items) |child| result += child.count();
//            return result;
//        }
//    };
//
//    const Self = @This();
//
//    allocator: *Allocator,
//    start: ArrayList(Node),
//
//    pub fn init(allocator: *Allocator) Self {
//        return .{
//            .allocator = allocator,
//            .start = ArrayList(Node).init(allocator),
//        };
//    }
//
//    pub fn deinit(self: Self) void {
//        for (self.start.items) |node| node.deinit();
//        self.start.deinit();
//    }
//
//    pub fn add(self: *Self, path: [][]const u8) !void {
//        if (path.len == 0) return;
//
//        for (self.start.items) |*node| {
//            if (mem.eql(u8, node.value, path[0])) {
//                if (path.len == 1) {
//                    node.final = true;
//                    return;
//                }
//
//                try node.add(path[1..]);
//                return;
//            }
//        }
//
//        var node = Node.init(self.allocator, path[0]);
//        if (path.len == 1) {
//            node.final = true;
//        } else {
//            try node.add(path[1..]);
//        }
//        try self.start.append(node);
//    }
//
//    pub fn count(self: Self) usize {
//        var result: usize = 0;
//        for (self.start.items) |node| {
//            result += node.count();
//        }
//        return result;
//    }
//};

pub const Map = struct {
    const Self = @This();

    allocator: *Allocator,
    map: StringHashMap(ArrayList([]const u8)),

    pub fn parse(
        allocator: *Allocator,
        string: []const u8,
    ) !Self {
        var result = StringHashMap(ArrayList([]const u8)).init(allocator);
        errdefer {
            var it = result.iterator();
            while (it.next()) |entry| {
                allocator.free(entry.key_ptr.*);
                for (entry.value_ptr.*.items) |s| allocator.free(s);
                entry.value_ptr.*.deinit();
            }
            result.deinit();
        }

        var it = mem.tokenize(u8, string, "\n");
        while (it.next()) |line| {
            const index = mem.indexOf(u8, line, "-").?;

            if (!mem.eql(u8, line[0..index], "start") and
                !mem.eql(u8, line[index + 1 ..], "end"))
            {
                const key = try allocator.dupe(u8, line[index + 1 ..]);
                errdefer allocator.free(key);

                const value = try allocator.dupe(u8, line[0..index]);
                errdefer allocator.free(value);

                var res = try result.getOrPut(key);
                if (res.found_existing) {
                    try res.value_ptr.*.append(value);
                    allocator.free(key);
                } else {
                    res.value_ptr.* = ArrayList([]const u8).init(allocator);
                    try res.value_ptr.*.append(value);
                }
            }

            const key = try allocator.dupe(u8, line[0..index]);
            errdefer allocator.free(key);

            const value = try allocator.dupe(u8, line[index + 1 ..]);
            errdefer allocator.free(value);

            var res = try result.getOrPut(key);
            if (res.found_existing) {
                try res.value_ptr.*.append(value);
                allocator.free(key);
            } else {
                res.value_ptr.* = ArrayList([]const u8).init(allocator);
                try res.value_ptr.*.append(value);
            }
        }

        return Self{ .allocator = allocator, .map = result };
    }

    pub fn deinit(self: *Self) void {
        var it = self.map.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            for (entry.value_ptr.*.items) |s| self.allocator.free(s);
            entry.value_ptr.*.deinit();
        }
        self.map.deinit();
    }

    pub fn findPaths(self: Self, allocator: *Allocator) !u32 {
        var path = ArrayList([]const u8).init(allocator);
        defer path.deinit();

        return try self.findPathsInternal(allocator, "start", "end", &path);
    }

    fn findPathsInternal(
        self: Self,
        allocator: *Allocator,
        start: []const u8,
        end: []const u8,
        path: *ArrayList([]const u8),
    ) Allocator.Error!u32 {
        if (mem.eql(u8, start, end)) {
            return 1;
        }

        var result: u32 = 0;

        for (self.map.get(start).?.items) |node| {
            try path.append(start);
            defer _ = path.pop();
            if (!try nodeAllowed(allocator, node, path.items)) continue;
            result += try self.findPathsInternal(allocator, node, end, path);
        }

        return result;
    }
};

pub fn nodeAllowed(
    allocator: *Allocator,
    node: []const u8,
    path: [][]const u8,
) !bool {
    if (mem.eql(u8, node, "start")) return false;
    if (mem.eql(u8, node, "end")) return true;
    if (!ascii.isLower(node[0])) return true;

    var counts = StringHashMap(u32).init(allocator);
    defer counts.deinit();
    for (path) |cave| {
        if (mem.eql(u8, cave, "start") or mem.eql(u8, cave, "end")) continue;
        if (ascii.isLower(cave[0])) {
            var res = try counts.getOrPut(cave);
            if (!res.found_existing) res.value_ptr.* = 0;
            res.value_ptr.* += 1;
        }
    }

    const count = counts.get(node) orelse return true;

    if (count == 1) {
        var many: u32 = 0;

        var it = counts.iterator();
        while (it.next()) |entry| {
            if (mem.eql(u8, entry.key_ptr.*, node)) continue;
            if (entry.value_ptr.* != 2) continue;
            many += 1;
        }

        if (many == 0) return true;
    }
    return false;
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var map = try Map.parse(&gpa.allocator, file);
    defer map.deinit();

    const result = try map.findPaths(&gpa.allocator);

    try stdout.print("{d}\n", .{result});
}
