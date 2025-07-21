// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: kernel.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const core: type = @import("saturn/kernel/core");
pub const interfaces: type = @import("saturn/lib/interfaces");
pub const io: type = @import("saturn/lib/io");
pub const memory: type = @import("saturn/kernel/memory");

pub const modules: type = @import("saturn/modules");

pub const debug: type = @import("saturn/debug");

pub const arch: type = @import("saturn/arch").__SaturnEnabledArch__;

comptime {
    if(@import("builtin").mode == .Debug)
        @compileError("-O Debug is blocked, use -O Releasesmall or -O ReleaseFast");
}

export fn init() void {
    @call(.never_inline, arch.init, .{});
}

export fn main() void {
    @call(.always_inline, &init, .{});
    @call(.always_inline, &modules.callLinkableMods, .{});
}
