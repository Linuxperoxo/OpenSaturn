// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const drivers: type = @import("drivers");

fn smain(_: ?*drivers.video.vesa.VBEModeInfo) callconv(.c) u8 {
    var vga: drivers.video.vga.VgaState = .{};

    vga.Framebuffer.ptr = @ptrFromInt(0xb8000);
    vga.Framebuffer.len = comptime 80 * 25;

    vga.write('H');
    return 0;
} 

comptime {
    @export(&smain, 
        .{
            .name = "smain",
            .linkage = .strong,
            .visibility = .default,
        }
    );
}
