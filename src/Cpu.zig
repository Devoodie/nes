const component = @import("Bus.zig");
const std = @import("std");
const StatusRegister = struct {
    carry: u1 = 0,
    zero: u1 = 0,
    interrupt_dsble: u1 = 0,
    break_inter: u0 = 0,
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
    bus: *component.Bus,
    instruction: u24,
    extra_cycle: u1,

    pub fn cycle(prev_time: i128, cycles: u8) void {
        const cur_time = std.time.nanoTimestamp();
        const elapsed_time = cur_time - prev_time;

        std.time.sleep(559 * cycles - elapsed_time);
    }

    pub fn stackPush(data: u8, self: *Cpu) void {
        self.bus.addr_bus = self.stack_pointer + 0x100;
        self.bus.data_bus = data;
        self.bus.putMmi();
        self.stack_pointer -= 1;
    }

    pub fn stackPushAddress(address: u16, self: *Cpu) void {
        const highbyte: u8 = address >> 8;
        const lowbyte: u8 = address & 0xFF;

        self.bus.addr_bus = self.stack_pointer + 0x100;
        self.bus.data_bus = highbyte;
        self.bus.putMmi();

        self.bus.addr_bus = self.stack_pointer + 0x100;
        self.bus.data_bus = lowbyte;
        self.bus.putMmi();
        self.stack_pointer -= 2;
    }
    pub fn stackPop(self: *Cpu) u8 {
        self.bus.addr_bus = self.stack_pointer + 0x100;
        self.bus.getMmo();
        self.stack_pointer += 1;
        return self.bus.data_bus;
    }

    pub fn stackPopAddress(self: *Cpu) u16 {
        var address: u16 = 0;
        self.bus.addr_bus = self.stack_pointer + 0x100;
        self.bus.getMmo();
        const highbyte: u8 = self.bus.data_bus;

        self.bus.addr_bus - self.stack_pointer + 0x100;
        self.bus.getMmo();
        const lowbyte: u8 = self.bus.data_bus;

        address = (highbyte << 8) | lowbyte;
        return address;
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

    pub fn nop(time: i128, self: *Cpu) void {
        self.pc += 1;
        cycle(time, 2);
    }

    pub fn loadYRegister(time: i128, self: *Cpu) void {
        if (self.instruction & 0xF0 == 0xA) {
            switch (self.instruction) {
                0xf => something: {
                    break :something;
                },
                else => default: {
                    std.debug.print("", .{});
                    break :default;
                },
            }
        } else {}
        cycle(time, 6);
    }

    pub fn returnInterrupt(time: i128, self: *Cpu) void {
        const status = self.stackPopAddress();
        self.status.negative = status >> 7;
        self.status.overflow = (status >> 6) & 0b1;
        self.status.decimal = (status >> 4) & 0b1;
        self.status.interrupt = (status >> 3) & 0b1;
        self.status.zero = (status >> 2) & 0b1;
        self.status.carry = status & 0b1;
        self.pc += 1;
        self.pc += 1;
        cycle(time, 6);
    }

    pub fn returnSubroutine(time: i128, self: *Cpu) void {
        self.pc = self.stackPopAddress() + 1;
        cycle(time, 6);
    }

    pub fn forceInterrupt(time: i128, self: *Cpu) void {
        self.stackPushAddress(self.pc + 1);
        self.status.break_inter = 1;
        self.pc = 0xFFFF;
        self.cycle(time, 7);
    }

    pub fn jumpSubroutine(time: i128, self: *Cpu) void {
        self.stackPush(self.pc + 3 - 1);

        self.bus.addr_bus = self.pc + 2;
        self.bus.getMmo();

        var addr: u16 = self.bus.data_bus << 8;

        self.bus.addr_bus = self.pc + 1;
        self.bus.getMmo();

        addr |= self.bus.data_bus;

        self.pc = addr;

        self.cycle(time, 6);
    }
    pub fn subtractWithCarry(time: i128, self: *Cpu) void {
        if (self.instruction & 0xF0 == 0xF) {
            switch (self.instruction & 0xF) {
                1 => indirecty: {
                    const negative: u1 = self.accumulator >> 7;
                    const carry = 1 - self.status.carry;

                    const operation1 = @subWithOverflow(self.accumulator, self.GetIndirectY());
                    const difference = @subWithOverflow(operation1, carry);

                    self.accumulator = difference[0];
                    if (negative != difference[0] >> 7) {
                        self.status.overflow = 1;
                        self.status.carry = 0;
                    } else {
                        self.status.carry = 1;
                    }

                    self.pc += 2;
                    cycle(time, 5 + self.extra_cycle);
                    break :indirecty;
                },
                5 => zero_pagex: {
                    const negative: u1 = self.accumulator >> 7;
                    const carry = 1 - self.status.carry;

                    const operation1 = @subWithOverflow(self.accumulator, self.GetZeroPageX());
                    const difference = @subWithOverflow(operation1, carry);

                    self.accumulator = difference[0];
                    if (negative != difference[0] >> 7) {
                        self.status.overflow = 1;
                        self.status.carry = 0;
                    } else {
                        self.status.carry = 1;
                    }

                    self.pc += 2;
                    cycle(time, 4);
                    break :zero_pagex;
                },
                9 => absolutey: {
                    const negative: u1 = self.accumulator >> 7;
                    const carry = 1 - self.status.carry;

                    const operation1 = @subWithOverflow(self.accumulator, self.GetAbsoluteIndexed(1));
                    const difference = @subWithOverflow(operation1, carry);

                    self.accumulator = difference[0];
                    if (negative != difference[0] >> 7) {
                        self.status.overflow = 1;
                        self.status.carry = 0;
                    } else {
                        self.status.carry = 1;
                    }

                    self.pc += 3;
                    cycle(time, 4 + self.extra_cycle);
                    break :absolutey;
                },
                0xD => absolutex: {
                    const negative: u1 = self.accumulator >> 7;
                    const carry = 1 - self.status.carry;

                    const operation1 = @subWithOverflow(self.accumulator, self.GetAbsoluteIndexed(0));
                    const difference = @subWithOverflow(operation1, carry);

                    self.accumulator = difference[0];
                    if (negative != difference[0] >> 7) {
                        self.status.overflow = 1;
                        self.status.carry = 0;
                    } else {
                        self.status.carry = 1;
                    }

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
                    const carry = 1 - self.status.carry;

                    const operation1 = @subWithOverflow(self.accumulator, self.GetIndirectX());
                    const difference = @subWithOverflow(operation1, carry);

                    self.accumulator = difference[0];
                    if (negative != difference[0] >> 7) {
                        self.status.overflow = 1;
                        self.status.carry = 0;
                    } else {
                        self.status.carry = 1;
                    }

                    self.pc += 2;
                    cycle(time, 6);
                    break :indirectx;
                },
                5 => zero_page: {
                    const negative: u1 = self.accumulator >> 7;
                    const carry = 1 - self.status.carry;

                    const operation1 = @subWithOverflow(self.accumulator, self.GetZeroPage());
                    const difference = @subWithOverflow(operation1, carry);

                    self.accumulator = difference[0];
                    if (negative != difference[0] >> 7) {
                        self.status.overflow = 1;
                        self.status.carry = 0;
                    } else {
                        self.status.carry = 1;
                    }

                    self.pc += 2;
                    cycle(time, 3);
                    break :zero_page;
                },
                9 => immediate: {
                    const negative: u1 = self.accumulator >> 7;
                    const carry = self.status.carry;

                    const operation1 = @subWithOverflow(self.accumulator, self.GetImmediate());
                    const difference = @subWithOverflow(operation1, carry);

                    self.accumulator = difference[0];
                    if (negative != difference[0] >> 7) {
                        self.status.overflow = 1;
                        self.status.carry = 0;
                    } else {
                        self.status.carry = 1;
                    }

                    self.pc += 2;
                    cycle(time, 2);
                    break :immediate;
                },
                0xD => absolute: {
                    const negative: u1 = self.accumulator >> 7;
                    const carry = 1 - self.status.carry;

                    const operation1 = @subWithOverflow(self.accumulator, self.GetAbsolute());
                    const difference = @subWithOverflow(operation1, carry);

                    self.accumulator = difference[0];
                    if (negative != difference[0] >> 7) {
                        self.status.overflow = 1;
                        self.status.carry = 0;
                    } else {
                        self.status.carry = 1;
                    }

                    self.pc += 3;
                    cycle(time, 4);
                    break :absolute;
                },
                else => default: {
                    std.debug.print("No Addressing Mode found (Add With Carry)!\n", .{});
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

    pub fn compareAccumulator(time: i128, self: *Cpu) void {
        if (self.instruction & 0xF0 == 5) {
            switch (self.instruction & 0xF) {
                1 => indirecty: {
                    const value = self.GetIndirectY();
                    if (self.accumulator == value) {
                        self.status.carry = 1;
                        self.status.zero = 1;
                    } else if (self.accumulator > value) {
                        self.status.carry = 1;
                    }
                    self.pc += 2;
                    cycle(time, 5 + self.extra_cycle);
                    break :indirecty;
                },
                5 => zero_pagex: {
                    const value = self.GetIndirectX();
                    if (self.accumulator == value) {
                        self.status.carry = 1;
                        self.status.zero = 1;
                    } else if (self.accumulator > value) {
                        self.status.carry = 1;
                    }
                    self.pc += 2;
                    cycle(time, 4);
                    break :zero_pagex;
                },
                9 => absolutey: {
                    const value = self.GetAbsoluteIndexed(1);
                    if (self.accumulator == value) {
                        self.status.carry = 1;
                        self.status.zero = 1;
                    } else if (self.accumulator > value) {
                        self.status.carry = 1;
                    }
                    self.pc += 3;
                    cycle(time, 4 + self.extra_cycle);
                    break :absolutey;
                },
                0xD => absolutex: {
                    const value = self.GetAbsoluteIndexed(1);
                    if (self.accumulator == value) {
                        self.status.carry = 1;
                        self.status.zero = 1;
                    } else if (self.accumulator > value) {
                        self.status.carry = 1;
                    }
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
                    const value = self.GetIndirectX();
                    if (self.accumulator == value) {
                        self.status.carry = 1;
                        self.status.zero = 1;
                    } else if (self.accumulator > value) {
                        self.status.carry = 1;
                    }
                    self.pc += 2;
                    cycle(time, 6);
                    break :indirectx;
                },
                5 => zero_page: {
                    const value = self.GetZeroPage();
                    if (self.accumulator == value) {
                        self.status.carry = 1;
                        self.status.zero = 1;
                    } else if (self.accumulator > value) {
                        self.status.carry = 1;
                    }
                    self.pc += 2;
                    cycle(time, 3);
                    break :zero_page;
                },
                9 => immediate: {
                    const value = self.GetImmediate();
                    if (self.accumulator == value) {
                        self.status.carry = 1;
                        self.status.zero = 1;
                    } else if (self.accumulator > value) {
                        self.status.carry = 1;
                    }
                    self.pc += 2;
                    cycle(time, 2);
                    break :immediate;
                },
                0xD => absolute: {
                    const value = self.GetAbsolute();
                    if (self.accumulator == value) {
                        self.status.carry = 1;
                        self.status.zero = 1;
                    } else if (self.accumulator > value) {
                        self.status.carry = 1;
                    }
                    self.pc += 3;
                    cycle(time, 4);
                    break :absolute;
                },
                else => default: {
                    std.debug.print("No Addressing Mode found (Logical XOR)!\n", .{});
                    break :default;
                },
            }
            self.status.negative = self.accumulator >> 7;
        }
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
        if (self.instruction & 0xF0 == 9) {
            self.setZeroPageY(self.accumulator);
            self.pc += 2;
            cycle(time, 4);
        } else {
            switch (self.instruction & 0xF) {
                6 => zeropage: {
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
                },
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
                    const carry = @addWithOverflow(self.accumulator, self.status.carry);
                    const sum = @addWithOverflow(self.GetIndirectY(), carry[0]);

                    if (carry[1] == 1 or sum[1] == 1) {
                        self.status.carry = 1;
                    }
                    self.accumulator = sum[0];
                    if (negative != sum[0] >> 7) {
                        self.status.overflow = 1;
                    }

                    self.pc += 2;
                    cycle(time, 5 + self.extra_cycle);
                    break :indirecty;
                },
                5 => zero_pagex: {
                    const negative: u1 = self.accumulator >> 7;
                    const carry = @addWithOverflow(self.accumulator, self.status.carry);
                    const sum = @addWithOverflow(self.GetIndirectY(), carry[0]);

                    if (carry[1] == 1 or sum[1] == 1) {
                        self.status.carry = 1;
                    }
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
                    const carry = @addWithOverflow(self.accumulator, self.status.carry);
                    const sum = @addWithOverflow(self.GetIndirectY(), carry[0]);

                    if (carry[1] == 1 or sum[1] == 1) {
                        self.status.carry = 1;
                    }
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
                    const carry = @addWithOverflow(self.accumulator, self.status.carry);
                    const sum = @addWithOverflow(self.GetIndirectY(), carry[0]);

                    if (carry[1] == 1 or sum[1] == 1) {
                        self.status.carry = 1;
                    }
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
                    const carry = @addWithOverflow(self.accumulator, self.status.carry);
                    const sum = @addWithOverflow(self.GetIndirectY(), carry[0]);

                    if (carry[1] == 1 or sum[1] == 1) {
                        self.status.carry = 1;
                    }
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
                    const carry = @addWithOverflow(self.accumulator, self.status.carry);
                    const sum = @addWithOverflow(self.GetIndirectY(), carry[0]);

                    if (carry[1] == 1 or sum[1] == 1) {
                        self.status.carry = 1;
                    }
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
                    const carry = @addWithOverflow(self.accumulator, self.status.carry);
                    const sum = @addWithOverflow(self.GetIndirectY(), carry[0]);

                    if (carry[1] == 1 or sum[1] == 1) {
                        self.status.carry = 1;
                    }
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
                    const carry = @addWithOverflow(self.accumulator, self.status.carry);
                    const sum = @addWithOverflow(self.GetIndirectY(), carry[0]);

                    if (carry[1] == 1 or sum[1] == 1) {
                        self.status.carry = 1;
                    }
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

pub const Apu = struct {};