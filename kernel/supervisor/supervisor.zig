// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: supervisor.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const supervisor_T: type = @import("types.zig").supervisor_T;

pub const supervisorIsrTable = @import("management.zig").supervisorIsrTable;
pub const supervisorHandlerPerIsr = @import("management.zig").supervisorHandlerPerIsr;
