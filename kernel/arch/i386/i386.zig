// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: i386.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const root: type = @import("root");

const entry: type = root.entry;
const init: type = root.init;
const interrupts: type = root.interrupts;
const mm: type = root.mm;
const interfaces: type = root.interfaces;
const physio: type = root.physio;

pub const linker: type = @import("linker.zig");
pub const sections: type = @import("sections.zig");

pub const __SaturnArchDescription__: interfaces.arch.ArchDescription_T = .{
    .usable = true,
    .entry = .{
        .maintainer = "Linuxperoxo",
        .label = ".i386.entry",
        .entry = &entry.entry,
    },
    .init = .{
        .maintainer = "Linuxperoxo",
        .label = ".i386.init",
        .entry = &init.init,
    },
    .interrupts = .{
        .maintainer = "Linuxperoxo",
        .label = ".i386.interrupts",
        .entry = &interrupts.idt_init,
    },
    .mm = .{
        .maintainer = "Linuxperoxo",
        .label = ".i386.mm",
        .entry = &mm.mmu_init,
    },
    .physio = .{
        .maintainer = "Linuxperoxo",
        .label = ".i386.physio",
        .entry = &physio.physio_init,
        .sync = &physio.physio_sync,
    },
    .extra = &[_]interfaces.arch.ArchDescription_T.Extra_T {
        .{
            .maintainer = "Linuxperoxo",
            .label = ".i386.gdt",
            .entry = .{
                .naked = &init.gdt.gdt_config,
            },
        },
        .{
            .maintainer = "Linuxperoxo",
            .label = ".i386.idt.csi",
            .entry = .{
                .c = &interrupts.csi.csi_event_install,
            },
        },
        .{
            .maintainer = "Linuxperoxo",
            .label = ".i386.csi.handler",
            .entry = .{
                // podemos fazer esse @ptrCast sem nenhum problema, o kernel
                // nao chama diretamente essa funcao, apenas usa o ponteiro
                // para o @export, entao, nao tem nenhum problema caso seja
                // fn(u32) ou fn(), o unico problema seria se a funcao for
                // chamada por esse ponteiro, nesse caso, poderiamos ter problema
                // por causa da ABI
                .c = @ptrCast(&interrupts.handler.csi_handler),
            },
        },
    },
    .data = &[_]interfaces.arch.ArchDescription_T.Data_T {
        .{
            .label = "gdt_struct",
            .section = sections.section_data_persist,
            .ptr = &init.gdt.gdt_struct,
        },
        .{
            .label = "gdt_entries",
            .section = sections.section_data_persist,
            .ptr = &init.gdt.gdt_entries,
        },
        .{
            .label = "idt_struct",
            .section = sections.section_data_persist,
            .ptr = &interrupts.idt_struct,
        },
        .{
            .label = "idt_entries",
            .section = sections.section_data_persist,
            .ptr = &interrupts.idt_entries,
        },
    },
    .overrider = interfaces.arch.ArchDescription_T.Overrider_T {
        .modules = &[_]interfaces.arch.ArchDescription_T.ModuleOverrider_T {
            .{
                .module = "ke_m_rootfs",
                .value = .yes,
            },
            .{
                .module = "ke_m_devfs",
                .value = .yes,
            },
        },
        .fusioners = null,
    },
    // TODO:
    //
    //.userspace = .{
    //    .maintainer = "Linuxperoxo",
    //    .entry = &userspace.switch_kernel_to_user,
    //}
};

