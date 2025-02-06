const std = @import("std");
const test_structs = @import("json");
const components = @import("nes");

test "JSON 6502 Tests" {
    const name_slices = []const u8;
    const unused_instructions = [_]name_slices{ "03.json", "07.json", "0b.json", "0f.json", "13.json", "17.json", "1b.json", "1f.json", "23.json", "27.json", "2b.json", "2f.json", "33.json", "37.json", "3b.json", "3f.json", "43.json", "47.json", "4b.json", "4f.json", "53.json", "57.json", "5b.json", "5f.json", "63.json", "67.json", "6b.json", "6f.json", "73.json", "77.json", "7b.json", "7f.json", "83.json", "87.json", "8b.json", "8f.json", "93.json", "97.json", "9b.json", "9f.json", "a3.json", "a7.json", "ab.json", "af.json", "b3.json", "b7.json", "bb.json", "bf.json", "c3.json", "c7.json", "cb.json", "cf.json", "d3.json", "d7.json", "db.json", "df.json", "e3.json", "e7.json", "eb.json", "ef.json", "f3.json", "f7.json", "fb.json", "ff.json", "18.json", "9c.json", "9e.json" };

    var nes: components.Nes = .{ .Cpu = .{}, .Ppu = .{}, .Bus = .{} };

    nes.init();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    nes.Bus.isTest = true;
    nes.Bus.test_ram = try allocator.alloc(u8, 65536);
    defer allocator.free(nes.Bus.test_ram);

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

    outer: while (try iterator.next()) |kind| {
        //get the json
        iterations += 1;
        std.debug.print("Iterations: {d}\n", .{iterations});
        const filename = kind.name;

        for (unused_instructions) |name| {
            if (std.mem.eql(u8, filename, name)) continue :outer;
        }

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
