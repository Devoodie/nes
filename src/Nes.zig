const std = @import("std");
const cpu = @import("Cpu.zig");
const ppu = @import("Ppu.zig");
const bus = @import("Bus.zig");
const catridge = @import("Mapper.zig");

pub const Nes = struct {
    Ppu: ppu.Ppu,
    Bus: bus.Bus,
    Cpu: cpu.Cpu,
    Mapper: catridge = undefined,

    pub fn init(self: *Nes) void {
        self.Cpu = .{
            .memory = [_]u8{0} ** 2048,
            .bus = &self.Bus,
        };
        self.Mapper = .{};
        self.Bus.cpu_ptr = &self.Cpu;
        self.Bus.ppu_ptr = &self.Ppu;
        self.Ppu = .{
            .nametable = [_]u8{0} ** 2048,
            .oam = [_]u8{0} ** 256,
            .pattern_table = [_]u8{0} ** 8192,
        };
    }
};
