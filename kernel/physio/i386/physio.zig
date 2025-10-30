// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: physio.zig      │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const tree: type = @import("tree.zig");
const scan: type = @import("scan.zig");
const types: type = @import("types.zig");
const init: type = @import("init.zig");
const sync: type = @import("sync.zig");

pub const PhysIo_T: type = types.PhysIo_T;
pub const PhysIoErr_T: type = types.PhysIo_T;

pub const physio_init = &init.physio_init;
pub const physio_sync = &sync.physio_sync;
pub const physio_search = &tree.physio_search;
