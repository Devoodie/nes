const std = @import("std");
const components = @import("Nes.zig");

test "Immediate Addressing" {
    std.debug.print("Cpu Testing!\n\n", .{});
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
    std.debug.print("Difference is {d}!\n\n", .{nes.Cpu.accumulator});
    try std.testing.expect(nes.Cpu.accumulator == 255);
    try std.testing.expect(nes.Cpu.status.carry == 0);
    try std.testing.expect(nes.Cpu.status.negative == 1);
    try std.testing.expect(nes.Cpu.status.zero == 0);
    try std.testing.expect(nes.Cpu.status.overflow == 1);

    std.debug.print("Ppu Testing!\n\n", .{});
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
    std.debug.print("VRAM address is {X}!\n", .{nes.Ppu.v});
    try std.testing.expect(nes.Ppu.v == 0x2000);

    //read delay test
    nes.Cpu.accumulator = 240;
    nes.Cpu.pc = 0;
    nes.Cpu.memory[1] = 0x20;
    nes.Cpu.memory[2] = 0x07;
    nes.Cpu.storeAccumulator(std.time.nanoTimestamp());

    nes.Cpu.pc = 0;
    nes.Ppu.v -= 1;
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
    std.debug.print("{d} at Cpu address 0x2002!\n\n", .{nes.Ppu.nametable[2]});
    try std.testing.expect(nes.Ppu.nametable[2] == 240);
}

test "Read/Write Scroll" {
    std.debug.print("Read/Write Scroll!\n", .{});
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
    nes.Cpu.accumulator = 0b01111101;
    nes.Cpu.memory[1] = 0x20;
    nes.Cpu.memory[2] = 0x05;
    nes.Cpu.storeAccumulator(std.time.nanoTimestamp());
    std.debug.print("Temp Vram is: {X}!\n", .{nes.Ppu.t});

    try std.testing.expect(nes.Ppu.t == 0b0000100000001111);
    try std.testing.expect(nes.Ppu.fine_x == 0b101);

    nes.Cpu.pc = 0;
    nes.Cpu.accumulator = 0b01011110;
    nes.Cpu.memory[1] = 0x20;
    nes.Cpu.memory[2] = 0x05;
    nes.Cpu.storeAccumulator(std.time.nanoTimestamp());

    std.debug.print("Scroll is: {X}!\n\n", .{nes.Ppu.v});

    try std.testing.expect(nes.Ppu.t == 0b110100101101111);
}

test "Ppu Direct Memory Access" {
    std.debug.print("PPU Direct Memory Access!\n\n", .{});
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    //dma from the second page (zeropage)

    nes.init();
    nes.Cpu.pc = 0;
    nes.Cpu.accumulator = 1;
    nes.Cpu.instruction = 0x8D;
    nes.Cpu.memory[1] = 0x40;
    nes.Cpu.memory[2] = 0x14;

    var i: u8 = 0;

    for (nes.Cpu.memory[256..512]) |*value| {
        value.* = i;
        i +%= 1;
    }

    nes.Cpu.storeAccumulator(std.time.nanoTimestamp());

    for (nes.Cpu.memory[256..512], nes.Ppu.oam) |cpu, oam| {
        try std.testing.expect(cpu == oam);
    }
}

test "Ppu Draw Coarse X " {
    std.debug.print("Draw Coarse X!\n\n", .{});
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    //dma from the second page (zeropage)

    nes.init();
    nes.Ppu.v = 1;
    nes.Ppu.cycles = 1;

    nes.Ppu.nametable[0] = 0;
    nes.Ppu.nametable[960] = 12;

    //test right table capabilities
    nes.Ppu.control = 0b10000;
    nes.Ppu.pattern_table[0x1000] = 187;
    nes.Ppu.pattern_table[0x1008] = 217;

    nes.Ppu.scanline = 0;
    nes.Ppu.fine_x = 7;
    nes.Ppu.mask = 0xA;
    nes.Ppu.x_pos = 0;

    nes.Ppu.drawCoarseX(); //fetch the 2 tiles
    nes.Ppu.drawCoarseX();
    try std.testing.expect(nes.Ppu.bitmap[0][8] == 15);
    try std.testing.expect(nes.Ppu.bitmap[0][9] == 14);
    try std.testing.expect(nes.Ppu.bitmap[0][10] == 13);
    try std.testing.expect(nes.Ppu.bitmap[0][11] == 15);
    try std.testing.expect(nes.Ppu.bitmap[0][12] == 15);
    try std.testing.expect(nes.Ppu.bitmap[0][13] == 12);
    try std.testing.expect(nes.Ppu.bitmap[0][14] == 13);
    try std.testing.expect(nes.Ppu.bitmap[0][15] == 15);
}

test "Fill Sprites" {
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    std.debug.print("Fill Sprites!\n", .{});
    nes.init();

    nes.Ppu.oam[5] = 1;
    nes.Ppu.oam[6] = 3;

    //test right table capabilities
    nes.Ppu.pattern_table[16] = 187;
    nes.Ppu.pattern_table[24] = 217;
    nes.Ppu.pattern_table[17] = 111;
    nes.Ppu.pattern_table[25] = 222;
    nes.Ppu.pattern_table[18] = 192;
    nes.Ppu.pattern_table[26] = 234;
    nes.Ppu.pattern_table[19] = 139;
    nes.Ppu.pattern_table[27] = 189;
    nes.Ppu.pattern_table[20] = 182;
    nes.Ppu.pattern_table[28] = 100;
    nes.Ppu.pattern_table[21] = 44;
    nes.Ppu.pattern_table[29] = 246;
    nes.Ppu.pattern_table[22] = 45;
    nes.Ppu.pattern_table[30] = 0;
    nes.Ppu.pattern_table[23] = 85;
    nes.Ppu.pattern_table[31] = 72;

    const answers = [8][8]u5{
        [8]u5{ 31, 30, 29, 31, 31, 28, 29, 31 },
        [8]u5{ 30, 31, 29, 30, 31, 31, 31, 29 },
        [8]u5{ 31, 31, 30, 28, 30, 28, 30, 28 },
        [8]u5{ 31, 28, 30, 30, 31, 30, 29, 31 },
        [8]u5{ 29, 30, 31, 29, 28, 31, 29, 28 },
        [8]u5{ 30, 30, 31, 30, 29, 31, 30, 28 },
        [8]u5{ 28, 28, 29, 28, 29, 29, 28, 29 },
        [8]u5{ 28, 31, 28, 29, 30, 29, 28, 29 },
    };

    nes.Ppu.fillSprites();

    for (nes.Ppu.sprites[1].small, answers) |value_row, answer_row| {
        for (value_row, answer_row) |value, answer| {
            try std.testing.expect(value == answer);
        }
    }

    std.debug.print("Fill Sprites Long!\n\n", .{});

    nes.Ppu.pattern_table[0 + 0x1000] = 187;
    nes.Ppu.pattern_table[8 + 0x1000] = 217;
    nes.Ppu.pattern_table[1 + 0x1000] = 111;
    nes.Ppu.pattern_table[9 + 0x1000] = 222;
    nes.Ppu.pattern_table[2 + 0x1000] = 192;
    nes.Ppu.pattern_table[10 + 0x1000] = 234;
    nes.Ppu.pattern_table[3 + 0x1000] = 139;
    nes.Ppu.pattern_table[11 + 0x1000] = 189;
    nes.Ppu.pattern_table[4 + 0x1000] = 182;
    nes.Ppu.pattern_table[12 + 0x1000] = 100;
    nes.Ppu.pattern_table[5 + 0x1000] = 44;
    nes.Ppu.pattern_table[13 + 0x1000] = 246;
    nes.Ppu.pattern_table[6 + 0x1000] = 45;
    nes.Ppu.pattern_table[14 + 0x1000] = 0;
    nes.Ppu.pattern_table[7 + 0x1000] = 85;
    nes.Ppu.pattern_table[15 + 0x1000] = 72;
    nes.Ppu.pattern_table[16 + 0x1000] = 187;
    nes.Ppu.pattern_table[24 + 0x1000] = 217;
    nes.Ppu.pattern_table[17 + 0x1000] = 111;
    nes.Ppu.pattern_table[25 + 0x1000] = 222;
    nes.Ppu.pattern_table[18 + 0x1000] = 192;
    nes.Ppu.pattern_table[26 + 0x1000] = 234;
    nes.Ppu.pattern_table[19 + 0x1000] = 139;
    nes.Ppu.pattern_table[27 + 0x1000] = 189;
    nes.Ppu.pattern_table[20 + 0x1000] = 182;
    nes.Ppu.pattern_table[28 + 0x1000] = 100;
    nes.Ppu.pattern_table[21 + 0x1000] = 44;
    nes.Ppu.pattern_table[29 + 0x1000] = 246;
    nes.Ppu.pattern_table[22 + 0x1000] = 45;
    nes.Ppu.pattern_table[30 + 0x1000] = 0;
    nes.Ppu.pattern_table[23 + 0x1000] = 85;
    nes.Ppu.pattern_table[31 + 0x1000] = 72;

    nes.Ppu.control = 0b100000;

    nes.Ppu.fillSprites();

    const long_answers = [16][8]u5{
        [8]u5{ 31, 30, 29, 31, 31, 28, 29, 31 },
        [8]u5{ 30, 31, 29, 30, 31, 31, 31, 29 },
        [8]u5{ 31, 31, 30, 28, 30, 28, 30, 28 },
        [8]u5{ 31, 28, 30, 30, 31, 30, 29, 31 },
        [8]u5{ 29, 30, 31, 29, 28, 31, 29, 28 },
        [8]u5{ 30, 30, 31, 30, 29, 31, 30, 28 },
        [8]u5{ 28, 28, 29, 28, 29, 29, 28, 29 },
        [8]u5{ 28, 31, 28, 29, 30, 29, 28, 29 },
        [8]u5{ 31, 30, 29, 31, 31, 28, 29, 31 },
        [8]u5{ 30, 31, 29, 30, 31, 31, 31, 29 },
        [8]u5{ 31, 31, 30, 28, 30, 28, 30, 28 },
        [8]u5{ 31, 28, 30, 30, 31, 30, 29, 31 },
        [8]u5{ 29, 30, 31, 29, 28, 31, 29, 28 },
        [8]u5{ 30, 30, 31, 30, 29, 31, 30, 28 },
        [8]u5{ 28, 28, 29, 28, 29, 29, 28, 29 },
        [8]u5{ 28, 31, 28, 29, 30, 29, 28, 29 },
    };

    for (nes.Ppu.sprites[1].large, long_answers) |value_row, answer_row| {
        for (value_row, answer_row) |value, answer| {
            //            std.debug.print("Value: {d}, Answer: {d}, Index: {d}\n", .{ value, answer, index });
            try std.testing.expect(value == answer);
        }
    }
}

test "Get Sprite Pixel" {
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    std.debug.print("Get Sprite Pixel!\n", .{});

    nes.Ppu.v |= 0b000100000;
    nes.Ppu.scanline = 8;

    nes.Ppu.oam[4] = 8;
    nes.Ppu.oam[5] = 1;
    nes.Ppu.oam[6] = 0x23;
    nes.Ppu.oam[7] = 0;

    nes.Ppu.pattern_table[0] = 187;
    nes.Ppu.pattern_table[8] = 217;
    nes.Ppu.pattern_table[1] = 111;
    nes.Ppu.pattern_table[9] = 222;
    nes.Ppu.pattern_table[2] = 192;
    nes.Ppu.pattern_table[10] = 234;
    nes.Ppu.pattern_table[3] = 139;
    nes.Ppu.pattern_table[11] = 189;
    nes.Ppu.pattern_table[4] = 182;
    nes.Ppu.pattern_table[12] = 100;
    nes.Ppu.pattern_table[5] = 44;
    nes.Ppu.pattern_table[13] = 246;
    nes.Ppu.pattern_table[6] = 45;
    nes.Ppu.pattern_table[14] = 0;
    nes.Ppu.pattern_table[7] = 85;
    nes.Ppu.pattern_table[15] = 72;
    nes.Ppu.pattern_table[16] = 187;
    nes.Ppu.pattern_table[24] = 217;
    nes.Ppu.pattern_table[17] = 111;
    nes.Ppu.pattern_table[25] = 222;
    nes.Ppu.pattern_table[18] = 192;
    nes.Ppu.pattern_table[26] = 234;
    nes.Ppu.pattern_table[19] = 139;
    nes.Ppu.pattern_table[27] = 189;
    nes.Ppu.pattern_table[20] = 182;
    nes.Ppu.pattern_table[28] = 100;
    nes.Ppu.pattern_table[21] = 44;
    nes.Ppu.pattern_table[29] = 246;
    nes.Ppu.pattern_table[22] = 45;
    nes.Ppu.pattern_table[30] = 0;
    nes.Ppu.pattern_table[23] = 85;
    nes.Ppu.pattern_table[31] = 72;

    nes.Ppu.fillSprites();

    //sprite evaluation test
    nes.Ppu.spriteEvaluation();

    try std.testing.expect(nes.Ppu.secondary_oam[0].? == 1);
    std.debug.print("Sprite Evaluation Test: GOOD!\n", .{});

    //no rendering test

    const background: u5 = 15;

    var sprite: ?u5 = nes.Ppu.drawSprites(0, background);
    std.debug.print("No Sprite Rendering Test: GOOD!\n", .{});

    try std.testing.expect(sprite == null);

    //background priority
    nes.Ppu.mask |= 0x14;

    sprite = nes.Ppu.drawSprites(0, background);

    try std.testing.expect(sprite.? == background);

    std.debug.print("Background Priority Test: GOOD!\n\n", .{});

    //Draw Sprite
    nes.Ppu.oam[6] = 3;

    sprite = nes.Ppu.drawSprites(0, background);

    try std.testing.expect(sprite.? == 31);
    std.debug.print("Small Sprite Drawing: GOOD!\n\n", .{});

    //Draw Sprite Horizontal Flipped
    nes.Ppu.oam[6] = 0x43;

    sprite = 0;

    sprite = nes.Ppu.drawSprites(0, background);

    try std.testing.expect(sprite.? == 31);
    std.debug.print("Small Sprite Horizontal Flipped: GOOD!\n\n", .{});

    //Draw Sprite Vertical Flipped
    nes.Ppu.oam[6] = 0xC3;

    sprite = 0;

    sprite = nes.Ppu.drawSprites(0, background);

    try std.testing.expect(sprite.? == 29);
    std.debug.print("Small Sprite Vertical Flipped: GOOD!\n\n", .{});

    //Draw Sprite Large
    nes.Ppu.control = 0x20;

    nes.Ppu.oam[5] = 0;
    nes.Ppu.oam[6] = 3;

    nes.Ppu.fillSprites();

    sprite = 0;

    sprite = nes.Ppu.drawSprites(0, background);

    try std.testing.expect(sprite.? == 31);
    std.debug.print("Large Sprite Drawing: GOOD!\n\n", .{});

    //Draw Large Sprite Horizontal Flipped
    nes.Ppu.oam[6] = 0x43;

    sprite = 0;

    sprite = nes.Ppu.drawSprites(0, background);

    try std.testing.expect(sprite.? == 31);
    std.debug.print("Large Sprite Horizontal Flipped: Good!\n\n", .{});

    //Draw Large Sprite Verticle Flipped
    nes.Ppu.oam[6] = 0xC3;

    sprite = 0;

    sprite = nes.Ppu.drawSprites(0, background);

    try std.testing.expect(sprite.? == 28);
    std.debug.print("Large Sprite Verticle Flipped: Good!\n\n", .{});
}

test "Draw Scanline" {
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    std.debug.print("Draw Scanline!\n", .{});

    //we're on scanline 12 loading the last row of the tile
    nes.Ppu.v = 0x700C;
    nes.Ppu.scanline = 7;
    nes.Ppu.mask = 0x1E;

    nes.Ppu.oam[0] = 0;
    nes.Ppu.oam[1] = 63;
    nes.Ppu.oam[2] = 3;
    nes.Ppu.oam[3] = 4;

    nes.Ppu.oam[4] = 0;
    nes.Ppu.oam[5] = 64;
    nes.Ppu.oam[6] = 3;
    nes.Ppu.oam[7] = 0;

    //sprite 0's pattern data
    nes.Ppu.pattern_table[1008] = 187;
    nes.Ppu.pattern_table[1016] = 217;
    nes.Ppu.pattern_table[1009] = 111;
    nes.Ppu.pattern_table[1017] = 222;
    nes.Ppu.pattern_table[1010] = 192;
    nes.Ppu.pattern_table[1018] = 234;
    nes.Ppu.pattern_table[1011] = 139;
    nes.Ppu.pattern_table[1019] = 189;
    nes.Ppu.pattern_table[1012] = 182;
    nes.Ppu.pattern_table[1020] = 100;
    nes.Ppu.pattern_table[1013] = 44;
    nes.Ppu.pattern_table[1021] = 246;
    nes.Ppu.pattern_table[1014] = 45;
    nes.Ppu.pattern_table[1022] = 0;
    nes.Ppu.pattern_table[1015] = 85;
    nes.Ppu.pattern_table[1023] = 72;

    //next sprites pattern data
    nes.Ppu.pattern_table[1024] = 187;
    nes.Ppu.pattern_table[1032] = 217;
    nes.Ppu.pattern_table[1025] = 111;
    nes.Ppu.pattern_table[1033] = 222;
    nes.Ppu.pattern_table[1026] = 192;
    nes.Ppu.pattern_table[1034] = 234;
    nes.Ppu.pattern_table[1027] = 139;
    nes.Ppu.pattern_table[1035] = 189;
    nes.Ppu.pattern_table[1028] = 182;
    nes.Ppu.pattern_table[1036] = 100;
    nes.Ppu.pattern_table[1029] = 44;
    nes.Ppu.pattern_table[1037] = 246;
    nes.Ppu.pattern_table[1030] = 45;
    nes.Ppu.pattern_table[1038] = 0;
    nes.Ppu.pattern_table[1031] = 85;
    nes.Ppu.pattern_table[1039] = 72;

    for (0..32) |index| {
        nes.Ppu.nametable[index] = @as(u8, @truncate(index));
    }

    //background tiles should be = to 255
    for (0..32) |tile| {
        // fine y = 7 and scanline = 8; name table points to this tile first
        nes.Ppu.pattern_table[tile * 16 + 7] = 0xFF;
        nes.Ppu.pattern_table[tile * 16 + 15] = 0xFF;
    }

    // first two tiles
    //    nes.Ppu.low_shift = 192 << 8;
    //   nes.Ppu.high_shift = 148 << 8;

    //  nes.Ppu.low_shift |= 234;
    // nes.Ppu.high_shift |= 214;
    nes.Ppu.low_shift = 0xFFFF;
    nes.Ppu.high_shift = 0xFFFF;

    //fill sprites
    nes.Ppu.fillSprites();
    nes.Ppu.spriteEvaluation();
    nes.Ppu.drawScanLine(std.time.nanoTimestamp());

    for (nes.Ppu.bitmap[7], 0..) |pixel, index| {
        if (index < 4) {
            // std.debug.print("Bitmap Value: {d}, Sprite Value: {d}!\n", .{ pixel, nes.Ppu.sprites[1].small[7][@truncate(index)] });
            try std.testing.expect(pixel == nes.Ppu.sprites[1].small[7][@truncate(index)]);
        } else if (index < 12) {
            //            std.debug.print("Bitmap Value: {d}, Sprite Value: {d}!\n", .{ pixel, nes.Ppu.sprites[1].small[7][@as(u3, @truncate(index - 4))] });
            try std.testing.expect(pixel == nes.Ppu.sprites[0].small[7][@as(u3, @truncate(index - 4))]);
        } else {
            try std.testing.expect(pixel == 3);
        }
        //std.debug.print("Pixel: {d}!\n", .{pixel});
    }
    std.debug.print("\n\n", .{});
}
