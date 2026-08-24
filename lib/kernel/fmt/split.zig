// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: split.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub inline fn broken_info(str: []const u8, separator: u8) anyerror!struct { usize, usize, usize } {
    if (str.len == 0) return error.Empty;
    r: {
        for (0..str.len) |i|
            if (str[i] != separator) break :r {};
        return error.WithoutSub;
    }
    const final_offset: usize = r: {
        var count: usize = str.len;
        while (str[count - 1] == separator) : (count -= 1) {}
        break :r count;
    };
    const initial_offset: usize = if (str[0] != separator) 1 else 0;
    var subs: usize = initial_offset;
    for (subs..final_offset) |i| {
        subs += if (str[i] == separator) 1 else 0;
    }
    return .{
        initial_offset,
        final_offset,
        subs,
    };
}
