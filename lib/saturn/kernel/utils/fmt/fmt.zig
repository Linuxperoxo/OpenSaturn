// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fmt.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

fn numSize(comptime num: usize) usize {
    if(num < 10) return 1;
    var context: usize = num;
    var size: usize = 0;
    while(context != 0) : (context /= 10) {
        size += 1;
    }
    return size;
}

pub fn intFromArray(comptime num: usize) [r: {
    break :r numSize(num);
}]u8 {
    const size = numSize(num);
    var context: usize = num;
    var result = [_]u8 {
        0
    } ** size;
    context = num;
    for(0..size) |i| {
        result[(size - 1) - i] = (context % 10) + '0';
        context /= 10;
    }
    return result;
}

pub fn broken_str(str: []const u8, broken: u8, allocator: anytype) anyerror![][]const u8 {
    const aux: type = opaque {
        inline fn BrokenInfo(strr: []const u8, brokenn: u8) anyerror!struct { usize, usize, usize } {
            if(strr.len == 0) return error.Empty;
            r: {
                for(0..strr.len) |i|
                    if(strr[i] != brokenn) break :r {};
                return error.WithoutSub;
            }
            const final_offset: usize = r: {
                var count: usize = strr.len;
                while(strr[count - 1] == brokenn) : (count -= 1) {}
                break :r count;
            };
            const initial_offset: usize = if(strr[0] != brokenn) 1 else 0;
            var subs: usize = initial_offset;
            for(subs..final_offset) |i| {
                subs += if(strr[i] == brokenn) 1 else 0;
            }
            return .{
                initial_offset,
                final_offset,
                subs,
            };
        }
    };
    const initial_offset,
    const final_offset,
    const subs = try aux.BrokenInfo(str, broken);
    const sub_strs: [][]const u8 = (try allocator.alloc([]const u8, subs)).ptr[0..subs]; // FIXME: alloc retorna .len errado para o slice
    var sub_strs_index: usize = 0;
    var i: usize = initial_offset;
    while(i < final_offset) : (i += 1) {
        while(i < final_offset and str[i] == broken)
            : (i += 1) {}
        var sub_str_end: usize = i;
        while(sub_str_end < final_offset and str[sub_str_end] != broken)
            : (sub_str_end += 1) {}
        sub_strs[sub_strs_index] = str[i..sub_str_end];
        sub_strs_index += 1;
        i = sub_str_end;
    }
    return sub_strs;
}
