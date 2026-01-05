// ┌────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: ar.zig     │
// │            Author: Linuxperoxo             │
// └────────────────────────────────────────────┘

const config: type = @import("root").config;
const codes: type = @import("root").codes;
const types: type = @import("types.zig");

pub const target_code: type = r: {
    const code = @field(codes.__SaturnTargets__, @tagName(config.arch.options.Target));
    break :r struct {
        pub const arch: type = code.arch;
        pub const entry: type = code.entry;
        pub const init: type = code.init orelse target_null_field("init");
        pub const interrupts: type = code.interrupts orelse target_null_field("interrupts");
        pub const physio: type = code.physio orelse target_null_field("physio");
        pub const mm: type = code.mm orelse target_null_field("init");
        pub const lib: type = if(config.lib == null) target_null_field("lib") else struct {
            pub const kernel: type = code.lib.?.kernel orelse target_null_field("lib/kernel");
            pub const userspace: type = code.lib.?.userspace orelse target_null_field("lib/userspace");
        };
    };
};

comptime {
    for(@typeInfo(@TypeOf(config.arch.options.Target)).@"enum".decls) |decl| {
        if(!@hasField(types.Targets_T, decl)) @compileError("");
        if(@FieldType(types.Targets_T, decl)) @compileError("");
    }
}

fn target_null_field(comptime field: []const u8) noreturn {
    @compileError(
        "\"" ++ @tagName(config.arch.options.Target) ++ "\" architecture has no implementation for \"" ++ field ++ "\""
    );
}
