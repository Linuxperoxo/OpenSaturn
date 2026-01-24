const interfaces: type = @import("root").interfaces;

const ModuleDescription_T: type = interfaces.module.ModuleDescription_T;
const ModuleDescriptionTarget_T: type = interfaces.module.ModuleDescriptionTarget_T;

pub const __SaturnModuleDescription__: ModuleDescription_T = .{
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
    .arch = &[_]ModuleDescriptionTarget_T {
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

//extern fn c_init() void;

fn init() anyerror!void {
//    c_init();
}
