// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fmt.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const aux: type = @import("aux.zig");

pub fn format(comptime fmt: []const u8, comptime args: anytype) [aux.format.total_bytes_fmt(fmt, args) + aux.format.total_bytes_args(args)]u8 {
    if(!@inComptime())
        @compileError("comptime only fn");

    const fields = @typeInfo(@TypeOf(args)).@"struct".fields;

    var buffer = [_]u8 {
        0
    } ** (aux.format.total_bytes_fmt(fmt, args) + aux.format.total_bytes_args(args));

    var fmt_index: usize = 0;
    var fields_index: usize = 0;
    var inside: bool = false;
    var buffer_index: usize = 0;

    inline while(fmt_index < fmt.len) {
        const char: u8 = fmt[fmt_index];
        if(char == '{') {
            inside = true;
            fmt_index += 1;
            continue;
        }
        if(comptime inside) switch(comptime char) {
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
                const dest = buffer[buffer_index..(buffer_index + aux.format.int_to_bytes(int))];
                buffer_index += aux.format.str_from_int(int, dest);
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
