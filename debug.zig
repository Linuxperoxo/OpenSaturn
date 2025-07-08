// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: debug.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// NOTE: Esse arquivo serve apenas para ajudar no debug do kernel
// NOTE: Atualmente apenas suporte para debug no x86
// NOTE: Para usar o debug use -O ReleaseSmall

pub const builtin: type = @import("builtin");

pub const RegDebug: type = enum(u2) {
    eax,
    ecx,
    edx,
    ebx,
};

const DebugAsm = "jmp .";

// TODO: Adicionar suporte a multiplos reg para debug
pub inline fn breakpoint(A: anytype, comptime R: RegDebug) void {
    if(builtin.mode != .ReleaseSmall)
        return;
    switch(@typeInfo(@TypeOf(A))) {
        .@"struct" => |S| {
            if(S.fields.len == 0) {
                asm volatile(DebugAsm :::);
            }
        },
        else => {},
    }
    switch(R) {
        .eax => asm volatile(DebugAsm ::[_] "{eax}" (A):),
        .ebx => asm volatile(DebugAsm ::[_] "{ebx}" (A):),
        .ecx => asm volatile(DebugAsm ::[_] "{ecx}" (A):),
        .edx => asm volatile(DebugAsm ::[_] "{edx}" (A):),
    }
    unreachable;
}
