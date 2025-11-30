
// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fmt.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub fn intFromArray(comptime num: usize) [r: {
    if(num == 0) break :r 1;
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

fn numSize(comptime num: usize) usize {
    var context: usize = num;
    var size: usize = 0;
    while(context != 0) : (context /= 10) {
        size += 1;
    }
    return size;
}
