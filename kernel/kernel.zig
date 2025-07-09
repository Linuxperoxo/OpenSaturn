// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: kernel.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const x86: type = @import("saturn/kernel/arch/x86");
pub const x86_64: type = @import("saturn/kernel/arch/x86_64");
pub const arm: type = @import("saturn/kernel/arch/arm");

pub const core: type = @import("saturn/kernel/core");
pub const interfaces: type = @import("saturn/lib/interfaces");
pub const io: type = @import("saturn/lib/io");
pub const memory: type = @import("saturn/kernel/memory");

pub const modules: type = @import("saturn/modules");

pub const debug: type = @import("saturn/debug");

comptime {
    if(@import("builtin").mode == .Debug)
        @compileError("-O Debug is blocked, use -O Releasesmall or -O ReleaseFast");
}

pub const arch: type = init: {
    const cpu_arch: type = switch(@import("builtin").cpu.arch) {
        .x86 => x86,
        .x86_64 => x86_64,
        .arm => arm,
        else => {
            @compileError(
                "the selected target architecture is not supported"
            );
        },
    };
    break :init cpu_arch;
};

comptime {
    const typeInfo = init: {
        if(!@hasDecl(arch, "entry")) {
            @compileError(
                "target kernel cpu architecture does not have an internal function set to \'pub fn entry(u32) callconv(.naked) noreturn\'"
            );
        }
        break :init @TypeOf(arch.entry);
    };
    if(typeInfo != (fn(u32) callconv(.naked) noreturn)) {
        @compileError("entry function is expected to be an \'pub fn(u32) callconv(.naked) noreturn\'");
    }
    @export(&arch.entry, .{
        .name = "arch.entry",
        .section = ".text.arch.entry",
    });
}

export fn init() void {
    // NOTE: Todo esse codigo e rodado em comptime para fazer
    //       algumas verificaçoes para a arquitetura alvo do kernel
    comptime {
        const typeInfo = init: {
            if(!@hasDecl(arch, "init")) {
                @compileError(
                    "target kernel cpu architecture does not have an internal function set to \'pub fn init() void\'"
                );
            }
            break :init @TypeOf(arch.init);
        };
        if(typeInfo != (fn() void)) {
            @compileError("target kernel cpu architecture does not have an internal function set to \'pub fn init() void\'");
        }
    }
    @call(.never_inline, arch.init, .{});
}

export fn main() void {
    @call(.always_inline, &init, .{});
    @call(.always_inline, &modules.callLinkableMods, .{});
}
