// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// modificar o campo data da lista, ele pode receber
// ponteiros quando struct brutas, isso vai tirar
// a alocacao dinamica para data

const list: type = @import("root").kernel.utils.list;

pub const Event_T: type = struct {
    bus: u2,
    line: u3,
    flags: packed struct(u8) {
        active: u1,
        block: u1,
        listeners: u4,
        reserved: u2 = 0,
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
    csi, // cpu software interrupts
    timer,
};

pub const EventErr_T: type = error {
    EventCollision,
    NoNEvent,
    BlockedEvent,
};

pub const EventListener_T: type = struct {
    handler: *const fn(EventOut_T) EventInput_T,
    flags: packed struct(u8) {
        satisfied: u1,
    },
};

pub const EventInfo_T: type = struct {
    event: *Event_T,
    // aqui deve ser ponteiro, ja que quem e responsavel
    // pelo proprio EventListener_T e quem esta escutando
    listeners: list.BuildList(*EventListener_T),
};

pub const EventBus_T: type = struct {
    line: [8]?*EventInfo_T,
};
