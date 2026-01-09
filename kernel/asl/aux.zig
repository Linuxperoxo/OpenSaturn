// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const lib: type = @import("root").lib;

pub fn asm_set(comptime name: []const u8, comptime value: u32) []const u8 {
    return ".set " ++ name ++ ", " ++ lib.utils.fmt.intFromArray(value) ++ "\n"
        ++ ".globl " ++ name ++ "\n"
    ;
}

pub fn ret_export_entry(comptime lhs: anytype, comptime field: []const u8) *anyopaque {
    const field_access = @field(lhs, field);
    return @constCast(switch(@typeInfo(@TypeOf(field_access))) {
        .optional => field_access.?.entry,
        .@"struct" => field_access.entry,
        else => unreachable,
    });
}

pub fn ret_export_label(comptime lhs: anytype, comptime field: []const u8) []const u8 {
    const field_access = @field(lhs, field);
    return switch(@typeInfo(@TypeOf(field_access))) {
        .optional => field_access.?.label,
        .@"struct" => field_access.label,
        else => unreachable,
    };
}

pub fn extract_opt_child(comptime container: type) type {
    return switch(@typeInfo(container)) {
        .optional => |opt| opt.child,
        else => container,
    };
}
