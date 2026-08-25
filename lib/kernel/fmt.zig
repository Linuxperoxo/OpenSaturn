// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fmt.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const format_impl: type = @import("fmt/format.zig");
const split: type = @import("fmt/split.zig");

pub fn format(allocator: anytype, comptime fmt: []const u8, args: anytype) anyerror![]u8 {
    const buffer_len: usize = (format_impl.format.totalBytesFmt(fmt, args) + format_impl.format.totalBytesArgs(args));
    const buffer: []u8 = try allocator.alloc(u8, buffer_len);
    var buffer_index: usize = 0;

    const fields = @typeInfo(@TypeOf(args)).@"struct".fields;

    comptime var fmt_index: usize = 0;
    comptime var fields_index: usize = 0;
    comptime var inside: bool = false;

    inline while (fmt_index < fmt.len) {
        const char: u8 = fmt[fmt_index];
        if (char == '{') {
            inside = true;
            fmt_index += 1;
            continue;
        }

        if (comptime inside) switch (comptime char) {
            's' => {
                const src = @field(args, fields[fields_index].name);
                const dest = buffer[buffer_index..(buffer_index + src.len)];

                @memcpy(dest, src);

                buffer_index += src.len;
                fmt_index += 2;
                fields_index += 1;
                inside = false;

                continue;
            },

            'd' => {
                const int = @field(args, fields[fields_index].name);
                const dest = buffer[buffer_index..(buffer_index + format_impl.format.intToBytes(int))];

                buffer_index += format_impl.format.strFromInt(int, dest);
                fmt_index += 2;
                fields_index += 1;
                inside = false;

                continue;
            },

            else => unreachable,
        };
        buffer[buffer_index] = char;
        buffer_index += 1;
        fmt_index += 1;
    }
    return buffer;
}

pub fn splitAlloc(str: []const u8, broken: u8, allocator: anytype) anyerror![][]const u8 {
    const initial_offset, const final_offset, const subs = try split.brokenInfo(str, broken);
    const sub_strs: [][]const u8 = try allocator.alloc([]const u8, subs);

    var sub_strs_index: usize = 0;
    var i: usize = initial_offset;

    while (i < final_offset) : (i += 1) {
        while (i < final_offset and str[i] == broken) : (i += 1) {}

        var sub_str_end: usize = i;
        while (sub_str_end < final_offset and str[sub_str_end] != broken) : (sub_str_end += 1) {}

        sub_strs[sub_strs_index] = str[i..sub_str_end];
        sub_strs_index += 1;
        i = sub_str_end;
    }
    return sub_strs;
}
