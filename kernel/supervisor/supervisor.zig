// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: supervisor.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const supervisor_T: type = @import("interfaces.zig").supervisor_T;
pub const initSupervisor_T: type = @import("interfaces.zig").initSupervisor_T;

const handler: type = @import("handler.zig");

pub fn init(comptime ISR: anytype, T: type) T {
    const isr: @TypeOf(ISR) = ISR;
    var aloneHandler: T = undefined;
    for(0..isr.len) |i| {
        switch(isr[i].type) {
            .exception => {
                aloneHandler[i] = &(struct {
                    pub fn exception() noreturn {
                        @call(.never_inline, &handler.exception, .{i});
                        unreachable;
                    }
                }.exception);
            },
            .syscall => {
                aloneHandler[i] = &(struct {
                    pub fn syscall() noreturn {
                        @call(.never_inline, &handler.syscall, .{i});
                        unreachable;
                    }
                }.syscall);
            },
            .irq => {
                aloneHandler[i] = &(struct {
                    pub fn irq() noreturn {
                        @call(.never_inline, &handler.irq, .{i});
                        unreachable;
                    }
                }.irq);
            },
            .none => continue,
        }
    }
    return aloneHandler;
}
