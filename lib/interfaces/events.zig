// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: events.zig  │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const events: type = @import("root").core.events;

pub const Event: type = events.Event_T;
pub const EventErr: type = events.EventErr_T;
pub const EventOut: type = events.EventOut_T;
pub const EventInput: type = events.EventInput_T;
pub const EventDefault: type = events.EventDefault_T;
pub const EventListener: type = events.EventListener_T;

pub const installEvent = events.install_event;
pub const removeEvent = events.remove_event;
pub const installListener = events.install_listener_event;
pub const removeListener = events.remove_listener_event;
pub const sendEvent = events.send_event;
