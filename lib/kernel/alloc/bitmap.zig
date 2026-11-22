// ┌───────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: bitmap.zig    │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

pub fn Bitmap(comptime len: usize) type {
    return struct {
        const Self: type = @This();
        const BitmapVector: type = @Vector(len, u1);
        const BitmapOperation: type = enum {
            UNSET,
            SET,
        };
        const IntBitmap: type = @Type(.{
           .int = .{
               .bits = len,
               .signedness = .unsigned,
           },
        });

        bitmap: BitmapVector,

        pub fn init() Self {
            return Self {
                .bitmap = @splat(0),
            };
        }

        pub fn deinit(self: *Self) void {
            const ptr: *IntBitmap = @ptrCast(&self.bitmap);
            ptr.* = 0;
        }

        /// Sets or clears a sequence of consecutive bits starting at `index`.
        ///
        /// `op` determines whether the bits are set `.SET` or cleared `.UNSET`.
        /// Does nothing if `continuos` is zero or invalid, or if `index` is outside
        /// the bitmap.
        pub fn modifyBitRange(self: *Self, op: BitmapOperation, continuos: usize, index: usize) void {
            if (continuos == 0 or index >= len or continuos > len - index)
                return;

            const mask: IntBitmap = ~(~(@as(IntBitmap, 0x01) << @intCast(continuos)) + 1) << @intCast(index);
            switch(op) {
                .set => self.bitmap = self.bitmap | @as(BitmapVector, @bitCast(mask)),
                .unset => self.bitmap = self.bitmap & @as(BitmapVector, @bitCast(~mask)),
            }
        }

        /// Finds the lowest index of a consecutive run of bits matching `op`.
        ///
        /// `continuos` is the required run length and must be greater than zero and
        /// less than the bitmap length. Returns the starting index of the run, or
        /// `null` if no matching run is found. `.SET` searches for set bits; `.UNSET`
        /// searches for unset bits.
        ///
        /// NOTE: This function does not check whether all bits in the bitmap are set.
        /// `continuos` must be greater than 0 and less than `bitmap.len`.
        /// To check whether the entire bitmap is set, use `allEqualTo()`.
        pub fn findFirstIndexOfConsecutiveSetBits(self: *const Self, op: BitmapOperation, continuos: usize) ?usize {
            if(continuos >= len or continuos == 0)
                return null;

            const mask: IntBitmap = ~(~(@as(IntBitmap, 0x01) << @intCast(continuos)) + 1);

            var bitmap: IntBitmap = @bitCast(self.bitmap);

            if(op == .UNSET)
                bitmap = ~bitmap;

            if(bitmap == 0)
                return null;

            var ctz: usize = @ctz(bitmap);
            var index: usize = ctz;

            bitmap >>= @intCast(ctz);

            while(bitmap != 0) {
                if(bitmap & mask == mask)
                    return index;

                ctz = @ctz(~bitmap) + 1;

                bitmap >>= @intCast(ctz);
                index += ctz;

                if(bitmap == 0)
                    return null;

                ctz = @ctz(bitmap);

                bitmap >>= @intCast(ctz);
                index += ctz;
            }
            return null;
        }

        /// Checks whether every bit in the bitmap equals `mask`.
        ///
        /// Use `mask = 1` to check whether all bits are set, or `mask = 0` to check
        /// whether all bits are clear.
        pub inline fn allEqualTo(self: *const Self, mask: u1) bool {
            const ptr: *const IntBitmap = @alignCast(@ptrCast(&self.bitmap));
            return ptr.* == (comptime(~@as(IntBitmap, 0)) * mask);
        }
    };
}
