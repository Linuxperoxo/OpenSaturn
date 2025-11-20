// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: events.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const main: type = @import("main.zig");

pub const Event_T: type = types.Event_T;
pub const EventErr_T: type = types.EventErr_T;
pub const EventOut_T: type = types.EventOut_T;
pub const EventInput_T: type = types.EventInput_T;
pub const EventDefault_T: type = types.EventDefault_T;
pub const EventListener_T: type = types.EventListener_T;

pub const install_event = main.install_event;
pub const remove_event = main.remove_event;
pub const install_listener_event = main.install_listener_event;
pub const remove_listener_event = main.remove_listener_event;
pub const send_event = main.send_event;
