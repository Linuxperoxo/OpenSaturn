// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const drivers: type = @import("saturn/drivers");
pub const cpu: type = @import("saturn/cpu");
pub const libsat: type = @import("saturn/lib");
pub const devices: type = @import("saturn/devices");

pub const video: type = drivers.video;

comptime {
    @export(&smain, .{
        .name = "smain",
        .linkage = .strong,
        .visibility = .default,
    });
}

fn smain() callconv(.c) u8 {
    // Inicializando GDT
    @call(.always_inline, &cpu.gdt.load, .{
        cpu.gdt.Pointer { // Struct resolvida em tempo de compilação
            .Limit = (cpu.gdt.Entries.len * @sizeOf(cpu.gdt.Entry)) - 1,
            .First = @intFromPtr(&cpu.gdt.Entries[0]),
        }
    });

    _ = devices.video.videoDevice.deviceDriver.IOctrl.write(drivers.DriverCommand { 
        .command = @as(u8, @intFromEnum(video.VideoCommand.@"write")),
        .args = @constCast(&[_:0]u8{'H', 'e', 'l', 'l', 'o',',', ' ', 'W', 'o', 'r', 'l', 'd', '!'}),
    });

    // FIXME: Por algum motivo isso não está funcionando, alguma interrupção de
    //        software está ocorrendo, acredito que o bootloader não está carregando
    //        o binário totalmente

    //_ = devices.video.videoDevice.deviceDriver.IOctrl.write(drivers.DriverCommand {
    //    .command = @as(u8, @intFromEnum(video.VideoCommand.@"clear")),
    //});

    // TODO: Configurar PIC
    //
    return 0;
}

