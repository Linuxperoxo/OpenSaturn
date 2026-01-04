// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig     │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const types: type = @import("types.zig");
const config: type = @import("root").config;
const main: type = @import("main.zig");

pub inline fn default_bus(comptime default: types.EventDefault_T) struct { u2, u3 } {
    return switch(comptime default) {
        .keyboard => .{
            config.kernel.options.keyboard_event.bus,
            config.kernel.options.keyboard_event.line,
        },
        .mouse => .{
            config.kernel.options.mouse_event.bus,
            config.kernel.options.mouse_event.line,
        },
        .csi => .{
            config.kernel.options.csi_event.bus,
            config.kernel.options.csi_event.line,
        },
        .timer => .{
            config.kernel.options.timer_event.bus,
            config.kernel.options.timer_event.line,
        }
    };
}

pub inline fn check_path(bus: u2, line: u3) bool {
    return if(main.event_buses[bus].line[line] != null) true else false;
}

pub inline fn ret_event(bus: u2, line: u3) *types.EventInfo_T {
    return main.event_buses[bus].line[line].?;
}
