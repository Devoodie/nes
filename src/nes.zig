const std = @import("std");

const StatusRegister = struct {
    carry: u1 = 0,
    zero: u1 = 0,
    interrupt: u1 = 0,
    decimal: u1 = 0,
    overflow: u1 = 0,
    negative: u1 = 0,
};

pub const Cpu = struct {
    memory: [2048]u8 = undefined,
    accumulator: u8 = 0,
    x_register: u8 = 0,
    y_register: u8 = 0,
    pc: u16 = 0xFFFC,
    stack_pointer: u8 = 0xFD,
    status: StatusRegister = .{},
    bus: *Bus,
    instruction: u24,
    extra_cycle: u1,

    pub fn cycle(prev_time: *i128, cycles: u8) void {
        const cur_time = std.time.nanoTimestamp();
        const elapsed_time = cur_time - prev_time.*;

        std.time.sleep(559 * cycles - elapsed_time);
    }

    pub fn getIndirectY(self: *Cpu) u8 {
        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();
        self.extra_cycle = 0;

        var addr: u16 = self.bus.data_bus;
        const sum: u8 = @addWithOverflow(self.bus.data_bus, self.y_register);
        if (sum[1] == 1) {
            self.extra_cycle = 1;
        }
        addr += self.y_register;

        self.bus.addr_bus = addr;
        self.bus.getMmo();

        return self.bus.data_bus;
    }

    pub fn getZeroPageX(self: *Cpu) u8 {
        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();

        const addr: u8 = (self.bus.data_bus + self.x_register) % 256;
        self.bus.addr_bus = addr;
        self.bus.getMmo();

        return self.bus.data_bus;
    }

    pub fn getAbsoluteIndexed(self: *Cpu, xory: u1) u8 {
        self.bus.addr_bus = self.pc + 2;
        self.bus.getMmo();
        var addr: u16 = self.bus.data_bus << 8;
        self.extra_cycle = 0;
        var sum = undefined;

        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();
        if (xory == 0) {
            sum = @addWithOverflow(self.bus.data_bus, self.x_register);
        } else {
            sum = @addWithOverflow(self.bus.data_bus, self.y_register);
        }

        if (sum[1] == 1) {
            self.extra_cycle = 1;
            addr += 0x100 + sum[0];
        } else {
            addr += sum[0];
        }
        self.bus.addr_bus = addr;
        self.bus.getMmo();
        return self.bus.data_bus;
    }

    pub fn getIndirectX(self: *Cpu) u8 {
        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();
        const addr = self.bus.data_bus;

        self.bus.addr_bus = (addr + self.x_register) % 256;
        self.bus.getMmo();

        return self.bus.data_bus;
    }

    pub fn getZeroPage(self: *Cpu) u8 {
        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();

        return self.bus.data_bus;
    }

    pub fn getImmediate(self: *Cpu) u8 {
        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();

        return self.bus.data_bus;
    }

    pub fn getAbsolute(self: *Cpu) u8 {
        self.bus.addr_bus = self.pc + 2;
        self.bus.getMmo();

        var addr: u16 = self.bus.data_bus << 8;

        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();

        addr |= self.bus.data_bus;
        self.bus.addr_bus = addr;
        self.bus.getMmo();

        return self.bus.data_bus;
    }

    pub fn logicalAnd(time: *i128, self: *Cpu) void {
        //I know its an annd because the lowest nib % 4 == 1
        if (self.instruction & 0xF0 == 0x30) {
            switch (self.instruction & 0xF) {
                1 => indirecty: {
                    self.accumulator &= self.getIndirectY();
                    self.pc += 2;
                    cycle(time, 5 + self.extra_cycle);
                    break :indirecty;
                },
                5 => zero_pagex: {
                    self.accumulator &= self.getZeroPageX();
                    self.pc += 3;
                    cycle(time, 4);
                    break :zero_pagex;
                },
                9 => absolute_y: {
                    self.accumulator &= self.getAbsoluteIndexed(1);
                    self.pc += 3;
                    cycle(time, 4 + self.extra_cycle);
                    break :absolute_y;
                },
                0xD => absolute_x: {
                    self.accumulator &= self.getAbsoluteIndexed(0);
                    self.pc += 3;
                    cycle(time, 4 + self.extra_cycle);
                    break :absolute_x;
                },
                else => default: {
                    std.debug.print("No Addressing mode found (Logical And)!\n", .{});
                    break :default;
                },
            }
        } else {
            switch (self.instruction & 0xF) {
                1 => indirectx: {
                    self.accumulator &= self.getIndirectX();

                    self.pc += 2;
                    cycle(time, 6);
                    break :indirectx;
                },
                5 => zero_page: {
                    self.accumulator &= self.getZeroPage();

                    self.pc += 2;
                    cycle(time, 3);
                    break :zero_page;
                },
                9 => immediate: {
                    self.accumulator &= self.getImmediate();

                    self.pc += 2;
                    cycle(time, 2);
                    break :immediate;
                },
                0xD => absolute: {
                    self.accumulator &= self.getAbsolute();
                    self.pc += 3;
                    cycle(time, 4);
                    break :absolute;
                },
                else => default: {
                    std.debug.print("No Addressing Mode found (Logical And)!\n", .{});
                    break :default;
                },
            }
        }
    }
};

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

    pub fn ppuMmo(self: *Ppu, address: u16) u8 {
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
};

pub const Apu = struct {};

pub const Bus = struct {
    addr_bus: u16 = 0,
    data_bus: u8 = 0,
    cpu_ptr: *Cpu,
    ppu_ptr: *Ppu,
    apu_ptr: *Apu,

    pub fn getMmo(self: *Bus) void {
        if (self.addr_bus <= 0x1FFF) {
            self.data_bus = self.cpu_ptr.cpu.memory[self.addr_bus % 0x800];
        } else if (self.addr_bus <= 0x3FFF) {
            self.data_bus = self.ppu_ptr.ppuMmo(self.addr_bus);
        } else if (self.addr_bus <= 0x401F) {
            return;
        }
    }
};
