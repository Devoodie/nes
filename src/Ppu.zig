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
    addr: u14 = 0,
    write_reg: u1 = 0,
    nametable_mirroring: u1,
    oam: [64]u32 = undefined,

    pub fn PpuMmo(self: *Ppu, address: u16) u8 {
        if (address == 0x4014) {
            return self.oam_dma;
        }
        switch (address % 8) {
            2 => {
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
                self.addr = data;
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
        self.data = data;
        const status = (self.status & 0b00000100) >> 3;
        if (status == 0) {
            self.addr += 1;
        } else {
            self.addr += 32;
        }
    }

    pub fn ReadData(self: *Ppu) u8 {
        //add logic for retrieving ppubus
        const value = self.read_buffer;
        self.read_buffer = self.GetPpuBus();
        return value;
    }

    pub fn GetPpuBus(self: *Ppu) u8 {
        if (self.addr < 0xFFF) {
            //pattern table 0
            return 1;
        } else if (self.addr < 0x1FFF) {
            //pattern table 1
            return 1;
        } else if (self.addr < 0x23BF) {
            //name table 0
            return 1;
        } else if (self.addr < 0x27FF) {
            //name table 1
            return 1;
        } else if (self.addr < 0x2BFF) {
            //nametable 2
            return 1;
        } else if (self.addr < 0x2FFF) {
            //nametable 3
            return 1;
        } else if (self.addr > 0x3EFF) {
            //pallete RAM
            return 1;
        }
    }
};
