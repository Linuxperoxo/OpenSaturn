// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: kparam.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const kparam_enable: bool = true;
pub const kparam_dynamic_loader: bool = false;
pub const kernel_parameter: []const u8 =
    \\ sys.kernel.verbose_boot=yes
    \\ modsys.tty.buffers=yes
;
