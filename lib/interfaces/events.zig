// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: events.zig  │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const events: type = @import("root").core.events;

pub const Event: type = events.Event;
pub const EventErr: type = events.EventErr;
pub const EventOut: type = events.EventOut;
pub const EventInput: type = events.EventInput;
pub const EventDefault: type = events.EventDefault;
pub const EventListener: type = events.EventListener;

pub const installEvent = events.installEvent;
pub const removeEvent = events.removeEvent;
pub const installListener = events.installListener;
pub const removeListener = events.removeListener;
pub const sendEvent = events.sendEvent;
