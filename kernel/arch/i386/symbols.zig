// ┌───────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: symbols.zig   │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

// Physical boundaries of the i386 initialization area.
pub const phys_i386_start = @extern(*anyopaque, .{
    .name = "phys_i386_start",
});
pub const phys_i386_text_start = @extern(*anyopaque, .{
    .name = "phys_i386_text_start",
});
pub const phys_i386_text_end = @extern(*anyopaque, .{
    .name = "phys_i386_text_end",
});
pub const phys_i386_data_start = @extern(*anyopaque, .{
    .name = "phys_i386_data_start",
});
pub const phys_i386_data_end = @extern(*anyopaque, .{
    .name = "phys_i386_data_end",
});
pub const phys_i386_end = @extern(*anyopaque, .{
    .name = "phys_i386_end",
});

// Physical boundaries of the OpenSaturn kernel image.
pub const phys_opensaturn_start = @extern(*anyopaque, .{
    .name = "phys_opensaturn_start",
});
pub const phys_opensaturn_text_start = @extern(*anyopaque, .{
    .name = "phys_opensaturn_text_start",
});
pub const phys_opensaturn_text_end = @extern(*anyopaque, .{
    .name = "phys_opensaturn_text_end",
});
pub const phys_opensaturn_data_start = @extern(*anyopaque, .{
    .name = "phys_opensaturn_data_start",
});
pub const phys_opensaturn_data_end = @extern(*anyopaque, .{
    .name = "phys_opensaturn_data_end",
});
pub const phys_opensaturn_rodata_start = @extern(*anyopaque, .{
    .name = "phys_opensaturn_rodata_start",
});
pub const phys_opensaturn_rodata_end = @extern(*anyopaque, .{
    .name = "phys_opensaturn_rodata_end",
});
pub const phys_opensaturn_bss_start = @extern(*anyopaque, .{
    .name = "phys_opensaturn_bss_start",
});
pub const phys_opensaturn_bss_end = @extern(*anyopaque, .{
    .name = "phys_opensaturn_bss_end",
});
pub const phys_opensaturn_mmu_start = @extern(*anyopaque, .{
    .name = "phys_opensaturn_mmu_start",
});
pub const phys_opensaturn_mmu_end = @extern(*anyopaque, .{
    .name = "phys_opensaturn_mmu_end",
});
pub const phys_opensaturn_end = @extern(*anyopaque, .{
    .name = "phys_opensaturn_end",
});
pub const phys_opensaturn_kernel_zone_start = @extern(*anyopaque, .{
    .name = "phys_opensaturn_kernel_zone_start",
});
