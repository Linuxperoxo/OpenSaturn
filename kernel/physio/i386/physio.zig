// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: physio.zig      │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const tree: type = @import("tree.zig");
const scan: type = @import("scan.zig");
const types: type = @import("types.zig");
const init: type = @import("init.zig");
const sync: type = @import("sync.zig");
const listeners: type = @import("listeners.zig");
const waiting: type = @import("waiting.zig");

pub const PhysIo: type = types.PhysIo;
pub const PhysIoErr: type = types.PhysIoErr;
pub const PhysIoClass: type = types.PhysIoClass;
pub const PhysIoVendor: type = types.PhysIoVendor;

pub const physioInit = init.physioInit;
pub const physioSync = sync.physioSync;
pub const physioSearch = tree.physioSearch;
pub const physioListen = listeners.physioListen;
pub const physioListenDrop = listeners.physioListenDrop;
pub const physioWaitBy = waiting.physioWaitBy;
pub const physioWaitDrop = waiting.physioWaitDrop;
