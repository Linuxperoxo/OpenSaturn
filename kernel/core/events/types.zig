// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const list: type = if(!builtin.is_test) @import("root").kernel.utils.list else @import("test/list.zig");

pub const Event_T: type = struct {
    bus: u2,
    line: u3,
    listener_out: ?*const fn(EventInput_T) void,
    flags: packed struct(u8) {
        control: packed struct(u2) {
            active: u1,
            block: u1,
        },
        reserved: u6 = 0,
    },
};

pub const EventOut_T: type = struct {
    sender: u8 = 0, // TODO:
    data: ?usize,
    extra: u16,
};

pub const EventInput_T: type = struct {
    
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
    BlockedEvent,
    ListenerInteratorFailed,
    FreeEventFailed,
    NoNListenerInstall,
    IteratorForceExit,
    RemoveListenerInternalError,
    AllocFailed,
};

pub const EventListener_T: type = struct {
    handler: *const fn(EventOut_T) EventInput_T,
    who: u8, // TODO:
    flags: packed struct(u8) {
        // flags change the way the listener works (RW)
        control: packed struct(u2) {
            satisfied: u1,
            listen: u1,
        },
        // flags changed by the event (READY ONLY FLAGS!)
        internal: packed struct(u1) {
            link: u1,
        },
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
