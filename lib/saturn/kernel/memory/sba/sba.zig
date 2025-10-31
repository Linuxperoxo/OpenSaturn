// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: sba.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const mm: type = @import("root").mm;
const config: type = @import("root").config;
const types: type = @import("types.zig");

// === Saturn Byte Allocator ===

const default_block_size: comptime_int = 16;
const total_bytes_of_pool = switch(config.arch.options.Target) {
    .i386 => config.kernel.options.kernel_page_size,
    else => unreachable,
};

pub fn buildByteAllocator(
    comptime block: ?comptime_int,
    comptime cache: types.Cache_T,
    comptime personality: types.Personality_T,
) type {
    return struct {
        pool: Pool_T,
        cache: [if(personality.resize) 0 else total_of_cache_entries]MaxBits_T,
        cindex: if(personality.resize) void else MaxBits_T,

        const total_of_cache_entries = switch(cache.size) {
            .small => {},
            .large => {},
            .huge => {},
        };

        const MaxBits_T: type = switch((total_bytes_of_pool / 2) / (block orelse default_block_size)) {
            0...255 => u8,
            256...65535 => u16,
            else => u32,
        };

        pub const Pool_T: type = struct {
            bytes: []u8,
            next: ?MaxBits_T = if(personality.resize) @sizeOf(Pool_T) else 0,
            flags: packed struct(u8) {
                full: u1,
                hit: u2,
                parent: u1,
            },
            private: switch(config.arch.options.Target) {
                .i386 => mm.AllocPage_T,
                else => void,
            },
        };

        pub const err_T: type = error {
            PoolInitFailed,
        };

        fn pool_init(pool: *types.Pool_T) err_T!void {
            switch(config.arch.options.Target) {
                .i386 => pool.private = @call(.never_inline, mm.alloc_page, .{}) catch return err_T.PoolInitFailed,
                else => unreachable,
            }
        }

        fn pool_deinit(pool: *types.Pool_T) err_T!void {
            switch(config.arch.options.Target) {
                .i386 => @call(.never_inline, mm.free_page, .{
                    &pool.private
                }) catch return err_T.PoolInitFailed,
                else => unreachable,
            }
        }

        fn resize() err_T!void {
            
        }

        pub fn alloc(num: u32) err_T![]u8 {

        }

        pub fn free(ptr: []u8) err_T!void {

        }
    };
}
