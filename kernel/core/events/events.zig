// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: events.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const main: type = @import("main.zig");

pub const Event: type = types.Event;
pub const EventErr: type = types.EventErr;
pub const EventOut: type = types.EventOut;
pub const EventInput: type = types.EventInput;
pub const EventDefault: type = types.EventDefault;
pub const EventListener: type = types.EventListener;

pub const installEvent = main.installEvent;
pub const removeEvent = main.removeEvent;
pub const installListener = main.installListener;
pub const removeListener = main.removeListener;
pub const sendEvent= main.sendEvent;
