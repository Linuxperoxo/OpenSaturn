// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: supervisor.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const Supervisor: type = @import("types.zig").Supervisor;

pub const supervisor_isr_table = @import("management.zig").supervisorIsrTable;
pub const supervisor_handler_per_isr = @import("management.zig").supervisorHandlerPerIsr;
