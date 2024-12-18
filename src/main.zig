const std = @import("std");
const components = @import("Nes.zig");

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };
    nes.init();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
