// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: meta.zig       │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const fmt: type = @import("meta/comptime_fmt.zig");

/// Returns the child type of a pointer or optional type.
pub fn Child(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .pointer => |info| info.child,
        .optional => |info| info.child,
        else => @compileError("expected pointer or optional type, found '" ++ @typeName(T) ++ "'"),
    };
}

/// Recursively unwraps pointer and optional types.
pub fn DeepChild(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .pointer => |info| DeepChild(info.child),
        .optional => |info| DeepChild(info.child),
        else => T,
    };
}

pub fn isSlice(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .pointer => |info| info.size == .slice,
        else => false,
    };
}

pub fn isSinglePointer(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .pointer => |info| info.size == .one,
        else => false,
    };
}

/// Converts a comptime-known slice into an array.
pub fn arrayFromSlice(comptime slice: anytype) [slice.len]Child(@TypeOf(slice)) {
    comptime if (!isSlice(@TypeOf(slice)))
        @compileError("expected a slice, found '" ++ @typeName(@TypeOf(slice)) ++ "'");

    var array: [slice.len]Child(@TypeOf(slice)) = undefined;

    comptime {
        for (slice, 0..) |value, i| {
            array[i] = value;
        }
    }

    return array;
}
