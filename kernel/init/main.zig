// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const drivers: type = @import("drivers");
const cpu: type = @import("saturn/cpu");

comptime {
    @export(&smain, .{
        .name = "smain",
        .linkage = .strong,
        .visibility = .default,
    });
}

fn smain(_: ?*drivers.video.vesa.VBEModeInfo) callconv(.c) u8 {
    // Inicializando GDT
    @call(.always_inline, &cpu.gdt.load, .{
        cpu.gdt.Pointer { // Struct resolvida em tempo de compilação
            .First = @intFromPtr(&cpu.gdt.Entries[0]),
            .Size = (cpu.gdt.Entries.len * @sizeOf(cpu.gdt.Entry)) - 1,
        }
    });
    // TODO: Configurar PIC
    return 0;
}

