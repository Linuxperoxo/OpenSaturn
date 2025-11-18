// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig    │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const types: type = @import("types.zig");

pub fn install_event(event: *types.Event_T, comptime default: ?types.EventDefault_T) types.EventErr_T!void {
    
}

pub fn remove_event(event: *types.Event_T) types.EventErr_T!void {
    
}

pub fn listen_event_bus_line(handler: *const fn(types.EventOut_T) types.EventInput_T) types.EventErr_T!void {
    
}
