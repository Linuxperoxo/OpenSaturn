// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fmt.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub fn int_to_bytes(comptime int: usize) usize {
    var current: usize = int;
    var total: usize = 1;
    while(current != 0) : ({ current /= 10; total += 1; }) {}
    return total;
}

pub fn str_from_int(comptime int: usize) []u8 {

}
