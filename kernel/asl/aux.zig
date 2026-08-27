// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const lib: type = @import("root").lib;

pub fn retExportEntry(comptime lhs: anytype, comptime field: []const u8) *anyopaque {
    const field_access = @field(lhs, field);
    return @constCast(switch(@typeInfo(@TypeOf(field_access))) {
        .optional => field_access.?.entry,
        .@"struct" => field_access.entry,
        else => unreachable,
    });
}

pub fn retExportLabel(comptime lhs: anytype, comptime field: []const u8) []const u8 {
    const field_access = @field(lhs, field);
    return switch(@typeInfo(@TypeOf(field_access))) {
        .optional => field_access.?.label,
        .@"struct" => field_access.label,
        else => unreachable,
    };
}

pub fn extractOptChild(comptime container: type) type {
    return switch(@typeInfo(container)) {
        .optional => |opt| opt.child,
        else => container,
    };
}
