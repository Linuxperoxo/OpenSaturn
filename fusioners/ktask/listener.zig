// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: listener.zig    │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const events: type = @import("root").interfaces.events;
const config: type = @import("root").config;
const sched: type = @import("sched.zig");

pub var listener: events.EventListener = .{
    .listening = config.kernel.options.timer_event.who,
    .event = 0, // para timer temos apenas o evento 0
    .handler = &opaque {
        pub fn handler(_: events.EventOut) ?events.EventInput {
            @call(.always_inline, sched.schedRun, .{
                null
            });
            return null;
        }
    }.handler,
    .flags = .{
        .control = .{
            .all = 1, // opcional
            .satisfied = 0,
        },
    },
};

pub fn ktaskInstallListener() anyerror!void {
    errdefer {
        // klog()
    }
    try events.installListener(&listener, .{
        .default = .timer,
    });
}

pub inline fn ktaskEnable() void {
    listener.flags.control = .{
        .all = 1,
        .satisfied = 0,
    };
}

pub inline fn ktaskDisable() void {
    listener.flags.control = .{
        .all = 0,
        .satisfied = 1,
    };
}
