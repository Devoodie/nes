const std = @import("std");
const test_structs = @import("json");
const components = @import("nes");

test "JSON 6502 Tests" {
    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    nes.Mapper.prg_ram = try allocator.alloc(u8, 0x2000);
    defer allocator.free(nes.Mapper.prg_ram);

    nes.Mapper.prg_rom = try allocator.alloc(u8, 0x8000);
    defer allocator.free(nes.Mapper.prg_rom);

    var cwd = std.fs.cwd();

    var test_dir = try cwd.openDir("test/6502_JSON_TESTS", .{ .iterate = true });
    defer test_dir.close();

    var iterator = test_dir.iterate();
    //10M allocated on the heap to avoid stack overflow
    var json_string: []u8 = undefined;
    var iterations: u16 = 0;

    while (try iterator.next()) |kind| {
        //get the json
        iterations += 1;
        std.debug.print("Iterations: {d}\n", .{iterations});
        const filename = kind.name;

        var test_file = try test_dir.openFile(filename, .{});
        try test_file.seekTo(0);
        defer test_file.close();

        json_string = try test_file.readToEndAlloc(allocator, 10000000);
        defer allocator.free(json_string);

        if (!try std.json.validate(allocator, json_string)) {
            std.debug.print("Invalid Json Found!\n", .{});
            break;
        }

        var json = try std.json.parseFromSlice([]test_structs.json_test, allocator, json_string, .{ .ignore_unknown_fields = true });
        defer json.deinit();

        for (json.value) |*case| {
            try std.testing.expect(case.run_test(&nes));
        }
    }
}
