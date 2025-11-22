// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: options.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const kernel_page_size: u32 = 0x1000;
pub const kernel_stack_size: u32 = kernel_page_size * 1;
pub const keyboard_event: struct { bus: u2, line: u3 } = .{ .bus = 0, .line = 7 };
pub const mouse_event: struct { bus: u2, line: u3 } = .{ .bus = 1, .line = 7 };
pub const csi_event: struct { bus: u2, line: u3 } = .{ .bus = 2, .line = 7 };
pub const timer_event: struct { bus: u2, line: u3 } = .{ .bus = 3, .line = 7 };
