// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: formats.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

fn str_from_int(comptime int: anytype) []const u8 {
    switch(@typeInfo(@TypeOf(int))) {
        .int => {},
        else => @compileError(
            "expect int type"
        ),
    }
    if(int == 0) return &[_]u8 { 48 };
    var int_str = [_]u8 {
        0
    } ** r: {
        var count: usize = 0;
        var number = int;
        while(number != 0) : (number /= 10) {
            count += 1;
        }
        break :r count;
    };
    var number = int;
    var i: usize = 0;
    while(number != 0) : (number /= 10) {
        int_str[int_str.len - 1 - i] = @intCast((number % 10) + '0');
        i += 1;
    }
    return int_str[0..int_str.len];
}
