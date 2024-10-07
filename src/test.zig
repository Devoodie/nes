const std = @import("std");
const components = @import("Nes.zig");

test "Immediate Addressing" {
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    nes.Cpu.pc = 0;
    nes.Cpu.memory[1] = 150;

    std.debug.print("{d} provided by Immediate Addressing!\n", .{nes.Cpu.GetImmediate()});
    try std.testing.expect(nes.Cpu.GetImmediate() == 150);
}

test "Zero Page Addressing" {
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    nes.Cpu.pc = 0;
    nes.Cpu.memory[1] = 150;
    nes.Cpu.memory[150] = 240;

    std.debug.print("{d} provided by Zero Page!\n", .{nes.Cpu.GetZeroPage()});
    try std.testing.expect(nes.Cpu.GetZeroPage() == 240);
}

test "Zero Page Y Addresing" {
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    nes.Cpu.pc = 0;
    nes.Cpu.y_register = 8;
    nes.Cpu.memory[1] = 248;
    nes.Cpu.memory[0] = 240;

    std.debug.print("{d} provided by Zero Page!\n", .{nes.Cpu.GetZeroPageY()});
    try std.testing.expect(nes.Cpu.GetZeroPageY() == 240);
}
