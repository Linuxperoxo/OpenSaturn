// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: x86.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const root: type = @import("root");

const entry: type = root.entry;
const init: type = root.init;
const interrupts: type = root.interrupts;
const mm: type = root.mm;
const interfaces: type = root.interfaces;

pub const linker: type = @import("linker.zig");
pub const sections: type = @import("sections.zig");

pub const __SaturnArchDescription__: interfaces.arch.ArchDescription_T = .{
    .usable = true,
    .entry = .{
        .maintainer = "Linuxperoxo",
        .label = ".x86.entry",
        .entry = &entry.entry,
    },
    .init = .{
        .maintainer = "Linuxperoxo",
        .label = ".x86.init",
        .entry = &init.init,
    },
    .interrupts = .{
        .maintainer = "Linuxperoxo",
        .label = ".x86.interrupts",
        .entry = &interrupts.idt_init,
    },
    .mm = .{
        .maintainer = "Linuxperoxo",
        .label = ".x86.mm",
        .entry = &mm.mmu_init,
    },
    // TODO:
    //
    //.userspace = .{
    //    .maintainer = "Linuxperoxo",
    //    .entry = &userspace.switch_kernel_to_user,
    //}
};

