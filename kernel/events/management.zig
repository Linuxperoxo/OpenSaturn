// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const Event_T: type = @import("types.zig").Event_T;
const EventInput_T: type = @import("types.zig").EventInput_T;
const EventErr_T: type = @import("types.zig").EventErr_T;
const EventNode_T: type = @import("types.zig").EventNode_T;

var bus0: [16]?Event_T = .{};
var bus1: [16]?Event_T = .{};

fn resolvTarget(event: Event_T) *?Event_T {
    return r: {
        const allBus = [_]*[16]Event_T {
            &bus0,
            &bus1,
        };
        break :r allBus[event.bus][event.line];
    };
}

pub fn eventPush(event: Event_T) EventErr_T!void {
    const target: *?Event_T = @call(.always_inline, &resolvTarget, .{
        event
    });
    if(target.*) |_| {
        
    }
    return EventErr_T.Reserved;
}

pub fn eventDrop(event: Event_T) EventErr_T!void {
    const target: *?Event_T = @call(.always_inline, &resolvTarget, .{
        event
    });
    if(target.*) |_| {

    }
    return EventErr_T.NoNFound;
}

