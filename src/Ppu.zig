const std = @import("std");

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
    t: u16 = 0,
    //suspected padding
    fine_x: u3 = 0,
    pattern_table: [8192]u8 = undefined,
    // this is gunna cause padding
    bitmap: [240][256]u5 = undefined,
    pallet_memory: [32]u8 = undefined,
    scanline: u12 = 261,
    high_shift: u16 = 0,
    low_shift: u16 = 0,

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

        const status = (self.status & 0b00000100) >> 3;
        if (status == 0) {
            self.v += 1;
        } else {
            self.v += 32;
        }
    }

    pub fn ReadData(self: *Ppu) u8 {
        const value = self.read_buffer;
        self.read_buffer = self.GetPpuBus();

        const status = (self.status & 0b00000100) >> 3;
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
            const index = self.v & 0x7FF;
            self.nametable[index] = data;
        } else if (self.v <= 0x27FF) {
            //name table 1
            const offset: u12 = @as(u12, self.nametable_mirroring) * 1024;
            const index = (self.v & 0x7FF) % 1024;
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

    pub fn GetBackgroundPixel(self: *Ppu, attribute_bits: u5) u5 {
        const fine_x_shifts = 14 - @as(u4, self.fine_x);

        const low_pixel = self.low_shift >> fine_x_shifts & 0b1;
        const high_pixel = self.high_shift >> fine_x_shifts & 0b1;

        const pixel_data: u5 = @as(u5, @intCast(low_pixel)) | @as(u5, @intCast(high_pixel << 1)) | @as(u5, @intCast(attribute_bits << 2));
        std.debug.print("You are drawing: {d}!\n From low: {d}\n From high: {d}\n Attribute: {d}\n", .{ pixel_data, self.low_shift, self.high_shift, attribute_bits });
        return pixel_data;
    }

    //pub fn spriteEvaluation(self: *Ppu) void {}
    pub fn drawCoarseX(self: *Ppu) void {
        //get nametable tile
        //get attribute tile
        //get pattern table low
        //get pattern table high
        //draw!
        self.t = self.v;
        self.v = 0x2000;
        self.v |= self.t & 0x0FFF;

        const nametable_data = self.GetPpuBus();
        self.v = 0x23C0 | (self.t & 0x0C0) | ((self.t >> 4) & 0x38) | ((self.t >> 2) & 0x07);
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
        var attribute_bits: u8 = attribute_data >> attr_shifts;
        attribute_bits &= 0b11;

        //pattern fetch
        var pattern_address: u16 = nametable_data;
        pattern_address <<= 3;
        const right_table: u16 = self.status & 0b00010000;

        pattern_address |= right_table << 8;
        pattern_address |= self.v >> 12;

        //placement into shift registers
        self.low_shift |= self.pattern_table[pattern_address];
        self.high_shift |= self.pattern_table[pattern_address + 0b1000];

        if (self.scanline <= 239) {
            for (self.bitmap[self.scanline][coarse_x .. coarse_x + 8]) |*pixel| {
                pixel.* = self.GetBackgroundPixel(@truncate(attribute_bits));
                self.low_shift <<= 1;
                self.high_shift <<= 1;
            }
        }
    }

    pub fn backgroundScanLine(self: *Ppu) void {
        self.low_shift &= 0xFF00;
    }

    pub fn draw(self: *Ppu) void {
        if (self.scanline == 262) {
            self.scanline == 0;
            self.status &= 0x70;
        } else if (self.scanline >= 240) {
            //handle post render scanline
            self.status |= 0x80;
            self.scanline += 1;
        } else {
            //handle rendering
        }
    }
};
