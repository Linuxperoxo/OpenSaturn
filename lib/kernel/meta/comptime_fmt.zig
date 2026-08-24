// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: comptime_fmt.zig │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const format_impl: type = @import("format.zig");

pub fn format(comptime fmt: []const u8, comptime args: anytype) [format_impl.format.total_bytes_fmt(fmt, args) + format_impl.format.total_bytes_args(args)]u8 {
    if (!@inComptime())
        @compileError("comptime only fn");

    const fields = @typeInfo(@TypeOf(args)).@"struct".fields;

    var buffer = [_]u8{0} ** (format_impl.format.total_bytes_fmt(fmt, args) + format_impl.format.total_bytes_args(args));

    var fmt_index: usize = 0;
    var fields_index: usize = 0;
    var inside: bool = false;
    var buffer_index: usize = 0;

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
                const dest = buffer[buffer_index..(buffer_index + format_impl.format.int_to_bytes(int))];
                buffer_index += format_impl.format.str_from_int(int, dest);
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
