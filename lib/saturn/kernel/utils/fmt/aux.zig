// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const compile: type = @import("root").lib.utils.compile;

pub const format: type = opaque {
    pub fn format(allocator: anytype, comptime fmt: []const u8, args: anytype) anyerror![]u8 {
        const buffer_len: usize = (comptime total_bytes_fmt(fmt, args)) + total_bytes_args(args);
        const buffer: []u8 = try allocator.alloc(u8, buffer_len);
        var buffer_index: usize = 0;

        const fields = @typeInfo(@TypeOf(args)).@"struct".fields;

        comptime var fmt_index: usize = 0;
        comptime var fields_index: usize = 0;
        comptime var inside: bool = false;

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
                    const dest = buffer[buffer_index..buffer_index + int_to_bytes(int)];
                    buffer_index += str_from_int(int, dest);
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

    pub fn str_from_int(int: usize, buffer: []u8) usize {
        var current: usize = int;
        var i: usize = 0;
        while(current != 0 and i < buffer.len) : ({ current /= 10; i += 1; })
            buffer[buffer.len - 1 - i] = @as(u8, @truncate(current % 10)) + '0';
        return i;
    }

    pub fn total_bytes_fmt(comptime fmt: []const u8, args: anytype) usize {
        if(@typeInfo(@TypeOf(args)) != .@"struct")
            @compileError("expect a tuple");
        const fields = @typeInfo(@TypeOf(args)).@"struct".fields;
        var fields_index: usize = 0;
        var inside: bool = false;
        var fmt_len: usize = 0;
        var fmt_index: usize = 0;
        while(fmt_index < fmt.len) : (fmt_index += 1) {
            const char: u8 = fmt[fmt_index];
            switch(char) {
                '{' => {
                    if(inside) @compileError("missing clossing }");
                    inside = true;
                    continue;
                },
                '}' => @compileError("missing openning }"),
                else => {},
            }
            if(inside) {
                if(fields_index + 1 > fields.len)
                    @compileError("too many args");
                const field: type = fields[fields_index].type;
                sw0: switch(char) {
                    's' => {
                        sw1: switch(@typeInfo(field)) {
                            .pointer => |ptr| {
                                if(ptr.size == .c or ptr.size == .many) {
                                    if(@typeInfo(ptr.child) == .array)
                                        continue :sw1 1;
                                    continue :sw0 0;
                                }
                            },
                            .array => |arr| {
                                if(arr.child != u8)
                                    continue :sw0 0;
                            },
                            else => continue :sw0 0,
                        }
                    },
                    'd' => {
                        switch(@typeInfo(field)) {
                            .int => {},
                            .comptime_int => {},
                            else => continue :sw0 ' ',
                        }
                    },
                    else => @compileError("invalid format string \"" ++ fmt[fmt_index..fmt_index + 1] ++ "\" for type \"" ++ @typeName(field) ++ "\""),
                }
                if(fmt_index + 1 > fmt.len or fmt[fmt_index + 1] != '}')
                    @compileError("missing clossing }");
                fmt_index += 1;
                fields_index += 1;
                inside = false;
                continue;
            }
            fmt_len += 1;
        }
        if(fields_index != fields.len)
            @compileError("too many args");
        return fmt_len;
    }

    pub fn total_bytes_args(args: anytype) usize {
        var total: usize = 0;
        inline for(@typeInfo(@TypeOf(args)).@"struct".fields) |field| {
            total += switch(@typeInfo(field.type)) {
                .pointer => (@field(args, field.name)).len,
                .int => int_to_bytes(@field(args, field.name)),
                .comptime_int => comptime int_to_bytes(@field(args, field.name)),
                else => unreachable,
            };
        }
        return total;
    }

    pub fn int_to_bytes(int: usize) usize {
        if(int == 0) return 1;
        var current: usize = int;
        var total: usize = 0;
        while(current != 0) : ({ current /= 10; total += 1; }) {}
        return total;
    }
};

pub const broken_str: type = opaque {
    inline fn broken_info(strr: []const u8, brokenn: u8) anyerror!struct { usize, usize, usize } {
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
