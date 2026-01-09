// ┌────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig    │
// │            Author: Linuxperoxo             │
// └────────────────────────────────────────────┘

pub fn is_slice(comptime possible_slice: type) bool {
    return r: switch(@typeInfo(possible_slice)) {
        .optional => |opt| break :r is_slice(opt.child),
        .pointer => |ptr| break :r ptr.size == .slice,
        else => break :r false,
    };
}

pub fn slice_child_type(comptime slice: type) type {
    return switch(@typeInfo(slice)) {
        .pointer => |ptr| ptr.child,
        else => unreachable,
    };
}
