// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const PhysIoSaturnRef_T: type = struct {
    did: usize,
    state: PhysIoSaturnRefState_T,
    private: *anyopaque,
};

pub const PhysIoSaturnRefState_T: type = enum {
    missing,
    active,
    blocked,
};
