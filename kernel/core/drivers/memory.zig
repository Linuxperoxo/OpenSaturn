// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: memory.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const SOA: type = switch(@import("builtin").is_test) {
    true => @import("test/SOA/SOA.zig"),
    false => @import("root").memory.SOA,
};
pub const totalOfPossibleAllocs: comptime_int = if(@import("builtin").is_test) 64 else r: {
    if(@import("root").config.modules.options.AllowDynamicModulesLoad)
        break :r 64;
    break :r @import("root").modules.countModOfType(.driver);
};
