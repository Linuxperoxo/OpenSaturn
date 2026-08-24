pub fn Writer(comptime Context: type, WriteError: type, writeFn: *const fn(Context, []const u8) WriteError!usize) type {
    return struct {
        context: Context,

        const Self: type = @This();

        pub fn write(self: *Self, bytes: []const u8) WriteError!usize {
            return writeFn(self.context, bytes);
        }

        pub fn writeAll(self: *Self, bytes: []const u8) (WriteError || error { WriteZero })!void {
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
