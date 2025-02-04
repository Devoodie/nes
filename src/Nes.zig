const std = @import("std");
const cpu = @import("cpu");
const ppu = @import("ppu");
const bus = @import("bus");
const mapper = @import("mapper");

pub const Nes = struct {
    Ppu: ppu.Ppu,
    Bus: bus.Bus,
    Cpu: cpu.Cpu,
    Mapper: mapper.Cartridge = undefined,

    pub fn init(self: *Nes) void {
        self.Cpu = .{
            .memory = [_]u8{0} ** 2048,
            .bus = &self.Bus,
        };
        self.Mapper = .{};
        self.Bus.cpu_ptr = &self.Cpu;
        self.Bus.ppu_ptr = &self.Ppu;
        self.Bus.catridge_ptr = &self.Mapper;
        self.Ppu = .{
            .nametable = [_]u8{0} ** 2048,
            .oam = [_]u8{0} ** 256,
            .pattern_table = [_]u8{0} ** 8192,
            .cartridge = &self.Mapper,
        };
    }
};
