// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: mem.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub fn eql(noalias b0: []const u8, noalias b1: []const u8, comptime rule: struct {
    len: bool = true,
    case: bool = false,
}) bool {
    return r: {
        if(comptime rule.len) {
            if(b0.len != b1.len) {
                return false;
            }
        }
        const end: usize = if(b0.len > b1.len) b1.len else b0.len;
        for(0..end) |i| {
            if(
                (b0[i] & if(!rule.case) (~(@as(u8, @intCast(0x20)))) else 0xFF) !=
                (b1[i] & if(!rule.case) (~(@as(u8, @intCast(0x20)))) else 0xFF)
            ) {
                break :r false;
            }
        }
        break :r true;
    };
}

pub fn cpy(noalias dest: []u8, noalias src: []const u8) void {
    for(0..dest.len) |i| {
        if(src.len <= i) break;
        dest[i] = src[i];
    }
}

pub fn zero(comptime T: type) T {
    @setEvalBranchQuota(4294967295);
    switch(@typeInfo(T)) {
        .int, .float => return @as(T, 0),
        .pointer => |info| if(info.is_allowzero) return @intFromPtr(0) else return undefined,
        .null, .optional => return null,
        .array => |info| {
            var array: T = undefined;
            for(0..info.len) |i| {
                array[i] = comptime zero(info.child);
            }
        },
        .@"struct" => |info| {
            var @"struct": T = undefined;
            for(info.fields) |field| {
                @field(@"struct", field.name) = comptime zero(field.type);
            }
            return @"struct";
        },
        else => {},
    }
    return undefined;
}
