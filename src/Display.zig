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
    const bitmap: rl.Texture2D = .{ .format = .uncompressed_r8g8b8, .mipmaps = 1, .height = 1200, .width = 1280, .id = 1 };

    while (true) {
        if (ppu.status & 0x80 == 0x80) {
            rl.beginDrawing();
            //    rl.drawText("You're In It!\n", 190, 200, 20, rl.Color.white);
            rl.clearBackground(rl.Color.black);
            rl.updateTexture(bitmap, GetScreen(ppu.bitmap, ppu.pallet_memory));
            //            rl.drawText("Drew\n", 190, 200, 20, rl.Color.white);
            rl.endDrawing();
            //        std.debug.print("PPU bitmap: {any}!\n", .{ppu.bitmap});
        }
    }
    // }
}

fn GetScreen(bitmap: *[240][256]u5, pallet: [32]u8) [][]rl.Color {
    var screen: [240][256]rl.Color = undefined;
    var pixel: u8 = 0;
    for (bitmap, 0..) |row, y_pos| {
        for (row, 0..) |column, x_pos| {
            pixel = pallet[column];
            switch (pixel) {
                0 => {
                    screen[y_pos][x_pos] = rl.getColor(0x626262);
                },
                0x1 => {
                    screen[y_pos][x_pos] = rl.getColor(0x002E98);
                },
                0x2 => {
                    screen[y_pos][x_pos] = rl.getColor(0x0C11C2);
                },
                0x3 => {
                    screen[y_pos][x_pos] = rl.getColor(0x3B00C2);
                },
                0x4 => {
                    screen[y_pos][x_pos] = rl.getColor(0x650098);
                },
                0x5 => {
                    screen[y_pos][x_pos] = rl.getColor(0x7D004E);
                },
                0x6 => {
                    screen[y_pos][x_pos] = rl.getColor(0x7D0000);
                },
                0x7 => {
                    screen[y_pos][x_pos] = rl.getColor(0x651900);
                },
                0x8 => {
                    screen[y_pos][x_pos] = rl.getColor(0x3B3600);
                },
                0x9 => {
                    screen[y_pos][x_pos] = rl.getColor(0x0C4F00);
                },
                0xA => {
                    screen[y_pos][x_pos] = rl.getColor(0x005B00);
                },
                0xB => {
                    screen[y_pos][x_pos] = rl.getColor(0x005900);
                },
                0xC => {
                    screen[y_pos][x_pos] = rl.getColor(0x00494E);
                },
                0xD, 0xE, 0xF, 0x1D, 0x1E, 0x1F, 0x2E, 0x2F, 0x3E, 0x3F => {
                    screen[y_pos][x_pos] = rl.getColor(0x000000);
                },
                0x10 => {
                    screen[y_pos][x_pos] = rl.getColor(0xABABAB);
                },
                0x11 => {
                    screen[y_pos][x_pos] = rl.getColor(0x0064F4);
                },
                0x12 => {
                    screen[y_pos][x_pos] = rl.getColor(0x353CFF);
                },
                0x13 => {
                    screen[y_pos][x_pos] = rl.getColor(0x761BFF);
                },
                0x14 => {
                    screen[y_pos][x_pos] = rl.getColor(0xAE0AF4);
                },
                0x15 => {
                    screen[y_pos][x_pos] = rl.getColor(0xCF0C8F);
                },
                0x16 => {
                    screen[y_pos][x_pos] = rl.getColor(0xCF231C);
                },
                0x17 => {
                    screen[y_pos][x_pos] = rl.getColor(0xAE4700);
                },
                0x18 => {
                    screen[y_pos][x_pos] = rl.getColor(0x766F00);
                },
                0x19 => {
                    screen[y_pos][x_pos] = rl.getColor(0x359000);
                },
                0x1A => {
                    screen[y_pos][x_pos] = rl.getColor(0x00A100);
                },
                0x1B => {
                    screen[y_pos][x_pos] = rl.getColor(0x009E1C);
                },
                0x1C => {
                    screen[y_pos][x_pos] = rl.getColor(0x00888F);
                },
                0x20, 0x30 => {
                    screen[y_pos][x_pos] = rl.getColor(0xFFFFFF);
                },
                0x21 => {
                    screen[y_pos][x_pos] = rl.getColor(0x4AB5FF);
                },
                0x22 => {
                    screen[y_pos][x_pos] = rl.getColor(0x858CFF);
                },
                0x23 => {
                    screen[y_pos][x_pos] = rl.getColor(0xC86AFF);
                },
                0x24 => {
                    screen[y_pos][x_pos] = rl.getColor(0xFF58FF);
                },
                0x25 => {
                    screen[y_pos][x_pos] = rl.getColor(0xFF5BE2);
                },
                0x26 => {
                    screen[y_pos][x_pos] = rl.getColor(0xFF726A);
                },
                0x27 => {
                    screen[y_pos][x_pos] = rl.getColor(0xFF9702);
                },
                0x28 => {
                    screen[y_pos][x_pos] = rl.getColor(0xC8C100);
                },
                0x29 => {
                    screen[y_pos][x_pos] = rl.getColor(0x85E300);
                },
                0x2A => {
                    screen[y_pos][x_pos] = rl.getColor(0x4AF502);
                },
                0x2B => {
                    screen[y_pos][x_pos] = rl.getColor(0x29F26A);
                },
                0x2C => {
                    screen[y_pos][x_pos] = rl.getColor(0x29DBE2);
                },
                0x2D => {
                    screen[y_pos][x_pos] = rl.getColor(0x4E4E4E);
                },
                0x31 => {
                    screen[y_pos][x_pos] = rl.getColor(0xB6E1FF);
                },
                0x32 => {
                    screen[y_pos][x_pos] = rl.getColor(0xCED1FF);
                },
                0x33 => {
                    screen[y_pos][x_pos] = rl.getColor(0xE9C3FF);
                },
                0x34 => {
                    screen[y_pos][x_pos] = rl.getColor(0xFFBCFF);
                },
                0x35 => {
                    screen[y_pos][x_pos] = rl.getColor(0xFFBDF4);
                },
                0x36 => {
                    screen[y_pos][x_pos] = rl.getColor(0xFFC6C3);
                },
                0x37 => {
                    screen[y_pos][x_pos] = rl.getColor(0xFFD59A);
                },
                0x38 => {
                    screen[y_pos][x_pos] = rl.getColor(0xE9E681);
                },
                0x39 => {
                    screen[y_pos][x_pos] = rl.getColor(0xCEF481);
                },
                0x3A => {
                    screen[y_pos][x_pos] = rl.getColor(0xB6E1FF);
                },
                0x3B => {
                    screen[y_pos][x_pos] = rl.getColor(0xA9FAC3);
                },
                0x3C => {
                    screen[y_pos][x_pos] = rl.getColor(0xA9F0F4);
                },
                0x3D => {
                    screen[y_pos][x_pos] = rl.getColor(0xB8B8B8);
                },
                else => {
                    screen[y_pos][x_pos] = rl.Color.black;
                },
            }
        }
        return screen;
    }
}
