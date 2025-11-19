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

inline fn ret_event(bus: u2, line: u3) *types.EventInfo_T {
    return event_buses[bus].line[line];
}

pub fn install_event(event: *types.Event_T, comptime default: ?types.EventDefault_T) types.EventErr_T!void {
    const bus, const line = if(default != null) aux.default_bus(default) else .{
        event.bus,
        event.line
    };
    if(check_path(bus, line)) return types.EventErr_T.EventCollision;
    
}

pub fn send_event(event: *types.Event_T, out: types.EventOut_T) types.EventErr_T!void {
    if(!check_path(event.bus, event.line)) return types.EventErr_T.NoNEvent;
    const event_info = ret_event(event.bus, event.line);
    while(event_info.listeners.interator()) |listener| {
         listener.handler(out);
    } else |err| {
        switch(err) {
            @TypeOf(event_info.listeners).ListErr_T.EndOfInterator => {},
            else => return types.EventErr_T.
        }
    }
}

pub fn remove_event(event: *types.Event_T) types.EventErr_T!void {
    
}

pub fn listen_event(listener: *types.EventListener_T) types.EventErr_T!void {
    
}
