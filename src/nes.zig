const std = @import("std");

const address_mode = enum { 
    immediate,
    zero_pg,
    zero_pgx,
    absolute,
    absolute_x,
    absolute_y,
    indirect_x,
    indirect_y,
};

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
    pc: u16 = 0xFFFC,
    stack_pointer: u8 = 0xFD,
    status: StatusRegister = .{},
    instruction: u24,

    pub fn cycle(prev_time: *i128) void {
        const cur_time = std.time.nanoTimestamp();
        const difference = cur_time - prev_time.*;

        if (difference < 559) {
            std.time.sleep(559 - difference);
        }
        prev_time.* = std.time.nanoTimestamp();
    }

    pub fn logical_and(time: i128, self: *Cpu, bus: *Bus) void {
        //I know its an annd because the lowest nib % 4 == 
        if(self.instruction & 0xF0 == 0x30){
            switch(self.instruction & 0xF){}
        } else {
            switch(self.instruction & 0xF){
                1 => indirect: {
                    break :indirect;
                },
                5 => zeropage: {
                    break :zeropage;
                },
                9 => immediate: {
                    bus.addr_bus = self.pc + 1;

                    break :immediate;
                },
                else => default: {
                    std.debug.print("No Addressing Mode found!\n", .{});
                    break :default;
                }
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

    pub fn ppu_mmo(self: *Ppu, address: u16) u8 {
        switch(address % 8) {
            0 => send_control: {
                break :send_control self.control;
            }, 
            1 => send_mask: {
                break :send_mask self.mask;
            },
            2 => send_status: {
                break :send_status self.status;
            },
            3 => send_oma_addr: {
                break :send_oma_addr self.oama_addr;
            },
            4 => send_oma_data: {
                break :send_oma_data self.oam_data;
            },
            5 => send_scroll: {
                break :send_scroll self.scroll;
            },
            6 => send_data: {
                break :send_data self.data;
            },
            7 => send_oma_dma: {
                break :send_oma_dma self.oam_dma;
            }

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

    pub fn get_mmi(self: *Bus) u8{
        if(self.addr_bus <= 0x1FFF){
            return self.cpu_ptr.cpu.memory[self.addr_bus % 0x800];
        } else if (self.addr_bus <= 0x3FFF) {
            return self.ppu_ptr.ppu_mmo(self.addr_bus);
        }
}
};
