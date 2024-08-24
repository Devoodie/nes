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

    pub fn logical_and(time: i128, self: *Cpu) void {
        //I know its an annd because the lowest nib % 4 == 
        if(self.instruction & 0xF0 == 0x30){
            switch(self.instruction & 0xF){}
        } else {
            switch(self.instruction & 0xF){}
        }
}
};

const Ppu = struct {
    control: u8,
    mask: u8,
    status: u3,
    oama_addr: u8,
    oam_data: u8,
    scroll: u8,
    addr: u8,
    data: u8,
    oam_dma: u8,
};

const Apu = struct {};

const Bus = struct {
    addr_bus: u16 = 0,
    data_bus: u8 = 0,
};
