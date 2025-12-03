// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: csi.zig     │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const events: type = @import("root").core.events;
const config: type = @import("root").config;

pub var csi_event: events.Event_T = .{
    .bus = config.kernel.options.csi_event.bus,
    .line = config.kernel.options.csi_event.line,
    .who = config.kernel.options.csi_event.who,
    .flags = .{
        .control = .{
            .active = 0,
            .block = 0,
        },
    },
    .listener_out = null,
};

// idt_event is a virtual address
pub fn csi_event_install() callconv(.c) void {
    @call(.never_inline, events.install_event, .{
        &csi_event, events.EventDefault_T.csi
    }) catch {
        // KLOG: this is a kernel panic!
    };
}
