// ┌────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: ar.zig     │
// │            Author: Linuxperoxo             │
// └────────────────────────────────────────────┘

const config: type = @import("root").config;
const arch: type = @import("root").interfaces.arch;
const codes: type = @import("root").codes;
const OutSide_T: type = @This();

pub const types: type = @import("types.zig");

pub const target_code: type = r: {
    const code = codes.fetch_code(config.arch.options.Target);
    break :r struct {
        pub const target: OutSide_T.arch.Target_T = OutSide_T.config.arch.options.Target;
        pub const arch: type = code.arch;
        pub const entry: type = code.entry;
        pub const init: type = code.init orelse target_null_field("init");
        pub const interrupts: type = code.interrupts orelse target_null_field("interrupts");
        pub const physio: type = code.physio orelse target_null_field("physio");
        pub const mm: type = code.mm orelse target_null_field("mm");
        pub const config: type = code.config orelse target_null_field("config");
        pub const segments: type = code.segments orelse target_null_field("segments");
        pub const lib: type = if(code.lib == null) target_null_field("lib") else struct {
            pub const kernel: type = code.lib.?.kernel orelse target_null_field("lib/kernel");
            pub const userspace: type = code.lib.?.userspace orelse target_null_field("lib/userspace");
        };
    };
};

comptime {
    for(@typeInfo(arch.Target_T).@"enum".fields) |field| {
        if(!@hasField(types.Targets_T, field.name)
            or @FieldType(types.Targets_T, field.name) != types.TargetCode_T) @compileError(
            "\"" ++ field.name ++ "\" architecture does not have a field of type \"TargetCode_T\" in kernel/ar/types.zig:\"Targets_T\""
        );
    }
}

fn target_null_field(comptime field: []const u8) noreturn {
    @compileError(
        "\"" ++ @tagName(config.arch.options.Target) ++ "\" architecture has no implementation for \"" ++ field ++ "\""
    );
}
