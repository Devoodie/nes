const std = @import("std");

pub fn cycle(prev_time: *i128) void {
    const cur_time = std.time.nanoTimestamp();
    const difference = cur_time - prev_time.*;

    if (difference < 559) {
        std.time.sleep(559 - difference);
    }
    prev_time.* = std.time.nanoTimestamp();
}

pub fn add() void {}
