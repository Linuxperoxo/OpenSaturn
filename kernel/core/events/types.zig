// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const Event_T: type = struct {
    bus: u2,
    line: u3,
    flags: packed struct(u8) {
        active: u1,
        multi: u1,
        block: u1,
        listeners: u4,
    },
};

pub const EventOut_T: type = struct {
    data: ?usize,
    flags: u16,
};

pub const EventInput_T: type = struct {
    
};

pub const EventDefault_T: type = enum {
    keyboard,
    mouse,
    procs,
    timer,
};

pub const EventErr_T: type = struct {
    
};

pub const EventInfo_T: type = struct {
    event: *Event_T,
    // listeners: ?
};

pub const EventBus_T: type = struct {
    line: [8]?*Event_T = [_]?*Event_T {
        null
    } ** 8,
};
