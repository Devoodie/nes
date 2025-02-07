const std = @import("std");
const nes = @import("nes");
const cpu = @import("cpu");

pub const json_test = struct {
    name: []u8,
    initial: state,
    final: state,

    pub fn run_test(self: *json_test, nes_ptr: *nes.Nes) bool {
        nes_ptr.Cpu.pc = self.initial.pc;
        std.debug.print("Program Counter Initial: {d}\n", .{nes_ptr.Cpu.pc});
        nes_ptr.Cpu.stack_pointer = self.initial.s;
        nes_ptr.Cpu.accumulator = self.initial.a;
        nes_ptr.Cpu.x_register = self.initial.x;
        nes_ptr.Cpu.y_register = self.initial.y;
        nes_ptr.Cpu.status = extract_status(self.initial.p);

        for (self.initial.ram) |memory| {
            nes_ptr.Bus.addr_bus = memory[0];
            std.debug.print("Address: {d} ", .{memory[0]});
            nes_ptr.Bus.data_bus = @truncate(memory[1]);
            std.debug.print("Value: 0x{X}\n", .{memory[1]});
            nes_ptr.Bus.putMmi();
        }

        nes_ptr.Cpu.operate();
        std.debug.print("Program Counter After: {d}\n", .{nes_ptr.Cpu.pc});
        //compare with final results
        for (0..7) |index| {
            switch (index) {
                0 => {
                    if (nes_ptr.Cpu.pc != self.final.pc) {
                        std.debug.print("Wrong PC Value Returned Within JSON Test: {s}\n", .{self.name});
                        std.debug.print("Expected: {d}, Recieved: {d}\n", .{ self.final.pc, nes_ptr.Cpu.pc });
                        return false;
                    }
                    break;
                },
                //fix these values to correspond with registers
                1 => {
                    if (nes_ptr.Cpu.stack_pointer != self.final.s) {
                        std.debug.print("Wrong Stack Pointer Value Returned Within JSON Test: {s}\n", .{self.name});
                        std.debug.print("Expected: {d}, Recieved: {d}\n", .{ self.final.s, nes_ptr.Cpu.stack_pointer });
                        return false;
                    }
                    break;
                },
                2 => {
                    if (nes_ptr.Cpu.accumulator != self.final.a) {
                        std.debug.print("Wrong Accumulator Value Returned Within JSON Test: {s}\n", .{self.name});
                        std.debug.print("Expected: {d}, Recieved: {d}\n", .{ self.final.a, nes_ptr.Cpu.accumulator });
                        return false;
                    }
                    break;
                },
                3 => {
                    if (nes_ptr.Cpu.x_register != self.final.x) {
                        std.debug.print("Wrong X Register Value Returned Within JSON Test: {s}\n", .{self.name});
                        std.debug.print("Expected: {d}, Recieved: {d}\n", .{ self.final.x, nes_ptr.Cpu.x_register });
                        return false;
                    }
                    break;
                },
                4 => {
                    if (nes_ptr.Cpu.y_register != self.final.y) {
                        std.debug.print("Wrong Y Register Value Returned Within JSON Test: {s}\n", .{self.name});
                        std.debug.print("Expected: {d}, Recieved: {d}\n", .{ self.final.y, nes_ptr.Cpu.y_register });
                        return false;
                    }
                    break;
                },
                5 => {
                    if (std.meta.eql(nes_ptr.*.Cpu.status, extract_status(self.final.p))) {
                        std.debug.print("Wrong Status Returned Within JSON Test: {s}\n", .{self.name});
                        std.debug.print("Expected: {any}, Recieved: {any}\n", .{ self.final.p, nes_ptr.Cpu.status });
                        return false;
                    }
                    break;
                },
                6 => {
                    for (self.final.ram) |memory| {
                        nes_ptr.Bus.addr_bus = memory[0];
                        nes_ptr.Bus.getMmo();
                        if (nes_ptr.Bus.data_bus != memory[1]) {
                            std.debug.print("Wrong Memory Value Returned Within JSON Test: {s}\n", .{self.name});
                            std.debug.print("Expected: {d}, Recieved: {d}\n", .{ memory[1], nes_ptr.Bus.data_bus });
                            return false;
                        }
                    }
                    break;
                },
                else => {
                    std.debug.print("Something Went Wrong In JSON Test!\n", .{});
                    break;
                },
            }
        }
        std.debug.print("Test successful: {s}\n\n", .{self.name});
        return true;
    }

    fn extract_status(status: u8) cpu.StatusRegister {
        var new_status: cpu.StatusRegister = .{};

        new_status.negative = @truncate(status >> 7);
        new_status.overflow = @truncate((status >> 6) & 0b1);
        new_status.break_inter = @truncate(status >> 5);
        new_status.decimal = @truncate((status >> 3) & 0b1);
        new_status.interrupt_dsble = @truncate((status >> 2) & 0b1);
        new_status.zero = @truncate((status >> 1) & 0b1);
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
