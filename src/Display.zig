const std = @import("std");
const rl = @import("raylib");
const picture_unit = @import("ppu");

pub const Color = enum(u8) {
    darkGray = 0,
    silver = 0x10,
    white = 0x20,
    whitewhite = 0x30,

    darkAzure = 0x01,
    mediumAzure = 0x11,
    lightAzure = 0x21,
    paleAzure = 0x31,

    darkBlue = 0x02,
    mediumBlue = 0x12,
    lightBlue = 0x22,
    paleBlue = 0x32,

    darkViolet = 0x03,
    mediumViolet = 0x13,
    lightViolet = 0x23,
    paleViolet = 0x33,

    darkMagenta = 0x04,
    mediumMagenta = 0x14,
    lightMagenta = 0x24,
    paleMagenta = 0x34,

    darkRose = 0x05,
    mediumRose = 0x15,
    lightRose = 0x25,
    paleRose = 0x35,

    darkRed = 0x06,
    mediumRed = 0x16,
    lightRed = 0x26,
    paleRed = 0x36,

    darkOrange = 0x07,
    mediumOrange = 0x17,
    lightOrange = 0x27,
    paleOrange = 0x37,

    darkYellow = 0x08,
    mediumYellow = 0x18,
    lightYellow = 0x28,
    paleYellow = 0x38,

    darkChartreuse = 0x09,
    mediumChartreuse = 0x19,
    lightChartreuse = 0x29,
    paleChartreuse = 0x39,

    darkGreen = 0x0A,
    mediumGreen = 0x1A,
    lightGreen = 0x2A,
    paleGreen = 0x3A,

    darkSpring = 0x0B,
    mediumSpring = 0x1B,
    lightSpring = 0x2B,
    paleSpring = 0x3B,

    darkCyan = 0x0C,
    mediumCyan = 0x1C,
    lightCyan = 0x2C,
    paleCyan = 0x3C,

    darkBlack = 0x0D,
    mediumBlack = 0x1D,
    lightBlack = 0x2D,
    paleBlack = 0x3D,

    Black = 0x0E,
};

pub fn draw(ppu: *picture_unit.Ppu) !void {
    //
    const width = 1280;
    const height = 1200;
    rl.initWindow(width, height, "Devooty's Nes");
    defer rl.closeWindow();

    rl.setTargetFPS(60);
    const bitmap: rl.Texture2D = .{ .format = .uncompressed_r8g8b8, .mipmaps = 1, .height = 240, .width = 256, .id = 1 };
    var screen: [240][2048]u8 = undefined;

    while (true) {
        if (ppu.status & 0x80 == 0x80) {
            rl.beginDrawing();
            //    rl.drawText("You're In It!\n", 190, 200, 20, rl.Color.white);
            rl.clearBackground(rl.Color.black);
            GetScreen(&screen, ppu.bitmap, ppu.pallet_memory);
            rl.updateTexture(bitmap, &screen);
            rl.drawTexture(bitmap, 0, 0, rl.Color.white);
            //rl.drawTextureEx(bitmap, .{ .x = 0, .y = 0 }, 0, 5, rl.Color.blank);
            //            rl.drawText("Drew\n", 190, 200, 20, rl.Color.white);
            rl.endDrawing();
            //        std.debug.print("PPU bitmap: {any}!\n", .{ppu.bitmap});
        }
    }
    // }
}

fn GetScreen(screen: *[240][2048]u8, bitmap: *[240][256]u5, pallet: [32]u8) void {
    var pixel: u8 = 0;
    for (bitmap, 0..) |row, y_pos| {
        for (row, 0..) |column, x_pos| {
            pixel = pallet[column];
            switch (pixel) {
                0 => {
                    screen[y_pos][x_pos] = 0x62;
                    screen[y_pos][x_pos + 1] = 0x62;
                    screen[y_pos][x_pos + 2] = 0x62;
                },
                0x1 => {
                    screen[y_pos][x_pos] = 0x00;
                    screen[y_pos][x_pos + 1] = 0x2E;
                    screen[y_pos][x_pos + 2] = 0x98;
                },
                0x2 => {
                    screen[y_pos][x_pos] = 0x0C;
                    screen[y_pos][x_pos + 1] = 0x11;
                    screen[y_pos][x_pos + 2] = 0xC2;
                },
                0x3 => {
                    screen[y_pos][x_pos] = 0x3B;
                    screen[y_pos][x_pos + 1] = 0x00;
                    screen[y_pos][x_pos + 2] = 0xC2;
                },
                0x4 => {
                    screen[y_pos][x_pos] = 0x65;
                    screen[y_pos][x_pos + 1] = 0x00;
                    screen[y_pos][x_pos + 2] = 0x98;
                },
                0x5 => {
                    screen[y_pos][x_pos] = 0x7D;
                    screen[y_pos][x_pos + 1] = 0x00;
                    screen[y_pos][x_pos + 2] = 0x4E;
                },
                0x6 => {
                    screen[y_pos][x_pos] = 0x7D;
                    screen[y_pos][x_pos + 1] = 0x00;
                    screen[y_pos][x_pos + 2] = 0x00;
                },
                0x7 => {
                    screen[y_pos][x_pos] = 0x65;
                    screen[y_pos][x_pos + 1] = 0x19;
                    screen[y_pos][x_pos + 2] = 0x00;
                },
                0x8 => {
                    screen[y_pos][x_pos] = 0x3B;
                    screen[y_pos][x_pos + 1] = 0x36;
                    screen[y_pos][x_pos + 2] = 0x00;
                },
                0x9 => {
                    screen[y_pos][x_pos] = 0x0C;
                    screen[y_pos][x_pos + 1] = 0x4F;
                    screen[y_pos][x_pos + 2] = 0x00;
                },
                0xA => {
                    screen[y_pos][x_pos] = 0x00;
                    screen[y_pos][x_pos + 1] = 0x5B;
                    screen[y_pos][x_pos + 2] = 0x00;
                },
                0xB => {
                    screen[y_pos][x_pos] = 0x00;
                    screen[y_pos][x_pos + 1] = 0x59;
                    screen[y_pos][x_pos + 2] = 0x00;
                },
                0xC => {
                    screen[y_pos][x_pos] = 0x00;
                    screen[y_pos][x_pos + 1] = 0x49;
                    screen[y_pos][x_pos + 2] = 0x4E;
                },
                0xD, 0xE, 0xF, 0x1D, 0x1E, 0x1F, 0x2E, 0x2F, 0x3E, 0x3F => {
                    screen[y_pos][x_pos] = 0x0;
                    screen[y_pos][x_pos + 1] = 0x0;
                    screen[y_pos][x_pos + 2] = 0x0;
                },
                0x10 => {
                    screen[y_pos][x_pos] = 0xAB;
                    screen[y_pos][x_pos + 1] = 0xAB;
                    screen[y_pos][x_pos + 2] = 0xAB;
                },
                0x11 => {
                    screen[y_pos][x_pos] = 0x00;
                    screen[y_pos][x_pos + 1] = 0x64;
                    screen[y_pos][x_pos + 2] = 0xF4;
                },
                0x12 => {
                    screen[y_pos][x_pos] = 0x35;
                    screen[y_pos][x_pos + 1] = 0x3C;
                    screen[y_pos][x_pos + 2] = 0xFF;
                },
                0x13 => {
                    screen[y_pos][x_pos] = 0x76;
                    screen[y_pos][x_pos + 1] = 0x1B;
                    screen[y_pos][x_pos + 2] = 0xFF;
                },
                0x14 => {
                    screen[y_pos][x_pos] = 0xAE;
                    screen[y_pos][x_pos + 1] = 0x0A;
                    screen[y_pos][x_pos + 2] = 0xF4;
                },
                0x15 => {
                    screen[y_pos][x_pos] = 0xCF;
                    screen[y_pos][x_pos + 1] = 0x0C;
                    screen[y_pos][x_pos + 2] = 0x8F;
                },
                0x16 => {
                    screen[y_pos][x_pos] = 0xCF;
                    screen[y_pos][x_pos + 1] = 0x23;
                    screen[y_pos][x_pos + 2] = 0x1C;
                },
                0x17 => {
                    screen[y_pos][x_pos] = 0xAE;
                    screen[y_pos][x_pos + 1] = 0x47;
                    screen[y_pos][x_pos + 2] = 0x00;
                },
                0x18 => {
                    screen[y_pos][x_pos] = 0x76;
                    screen[y_pos][x_pos + 1] = 0x6F;
                    screen[y_pos][x_pos + 2] = 0x00;
                },
                0x19 => {
                    screen[y_pos][x_pos] = 0x35;
                    screen[y_pos][x_pos + 1] = 0x90;
                    screen[y_pos][x_pos + 2] = 0x00;
                },
                0x1A => {
                    screen[y_pos][x_pos] = 0x00;
                    screen[y_pos][x_pos + 1] = 0xA1;
                    screen[y_pos][x_pos + 2] = 0x00;
                },
                0x1B => {
                    screen[y_pos][x_pos] = 0x00;
                    screen[y_pos][x_pos + 1] = 0x9E;
                    screen[y_pos][x_pos + 2] = 0x1C;
                },
                0x1C => {
                    screen[y_pos][x_pos] = 0x00;
                    screen[y_pos][x_pos + 1] = 0x88;
                    screen[y_pos][x_pos + 2] = 0x8F;
                },
                0x20, 0x30 => {
                    screen[y_pos][x_pos] = 0xFF;
                    screen[y_pos][x_pos + 1] = 0xFF;
                    screen[y_pos][x_pos + 2] = 0xFF;
                },
                0x21 => {
                    screen[y_pos][x_pos] = 0x4A;
                    screen[y_pos][x_pos + 1] = 0xB5;
                    screen[y_pos][x_pos + 2] = 0xFF;
                },
                0x22 => {
                    screen[y_pos][x_pos] = 0x85;
                    screen[y_pos][x_pos + 1] = 0x8C;
                    screen[y_pos][x_pos + 2] = 0xFF;
                },
                0x23 => {
                    screen[y_pos][x_pos] = 0xC8;
                    screen[y_pos][x_pos + 1] = 0x6A;
                    screen[y_pos][x_pos + 2] = 0xFF;
                },
                0x24 => {
                    screen[y_pos][x_pos] = 0xFF;
                    screen[y_pos][x_pos + 1] = 0x58;
                    screen[y_pos][x_pos + 2] = 0xFF;
                },
                0x25 => {
                    screen[y_pos][x_pos] = 0xFF;
                    screen[y_pos][x_pos + 1] = 0x5B;
                    screen[y_pos][x_pos + 2] = 0xE2;
                },
                0x26 => {
                    screen[y_pos][x_pos] = 0xFF;
                    screen[y_pos][x_pos + 1] = 0x72;
                    screen[y_pos][x_pos + 2] = 0x6A;
                },
                0x27 => {
                    screen[y_pos][x_pos] = 0xFF;
                    screen[y_pos][x_pos + 1] = 0x97;
                    screen[y_pos][x_pos + 2] = 0x02;
                },
                0x28 => {
                    screen[y_pos][x_pos] = 0xC8;
                    screen[y_pos][x_pos + 1] = 0xC1;
                    screen[y_pos][x_pos + 2] = 0x00;
                },
                0x29 => {
                    screen[y_pos][x_pos] = 0x85;
                    screen[y_pos][x_pos + 1] = 0xE3;
                    screen[y_pos][x_pos + 2] = 0x00;
                },
                0x2A => {
                    screen[y_pos][x_pos] = 0x4A;
                    screen[y_pos][x_pos + 1] = 0xF5;
                    screen[y_pos][x_pos + 2] = 0x02;
                },
                0x2B => {
                    screen[y_pos][x_pos] = 0x29;
                    screen[y_pos][x_pos + 1] = 0xF2;
                    screen[y_pos][x_pos + 2] = 0x6A;
                },
                0x2C => {
                    screen[y_pos][x_pos] = 0x29;
                    screen[y_pos][x_pos + 1] = 0xDB;
                    screen[y_pos][x_pos + 2] = 0xE2;
                },
                0x2D => {
                    screen[y_pos][x_pos] = 0x4E;
                    screen[y_pos][x_pos + 1] = 0x4E;
                    screen[y_pos][x_pos + 2] = 0x4E;
                },
                0x31 => {
                    screen[y_pos][x_pos] = 0xB6;
                    screen[y_pos][x_pos + 1] = 0xE1;
                    screen[y_pos][x_pos + 2] = 0xFF;
                },
                0x32 => {
                    screen[y_pos][x_pos] = 0xCE;
                    screen[y_pos][x_pos + 1] = 0xD1;
                    screen[y_pos][x_pos + 2] = 0xFF;
                },
                0x33 => {
                    screen[y_pos][x_pos] = 0xE9;
                    screen[y_pos][x_pos + 1] = 0xC3;
                    screen[y_pos][x_pos + 2] = 0xFF;
                },
                0x34 => {
                    screen[y_pos][x_pos] = 0xFF;
                    screen[y_pos][x_pos + 1] = 0xBC;
                    screen[y_pos][x_pos + 2] = 0xFF;
                },
                0x35 => {
                    screen[y_pos][x_pos] = 0xFF;
                    screen[y_pos][x_pos + 1] = 0xBD;
                    screen[y_pos][x_pos + 2] = 0xF4;
                },
                0x36 => {
                    screen[y_pos][x_pos] = 0xFF;
                    screen[y_pos][x_pos + 1] = 0xC6;
                    screen[y_pos][x_pos + 2] = 0xC3;
                },
                0x37 => {
                    screen[y_pos][x_pos] = 0xFF;
                    screen[y_pos][x_pos + 1] = 0xD5;
                    screen[y_pos][x_pos + 2] = 0x9A;
                },
                0x38 => {
                    screen[y_pos][x_pos] = 0xE9;
                    screen[y_pos][x_pos + 1] = 0xE6;
                    screen[y_pos][x_pos + 2] = 0x81;
                },
                0x39 => {
                    screen[y_pos][x_pos] = 0xCE;
                    screen[y_pos][x_pos + 1] = 0xF4;
                    screen[y_pos][x_pos + 2] = 0x81;
                },
                0x3A => {
                    screen[y_pos][x_pos] = 0xB6;
                    screen[y_pos][x_pos + 1] = 0xE1;
                    screen[y_pos][x_pos + 2] = 0xFF;
                },
                0x3B => {
                    screen[y_pos][x_pos] = 0xA9;
                    screen[y_pos][x_pos + 1] = 0xFA;
                    screen[y_pos][x_pos + 2] = 0xC3;
                },
                0x3C => {
                    screen[y_pos][x_pos] = 0xA9;
                    screen[y_pos][x_pos + 1] = 0xF0;
                    screen[y_pos][x_pos + 2] = 0xF4;
                },
                0x3D => {
                    screen[y_pos][x_pos] = 0xB8;
                    screen[y_pos][x_pos + 1] = 0xB8;
                    screen[y_pos][x_pos + 2] = 0xB8;
                },
                else => {
                    screen[y_pos][x_pos] = 0xFF;
                    screen[y_pos][x_pos + 1] = 0xFF;
                    screen[y_pos][x_pos + 2] = 0xFF;
                },
            }
        }
    }
}
