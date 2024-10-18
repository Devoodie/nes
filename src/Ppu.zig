const std = @import("std");

pub const Ppu = struct {
    control: u8 = 0,
    mask: u8 = 0,
    status: u8 = 0,
    oam_addr: u16 = 0,
    oam_data: u8 = 0,
    scroll: u8 = 0,
    addr: u8 = 0,
    data: u8 = 0,
    oam_dma: u8 = 0,
    memory: [10240]u8 = undefined,
    write_reg: u1 = 0,

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
                return self.data;
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
                self.oama_addr = data;
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
                self.data = data;
            },
            else => default: {
                std.debug.print("Invalid PPU Register!\n", .{});
                break :default;
            },
        }
    }
};
