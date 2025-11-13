// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: atlas.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const config: type = @import("root").config;

pub const atlas_load_dest: u32 = config.kernel.mem.phys.kernel_phys;
pub const atlas_vmode: u32 = 0x1000;
pub const atlas_flags: u32 = 0b00000011;
