const std = @import("std");
const components = @import("Nes.zig");

test "Immediate Addressing" {
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    nes.Cpu.pc = 0;
    nes.Cpu.memory[1] = 240;

    std.debug.print("{d} provided by Immediate Addressing!\n", .{nes.Cpu.GetImmediate()});
    try std.testing.expect(nes.Cpu.GetImmediate() == 240);
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
    nes.Cpu.memory[0] = 0;

    nes.Cpu.setZeroPageY(240);

    std.debug.print("{d} provided by Zero Page Y!\n", .{nes.Cpu.GetZeroPageY()});
    try std.testing.expect(nes.Cpu.GetZeroPageY() == 240);
}

test "Zero Page X Addresssing" {
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    nes.Cpu.pc = 0;
    nes.Cpu.x_register = 8;
    nes.Cpu.memory[1] = 248;
    nes.Cpu.memory[0] = 0;

    nes.Cpu.setZeroPageX(240);

    std.debug.print("{d} provided by Zero Page X!\n", .{nes.Cpu.GetZeroPageX()});
    try std.testing.expect(nes.Cpu.GetZeroPageX() == 240);
}

test "Absolute Addressing" {
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    nes.Cpu.pc = 0;
    nes.Cpu.memory[1] = 0xF;
    nes.Cpu.memory[2] = 0xAF;

    nes.Cpu.setAbsolute(240);

    std.debug.print("{d} provided by Absolute!\n", .{nes.Cpu.GetAbsolute()});
    try std.testing.expect(nes.Cpu.GetAbsolute() == nes.Cpu.memory[0xFAF % 0x800]);
}

test "Absolute Indexed Addressing" {
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    nes.Cpu.pc = 0;
    nes.Cpu.x_register = 8;
    nes.Cpu.y_register = 8;
    nes.Cpu.memory[1] = 0xF;
    nes.Cpu.memory[2] = 0xA7;

    nes.Cpu.setAbsoluteIndexed(0, 240);
    std.debug.print("{d} provided by Absolute X!\n", .{nes.Cpu.GetAbsoluteIndexed(0)});

    try std.testing.expect(nes.Cpu.GetAbsoluteIndexed(0) == nes.Cpu.memory[0xFAF % 0x800]);

    nes.Cpu.setAbsoluteIndexed(1, 241);
    try std.testing.expect(nes.Cpu.GetAbsoluteIndexed(1) == nes.Cpu.memory[0xFAF % 0x800]);
    std.debug.print("{d} provided by Absolute Y!\n", .{nes.Cpu.GetAbsoluteIndexed(1)});
}

test "Relative Addressing!" {}
