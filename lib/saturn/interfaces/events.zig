// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: events.zig  │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const events: type = @import("root").core.events;

pub const Event_T: type = events.Event_T;
pub const EventErr_T: type = events.EventErr_T;
pub const EventOut_T: type = events.EventOut_T;
pub const EventInput_T: type = events.EventInput_T;
pub const EventDefault_T: type = events.EventDefault_T;
pub const EventListener_T: type = events.EventListener_T;

pub const install_event = events.install_event;
pub const remove_event = events.remove_event;
pub const install_listener_event = events.install_listener_event;
pub const remove_listener_event = events.remove_listener_event;
pub const send_event = events.send_event;
