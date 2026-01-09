// ┌────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig    │
// │            Author: Linuxperoxo             │
// └────────────────────────────────────────────┘

const config: type = @import("root").config;

fn target_null_field(comptime field: []const u8) noreturn {
    @compileError(
        "\"" ++ @tagName(config.arch.options.Target) ++ "\" architecture has no implementation for \"" ++ field ++ "\""
    );
}
