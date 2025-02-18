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
    mirroring: u1 = 0,
    trainer_bit: u1 = 0,
    alt_nametable: u1 = 0,

    pub fn mapper_init(self: *Cartridge, file: *[]u8, allocator: std.mem.Allocator) !void {
        //no raii gangy
        //determine ines or nes2.0 format
        var ines: bool = true;
        if (file.*[7] & 0xC == 8) ines = false;
        var prg_rom_size: u16 = 0;
        var chr_rom_size: u16 = 0;
        var prg_ram_size: u16 = 0;
        //       var prg_nvram_size: u16 = 0;
        var mapper: u8 = 0;

        for (4..12) |index| {
            const header = file.*[index];
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
                    self.trainer_bit = @truncate(header >> 2 & 0b1);
                    //battery
                    self.mirroring = @truncate(header & 0b1);
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
                        prg_ram_size = @as(u16, 64) << @truncate(header & 0xF);
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

        self.mapper = @enumFromInt(mapper);
        self.prg_rom = try allocator.alloc(u8, prg_rom_size * 16384);
        self.chr_rom = try allocator.alloc(u8, chr_rom_size * 8192);
        self.prg_ram = try allocator.alloc(u8, prg_ram_size);
        self.trainer = try allocator.alloc(u8, 512 * @as(u12, self.trainer_bit));
        //        std.log.defaultLog(.info, std.log.default_log_scope, "Mapper Initialized to PRG_RAM: {d}KiB, PRG_ROM: {d}KiB, CHR_ROM: {d}KiB\n", .{ self.prg_ram.len, self.prg_rom.len, self.chr_rom.len });

        std.debug.print("Mapper Initialized to PRG_RAM: {d}B, PRG_ROM: {d}B, CHR_ROM: {d}B\n", .{ self.prg_ram.len, self.prg_rom.len, self.chr_rom.len });
        self.mapROM(file);

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
            return self.chr_rom[address % 8192];
        }
        return 0;
        //  focus on NROM else if (address <=)

    }

    pub fn getCpuData(self: *Cartridge, address: u16) u8 {
        if (address <= 0x7FFF) {
            const index = address - 0x6000;
            return self.prg_ram[index % self.prg_ram.len];
        } else {
            const index = address - 0x8000;
            return self.prg_rom[index % self.prg_rom.len];
        }
        return 0;
        // just like PPU Data foucs on NROM
    }

    pub fn putCpuData(self: *Cartridge, address: u16, data: u8) void {
        if (address <= 0x7FFF) {
            const index = address - 0x6000;
            self.prg_ram[index % self.prg_ram.len] = data;
        }
    }

    pub fn mapROM(self: *Cartridge, rom: *[]u8) void {
        switch (self.mapper) {
            Mapper.NROM => nrom: {
                if (self.trainer_bit == 1) {
                    std.mem.copyForwards(u8, self.trainer, rom.*[16..528]);
                    std.mem.copyForwards(u8, self.prg_rom, rom.*[528 .. self.prg_rom.len + 528]);
                    std.mem.copyForwards(u8, self.chr_rom, rom.*[self.prg_rom.len + 528 .. self.prg_rom.len + 528 + self.chr_rom.len]);
                } else {
                    std.mem.copyForwards(u8, self.prg_rom, rom.*[16 .. self.prg_rom.len + 16]);
                    std.mem.copyForwards(u8, self.chr_rom, rom.*[self.prg_rom.len + 16 .. self.prg_rom.len + 16 + self.chr_rom.len]);
                }
                break :nrom;
            },
            //else => default: {
            //   break :default;
            //},
        }
    }
};
