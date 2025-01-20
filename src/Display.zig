const std = @import("std");
const rl = @import("raylib");
const picture_unit = @import("Ppu.zig");

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

    while (true) {
        //        if (ppu.status & 0x80 == 0x80) {
        rl.beginDrawing();
        //    rl.drawText("You're In It!\n", 190, 200, 20, rl.Color.white);
        rl.clearBackground(rl.Color.black);
        for (ppu.bitmap, 0..) |row, y_pos| {
            for (row, 0..) |column, x_pos| {
                if (column > 0) {
                    rl.drawRectangle(@intCast(x_pos * 5), @intCast(y_pos * 5), 5, 5, rl.Color.white);
                    rl.drawText("Drew\n", 190, 200, 20, rl.Color.white);
                }
            }
        }
        rl.endDrawing();
        //        std.debug.print("PPU bitmap: {any}!\n", .{ppu.bitmap});
        //}
    }
    // }
}
