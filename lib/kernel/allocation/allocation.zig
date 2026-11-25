// ┌─────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: allocation.zig  │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

pub const sba: type = @import("sba/sba.zig");
pub const soa: type = @import("soa/soa.zig");
pub const bitmap: type = @import("bitmap.zig");

pub const BitmapAllocator: type = @import("bitmap_allocator.zig").BitmapAllocator;
pub const Allocator: type = @import("Allocator.zig");
