// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: options.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");

pub const kernel_page_size: u32 = 0x1000;
pub const kernel_stack_size: u32 = kernel_page_size * 1;
pub const keyboard_event: types.EventDefaultInstall_T = .{ .bus = 0, .line = 7, .who = 16 };
pub const mouse_event: types.EventDefaultInstall_T = .{ .bus = 1, .line = 7, .who = 32 };
pub const csi_event: types.EventDefaultInstall_T = .{ .bus = 2, .line = 7, .who = 64};
pub const timer_event: types.EventDefaultInstall_T = .{ .bus = 3, .line = 7, .who = 128};
pub const kparam_enable: bool = true;
pub const kparam_dynamic: bool = false;
pub const kparam_config_file: ?[]const u8 = null; // default ".kparam.config";
