const std = @import("std");

pub const Ppu = struct {
    control: u8,
    mask: u8,
    status: u3,
    oama_addr: u8,
    oam_data: u8,
    scroll: u8,
    addr: u8,
    data: u8,
    oam_dma: u8,

    pub fn PpuMmo(self: *Ppu, address: u16) u8 {
        if (address == 0x4014) {
            return self.oam_dma;
        }
        switch (address % 8) {
            0 => {
                return self.control;
            },
            1 => {
                return self.mask;
            },
            2 => {
                return self.status;
            },
            3 => {
                return self.oama_addr;
            },
            4 => {
                return self.oam_data;
            },
            5 => {
                return self.scroll;
            },
            6 => {
                return self.addr;
            },
            7 => {
                return self.data;
            },
            else => default: {
                std.debug.print("Invalid PPU Register!\n", .{});
                break :default;
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
            2 => {
                self.status = data;
            },
            3 => {
                self.oama_addr = data;
            },
            4 => {
                self.oam_data = data;
            },
            5 => {
                self.scroll = data;
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
