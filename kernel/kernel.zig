// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: kernel.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const x86: type = @import("saturn/kernel/arch/x86");
pub const x86_64: type = @import("saturn/kernel/arch/x86_64");
pub const arm: type = @import("saturn/kernel/arch/arm");

//pub const core: type = @import("saturn/kernel/core");
//pub const interfaces: type = @import("saturn/lib/interfaces");
//pub const io: type = @import("saturn/lib/io");
//pub const memory: type = @import("saturn/kernel/memory");

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
        break :init @typeInfo(@TypeOf(arch.entry));
    };
    block0: {
        switch(typeInfo) {
            .@"fn" => {
                if(typeInfo.@"fn".return_type == noreturn and
                    typeInfo.@"fn".calling_convention == .naked and
                    typeInfo.@"fn".params.len == 1 and 
                    typeInfo.@"fn".params[0].type.? == u32) {
                    @export(&arch.entry, .{
                        .section = ".text.entry",
                        .name = "entry",
                    });
                    break :block0;
                }
                @compileError(
                    "entry function is expected to be an fn(u32) callconv(.naked) noreturn"
                );
            },
            else => {
                @compileError(
                "target kernel cpu architecture does not have an internal function set to \'pub fn entry(u32) callconv(.naked) noreturn\'"
                );
            },
        }
    }
}

export fn init() void {
    // Todo esse codigo e rodado em comptime para fazer
    // algumas verificaçoes para a arquitetura alvo do kernel
    const typeInfo = init: {
        if(!@hasDecl(arch, "init")) {
            @compileError(
                "target kernel cpu architecture does not have an internal function set to \'pub fn init() void\'"
            );
        }
        break :init @typeInfo(@TypeOf(arch.init));
    };
    switch(typeInfo) {
        .@"fn" => {
            if(typeInfo.@"fn".return_type != void or
                typeInfo.@"fn".params.len != 0) {
                @compileError(
                    "init function is expected to be an fn() void"
                );
            }
            // Caso chegue aqui, a chamada dessa funçao e adicionada 
            // no codigo final
            @call(.always_inline, arch.init, .{}); 
        },
        else => {
            @compileError(
                "target kernel cpu architecture does not have an internal function set to \'pub fn init() void\'"
            );
        },
    }
}

export fn main() void {
    @call(.always_inline, &init, .{});
}
