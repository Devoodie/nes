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

    pub fn cycle(prev_time: i128, cycles: u8) void {
        const cur_time = std.time.nanoTimestamp();
        const elapsed_time = cur_time - prev_time;

        std.time.sleep(559 * cycles - elapsed_time);
    }

    pub fn GetIndirectY(self: *Cpu) u8 {
        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();
        self.extra_cycle = 0;

        var addr: u16 = self.bus.data_bus;
        const sum = @addWithOverflow(self.bus.data_bus, self.y_register);
        if (sum[1] == 1) {
            self.extra_cycle = 1;
        }
        addr = sum[0];

        self.bus.addr_bus = addr;
        self.bus.getMmo();

        return self.bus.data_bus;
    }
    pub fn setIndirectY(self: *Cpu, data: u8) void {
        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();
        self.extra_cycle = 0;

        var addr: u16 = self.bus.data_bus;
        addr += self.y_register;

        self.bus.addr_bus = addr;
        self.bus.data_bus = data;

        self.bus.putMmi();
    }

    pub fn GetZeroPageX(self: *Cpu) u8 {
        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();

        const addr: u8 = (self.bus.data_bus + self.x_register) % 256;
        self.bus.addr_bus = addr;
        self.bus.getMmo();

        return self.bus.data_bus;
    }
    pub fn setZeroPageX(self: *Cpu, data: u8) void {
        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();

        const addr: u8 = (self.bus.data_bus + self.x_register) % 256;
        self.bus.addr_bus = addr;
        self.bus.data_bus = data;

        self.bus.putMmi();
    }

    pub fn GetAbsoluteIndexed(self: *Cpu, xory: u1) u8 {
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
    pub fn setAbsoluteIndexed(self: *Cpu, xory: u1, data: u8) void {
        self.bus.addr_bus = self.pc + 2;
        self.bus.getMmo();
        var addr: u16 = self.bus.data_bus << 8;
        self.extra_cycle = 0;
        var sum = undefined;

        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();

        if (xory == 0) {
            sum = self.bus.data_bus + self.x_register;
        } else {
            sum = self.bus.data_bus + self.y_register;
        }

        addr += sum;
        self.bus.addr_bus = addr;
        self.bus.data_bus = data;

        self.bus.putMmi();
    }

    pub fn GetIndirectX(self: *Cpu) u8 {
        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();
        const addr = self.bus.data_bus;

        self.bus.addr_bus = (addr + self.x_register) % 256;
        self.bus.getMmo();

        return self.bus.data_bus;
    }
    pub fn setIndirectX(self: *Cpu, data: u8) void {
        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();
        const addr = self.bus.data_bus;

        self.bus.addr_bus = (addr + self.x_register) % 256;
        self.bus.data_bus = data;

        self.bus.putMmi();
    }

    pub fn GetZeroPage(self: *Cpu) u8 {
        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();

        return self.bus.data_bus;
    }

    pub fn setZeroPage(self: *Cpu, data: u8) void {
        self.bus.addr_bus = self.pc + 1;
        self.bus.data_bus = data;

        self.bus.putMmi();
    }

    pub fn GetImmediate(self: *Cpu) u8 {
        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();

        return self.bus.data_bus;
    }

    pub fn setImmediate(self: *Cpu, data: u8) void {
        self.bus.addr_bus = self.pc + 1;
        self.bus.data_bus = data;

        self.bus.putMmi();
    }

    pub fn GetAbsolute(self: *Cpu) u8 {
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
    pub fn setAbsolute(self: *Cpu, data: u8) void {
        self.bus.addr_bus = self.pc + 2;
        self.bus.getMmo();

        var addr: u16 = self.bus.data_bus << 8;

        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();

        addr |= self.bus.data_bus;
        self.bus.addr_bus = addr;
        self.bus.data_bus = data;

        self.bus.putMmi();
    }

    pub fn loadAccumulator(time: i128, self: *Cpu) void {
        if (self.instruction & 0xF0 == 0xB) {
            switch (self.instruction & 0xF) {
                1 => indirecty: {
                    self.accumulator = self.GetIndirectY();
                    self.pc += 2;
                    cycle(time, 5 + self.extra_cycle);
                    break :indirecty;
                },
                5 => zero_pagex: {
                    self.accumulator = self.GetZeroPageX();
                    self.pc += 2;
                    cycle(time, 4);
                    break :zero_pagex;
                },
                9 => absolutey: {
                    self.accumulator = self.GetAbsoluteIndexed(1);
                    self.pc += 3;
                    cycle(time, 4 + self.extra_cycle);
                    break :absolutey;
                },
                0xD => absolutex: {
                    self.accumulator = self.GetAbsoluteIndexed(0);
                    self.pc += 3;
                    cycle(time, 4 + self.extra_cycle);
                    break :absolutex;
                },
                else => default: {
                    std.debug.print("No Addressing Mode found (Load Accumulator)!\n", .{});
                    break :default;
                },
            }
        } else {
            switch (self.instruction & 0xF) {
                1 => indirectx: {
                    self.accumulator = self.GetIndirectX();
                    self.pc += 2;
                    cycle(time, 6);
                    break :indirectx;
                },
                5 => zero_page: {
                    self.accumulator = self.GetZeroPage();
                    self.pc += 2;
                    cycle(time, 3);
                    break :zero_page;
                },
                9 => immediate: {
                    self.accumulator = self.GetImmediate();
                    self.pc += 2;
                    cycle(time, 2);
                    break :immediate;
                },
                0xD => absolute: {
                    self.accumulator = self.GetAbsolute();
                    self.pc += 3;
                    cycle(time, 4);
                    break :absolute;
                },
                else => default: {
                    std.debug.print("No Addressing Mode found (Load Accumulator)!\n", .{});
                    break :default;
                },
            }
            if (self.accumulator == 0) {
                self.status.zero = 1;
            } else {
                self.status.zero = 0;
            }
            self.status.negative = self.accumulator >> 7;
        }
    }

    pub fn storeXRegister(time: i128, self: *Cpu) void {
        if(self.instruction & 0xF0 == 9){
            self.setZeroPageY(self.accumulator);
            self.pc += 2;
            cycle(time, 4);
        } else {
            switch (self.instruction & 0xF) {
                1 => zeropage: {
                    self.setZeroPage(self.x_register);
                    self.pc += 2;
                    cycle(time, 3);
                    break :zeropage;
                },
                0xE => absolute: {
                    self.setAbsolute(self.x_register);
                    self.pc += 2;
                    cycle(time, 4);
                    break :absolute;
                },
                else => default: {
                    std.debug.print("No Valid Addresing mode found (Store X Register!\n", .{});
                    break :default;
                }
            }
        }
    }

    pub fn storeAccumulator(time: i128, self: *Cpu) void {
        if (self.instruction & 0xF0 == 9) {
            switch (self.instruction & 0xF) {
                1 => indirecty: {
                    self.setIndirectY(self.accumulator);
                    self.pc += 2;
                    cycle(time, 6);
                    break :indirecty;
                },
                5 => zero_pagex: {
                    self.setZeroPageX(self.accumulator);
                    self.pc += 2;
                    cycle(time, 4);
                    break :zero_pagex;
                },
                9 => absolutey: {
                    self.setAbsoluteIndexed(1, self.accumulator);
                    self.pc += 3;
                    cycle(time, 5);
                    break :absolutey;
                },
                0xD => absolutex: {
                    self.setAbsoluteIndexed(0, self.accumulator);
                    self.pc += 3;
                    cycle(time, 5);
                    break :absolutex;
                },
                else => default: {
                    std.debug.print("No Addressing Mode found (Logical XOR)!\n", .{});
                    break :default;
                },
            }
        } else {
            switch (self.instruction & 0xF) {
                1 => indirectx: {
                    self.setIndirectX(self.accumulator);
                    self.pc += 2;
                    cycle(time, 6);
                    break :indirectx;
                },
                5 => zero_page: {
                    self.setZeroPage(self.accumulator);
                    self.pc += 2;
                    cycle(time, 3);
                    break :zero_page;
                },
                0xD => absolute: {
                    self.pc += 3;
                    cycle(time, 4);
                    break :absolute;
                },
                else => default: {
                    std.debug.print("No Addressing Mode found (Logical XOR)!\n", .{});
                    break :default;
                },
            }
        }
    }

    pub fn addWithCarry(time: i128, self: *Cpu) void {
        if (self.instruction & 0xF0 == 7) {
            switch (self.instruction & 0xF) {
                1 => indirecty: {
                    const negative: u1 = self.accumulator >> 7;
                    const sum = @addWithOverflow(self.GetIndirectY(), self.accumulator);

                    self.accumulator = sum[0];
                    if (negative != sum[0] >> 7) {
                        self.status.overflow = 1;
                    }
                    self.status.carry = sum[1];

                    self.pc += 2;
                    cycle(time, 5 + self.extra_cycle);
                    break :indirecty;
                },
                5 => zero_pagex: {
                    const negative: u1 = self.accumulator >> 7;
                    const sum = @addWithOverflow(self.GetZeroPageX(), self.accumulator);

                    self.accumulator = sum[0];
                    if (negative != sum[0] >> 7) {
                        self.status.overflow = 1;
                    }
                    self.status.carry = sum[1];

                    self.pc += 2;
                    cycle(time, 4);
                    break :zero_pagex;
                },
                9 => absolutey: {
                    const negative: u1 = self.accumulator >> 7;
                    const sum = @addWithOverflow(self.GetAbsoluteIndexed(1), self.accumulator);

                    self.accumulator = sum[0];
                    if (negative != sum[0] >> 7) {
                        self.status.overflow = 1;
                    }
                    self.status.carry = sum[1];

                    self.pc += 3;
                    cycle(time, 4 + self.extra_cycle);
                    break :absolutey;
                },
                0xD => absolutex: {
                    const negative: u1 = self.accumulator >> 7;
                    const sum = @addWithOverflow(self.GetAbsoluteIndexed(0), self.accumulator);

                    self.accumulator = sum[0];
                    if (negative != sum[0] >> 7) {
                        self.status.overflow = 1;
                    }
                    self.status.carry = sum[1];

                    self.pc += 3;
                    cycle(time, 4 + self.extra_cycle);
                    break :absolutex;
                },
                else => default: {
                    std.debug.print("No Addressing Mode found (Add With Carry)!\n", .{});
                    break :default;
                },
            }
        } else {
            switch (self.instruction & 0xF) {
                1 => indirectx: {
                    const negative: u1 = self.accumulator >> 7;
                    const sum = @addWithOverflow(self.GetIndirectX(), self.accumulator);

                    self.accumulator = sum[0];
                    if (negative != sum[0] >> 7) {
                        self.status.overflow = 1;
                    }
                    self.status.carry = sum[1];

                    self.pc += 2;
                    cycle(time, 6);
                    break :indirectx;
                },
                5 => zero_page: {
                    const negative: u1 = self.accumulator >> 7;
                    const sum = @addWithOverflow(self.GetZeroPage(), self.accumulator);

                    self.accumulator = sum[0];
                    if (negative != sum[0] >> 7) {
                        self.status.overflow = 1;
                    }
                    self.status.carry = sum[1];

                    self.pc += 2;
                    cycle(time, 3);
                    break :zero_page;
                },
                9 => immediate: {
                    const negative: u1 = self.accumulator >> 7;
                    const sum = @addWithOverflow(self.GetImmediate(), self.accumulator);

                    self.accumulator = sum[0];
                    if (negative != sum[0] >> 7) {
                        self.status.overflow = 1;
                    }
                    self.status.carry = sum[1];

                    self.pc += 2;
                    cycle(time, 2);
                    break :immediate;
                },
                0xD => absolute: {
                    const negative: u1 = self.accumulator >> 7;
                    const sum = @addWithOverflow(self.GetAbsolute(), self.accumulator);

                    self.accumulator = sum[0];
                    if (negative != sum[0] >> 7) {
                        self.status.overflow = 1;
                    }
                    self.status.carry = sum[1];

                    self.pc += 3;
                    cycle(time, 4);
                    break :absolute;
                },
                else => default: {
                    std.debug.print("No Addressing Mode found (Add With Carry)!\n", .{});
                    break :default;
                },
            }
            if (self.accumulator == 0) {
                self.status.zero = 1;
            } else {
                self.status.zero = 0;
            }
            self.status.negative = self.accumulator >> 7;
        }
    }

    pub fn bitTest(time: i128, self: *Cpu) void {
        switch (self.instruction & 0xF) {
            4 => zero_page: {
                const value = self.GetZeroPage();
                const zero = self.accumulator & value;
                self.status.negative = value >> 7;
                self.status.overflow = value >> 6;
                if (zero == 0) {
                    self.status.zero = 1;
                }
                self.pc += 2;
                cycle(time, 3);
                break :zero_page;
            },
            0xC => absolute: {
                const value = self.GetAbsolute();
                const zero = self.accumulator & value;
                self.status.negative = value >> 7;
                self.status.overflow = value >> 6;
                if (zero == 0) {
                    self.status.zero = 1;
                }
                self.pc += 2;
                cycle(time, 4);
                break :absolute;
            },
            else => default: {
                std.debug.print("No Addressing Mode found (Bit Test)!\n", .{});
                break :default;
            },
        }
    }

    pub fn exclusiveOr(time: i128, self: *Cpu) void {
        if (self.instruction & 0xF0 == 5) {
            switch (self.instruction & 0xF) {
                1 => indirecty: {
                    self.accumulator ^= self.GetIndirectY();
                    self.pc += 2;
                    cycle(time, 5 + self.extra_cycle);
                    break :indirecty;
                },
                5 => zero_pagex: {
                    self.accumulator ^= self.GetZeroPageX();
                    self.pc += 2;
                    cycle(time, 4);
                    break :zero_pagex;
                },
                9 => absolutey: {
                    self.accumulator ^= self.GetAbsoluteIndexed(1);
                    self.pc += 3;
                    cycle(time, 4 + self.extra_cycle);
                    break :absolutey;
                },
                0xD => absolutex: {
                    self.accumulator ^= self.GetAbsoluteIndexed(0);
                    self.pc += 3;
                    cycle(time, 4 + self.extra_cycle);
                    break :absolutex;
                },
                else => default: {
                    std.debug.print("No Addressing Mode found (Logical XOR)!\n", .{});
                    break :default;
                },
            }
        } else {
            switch (self.instruction & 0xF) {
                1 => indirectx: {
                    self.accumulator ^= self.GetIndirectX();
                    self.pc += 2;
                    cycle(time, 6);
                    break :indirectx;
                },
                5 => zero_page: {
                    self.accumulator ^= self.GetZeroPage();
                    self.pc += 2;
                    cycle(time, 3);
                    break :zero_page;
                },
                9 => immediate: {
                    self.accumulator ^= self.GetImmediate();
                    self.pc += 2;
                    cycle(time, 2);
                    break :immediate;
                },
                0xD => absolute: {
                    self.accumulator ^= self.GetAbsolute();
                    self.pc += 3;
                    cycle(time, 4);
                    break :absolute;
                },
                else => default: {
                    std.debug.print("No Addressing Mode found (Logical XOR)!\n", .{});
                    break :default;
                },
            }
        }
        if (self.accumulator == 0) {
            self.status.zero = 1;
        } else {
            self.status.zero = 0;
        }
        self.status.negative = self.accumulator >> 7;
    }

    pub fn logicalOr(time: i128, self: *Cpu) void {
        if (self.instruction & 0xF0 == 1) {
            switch (self.instruction & 0xF) {
                1 => indirecty: {
                    self.accumulator |= self.GetIndirectY();
                    self.pc += 2;
                    cycle(time, 5 + self.extra_cycle);
                    break :indirecty;
                },
                5 => zero_pagex: {
                    self.accumulator |= self.GetZeroPageX();
                    self.pc += 2;
                    cycle(time, 4);
                    break :zero_pagex;
                },
                9 => absolutey: {
                    self.accumulator |= self.GetAbsoluteIndexed(1);
                    self.pc += 3;
                    cycle(time, 4 + self.extra_cycle);
                    break :absolutey;
                },
                0xD => absolutex: {
                    self.accumulator |= self.GetAbsoluteIndexed(0);
                    cycle(time, 4 + self.extra_cycle);
                    break :absolutex;
                },
                else => default: {
                    std.debug.print("No Addresing Mode found (Logical Or)!\n", .{});
                    break :default;
                },
            }
        } else {
            switch (self.instruction & 0xF) {
                1 => indirectx: {
                    self.accumulator |= self.GetIndirectX();
                    cycle(time, 6);
                    break :indirectx;
                },
                5 => zero_page: {
                    self.accumulator |= self.GetZeroPage();
                    cycle(time, 3);
                    break :zero_page;
                },
                9 => immediate: {
                    self.accumulator |= self.GetImmediate();
                    cycle(time, 2);
                    break :immediate;
                },
                0xD => absolute: {
                    self.accumulator |= self.GetAbsolute();
                    break :absolute;
                },
                else => default: {
                    std.debug.print("No Addressing Mode Found (Logical Or)\n!", .{});
                    break :default;
                },
            }
        }
        if (self.accumulator == 0) {
            self.status.zero = 1;
        } else {
            self.status.zero = 0;
        }
        self.status.negative = self.accumulator >> 7;
    }

    pub fn logicalAnd(time: i128, self: *Cpu) void {
        //I know its an annd because the lowest nib % 4 == 1
        if (self.instruction & 0xF0 == 0x30) {
            switch (self.instruction & 0xF) {
                1 => indirecty: {
                    self.accumulator &= self.GetIndirectY();
                    self.pc += 2;
                    cycle(time, 5 + self.extra_cycle);
                    break :indirecty;
                },
                5 => zero_pagex: {
                    self.accumulator &= self.GetZeroPageX();
                    self.pc += 3;
                    cycle(time, 4);
                    break :zero_pagex;
                },
                9 => absolute_y: {
                    self.accumulator &= self.GetAbsoluteIndexed(1);
                    self.pc += 3;
                    cycle(time, 4 + self.extra_cycle);
                    break :absolute_y;
                },
                0xD => absolute_x: {
                    self.accumulator &= self.GetAbsoluteIndexed(0);
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
                    self.accumulator &= self.GetIndirectX();

                    self.pc += 2;
                    cycle(time, 6);
                    break :indirectx;
                },
                5 => zero_page: {
                    self.accumulator &= self.GetZeroPage();

                    self.pc += 2;
                    cycle(time, 3);
                    break :zero_page;
                },
                9 => immediate: {
                    self.accumulator &= self.GetImmediate();

                    self.pc += 2;
                    cycle(time, 2);
                    break :immediate;
                },
                0xD => absolute: {
                    self.accumulator &= self.GetAbsolute();
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
        if (self.accumulator == 0) {
            self.status.zero = 1;
        } else {
            self.status.zero = 0;
        }
        self.status.negative = self.accumulator >> 7;
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

pub const Apu = struct {};

pub const Bus = struct {
    addr_bus: u16 = 0,
    data_bus: u8 = 0,
    cpu_ptr: *Cpu,
    ppu_ptr: *Ppu,
    apu_ptr: *Apu,

    pub fn getMmo(self: *Bus) void {
        if (self.addr_bus <= 0x1FFF) {
            self.data_bus = self.cpu_ptr.memory[self.addr_bus % 0x800];
        } else if (self.addr_bus <= 0x3FFF) {
            self.data_bus = self.ppu_ptr.PpuMmo(self.addr_bus);
        } else if (self.addr_bus <= 0x401F) {
            return;
        }
    }
    pub fn putMmi(self: *Bus) void {
        if (self.addr_bus <= 0x1FFF) {
            self.cpu_ptr.memory[self.addr_bus % 0x800] = self.data_bus;
        } else if (self.addr_bus <= 0x3FFF) {
            self.data_bus = self.ppu_ptr.ppuMmi(self.addr_bus, self.data_bus);
        } else if (self.addr_bus <= 0x401F) {
            return;
        }
    }
};
