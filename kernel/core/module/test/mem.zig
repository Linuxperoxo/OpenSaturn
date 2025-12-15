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