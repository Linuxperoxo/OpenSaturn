// ┌────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: ar.zig     │
// │            Author: Linuxperoxo             │
// └────────────────────────────────────────────┘

// Architecture Resolver

// o architecture resolver é responsável por obter o código de implementação
// da arquitetura target, tornando esse código visível para todo o kernel.

const config: type = @import("root").config;
const arch: type = @import("root").interfaces.arch;
const codes: type = @import("root").codes;
const aux: type = @import("aux.zig");
const OutSide_T: type = @This();

pub const types: type = @import("types.zig");

pub const target_code: type = r: {
    const code = fetch_code_target();
    break :r struct {
        pub const target: OutSide_T.arch.Target_T = OutSide_T.config.arch.options.Target;
        pub const arch: type = code.arch;
        pub const entry: type = code.entry;
        pub const init: type = code.init orelse aux.target_null_field("init");
        pub const interrupts: type = code.interrupts orelse aux.target_null_field("interrupts");
        pub const physio: type = code.physio orelse aux.target_null_field("physio");
        pub const mm: type = code.mm orelse aux.target_null_field("mm");
        pub const config: type = code.config orelse aux.target_null_field("config");
        pub const lib: type = if(code.lib == null) aux.target_null_field("lib") else struct {
            pub const kernel: type = code.lib.?.kernel orelse aux.target_null_field("lib/kernel");
            pub const userspace: type = code.lib.?.userspace orelse aux.target_null_field("lib/userspace");
        };
    };
};

comptime {
    for(codes.__SaturnTargets__, 0..) |target_impl, i| {
        for(codes.__SaturnTargets__[0..i]) |other_impl| {
            if(other_impl.target == target_impl.target) @compileError(
                "target \"" ++ @tagName(target_impl.target) ++ "\" duplicate implementation in codes.zig"
            );
        }
    }
}

pub fn fetch_code(comptime target: arch.Target_T) types.TargetCode_T {
    for(codes.__SaturnTargets__) |target_impl|
        if(target_impl.target == target) return target_impl;
    @compileError("target \"" ++ @tagName(config.arch.options.Target) ++ "\" does not have implementation");
}

pub fn fetch_code_target() types.TargetCode_T {
    return comptime fetch_code(
        config.arch.options.Target
    );
}
