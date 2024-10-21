const std = @import("std");

pub const Ppu = struct {
    control: u8 = 0,
    mask: u8 = 0,
    status: u8 = 0,
    oam_addr: u8 = 0,
    oam_data: u8 = 0,
    scroll: u8 = 0,
    data: u8 = 0,
    oam_dma: u8 = 0,
    memory: [2048]u8 = undefined,
    read_buffer: u8 = 0,
    addr: u16 = 0,
    write_reg: u1 = 0,
    nametable_mirroring: u1 = 0,
    oam: [64]u32 = undefined,
    temp_vram: u16 = 0,
    fine_x: u3 = 0,

    pub fn PpuMmo(self: *Ppu, address: u16) u8 {
        if (address == 0x4014) {
            return self.oam_dma;
        }
        switch (address % 8) {
            2 => {
                self.write_reg = 0;
                return self.status;
            },
            3 => {
                return self.oam_addr;
            },
            4 => {
                return self.oam_data;
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
        if (address == 0x4014) {
            self.oam_dma = data;
        }
        switch (address % 8) {
            0 => {
                self.control = data;
            },
            1 => {
                self.mask = data;
            },
            3 => {
                self.oam_addr = data;
            },
            4 => {
                self.oam_data = data;
                self.oam_addr += 1;
            },
            5 => {
                self.scroll = data;
                self.write_reg +%= 1;
            },
            6 => {
                self.writeAddress(data);
            },
            7 => {
                self.writeData(data);
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
            self.addr += 1;
        } else {
            self.addr += 32;
        }
    }

    pub fn ReadData(self: *Ppu) u8 {
        const value = self.read_buffer;
        self.read_buffer = self.GetPpuBus();

        const status = (self.status & 0b00000100) >> 3;
        if (status == 0) {
            self.addr += 1;
        } else {
            self.addr += 32;
        }
        return value;
    }

    pub fn writeAddress(self: *Ppu, addr: u8) void {
        if (self.write_reg == 1) {
            //low
            self.addr &= 0xFF00;
            self.addr |= addr;
            self.write_reg +%= 1;
            self.temp_vram |= addr;
        } else {
            //high
            self.addr &= 0x00FF;
            const high: u16 = @as(u16, addr) << 8;
            self.addr |= high;
            self.write_reg +%= 1;
            self.temp_vram = self.addr;
            self.temp_vram &= 0b1011111111111111;
        }
    }

    pub fn GetPpuBus(self: *Ppu) u8 {
        if (self.addr <= 0xFFF) {
            //pattern table 0
            return 1;
        } else if (self.addr <= 0x1FFF) {
            //pattern table 1
            return 1;
        } else if (self.addr <= 0x23BF) {
            //name table 0
            const index = self.addr & 0x7FF;
            return self.memory[index];
        } else if (self.addr <= 0x27FF) {
            //name table 1
            const offset: u12 = @as(u12, self.nametable_mirroring) * 1023;
            const index = (self.addr & 0x7FF) % 1024;
            return self.memory[index + offset];
        } else if (self.addr <= 0x2BFF) {
            //nametable 2
            const offset: u12 = @as(u12, self.nametable_mirroring) * 1023;
            const index = self.addr & 0x7FF;
            return self.memory[index - offset];
        } else if (self.addr <= 0x2FFF) {
            //nametable 3
            const index = self.addr & 0x7FF;
            return self.memory[index];
        } else if (self.addr >= 0x3EFF) {
            //pallete RAM
            return 1;
        }
        return 1;
    }

    pub fn setPpuBus(self: *Ppu, data: u8) void {
        if (self.addr <= 0xFFF) {
            //pattern table 0
        } else if (self.addr <= 0x1FFF) {
            //pattern table 1
        } else if (self.addr <= 0x23BF) {
            //name table 0
            const index = self.addr & 0x7FF;
            self.memory[index] = data;
        } else if (self.addr <= 0x27FF) {
            //name table 1
            const offset: u12 = @as(u12, self.nametable_mirroring) * 1023;
            const index = (self.addr & 0x7FF) % 1024;
            self.memory[index + offset] = data;
        } else if (self.addr <= 0x2BFF) {
            //nametable 2
            const offset: u12 = @as(u12, self.nametable_mirroring) * 1023;
            const index = self.addr & 0x7FF;
            self.memory[index - offset] = data;
        } else if (self.addr <= 0x2FFF) {
            //nametable 3
            const index = self.addr & 0x7FF;
            self.memory[index] = data;
        } else if (self.addr >= 0x3EFF) {
            //pallete RAM
        }
    }
};
