const std = @import("std");

pub const Ppu = struct {
    control: u8 = 0,
    mask: u8 = 0,
    status: u8 = 0,
    oam_addr: u8 = 0,
    scroll: u8 = 0,
    data: u8 = 0,
    memory: [2048]u8 = undefined,
    read_buffer: u8 = 0,
    cur_addr: u16 = 0,
    write_reg: u1 = 0,
    nametable_mirroring: u1 = 0,
    oam: [256]u8 = undefined,
    temp_addr: u16 = 0,
    fine_x: u3 = 0,
    pattern_table: [8192]u8 = undefined,
    bitmap: [240][256]u8 = undefined,

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
                self.temp_addr |= xyscroll;
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
            self.cur_addr += 1;
        } else {
            self.cur_addr += 32;
        }
    }

    pub fn ReadData(self: *Ppu) u8 {
        const value = self.read_buffer;
        self.read_buffer = self.GetPpuBus();

        const status = (self.status & 0b00000100) >> 3;
        if (status == 0) {
            self.cur_addr += 1;
        } else {
            self.cur_addr += 32;
        }
        return value;
    }

    pub fn writeAddress(self: *Ppu, addr: u8) void {
        if (self.write_reg == 1) {
            //low
            self.temp_addr &= 0xFF00;
            self.temp_addr |= addr;
            self.cur_addr = self.temp_addr;
            self.write_reg +%= 1;
        } else {
            //high
            self.temp_addr &= 0x00FF;
            const high: u16 = @as(u16, addr) << 8;
            self.temp_addr |= high;
            self.temp_addr &= 0b0011111111111111;
            self.write_reg +%= 1;
        }
    }
    pub fn writeScroll(self: *Ppu, data: u8) void {
        if (self.write_reg == 1) {
            const low: u16 = data & 0b00111000;
            const mid: u16 = data & 0b11000000;
            const high: u16 = data & 0b111;

            self.temp_addr &= 0b0000110000011111;
            self.temp_addr |= low << 2;
            self.temp_addr |= mid << 2;
            self.temp_addr |= high << 12;

            self.cur_addr = self.temp_addr;
        } else {
            var low: u8 = data & 0b11111000;
            low >>= 3;
            std.debug.print("The low comes out to: {X}!\n", .{low});
            self.temp_addr &= 0xFF00;
            self.temp_addr |= low;
            self.fine_x = @truncate(data & 0b00000111);
            std.debug.print("The Fine x scroll is: {d}!\n", .{self.fine_x});
        }
        self.write_reg +%= 1;
    }

    pub fn GetPpuBus(self: *Ppu) u8 {
        if (self.cur_addr <= 0xFFF) {
            //pattern table 0
            return 1;
        } else if (self.cur_addr <= 0x1FFF) {
            //pattern table 1
            return 1;
        } else if (self.cur_addr <= 0x23BF) {
            //name table 0
            const index = self.cur_addr & 0x7FF;
            return self.memory[index];
        } else if (self.cur_addr <= 0x27FF) {
            //name table 1
            const offset: u12 = @as(u12, self.nametable_mirroring) * 1023;
            const index = (self.cur_addr & 0x7FF) % 1024;
            return self.memory[index + offset];
        } else if (self.cur_addr <= 0x2BFF) {
            //nametable 2
            const offset: u12 = @as(u12, self.nametable_mirroring) * 1023;
            const index = self.cur_addr & 0x7FF;
            return self.memory[index - offset];
        } else if (self.cur_addr <= 0x2FFF) {
            //nametable 3
            const index = self.cur_addr & 0x7FF;
            return self.memory[index];
        } else if (self.cur_addr >= 0x3EFF) {
            //pallete RAM
            return 1;
        }
        return 1;
    }

    pub fn setPpuBus(self: *Ppu, data: u8) void {
        if (self.cur_addr <= 0xFFF) {
            //pattern table 0
        } else if (self.cur_addr <= 0x1FFF) {
            //pattern table 1
        } else if (self.cur_addr <= 0x23BF) {
            //name table 0
            const index = self.cur_addr & 0x7FF;
            self.memory[index] = data;
        } else if (self.cur_addr <= 0x27FF) {
            //name table 1
            const offset: u12 = @as(u12, self.nametable_mirroring) * 1023;
            const index = (self.cur_addr & 0x7FF) % 1024;
            self.memory[index + offset] = data;
        } else if (self.cur_addr <= 0x2BFF) {
            //nametable 2
            const offset: u12 = @as(u12, self.nametable_mirroring) * 1023;
            const index = self.cur_addr & 0x7FF;
            self.memory[index - offset] = data;
        } else if (self.cur_addr <= 0x2FFF) {
            //nametable 3
            const index = self.cur_addr & 0x7FF;
            self.memory[index] = data;
        } else if (self.cur_addr >= 0x3EFF) {
            //pallete RAM
        }
    }

    pub fn draw(self: *Ppu) void {
    }
};
