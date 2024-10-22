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

test "Indirect Indexed Addressing" {
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    nes.Cpu.pc = 0;
    nes.Cpu.x_register = 8;
    nes.Cpu.y_register = 8;
    nes.Cpu.memory[1] = 0x1;
    nes.Cpu.memory[9] = 0xAF;
    nes.Cpu.memory[10] = 0xF;

    nes.Cpu.setIndirectX(240);
    std.debug.print("{d} provided by Indirect Indexed X!\n", .{nes.Cpu.GetIndirectX()});
    try std.testing.expect(nes.Cpu.GetIndirectX() == nes.Cpu.memory[0xFAF % 0x800]);
    // implement Indirect Y Addressing Mode!
    //

    nes.Cpu.setIndirectY(241);
    std.debug.print("{d} provided by Indirect Indexed Y!\n", .{nes.Cpu.GetIndirectY()});
    try std.testing.expect(nes.Cpu.GetIndirectY() == nes.Cpu.memory[0xFAF % 0x800]);
}

test "Jump Addressing" {
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    nes.Cpu.pc = 0;
    nes.Cpu.memory[1] = 0xF;
    nes.Cpu.memory[2] = 0xAF;
    nes.Cpu.instruction = 0x6C;

    nes.Cpu.jump(std.time.nanoTimestamp());
    std.debug.print("Jumped to 0x{X}!\n", .{nes.Cpu.pc});
    try std.testing.expect(nes.Cpu.pc == 0xFAF);
}

test "Branch Relative Addressing" {
    std.debug.print("Branch Addressing!\n", .{});
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    nes.Cpu.pc = 256;
    nes.Cpu.memory[257] = 0b10000000;

    nes.Cpu.status.zero = 0;
    nes.Cpu.branchNoZero(std.time.nanoTimestamp());
    std.debug.print("Branched to {d}!\n", .{nes.Cpu.pc});
    try std.testing.expect(nes.Cpu.pc == 130);
}

test "Multi-Byte Add With Carry" {
    std.debug.print("Add With Carry!\n", .{});
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    nes.Cpu.pc = 0;
    nes.Cpu.status.carry = 1;
    nes.Cpu.accumulator = 254;
    nes.Cpu.memory[1] = 1;
    nes.Cpu.instruction = 0x69;

    nes.Cpu.addWithCarry(std.time.nanoTimestamp());
    std.debug.print("Sum is {d}!\n", .{nes.Cpu.accumulator});
    try std.testing.expect(nes.Cpu.accumulator == 0);
    try std.testing.expect(nes.Cpu.status.carry == 1);
    try std.testing.expect(nes.Cpu.status.overflow == 1);
    try std.testing.expect(nes.Cpu.status.zero == 1);
    try std.testing.expect(nes.Cpu.status.negative == 0);
}

test "Multi-Byte Subtraction" {
    std.debug.print("Subtract With Carry!\n", .{});
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    nes.Cpu.pc = 0;
    nes.Cpu.status.carry = 0;
    nes.Cpu.accumulator = 1;
    nes.Cpu.memory[1] = 1;
    nes.Cpu.instruction = 0xE9;

    nes.Cpu.subtractWithCarry(std.time.nanoTimestamp());
    std.debug.print("Difference is {d}!\n", .{nes.Cpu.accumulator});
    try std.testing.expect(nes.Cpu.accumulator == 255);
    try std.testing.expect(nes.Cpu.status.carry == 0);
    try std.testing.expect(nes.Cpu.status.negative == 1);
    try std.testing.expect(nes.Cpu.status.zero == 0);
    try std.testing.expect(nes.Cpu.status.overflow == 1);
}

test "Read/Write PPU" {
    std.debug.print("Write VRAM address!\n", .{});
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    //vram write test
    nes.init();
    nes.Cpu.pc = 0;
    nes.Cpu.accumulator = 0x20;
    nes.Cpu.memory[1] = 0x20;
    nes.Cpu.memory[2] = 0x06;
    nes.Cpu.instruction = 0x8D;
    nes.Cpu.storeAccumulator(std.time.nanoTimestamp());

    nes.Cpu.pc = 0;
    nes.Cpu.accumulator = 0;

    nes.Cpu.storeAccumulator(std.time.nanoTimestamp());
    std.debug.print("VRAM address is {X}!\n", .{nes.Ppu.cur_addr});
    try std.testing.expect(nes.Ppu.cur_addr == 0x2000);

    //read delay test
    nes.Cpu.accumulator = 240;
    nes.Cpu.pc = 0;
    nes.Cpu.memory[1] = 0x20;
    nes.Cpu.memory[2] = 0x07;
    nes.Cpu.storeAccumulator(std.time.nanoTimestamp());

    nes.Cpu.pc = 0;
    nes.Ppu.cur_addr -= 1;
    nes.Cpu.instruction = 0xAD;
    nes.Cpu.loadAccumulator(std.time.nanoTimestamp());

    try std.testing.expect(nes.Cpu.accumulator == 0);

    nes.Cpu.pc = 0;
    nes.Cpu.loadAccumulator(std.time.nanoTimestamp());
    try std.testing.expect(nes.Cpu.accumulator == 240);

    //write test
    nes.Cpu.pc = 0;
    nes.Cpu.instruction = 0x8D;
    nes.Cpu.storeAccumulator(std.time.nanoTimestamp());
    std.debug.print("{d} at Cpu address 0x2002!\n", .{nes.Ppu.memory[2]});
    try std.testing.expect(nes.Ppu.memory[2] == 240);
}

test "Read/Write Scroll" {
    std.debug.print("Write VRAM address!\n", .{});
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    //vram write test
    nes.init();
    nes.Cpu.pc = 0;
    nes.Cpu.accumulator = 0b00000010;
    nes.Cpu.memory[1] = 0x20;
    nes.Cpu.memory[2] = 0x00;
    nes.Cpu.instruction = 0x8D;
    nes.Cpu.storeAccumulator(std.time.nanoTimestamp());

    nes.Cpu.pc = 0;
    nes.Cpu.accumulator =  0b01111101;
    nes.Cpu.memory[1] = 0x20;
    nes.Cpu.memory[2] = 0x05;
    nes.Cpu.storeAccumulator(std.time.nanoTimestamp());

    nes.Cpu.pc = 0;
    nes.Cpu.accumulator = 0b01011110;
    nes.Cpu.memory[1] = 0x20;
    nes.Cpu.memory[2] = 0x05;
    nes.Cpu.storeAccumulator(std.time.nanoTimestamp());
}
