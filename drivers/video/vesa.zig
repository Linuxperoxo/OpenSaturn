// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vesa.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const VBEModeInfo: type = packed struct {
    mode_attributes: u16,
    win_a_attributes: u8,
    win_b_attributes: u8,
    win_granularity: u16,
    win_size: u16,
    win_a_segment: u16,
    win_b_segment: u16,
    win_func_ptr: u32,
    bytes_per_scan_line: u16,
    x_resolution: u16,
    y_resolution: u16,
    x_char_size: u8,
    y_char_size: u8,
    number_of_planes: u8,
    bits_per_pixel: u8,
    number_of_banks: u8,
    memory_model: u8,
    bank_size: u8,
    number_of_image_pages: u8,
    reserved_page: u8,
    red_mask_size: u8,
    red_mask_pos: u8,
    green_mask_size: u8,
    green_mask_pos: u8,
    blue_mask_size: u8,
    blue_mask_pos: u8,
    reserved_mask_size: u8,
    reserved_mask_pos: u8,
    direct_color_mode_info: u8,

    // NOTE: VBE 2.0 Extensions
    phys_base_ptr: u32,
    off_screen_mem_offset: u32,
    off_screen_mem_size: u16,
};
