pub fn writer(comptime context: type, write_error: type, writeFn: *const fn(context, []const u8) write_error!usize) type {
    return struct {
        context: context,

        const Self: type = @This();

        pub fn write(self: *Self, bytes: []const u8) write_error!usize {
            return writeFn(self.context, bytes);
        }

        pub fn writeAll(self: *Self, bytes: []const u8) (write_error || error { WriteZero })!void {
            var offset: usize = 0;

            while(offset < bytes.len) {
                const written: usize = try self.write(bytes[offset..]);

                if(written == 0)
                    return error.WriteZero;

                offset += written;
            }
        }
    };
}
