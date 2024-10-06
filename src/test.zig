const std = @import("std");
const components = @import("Nes.zig");

test "Immediate Addressing" {
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    nes.Cpu.pc = 0;
    nes.Cpu.memory[1] = 150;

    std.debug.print("{d}\n", .{nes.Cpu.GetImmediate()});
    try std.testing.expect(nes.Cpu.GetImmediate() == 150);
}

test "Zero Page Addressing" {
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    nes.Cpu.pc = 0;
    nes.Cpu.memory[1] = 150;
    nes.Cpu.memory[150] = 240;

    std.debug.print("{d}\n", .{nes.Cpu.GetZeroPage()});
    try std.testing.expect(nes.Cpu.GetZeroPage() == 240);
}
