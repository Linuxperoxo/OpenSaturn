// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: listener.zig    │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const events: type = @import("root").interfaces.events;
const config: type = @import("root").config;
const sched: type = @import("sched.zig");

pub var listener: events.EventListener_T = .{
    .listening = config.kernel.options.timer_event.who,
    .event = 0, // para timer temos apenas o evento 0
    .handler = &opaque {
        pub fn handler(_: events.EventOut_T) ?events.EventInput_T {
            @call(.always_inline, sched.sched_run, .{});
            return null;
        }
    },
    .flags = .{
        .control = .{
            .all = 1, // opcional
            .satisfied = 0,
        },
    },
};

pub fn ktask_install_listener() anyerror!void {
    errdefer {
        // klog()
    }
    try @call(.never_inline, events.install_listener_event, .{
        &listener,
        .{ .default = .timer }
    });
}

pub inline fn ktask_enable() void {
    listener.flags.control = .{
        .all = 1,
        .satisfied = 0,
    };
}

pub inline fn ktask_disable() void {
    listener.flags.control = .{
        .all = 0,
        .satisfied = 1,
    };
}
