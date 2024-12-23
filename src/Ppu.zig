const std = @import("std");

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

pub const Sprite = union {
    small: [8][8]u5,
    large: [16][8]u5,
};

pub const Ppu = struct {
    control: u8 = 0,
    mask: u8 = 0,
    status: u8 = 0,
    oam_addr: u8 = 0,
    scroll: u8 = 0,
    data: u8 = 0,
    nametable: [2048]u8 = undefined,
    read_buffer: u8 = 0,
    v: u16 = 0,
    write_reg: u1 = 0,
    nametable_mirroring: u1 = 0,
    oam: [256]u8 = undefined,
    secondary_oam: [8]?u6 = undefined,
    t: u16 = 0,
    //suspected padding
    fine_x: u3 = 0,
    pattern_table: [8192]u8 = undefined,
    // this is gunna cause padding
    bitmap: [240][256]u5 = undefined,
    pallet_memory: [32]u8 = undefined,
    scanline: u12 = 261,
    x_pos: u8 = 0,
    high_shift: u16 = 0,
    low_shift: u16 = 0,
    sprite_shift: u8 = 0,
    cycles: u12 = 0,
    attribute: u8 = 0,
    sprites: [64]Sprite = undefined,

    pub fn PpuMmo(self: *Ppu, address: u16) u8 {
        switch (address % 8) {
            2 => {
                self.write_reg = 0;
                return self.status;
            },
            3 => {
                return self.oam_addr;
            },
            4 => {
                return self.oam[self.oam_addr];
            },
            7 => {
                return self.ReadData();
            },
            else => {
                std.debug.print("Invalid PPU Register!\n", .{});
                return 0;
            },
        }
    }

    pub fn ppuMmi(self: *Ppu, address: u16, data: u8) void {
        switch (address % 8) {
            0 => control: {
                self.control = data;
                var xyscroll: u16 = @as(u16, data) & 0b11;
                xyscroll <<= 10;
                self.t |= xyscroll;
                break :control;
            },
            1 => mask: {
                self.mask = data;
                break :mask;
            },
            3 => oam_addr: {
                self.oam_addr = data;
                break :oam_addr;
            },
            4 => oam_data: {
                self.oam[self.oam_addr] = data;
                self.oam_addr +%= 1;
                break :oam_data;
            },
            5 => scroll: {
                self.writeScroll(data);
                break :scroll;
            },
            6 => addr: {
                self.writeAddress(data);
                break :addr;
            },
            7 => data: {
                self.writeData(data);
                break :data;
            },
            else => default: {
                std.debug.print("Invalid PPU Register!\n", .{});
                break :default;
            },
        }
    }
    pub fn writeData(self: *Ppu, data: u8) void {
        self.setPpuBus(data);

        const status = (self.control & 0b00000100) >> 3;
        if (status == 0) {
            self.v += 1;
        } else {
            self.v += 32;
        }
    }

    pub fn ReadData(self: *Ppu) u8 {
        const value = self.read_buffer;
        self.read_buffer = self.GetPpuBus();

        const status = (self.control & 0b00000100) >> 3;
        if (status == 0) {
            self.v += 1;
        } else {
            self.v += 32;
        }
        return value;
    }

    pub fn writeAddress(self: *Ppu, addr: u8) void {
        if (self.write_reg == 1) {
            //low
            self.t &= 0xFF00;
            self.t |= addr;
            self.v = self.t;
            self.write_reg +%= 1;
        } else {
            //high
            self.t &= 0x00FF;
            const high: u16 = @as(u16, addr) << 8;
            self.t |= high;
            self.t &= 0b0011111111111111;
            self.write_reg +%= 1;
        }
    }
    pub fn writeScroll(self: *Ppu, data: u8) void {
        if (self.write_reg == 1) {
            const low: u16 = data & 0b00111000;
            const mid: u16 = data & 0b11000000;
            const high: u16 = data & 0b111;

            self.t &= 0b0000110000011111;
            self.t |= low << 2;
            self.t |= mid << 2;
            self.t |= high << 12;

            self.v = self.t;
        } else {
            var low: u8 = data & 0b11111000;
            low >>= 3;
            std.debug.print("The low comes out to: {X}!\n", .{low});
            self.t &= 0xFF00;
            self.t |= low;
            self.fine_x = @truncate(data & 0b00000111);
            std.debug.print("The Fine x scroll is: {d}!\n", .{self.fine_x});
        }
        self.write_reg +%= 1;
    }

    pub fn GetPpuBus(self: *Ppu) u8 {
        if (self.v <= 0xFFF) {
            //pattern table 0
            return 1;
        } else if (self.v <= 0x1FFF) {
            //pattern table 1
            return 1;
        } else if (self.v <= 0x23FF) {
            //name table 0
            const index = self.v & 0x3FF;
            return self.nametable[index];
        } else if (self.v <= 0x27FF) {
            //name table 1
            const offset: u12 = @as(u12, self.nametable_mirroring) * 1023;
            const index = (self.v & 0x3FF) % 1024;
            return self.nametable[index + offset];
        } else if (self.v <= 0x2BFF) {
            //nametable 2
            const offset: u12 = @as(u12, self.nametable_mirroring) * 1023;
            const index = self.v & 0x7FF;
            return self.nametable[index - offset];
        } else if (self.v <= 0x2FFF) {
            //nametable 3
            const index = self.v & 0x7FF;
            return self.nametable[index];
        } else if (self.v >= 0x3EFF) {
            //pallete RAM
            return 1;
        }
        return 1;
    }

    pub fn setPpuBus(self: *Ppu, data: u8) void {
        if (self.v <= 0xFFF) {
            //pattern table 0
        } else if (self.v <= 0x1FFF) {
            //pattern table 1
        } else if (self.v <= 0x23FF) {
            //name table 0
            const index = self.v & 0x3FF;
            self.nametable[index] = data;
        } else if (self.v <= 0x27FF) {
            //name table 1
            const offset: u12 = @as(u12, self.nametable_mirroring) * 1024;
            const index = (self.v & 0x3FF) % 1024;
            self.nametable[index + offset] = data;
        } else if (self.v <= 0x2BFF) {
            //nametable 2
            const offset: u12 = @as(u12, self.nametable_mirroring) * 1024;
            const index = self.v & 0x7FF;
            self.nametable[index - offset] = data;
        } else if (self.v <= 0x2FFF) {
            //nametable 3
            const index = self.v & 0x7FF;
            self.nametable[index] = data;
        } else if (self.v >= 0x3EFF) {
            //pallete RAM
        }
    }

    pub fn cycle(prev_time: i128, count: u8) void {
        const wait_time: i128 = 186 * @as(i128, count);
        const goal_time = wait_time + prev_time;

        while (std.time.nanoTimestamp() <= goal_time) {
            continue;
        }
    }

    pub fn spriteEvaluation(self: *Ppu) void {
        var render_index: u8 = 0;

        //clear secondary oam for next scanline
        for (&self.secondary_oam) |*index| {
            index.* = null;
        }

        for (0..64) |index| render_buffer: {
            const is_sixteen = self.control >> 5 & 0b1;
            const y = self.oam[@as(u8, @truncate(index)) * 4];
            if (self.scanline >= y and self.scanline < y + 8 + (is_sixteen * 8)) {
                if (render_index > 7) {
                    //sprite overflow
                    break :render_buffer;
                } else {
                    //         std.debug.print("Entered Evaluation index: {d}!\n", .{index});
                    self.secondary_oam[render_index] = @truncate(index);
                    render_index += 1;
                }
            }
        }
    }

    pub fn fillSprites(self: *Ppu) void {
        const is_large = self.control >> 5 & 0b1;
        for (0..64) |oam_index| {
            self.sprites[oam_index] = self.GetSpriteBitmap(self.oam[oam_index * 4 + 1], self.oam[oam_index * 4 + 2], is_large);
        }
    }

    pub fn GetSpriteBitmap(self: *Ppu, tile_number: u16, attributes: u8, large: u8) Sprite {
        var small_buff: u8 = 0;
        var large_buff: u8 = 0;
        var pattern_index: u16 = 0;
        var pixel_data: u5 = undefined;
        var low_pixel: u8 = 0;
        var high_pixel: u8 = 0;
        const attr_bits = attributes & 0b11;
        var right_table: u16 = 0;

        if (large == 1) {
            pattern_index >>= 1;
            right_table = (@as(u16, tile_number) & 0b1) * 0x1000;
            var sprite_buffer: Sprite = .{ .large = undefined };

            for (0..16) |row| {
                if (row == 8) {
                    pattern_index += 16;
                }
                small_buff = self.pattern_table[right_table + pattern_index + row % 8];
                large_buff = self.pattern_table[right_table + pattern_index + row % 8 + 8];
                for (0..8) |column| {
                    low_pixel = small_buff >> 7 - @as(u3, @intCast(column)) & 0b1;
                    high_pixel = large_buff >> 7 - @as(u3, @intCast(column)) & 0b1;
                    pixel_data = @as(u5, @truncate(low_pixel)) | @as(u5, @truncate(high_pixel << 1)) | @as(u5, @truncate(attr_bits << 2)) | 0b10000;
                    sprite_buffer.large[row][column] = pixel_data;
                }
            }
            return sprite_buffer;
        } else {
            pattern_index = tile_number * 16;
            right_table = (@as(u16, self.status) >> 3 & 0b1) * 0x1000;
            var sprite_buffer: Sprite = .{ .small = undefined };

            for (0..8) |row| {
                small_buff = self.pattern_table[right_table + pattern_index + row];
                large_buff = self.pattern_table[right_table + pattern_index + row + 8];
                // i hate this nested for but it seems reasonable for a matrix
                for (0..8) |column| {
                    low_pixel = small_buff >> 7 - @as(u3, @intCast(column)) & 0b1;
                    high_pixel = large_buff >> 7 - @as(u3, @intCast(column)) & 0b1;
                    pixel_data = @as(u5, @truncate(low_pixel)) | @as(u5, @truncate(high_pixel << 1)) | @as(u5, @truncate(attr_bits << 2)) | 0b10000;
                    sprite_buffer.small[row][column] = pixel_data;
                }
            }
            return sprite_buffer;
        }
    }

    pub fn drawSprites(self: *Ppu, coarsex: u8, background: u5) ?u5 {
        var oam_index: ?u6 = 0;
        var x_buffer: u8 = 0;
        var x_coord: ?u8 = null;
        var y_coord: u8 = 0;
        var attributes: u8 = 0;
        var sprite0: u8 = 0;
        var sprite_index: u8 = 0;
        if (self.mask & 0x10 != 0x10) return null;

        for (0..8) |iterations| {
            oam_index = self.secondary_oam[7 - iterations];

            if (oam_index == null) {
                continue;
            }

            oam_index.? *= 4;
            sprite_index = self.secondary_oam[7 - iterations].?;
            x_buffer = self.oam[oam_index.? + 3];

            if (coarsex < x_buffer + 8 and coarsex >= x_buffer) {
                x_coord = coarsex - x_buffer;
                sprite0 = 7 - @as(u8, @intCast(iterations));
                y_coord = @as(u8, @truncate(self.scanline)) - self.oam[oam_index.?];
                attributes = self.oam[oam_index.? + 2];
            }
        }

        if (x_coord == null or (coarsex == 0 and self.mask & 0x4 != 0x4)) {
            return null;
        } else {
            return self.GetSpritePixel(x_coord.?, y_coord, attributes, self.sprites[sprite_index], background, sprite0);
        }
    }

    pub fn GetSpritePixel(self: *Ppu, x: u8, y: u8, attributes: u8, sprite: Sprite, background: u5, sprite0: u8) u5 {
        var bitmap_x: u8 = x;
        var bitmap_y: u8 = y;
        if (attributes & 0x20 == 0x20) { //background has priority return background;
            return background;
        } else if (self.control & 0x20 == 0x20) {
            if (attributes & 0x80 == 0x80) {
                bitmap_y = ~bitmap_y & 0b1111;
                bitmap_x = ~bitmap_x & 0b111;
            }
            if (attributes & 0x40 == 0x40) {
                bitmap_x = ~bitmap_x & 0b111;
            }
            if (x > 7 and sprite.large[bitmap_y][bitmap_x] & 0b11 < 0 and background & 0b11 < 0 and sprite0 == 0) {
                self.status |= 0x40;
            }
            // std.debug.print("X Coord: {d}, Y Coord: {d}\n", .{ bitmap_x, bitmap_y });
            return sprite.large[bitmap_y][bitmap_x];
        } else {
            if (attributes & 0x80 == 0x80) {
                bitmap_y = ~bitmap_y & 0b111;
            }
            if (attributes & 0x40 == 0x40) {
                bitmap_x = ~bitmap_x & 0b111;
            }
            if (x > 7 and sprite.small[bitmap_y][bitmap_x] & 0b11 < 0 and background & 0b11 < 0 and sprite0 == 0) {
                self.status |= 0x40;
            }
            //std.debug.print("X Coord: {d}, Y Coord: {d}\n", .{ bitmap_x, bitmap_y });
            return sprite.small[bitmap_y][bitmap_x];
        }
    }
    pub fn drawCoarseX(self: *Ppu) void {
        //get nametable tile
        //get attribute tile
        //get pattern table low
        //get pattern table high
        //draw!
        if (self.cycles == 0) {
            return;
        }
        self.t = self.v;
        self.v = 0x2000;
        self.v |= self.t & 0x0FFF;

        const nametable_data = self.GetPpuBus();
        self.v = 0x23C0 | (self.t & 0xC00) | ((self.t >> 4) & 0x38) | ((self.t >> 2) & 0x07);
        const attribute_data = self.GetPpuBus();

        self.v = self.t;

        //nametable fetch
        //attribute fetch and shift register placement

        const coarse_x = @as(u8, @truncate(self.v & 0b11111));
        const coarse_y = @as(u8, @truncate(self.v & 0b1111100000 >> 4));
        const coarse_x_bit1 = coarse_x & 0b1;
        const coarse_y_bit1 = coarse_y & 0b1;

        // extract attribute shifts
        const attr_shifts = @as(u3, @truncate(coarse_x_bit1 * 2 + coarse_y_bit1 * 4));
        self.attribute = attribute_data >> attr_shifts;
        // std.debug.print("Attribute Data: {d}, Attribute shifts: {d}\n", .{ attribute_data, attr_shifts });
        self.attribute &= 0b11;

        //pattern fetch
        var pattern_address: u16 = nametable_data;
        pattern_address <<= 3;
        const right_table: u16 = self.control & 0b00010000;

        pattern_address |= right_table << 8;
        pattern_address |= self.v >> 12;

        if (self.cycles <= 249) {
            //rendering occurs before
            for (self.bitmap[self.scanline][self.x_pos .. @as(u10, self.x_pos) + 8], self.x_pos..) |*pixel, x_index| {
                const background_pixel: ?u5 = self.GetBackgroundPixel(coarse_x);

                if (background_pixel != null) {
                    pixel.* = background_pixel.?;
                    self.low_shift <<= 1;
                    self.high_shift <<= 1;
                } else {
                    //return backdrop color (black placeholder)
                    pixel.* = 0x1F;
                }

                const sprite_pixel: ?u5 = self.drawSprites(@truncate(x_index), pixel.*);

                if (sprite_pixel != null) {
                    pixel.* = sprite_pixel.?;
                }
            }
            if (self.cycles != 249) self.x_pos += 8;
        } else {
            self.low_shift <<= 8;
            self.high_shift <<= 8;
        }
        //placement into shift registers occurs after
        self.low_shift |= self.pattern_table[pattern_address];
        self.high_shift |= self.pattern_table[pattern_address + 0b1000];
    }

    pub fn GetBackgroundPixel(self: *Ppu, coarsex: u8) ?u5 {
        const fine_x_shifts = 14 - @as(u4, self.fine_x);

        const low_pixel = self.low_shift >> fine_x_shifts & 0b1;
        const high_pixel = self.high_shift >> fine_x_shifts & 0b1;

        const pixel_data: u5 = @as(u5, @truncate(low_pixel)) | @as(u5, @truncate(high_pixel << 1)) | @as(u5, @truncate(self.attribute << 2));
        //std.debug.print("You are drawing: {d}!\n From low: {d}\n From high: {d}\n Attribute: {d}\n", .{ pixel_data, self.low_shift, self.high_shift, self.attribute });

        if (self.mask & 0x8 != 0x8 or (self.mask & 0x2 == 0x2 and coarsex == 0)) {
            return null;
        } else {
            return pixel_data;
        }
    }

    pub fn drawScanLine(self: *Ppu, time: i128) void {
        //cycle after this function in the main loop
        if (self.mask & 0x18 == 0) {
            return;
        }
        for (0..33) |_| {
            if (self.cycles == 0) {
                self.cycles += 1;
                cycle(time, 1);
                continue;
            }
            self.drawCoarseX();
            self.cycles += 8;
            //            std.debug.print("Cycles: {d}!, X_Position: {d}\n", .{ self.cycles, self.x_pos });
            cycle(time, 8);
        }
        var coarse_y = self.v & 0x3E0 >> 5;
        if (self.v & 0x1F == 31) {
            //coarse x increment
            self.v &= 0x7FE0;
            self.v ^= 0x400;
        } else {
            self.v += 1;
        }
        if (self.v & 0x7000 != 0x7000) {
            //fine y increment
            self.v += 0x1000;
        } else {
            //coarse y increment
            self.v &= 0x0FFF;
            if (coarse_y == 29) {
                coarse_y = 0;
                self.v ^= 0x800;
            } else if (coarse_y == 31) {
                coarse_y = 0;
            } else {
                coarse_y += 1;
            }
            self.v = (self.v & 0xFC1F) | (coarse_y << 5);
        }

        self.x_pos = 0;
    }

    pub fn draw(self: *Ppu) void {
        if (self.scanline == 261) {
            self.scanline == 0;
            self.control &= 0x70;
        } else if (self.scanline >= 240) {
            //handle post render scanline
            self.control |= 0x80;
            self.scanline += 1;
        } else {
            //handle rendering
            self.fillSprites();
            var time: i128 = std.time.nanoTimestamp();
            for (0..240) |_| {
                self.drawScanLine(std.time.nanoTimestamp());
                self.scanline += 1;
                time = std.time.nanoTimestamp();
            }
        }
    }
};
