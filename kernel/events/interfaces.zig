// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interfaces.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const Event_T: type = @import("types.zig").Event_T;
pub const EventInput_T: type = @import("types.zig").EventInput_T;
pub const EventErr_T: type = @import("types.zig").EventErr_T;

pub const eventPush: fn(Event_T) EventErr_T!void = undefined;
pub const eventDrop: fn(Event_T) EventErr_T!void = undefined;

