// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: linker.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// arch section
pub const phys_i386_start = @extern(*anyopaque, .{
    .name = "phys_i386_start",
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

// opensaturn section
pub const phys_address_opensaturn_start = @extern(*anyopaque, .{
    .name = "phys_address_opensaturn_start",
});
pub const phys_address_opensaturn_text_start = @extern(*anyopaque, .{
    .name = "phys_address_opensaturn_text_start",
});
pub const phys_address_opensaturn_text_end = @extern(*anyopaque, .{
    .name = "phys_address_opensaturn_text_end",
});
pub const phys_address_opensaturn_data_start = @extern(*anyopaque, .{
    .name = "phys_address_opensaturn_data_start",
});
pub const phys_address_opensaturn_data_end = @extern(*anyopaque, .{
    .name = "phys_address_opensaturn_data_end",
});
pub const phys_address_opensaturn_rodata_start = @extern(*anyopaque, .{
    .name = "phys_address_opensaturn_rodata_start",
});
pub const phys_address_opensaturn_rodata_end = @extern(*anyopaque, .{
    .name = "phys_address_opensaturn_rodata_end",
});
pub const phys_address_opensaturn_end = @extern(*anyopaque, .{
    .name = "phys_address_opensaturn_end",
});


