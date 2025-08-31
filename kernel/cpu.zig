// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: cpu.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const config: type = @import("root").config;
const entries: type = @import("root").entries;
const supported: type = @import("root").supported;
const interrupts: type = @import("root").interrupts;

// Nesses arquivos relacionado a arquitetura, decidi
// usar um [_]type para deixar mais claro o que esta
// acontecendo

pub const Arch: type = switch(config.arch.options.Target) {
    .x86 => supported.ArchSupports[0],
    .x86_64 => supported.ArchSupports[1],
    .arm => supported.ArchSupports[2],
    .avr => supported.ArchSupports[3],
    .xtensa => supported.ArchSupports[4],
};
pub const Entry: type = switch(config.arch.options.Target) {
    .x86 => entries.ArchEntries[0],
    .x86_64 => entries.ArchEntries[1],
    .arm => entries.ArchEntries[2],
    .avr => entries.ArchEntries[3],
    .xtensa => entries.ArchEntries[4],
};
pub const Interrupt: type = switch(config.arch.options.Target) {
    .x86 => interrupts.ArchInterrupts[0],
    .x86_64 => interrupts.ArchInterrupts[1],
    .arm => interrupts.ArchInterrupts[2],
    .avr => interrupts.ArchInterrupts[3],
    .xtensa => interrupts.ArchInterrupts[4],
};
