const std = @import("std");
const cpu = @import("Cpu.zig");
const ppu = @import("Ppu.zig");
const bus = @import("Bus.zig");

pub const Nes = struct {
    Ppu: ppu.Ppu,
    Bus: bus.Bus,
    Cpu: cpu.Cpu,

    pub fn init() Nes {
        const Bus: bus.Bus = .{};
        const Ppu: ppu.Ppu = .{};
        const Cpu: cpu.Cpu = .{
            .memory = [2048]u8{0} ** 2048,
            .bus = &Bus,
        };
        return .{
            .Ppu = Ppu,
            .Bus = Bus,
            .Cpu = Cpu,
        };
    }
};
