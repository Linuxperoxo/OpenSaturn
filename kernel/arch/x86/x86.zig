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

pub const __SaturnArchDescription__: interfaces.arch.ArchDesc_T = .{
    .section = ".x86.arch.init",
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
        .entry = &interrupts.init,
    },
    .mm = .{
        .maintainer = "Linuxperoxo",
        .label = ".x86.mm",
        .entry = &mm.mmu_init,
    },
};

