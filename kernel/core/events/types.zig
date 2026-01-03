// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const list: type = if(!builtin.is_test) @import("root").kernel.utils.list else @import("test/list.zig");

pub const Event_T: type = struct {
    bus: u2,
    line: u3,
    who: u8,
    listener_out: ?*const fn(EventInput_T) void,
    flags: packed struct {
        control: packed struct {
            active: u1,
            block: u1,
        },
    },
};

pub const EventOut_T: type = struct {
    data: usize,
    event: u8,
    flags: packed struct {
        data: u1, // with data
        event: u1, // with event
    },
};

pub const EventInput_T: type = struct {
    sender: u8,
    data: usize,
    flags: u16,
};

pub const EventDefault_T: type = enum {
    keyboard,
    mouse,
    csi, // cpu software interrupts
    timer,
};

pub const EventErr_T: type = error {
    EventCollision,
    NoNEvent,
    InactiveEvent,
    ListenerInteratorFailed,
    FreeEventFailed,
    NoNListenerInstall,
    IteratorForceExit,
    DropListFailed,
    RemoveListenerInternalError,
    AllocFailed,
    ListInitFailed,
    DisableEvent,
};

pub const EventListener_T: type = struct {
    handler: *const fn(EventOut_T) ?EventInput_T,
    listening: u8,
    event: u8,
    flags: packed struct(u8) {
        control: packed struct {
            // flags change the way the listener works (RW)
            satisfied: u1,
            all: u1
        },
        internal: packed struct {
            // flags changed by the event (READY ONLY FLAGS!)
            listen: u1 = 0,
        } = .{},
        reserved: u5 = 0,
    },
};

pub const EventInfo_T: type = struct {
    event: *Event_T,
    listeners: list.BuildList(*EventListener_T),
};

pub const EventBus_T: type = struct {
    line: [8]?*EventInfo_T,
};
