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

pub const arch_section_text_loader: []const u8 = ".x86.arch.text";
pub const arch_section_data_loader: []const u8 = ".x86.arch.data";

pub const __SaturnArchDescription__: interfaces.arch.ArchDescription_T = .{
    .text = arch_section_text_loader,
    .data = arch_section_data_loader,
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
        //.entry = &interrupts.init,
        .entry = &init.init,
    },
    .mm = .{
        .maintainer = "Linuxperoxo",
        .label = ".x86.mm",
        .entry = &mm.mmu_init,
    },
};

