// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: cpu.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const gdt: type = @import("gdt.zig");
pub const apic: type = @import("apic.zig");
//pub const pic: type = @import("pic.zig");
pub const msr: type = @import("msr.zig");

