const std = @import("std");

pub const Mapper = struct {
    prg_rom: []u8 = undefined,
    prg_ram: []u8 = undefined,
    chr_rom: []u8 = undefined,
    trainer: []u8 = undefined,
    hori_mirroring: u1 = 0,
    trainer_bit: u1 = 0,
    alt_nametable: u1,

    pub fn mapper_init(self: *Mapper, file: *[]u8, allocator: std.mem.Allocator) !void {
        //no raii gangy
        //determine ines or nes2.0 format
        var ines: bool = true;
        if (file[7] & 0xC == 8) ines = false;
        var prg_rom_size: u16 = 0;
        var chr_rom_size: u16 = 0;
        var mapper: u8 = 0;

        for (4..11) |index| {
            const header = file[index];
            switch (index) {
                4 => prg_rom_size: {
                    if (ines == true) {
                        prg_rom_size = header;
                    } else {
                        prg_rom_size |= header;
                    }
                    break :prg_rom_size;
                },
                5 => chr_rom_size: {
                    if (ines == true) {
                        chr_rom_size = header;
                    } else {
                        chr_rom_size |= header;
                    }
                    break :chr_rom_size;
                },
                6 => misc: {
                    if (ines == true) {
                        mapper = header >> 4;
                    }
                    break :misc;
                },
                7 => nes2: {
                    break :nes2;
                },
                8 => prg_ram_size: {
                    break :prg_ram_size;
                },
            }
        }

        self.prg_rom = try allocator.alloc(u8, prg_rom_size * 16384);
        self.chr_rom = try allocator.alloc(u8, chr_rom_size * 8192);
        //intialize every array according to their size values in the headers
    }

    // pub fn mapper_deinit() void{}
};
