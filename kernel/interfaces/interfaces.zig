// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: interfaces.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

// Interfaces internas usadas pelo próprio kernel

pub const drivers: type = @import("drivers/drivers.zig");
pub const filesystem: type = @import("filesystem/filesystem.zig");
pub const interrupts: type = @import("interrupts/interrupts.zig");
pub const irq: type = @import("irq/irq.zig");
pub const syscall: type = @import("syscall/syscall.zig");
