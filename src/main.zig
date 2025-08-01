const std = @import("std");
const components = @import("nes");
const display = @import("Display.zig");

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    var lock: std.Thread.Mutex = .{};

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    //    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{ .mutex = &lock }, .Bus = .{ .mutex = &lock } };
    //   nes.init();
    var nes = try allocator.create(components.Nes);
    defer allocator.destroy(nes);
    nes.Ppu.mutex = &lock;
    nes.Bus.mutex = &lock;

    nes.init();

    nes.Ppu.bitmap = try allocator.create([240][256]u5);

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

    try ines_file.seekTo(0);

    const rom = try ines_file.readToEndAlloc(allocator, 768000);
    defer allocator.free(rom);

    std.debug.print("Rom Loaded: {d}!\n\n", .{rom.len});

    try nes.Mapper.mapper_init(@constCast(&rom), allocator);
    //program start
    nes.Ppu.nametable_mirroring = nes.Mapper.mirroring;

    //boostrap sequence
    {
        nes.Cpu.pc -= 1;
        const lsb: u16 = nes.Cpu.GetImmediate();

        nes.Cpu.pc += 1;
        const msb: u16 = nes.Cpu.GetImmediate();

        //this is pulling the wrong address
        nes.Bus.addr_bus = msb << 8;
        nes.Bus.addr_bus |= lsb;
        std.debug.print("Initialization Address: 0x{x}\n\n", .{nes.Bus.addr_bus});

        nes.Cpu.pc = nes.Bus.addr_bus;
    }
    //
    var cpu_timer = try std.time.Timer.start();

    //  nes.Cpu.operate();
    {
        //var nes_thread = try std.Thread.spawn(.{}, masterClock, .{ &nes, &cpu_timer });
        //defer nes_thread.join();

        var display_thread = try std.Thread.spawn(.{}, display.draw, .{&nes.Ppu});
        defer display_thread.join();
        try masterClock(nes, &cpu_timer);
    }
    try nes.Mapper.deinit(allocator);
}

pub fn masterClock(nes: *components.Nes, cpu_timer: *std.time.Timer) !void {
    var timer = try std.time.Timer.start();
    while (true) {
        if (nes.Cpu.wait_time < cpu_timer.read()) {
            cpu_timer.reset();
            nes.Cpu.wait_time = 0;
            nes.Cpu.operate();
        }
        if (nes.Cpu.cycles >= 114) {
            timer.reset();
            nes.Ppu.operate();
            const time = timer.read();
            std.debug.print("PPU Scanline Time: {d} ns\n", .{time});
            nes.Cpu.cycles -= 114;
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
