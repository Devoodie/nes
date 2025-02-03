const std = @import("std");
const nes = @import("nes");
const cpu = @import("cpu");

pub const json_test = struct {
    name: []u8,
    initial: state,
    final: state,

    pub fn run_test(self: *json_test, nes_ptr: *nes.Nes) bool {
        nes_ptr.Cpu.pc = self.initial.pc;
        nes_ptr.Cpu.stack_pointer = self.initial.s;
        nes_ptr.Cpu.accumulator = self.initial.a;
        nes_ptr.Cpu.x_register = self.initial.x;
        nes_ptr.Cpu.y_register = self.initial.y;
        nes_ptr.Cpu.status = extract_status(self.initial.p);

        for (self.initial.ram) |memory| {
            nes_ptr.Bus.addr_bus = memory[0];
            nes_ptr.Bus.data_bus = memory[1];
            nes_ptr.Bus.putMmi();
        }

        nes_ptr.Cpu.operate();

        //compare with final results
        for (0..7) |index| {
            switch (index) {
                0 => {
                    if (nes_ptr.Cpu.pc != self.final.pc) {
                        std.debug.print("Wrong PC Value Returned Within JSON Test: {s}\n", .{self.name});
                        return false;
                    }
                    break;
                },
                //fix these values to correspond with registers
                1 => {
                    if (nes_ptr.Cpu.pc != self.final.pc) {
                        std.debug.print("Wrong PC Value Returned Within JSON Test: {s}\n", .{self.name});
                        return false;
                    }
                    break;
                },
                2 => {
                    if (nes_ptr.Cpu.pc != self.final.pc) {
                        std.debug.print("Wrong PC Value Returned Within JSON Test: {s}\n", .{self.name});
                        return false;
                    }
                    break;
                },
                3 => {
                    if (nes_ptr.Cpu.pc != self.final.pc) {
                        std.debug.print("Wrong PC Value Returned Within JSON Test: {s}\n", .{self.name});
                        return false;
                    }
                    break;
                },
                4 => {
                    if (nes_ptr.Cpu.pc != self.final.pc) {
                        std.debug.print("Wrong PC Value Returned Within JSON Test: {s}\n", .{self.name});
                        return false;
                    }
                    break;
                },
                5 => {
                    if (nes_ptr.Cpu.pc != self.final.pc) {
                        std.debug.print("Wrong PC Value Returned Within JSON Test: {s}\n", .{self.name});
                        return false;
                    }
                    break;
                },
                6 => {
                    if (nes_ptr.Cpu.pc != self.final.pc) {
                        std.debug.print("Wrong PC Value Returned Within JSON Test: {s}\n", .{self.name});
                        return false;
                    }
                    break;
                },
                else => {
                    std.debug.print("Something Went Wrong In JSON Test!\n", .{});
                    break;
                },
            }
        }
        return true;
    }

    fn extract_status(status: u8) cpu.StatusRegister {
        var new_status = .{};

        new_status.status.negative = @truncate(status >> 7);
        new_status.overflow = @truncate((status >> 6) & 0b1);
        new_status.break_inter = @truncate(status >> 5);
        new_status.decimal = @truncate((status >> 4) & 0b1);
        new_status.interrupt_dsble = @truncate((status >> 3) & 0b1);
        new_status.zero = @truncate((status >> 2) & 0b1);
        new_status.carry = @truncate(status & 0b1);

        return new_status;
    }
};

pub const state = struct {
    pc: u16,
    s: u8,
    a: u8,
    x: u8,
    y: u8,
    p: u8,
    ram: [][]u16,
};
