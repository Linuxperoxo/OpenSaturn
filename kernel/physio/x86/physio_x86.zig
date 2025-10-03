// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: x86_physio.zig  │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const core: type = @import("core.zig");
const scan: type = @import("scan.zig");

const physIo_T: type = @import("root").interfaces.arch.physIo_T;

pub const fun: type = @import("fun.zig");
pub const types: type = struct {
    pub const PhysIo_T: type = @import("types.zig").PhysIo_T;
    pub const PhysIoErr_T: type = @import("types.zig").PhysIoErr_T;
};

pub const __SaturnPhysIo__: physIo_T = .{
    .maintainer = "Linuxperoxo",
    .entry = &scan.physIoScan,
    .sync = &core.physIoSync,
};
