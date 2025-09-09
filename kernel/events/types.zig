// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Interfaces
pub const Event_T: type = struct {
    handler: ?*const fn(EventInput_T) EventErr_T!void,
    bus: u1,
    line: u4,
};

pub const EventInput_T: type = struct {
    scan: u16,
    flag: u16,
    critical: bool,
};

pub const EventErr_T: type = error {
    NoNFound,
    Reserved,
};

// Internal
pub const EventNode_T: type = struct {
    self: ?Event_T = null,
    next: ?*EventNode_T = null,
    flag: enum {
        sleeping,
        listening,
        unreliable,
    } = .unreliable,
};


