// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: c_types.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const utils: type = @cImport({
    @cInclude("saturn/kernel/utils/int.h");
    @cInclude("saturn/kernel/utils/err.h");
});

pub const interfaces: type = @cImport({
    @cInclude("saturn/interfaces/module.h");
});

