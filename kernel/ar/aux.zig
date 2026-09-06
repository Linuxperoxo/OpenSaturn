// ┌────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig    │
// │            Author: Linuxperoxo             │
// └────────────────────────────────────────────┘

const config: type = @import("root").config;

fn targetNullField(comptime field: []const u8) noreturn {
    @compileError(
        "\"" ++ @tagName(config.arch.options.target) ++ "\" architecture has no implementation for \"" ++ field ++ "\""
    );
}
