const interfaces: type = @import("root").interfaces;

const ModuleDescription: type = interfaces.module.ModuleDescription;
const ModuleDescriptionTarget: type = interfaces.module.ModuleDescriptionTarget;

pub const __SaturnModuleDescription__: ModuleDescription = .{
    .name = "ke_m_rootfs",
    .load = .linkable,
    .init = &init,
    .after = null,
    .deps = null,
    .type = .{
        .filesystem = .{
            .compile = .{
                .name = "rootfs",
                .mountpoint = "/",
            },
        }
    },
    .arch = &[_]ModuleDescriptionTarget {
        .i386,
        .amd64,
        .arm,
        .avr,
        .riscv64,
        .xtensa,
    },
    .flags = .{
        .call = .{
            .handler = 0,
            .after = 0,
        },
    },
    .libs = .{
        .mines = null,
        .outside = null,
    },
};

//extern fn cInit() void;

fn init() anyerror!void {
//    cInit();
}
