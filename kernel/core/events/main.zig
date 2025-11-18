// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig    │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const aux: type = @import("aux.zig");
const types: type = @import("types.zig");

var event_buses = [_]types.EventBus_T {
    types.EventInfo_T {
        .line = [_]types.EventInfo_T {
            null,
        } ** 8,
    },
} ** 4;

inline fn check_path(bus: u2, line: u3) bool {
    return if(event_buses[bus].line[line] != null) true else false;
}

inline fn ret_event(bus: u2, line: u3) *types.Event_T {
    return event_buses[bus].line[line].?;
}

pub fn install_event(event: *types.Event_T, comptime default: ?types.EventDefault_T) types.EventErr_T!void {
    const bus, const line = if(default != null) aux.default_bus(default) else .{
        event.bus,
        event.line
    };
    if(check_path(bus, line)) return types.EventErr_T.EventCollision;
    
}

pub fn remove_event(event: *types.Event_T) types.EventErr_T!void {
    
}

pub fn listen_event_bus_line(handler: *const fn(types.EventOut_T) types.EventInput_T) types.EventErr_T!void {
    
}
