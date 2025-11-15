// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: memory.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const SOA: type = switch(@import("builtin").is_test) {
    true => @import("test/SOA/SOA.zig"),
    false => @import("root").memory.SOA,
};
pub const totalOfPossibleAllocs: comptime_int = if(@import("builtin").is_test) totalInBits else r: {
    if(@import("root").config.modules.options.AllowDynamicModulesLoad)
        break :r totalInBits;
    break :r @import("root").modules.countModOfType(.driver);
};
pub const totalInBits: comptime_int = r: {
    var max: usize = 1;
    for(0..@bitSizeOf(@import("types.zig").MajorNum_T)) |_| {
        max *= 2;
    }
    break :r max;
};
