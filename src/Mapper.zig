const std = @import("std");

pub const Mapper = enum(u8) {
    NROM = 0,
};

pub const Cartridge = struct {
    prg_rom: []u8 = undefined,
    prg_ram: []u8 = undefined,
    chr_rom: []u8 = undefined,
    //    nvram: []u8 = undefined,
    trainer: []u8 = undefined,
    mapper: Mapper = undefined,
    hori_mirroring: u1 = 0,
    trainer_bit: u1 = 0,
    alt_nametable: u1,

    pub fn mapper_init(self: *Cartridge, file: *[]u8, allocator: std.mem.Allocator) !void {
        //no raii gangy
        //determine ines or nes2.0 format
        var ines: bool = true;
        if (file[7] & 0xC == 8) ines = false;
        var prg_rom_size: u16 = 0;
        var chr_rom_size: u16 = 0;
        var prg_ram_size: u16 = 0;
        //       var prg_nvram_size: u16 = 0;
        var mapper: u8 = 0;

        for (4..12) |index| {
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
                    mapper |= header >> 4;
                    self.alt_nametable = @truncate(header >> 3 & 0b1);
                    self.trainer = @truncate(header >> 2 & 0b1);
                    //battery
                    self.hori_mirroring = @truncate(header & 0b1);
                    break :misc;
                },
                7 => nes2: {
                    mapper |= header & 0xF0;
                    //other shit like console type
                    break :nes2;
                },
                8 => sub_mapper: {
                    //nes2.0  shit
                    break :sub_mapper;
                },
                9 => nes2_prg_rom_size: {
                    if (ines != true) {
                        prg_rom_size |= (@as(u16, header) & 0xF) << 8;
                        chr_rom_size |= (@as(u16, header) & 0xF0) << 4;
                    }
                    break :nes2_prg_rom_size;
                },
                10 => prg_ram_size: {
                    if (ines != true) {
                        prg_ram_size = 64 << (header & 0xF);
                        //nvramsize
                    }
                    break :prg_ram_size;
                },
                else => default: {
                    break :default;
                },
            }
        }

        if (ines == true) {
            if (mapper == 0) {
                prg_ram_size = 2048;
            }
        }

        self.mapper = mapper;
        self.prg_rom = try allocator.alloc(u8, prg_rom_size * 16384);
        self.chr_rom = try allocator.alloc(u8, chr_rom_size * 8192);
        self.prg_ram = try allocator.alloc(u8, prg_ram_size);

        std.debug.print("Mapper Initialized to PRG_RAM: {d}, PRG_ROM: {d}, CHR_ROM: {d}\n", .{ prg_ram_size, prg_rom_size, chr_rom_size });
        //intialize every array according to their size values in the headers
    }

    pub fn deinit(self: *Cartridge, allocator: std.mem.Allocator) !void {
        allocator.free(self.prg_ram);
        allocator.free(self.prg_rom);
        allocator.free(self.chr_rom);
        allocator.free(self.trainer);
    }

    pub fn getPpuData(self: *Cartridge, address: u16) u8 {
        if (address <= 0x1FFF) {
            return self.chr_rom[address];
        }
        //  focus on NROM else if (address <=)

    }

    // pub fn mapper_deinit() void{}
};
