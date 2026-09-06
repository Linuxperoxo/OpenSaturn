// ┌────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: int.zig    │
// │            Author: Linuxperoxo             │
// └────────────────────────────────────────────┘

pub inline fn cli() void {
    asm volatile(
        \\ cli
    );
}

pub inline fn sti() void {
    asm volatile(
        \\ sti
    );
}
