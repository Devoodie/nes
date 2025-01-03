const std = @import("std");
const components = @import("Nes.zig");
const cpu = @import("Cpu.zig");
const ppu = @import("Ppu.zig");
const rl = @import("raylib");
const display = @import("Display.zig");

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    var lock: std.Thread.Mutex = .{};

    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{ .mutex = &lock }, .Bus = .{ .mutex = &lock } };
    nes.init();

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    var args = std.process.args();
    var path: ?[]u8 = null;

    while (true) {
        const argument = args.next();
        if (argument == null) {
            break;
        }
        if (std.mem.eql(u8, argument.?, "-p")) {
            const path_arg = args.next();
            path = @constCast(path_arg.?[0..path_arg.?.len]);
        }
    }

    if (path == null) {
        std.debug.print("No Path variable found!\n", .{});
        return;
    }

    std.debug.print("Path: {s}\n", .{path.?});

    const working_directory = std.fs.cwd();

    const ines_file = try working_directory.openFile(path.?, .{});
    defer ines_file.close();

    const rom = try ines_file.readToEndAlloc(allocator, 768000);
    defer allocator.free(rom);

    std.debug.print("Rom Loaded: {d}!\n\n", .{rom.len});

    try nes.Mapper.mapper_init(@constCast(&rom), allocator);
    //program start

    //boostrap sequence
    {
        nes.Cpu.pc -= 1;
        const msb: u16 = nes.Cpu.GetImmediate();
        nes.Cpu.pc += 1;
        const lsb: u16 = nes.Cpu.GetImmediate();

        nes.Bus.addr_bus = msb << 8;
        nes.Bus.addr_bus |= lsb;

        nes.Cpu.pc = nes.Bus.addr_bus;
    }

    {
        var cpu_thread = try std.Thread.spawn(.{}, cpu.Cpu.operate, .{&nes.Cpu});
        defer cpu_thread.join();

        var ppu_thread = try std.Thread.spawn(.{}, ppu.Ppu.operate, .{&nes.Ppu});
        defer ppu_thread.join();

        var display_thread = try std.Thread.spawn(.{}, display.draw, .{&nes.Ppu});
        defer display_thread.join();
    }
    try nes.Mapper.deinit(allocator);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
