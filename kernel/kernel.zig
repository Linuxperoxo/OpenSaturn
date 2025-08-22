// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: kernel.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const arch: type = @import("saturn/arch");
pub const core: type = @import("saturn/kernel/core");
pub const exported: type = @import("saturn/kernel/exported");
pub const memory: type = @import("saturn/kernel/memory");
pub const interfaces: type = @import("saturn/kernel/modules/interfaces");
pub const debug: type = @import("saturn/kernel/debug");
pub const supervisor: type = @import("saturn/kernel/supervisor");
pub const interrupts: type = @import("saturn/kernel/interrupts");
pub const kernel: type = @import("saturn/kernel/lib"); // Possibly obsolete in the future
pub const userspace: type = @import("saturn/userspace/lib");
pub const config: type = @import("saturn/kernel/config");
pub const modules: type = @import("saturn/kernel/modules");

const loader: type = @import("saturn/kernel/loader");

export fn init() void {
    @call(.never_inline, &arch.__SaturnEnabledArch__.init, .{});
    @call(.never_inline, &loader.loadInterrupts, .{});
}

export fn main() void {
    @call(.always_inline, &init, .{});
    @call(.always_inline, &loader.loadModules, .{});
}
