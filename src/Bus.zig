const std = @import("std");
const cpu = @import("Cpu.zig");
const ppu = @import("Ppu.zig");
const apu = @import("Apu.zig");
pub const Bus = struct {
    addr_bus: u16 = 0,
    data_bus: u8 = 0,
    cpu_ptr: *cpu.Cpu = undefined,
    ppu_ptr: *ppu.Ppu = undefined,
    apu_ptr: *apu.Apu = undefined,

    pub fn getMmo(self: *Bus) void {
        if (self.addr_bus <= 0x1FFF) {
            self.data_bus = self.cpu_ptr.*.memory[self.addr_bus % 0x800];
        } else if (self.addr_bus <= 0x3FFF) {
            self.data_bus = self.ppu_ptr.*.PpuMmo(self.addr_bus);
        } else if (self.addr_bus <= 0x401F) {
            return;
        }
    }
    pub fn putMmi(self: *Bus) void {
        if (self.addr_bus <= 0x1FFF) {
            self.cpu_ptr.memory[self.addr_bus % 0x800] = self.data_bus;
        } else if (self.addr_bus <= 0x3FFF) {
            self.ppu_ptr.ppuMmi(self.addr_bus, self.data_bus);
        } else if (self.addr_bus <= 0x401F) {
            return;
        }
    }
};
