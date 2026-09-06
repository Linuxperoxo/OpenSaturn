// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: debug.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

comptime {
    @compileError("File Not Working");
}

pub const saturn_arch_infos: type = @import("root").arch;

pub const RegDebugX8664: type = enum(u2) {
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

            const debug_asm = "jmp .";

            pub inline fn breakpoint(a: anytype, comptime r: Regs) void {
                switch(@typeInfo(@TypeOf(a))) {
                    .@"struct" => |struct_info| {
                        if(struct_info.fields.len == 0) {
                            asm volatile (debug_asm);
                        }
                    },
                    else => {},
                }
                switch(r) {
                    .eax => asm volatile(debug_asm ::[_] "{eax}" (a):),
                    .ebx => asm volatile(debug_asm ::[_] "{ebx}" (a):),
                    .ecx => asm volatile(debug_asm ::[_] "{ecx}" (a):),
                    .edx => asm volatile(debug_asm ::[_] "{edx}" (a):),
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

    pub fn spawn(comptime a: Archs) type {
        return switch(a) {
            .x86 => ArchBreakPoint.ArchsTypes.x86,
            .x86_64 => ArchBreakPoint.ArchsTypes.x86_64,
            .arm => ArchBreakPoint.ArchsTypes.arm,
        };
    }
};

pub const breakpoint = init: {
    if(saturn_arch_infos.__SaturnCodeModel__ != .Debug)
        break :init notbreakpoint;
    const arch_type = switch(saturn_arch_infos.__SaturnTarget__) {
        .x86 => ArchBreakPoint.spawn(.x86),
        .x86_64 => ArchBreakPoint.spawn(.x86_64),
        .arm => ArchBreakPoint.spawn(.arm),
        else => @compileError("Attempt to use debug mode in an architecture that does not support debug"),
    };
    if(!@hasDecl(arch_type, "breakpoint"))
        @compileError("Attempt to use debug mode in an architecture that does not support debug");
    break :init arch_type.breakpoint;
};

fn notbreakpoint(_: anytype, _: anytype) void {
    return;
}
