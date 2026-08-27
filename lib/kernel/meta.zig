// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: meta.zig       │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

pub const fmt: type = @import("meta/comptime_fmt.zig");

/// Returns the child type of a pointer or optional type.
pub fn child(comptime t: type) type {
    return switch (@typeInfo(t)) {
        .pointer => |info| info.child,
        .optional => |info| info.child,
        else => @compileError("expected pointer or optional type, found '" ++ @typeName(t) ++ "'"),
    };
}

/// Recursively unwraps pointer and optional types.
pub fn deepChild(comptime t: type) type {
    return switch (@typeInfo(t)) {
        .pointer => |info| deepChild(info.child),
        .optional => |info| deepChild(info.child),
        else => t,
    };
}

pub fn isSlice(comptime t: type) bool {
    return switch (@typeInfo(t)) {
        .pointer => |info| info.size == .slice,
        else => false,
    };
}

pub fn isSinglePointer(comptime t: type) bool {
    return switch (@typeInfo(t)) {
        .pointer => |info| info.size == .one,
        else => false,
    };
}

/// Converts a comptime-known slice into an array.
pub fn arrayFromSlice(comptime slice: anytype) [slice.len]child(@TypeOf(slice)) {
    comptime if (!isSlice(@TypeOf(slice)))
        @compileError("expected a slice, found '" ++ @typeName(@TypeOf(slice)) ++ "'");

    var array: [slice.len]child(@TypeOf(slice)) = undefined;

    comptime {
        for (slice, 0..) |value, i| {
            array[i] = value;
        }
    }

    return array;
}
