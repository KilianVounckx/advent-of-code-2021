const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    var dir = try std.fs.cwd().openDir("src", .{ .iterate = true });
    var walker = try dir.walk(b.allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind != .Directory) continue;

        const name = entry.basename;

        const full_path = try std.fmt.allocPrint(b.allocator, "src/{s}/main.zig", .{name});
        defer b.allocator.free(full_path);

        const exe = b.addExecutable(name, full_path);
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.install();

        const help_text = try std.fmt.allocPrint(b.allocator, "Run {s}", .{name});
        defer b.allocator.free(help_text);

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| run_cmd.addArgs(args);

        const run_step = b.step(name, help_text);
        run_step.dependOn(&run_cmd.step);
    }
}
