// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const list: type = @import("root").lib.kernel.linked_list;

pub const Event: type = struct {
    bus: u2,
    line: u3,
    who: u8,
    listener_out: ?*const fn(EventInput) void,
    flags: packed struct {
        control: packed struct {
            active: u1,
            block: u1,
        },
    },
};

pub const EventOut: type = struct {
    data: usize,
    event: u8,
    flags: packed struct {
        data: u1, // with data
        event: u1, // with event
    },
};

pub const EventInput: type = struct {
    sender: u8,
    data: usize,
    flags: u16,
};

pub const EventDefault: type = enum {
    keyboard,
    mouse,
    csi, // cpu software interrupts
    timer,
};

pub const EventErr: type = error {
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

pub const EventListener: type = struct {
    handler: *const fn(EventOut) ?EventInput,
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

pub const EventInfo: type = struct {
    event: *Event,
    listeners: list.buildList(*EventListener),
};

pub const EventBus: type = struct {
    line: [8]?*EventInfo,
};
