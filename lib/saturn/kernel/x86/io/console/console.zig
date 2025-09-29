// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: console.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const impl: type = @import("impl.zig");
const stage: type = @import("root").stage;

const vtable = [_]*const fn([]u8) void {
    &impl.boot.kprint,
    &impl.init.kprint,
    &impl.runtime.kprint,
};

// Global kprint
pub fn kprint(str: []u8) void {
    @call(.never_inline, vtable[@intFromEnum(stage.get)], .{
        str
    });
}
