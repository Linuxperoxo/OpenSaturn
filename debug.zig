// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: debug.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// NOTE: Esse arquivo serve apenas para ajudar no debug do kernel
// NOTE: Atualmente apenas suporte para debug no x86
// NOTE: Para usar o debug use -O ReleaseSmall

pub const builtin: type = @import("builtin");

pub const RegDebug_x86_64: type = enum(u2) {
    rax,
    rcx,
    rdx,
    rbx,
    r8,
    r9,
    r10,
    r11,
    r12,
    r13,
    r14,
    r15,
};

const ArchBreakPoint: type = struct {
    pub const Archs: type = enum {
        x86,
        x86_64,
        arm,
    };

    const ArchsTypes: type = struct {
        pub const x86: type = struct {
            pub const Regs: type = enum {
                eax,
                ecx,
                edx,
                ebx,
            };

            const DebugAsm = "jmp .";

            pub inline fn breakpoint(A: anytype, comptime R: Regs) void {
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
            }
        };

        pub const x86_64: type = struct {
            pub const Regs: type = enum {
                rax,
                rcx,
                rdx,
                rbx,
                r8,
                r9,
                r10,
                r11,
                r12,
                r13,
                r14,
                r15,
            };

            pub inline fn breakpoint(_: anytype, comptime _: Regs) void {
                @compileError("breakpoint for x86_64 not implemented yet");
            }
        };

        pub const arm: type = struct {
            pub const Regs: type = enum {

            };

            pub inline fn breakpoint(_: anytype, comptime _: Regs) void {
                @compileError("breakpoint for arm not implemented yet");
            }
        };
    };

    pub fn Spawn(comptime A: Archs) type {
        return switch(A) {
            .x86 => ArchBreakPoint.ArchsTypes.x86,
            .x86_64 => ArchBreakPoint.ArchsTypes.x86_64,
            .arm => ArchBreakPoint.ArchsTypes.arm,
        };
    }
};

pub const breakpoint = init: {
    if(builtin.mode != .ReleaseSmall)
        break :init notbreakpoint;
    const archType = switch(builtin.cpu.arch) {
        .x86 => ArchBreakPoint.Spawn(.x86),
        .x86_64 => ArchBreakPoint.Spawn(.x86_64),
        .arm => ArchBreakPoint.Spawn(.arm),
        else => @compileError("Attempt to use debug mode in an architecture that does not support debug"),
    };
    if(!@hasDecl(archType, "breakpoint"))
        @compileError("Attempt to use debug mode in an architecture that does not support debug");
    break :init archType.breakpoint;
};

fn notbreakpoint(_: anytype, _: anytype) void {
    return;
}
