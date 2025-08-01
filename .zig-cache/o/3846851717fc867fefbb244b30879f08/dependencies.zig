pub const packages = struct {
    pub const @"122098b9174895f9708bc824b0f9e550c401892c40a900006459acf2cbf78acd99bb" = struct {
        pub const available = false;
    };
    pub const @"1220ce6e40b454766d901ac4a19b2408f84365fcad4e4840c788b59f34a0ed698883" = struct {
        pub const build_root = "/home/devooty/.cache/zig/p/N-V-__8AAPTSUgDObkC0VHZtkBrEoZskCPhDZfytTkhAx4i1";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"1220e8fe9509f0843e5e22326300ca415c27afbfbba3992f3c3184d71613540b5564" = struct {
        pub const available = false;
    };
    pub const @"1220f6aef0d678ba6e3d67a60069b5f32dc965a930c797f463840d224759d615b864" = struct {
        pub const build_root = "/home/devooty/.cache/zig/p/raylib-5.5.0-AAAAAFuxzAD2rvDWeLpuPWemAGm18y3JZakwx5f0Y4QN";
        pub const build_zig = @import("1220f6aef0d678ba6e3d67a60069b5f32dc965a930c797f463840d224759d615b864");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "xcode_frameworks", "122098b9174895f9708bc824b0f9e550c401892c40a900006459acf2cbf78acd99bb" },
            .{ "emsdk", "1220e8fe9509f0843e5e22326300ca415c27afbfbba3992f3c3184d71613540b5564" },
        };
    };
    pub const @"raylib_zig-5.6.0-dev-KE8RELUtBQD9ynf9BONdwukHlR4Ib8k_hZZUkqUPO7uJ" = struct {
        pub const build_root = "/home/devooty/.cache/zig/p/raylib_zig-5.6.0-dev-KE8RELUtBQD9ynf9BONdwukHlR4Ib8k_hZZUkqUPO7uJ";
        pub const build_zig = @import("raylib_zig-5.6.0-dev-KE8RELUtBQD9ynf9BONdwukHlR4Ib8k_hZZUkqUPO7uJ");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "raylib", "1220f6aef0d678ba6e3d67a60069b5f32dc965a930c797f463840d224759d615b864" },
            .{ "raygui", "1220ce6e40b454766d901ac4a19b2408f84365fcad4e4840c788b59f34a0ed698883" },
        };
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "raylib_zig", "raylib_zig-5.6.0-dev-KE8RELUtBQD9ynf9BONdwukHlR4Ib8k_hZZUkqUPO7uJ" },
};
