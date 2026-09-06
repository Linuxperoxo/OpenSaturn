// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: soa.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// === Saturn Object Allocator ===
//      A SLUB-like allocator
// === === === === === === === ===

const mm: type = @import("root").mm;
const config: type = @import("root").config;

pub const Optimize: type = @import("soa/types.zig").Optimize;
pub const Cache: type = @import("soa/types.zig").Cache;

pub fn buildObjAllocator(
    comptime t: type,
    comptime zero_init: bool,
    comptime num: usize,
    comptime optimize: Optimize,
    comptime cache: Cache,
) type {
    comptime {
        if (@sizeOf(t) == 0) {
            @compileError("SOA: type" ++
                @typeName(t) ++
                " cannot have size 0 (incomplete or invalid).");
        }

        if (num == 0) {
            @compileError("SOA: obj num cannot be zero. This may cause invalid state.");
        }

        if ((num % 2) != 0) {
            @compileError("SOA: obj num must be even. Provided value is odd.");
        }

        if (num <= 2) {
            @compileError("SOA: obj num must be greater than 2. Provided value is too small. Use 4 with value");
        }
    }
    return struct {
        pool: ?[]t = null,
        allocs: BitMaxIPool = 0,
        bitmap: [
            r: {
                break :r (num / BitMapStorage.map_size) + if ((num % BitMapStorage.map_size) != 0) 1 else 0;
                // essa calculo garante que tenha a quantidade certa
                // de bitmap para objetos caso nao seja multiplo do map_size.
            }
        ]BitMapStorage = [_]BitMapStorage{
            BitMapStorage{
                .map = [_]BitMapStorage.Map{
                    .free,
                } ** BitMapStorage.map_size,
            },
        } ** ((num / BitMapStorage.map_size) + if ((num % BitMapStorage.map_size) != 0) 1 else 0),
        lindex: ?BitMaxIPool = null,
        cindex: CindexType = if (CindexType == void) {} else null,
        cmiss: CmissType = if (CmissType == void) {} else 0,
        cache: CacheType = if (optimize.type == .linear) {} else [_]?BitMaxIPool{null} ** cache_element_size,
        page: Page = if (Page == void) {} else undefined,

        const Self: type = @This();
        const Page: type = switch (config.arch.options.target) {
            .i386 => mm.AllocPage,
            else => void,
        };
        const BitMapStorage: type = struct {
            map: [map_size]Map align(1),

            pub const map_size: comptime_int = 8;
            pub const Map: type = enum(u1) {
                free,
                busy,
            };
        };
        const BitMaxIPool: type = switch (num) {
            1...255 => u8,
            256...65535 => u16,
            else => usize,
        };
        const InternalErr: type = error{
            NonOptimize,
            Rangeless,
        };
        const CacheType: type = if (optimize.type == .linear) void else [cache_element_size]?BitMaxIPool;
        const CindexType: type = if (optimize.type == .linear) void else ?BitMaxIPool;
        const CmissType: type = r: {
            if (optimize.type == .linear) break :r void;
            switch (cache.sync) {
                .burning => break :r void,
                else => break :r u2,
            }
        };
        const cache_element_size = r: {
            const divisor = if (cache.size != .auto and num >= @intFromEnum(cache.size)) @intFromEnum(cache.size) else t: {
                sw: switch (@sizeOf(t)) {
                    1...16 => if (num <= 16) break :t @intFromEnum(Cache.CacheSize.huge) else continue :sw 17,
                    17...32 => if (num <= 32) break :t @intFromEnum(Cache.CacheSize.large) else continue :sw 33,
                    else => break :t @intFromEnum(Cache.CacheSize.small),
                }
            };
            break :r num / divisor;
        };

        pub const Err: type = error{
            OutOfMemory,
            DoubleFree,
            IndexOutBounds,
            UndefinedAction,
            NotInitialized,
        };

        pub const Options: type = struct {
            pub const Type: type = t;
            pub const config: struct { optimize: Optimize, cache: Cache } = .{
                .optimize = optimize,
                .cache = cache,
            };
        };

        const CacheAction: type = struct {
            pub const CacheErr: type = error{
                NonSync,
            };

            var mid_high: u1 = 1;
            pub fn sync(self: *Self) CacheErr!void {
                const init, const end = switch (cache.mode) {
                    .prioritize_hits => .{ 0, self.cache.len },

                    .prioritize_speed => .{
                        (self.cache.len / 2) * mid_high,
                        (self.cache.len / 2) + ((self.cache.len / 2) * mid_high),
                    },
                };
                var first: ?BitMaxIPool = null;
                var bindex: BitMaxIPool, var mindex: BitMaxIPool = .{ 0, 0 };
                for (init..end) |cindex| {
                    if (self.cache[cindex]) |_| continue;
                    r: {
                        while (bindex < self.bitmap.len) : (bindex += 1) {
                            while (mindex < BitMapStorage.map_size) : (mindex += 1) {
                                if (self.bitmap[bindex].map[mindex] == .free) {
                                    self.cache[cindex] = @call(.always_inline, &BitMap.bitMapIndexToIPool, .{ bindex, mindex });
                                    first = if (first) |_| first else @intCast(cindex);
                                    mindex += 1;
                                    break :r {};
                                }
                            }
                            mindex = 0;
                        }
                    }
                }
                mid_high ^= 1;
                self.cindex = first orelse return CacheErr.NonSync;
            }

            pub fn push(_: *Self) CacheErr!void {}
        };

        const BitMap: type = struct {
            fn obtain(ipool: BitMaxIPool) struct { BitMaxIPool, u4 } {
                return .{
                    ipool / BitMapStorage.map_size,
                    @intCast(ipool % BitMapStorage.map_size),
                };
            }

            pub fn bitMapIndexToIPool(bindex: BitMaxIPool, mindex: BitMaxIPool) BitMaxIPool {
                return (bindex * BitMapStorage.map_size) + mindex;
            }

            pub fn read(self: *Self, ipool: BitMaxIPool) BitMapStorage.Map {
                const index, const offset = @call(.always_inline, obtain, .{ipool});
                return self.bitmap[index].map[offset];
            }

            pub fn addrsToIPool(self: *Self, obj: *t) ?BitMaxIPool {
                return if (@intFromPtr(obj) < @intFromPtr(&self.pool.?[0]) and @intFromPtr(obj) > @intFromPtr(&self.pool.?[self.pool.?.len - 1])) null else r: {
                    break :r @intCast((@intFromPtr(obj) - @intFromPtr(&self.pool.?[0])) / @sizeOf(t));
                };
            }

            pub fn set(self: *Self, ipool: BitMaxIPool, value: BitMapStorage.Map) void {
                const index, const offset = @call(.always_inline, obtain, .{ipool});
                self.bitmap[index].map[offset] = value;
            }
        };

        fn auto(self: *Self) InternalErr!*t {
            return r: {
                const init, const end = t: {
                    if (self.cindex != null and self.cindex.? + @intFromEnum(optimize.range) < self.cache.len)
                        break :t .{ self.cindex.?, self.cindex.? + @intFromEnum(optimize.range) };
                    break :t .{ 0, @intFromEnum(optimize.range) };
                };
                for (init..end) |_| {
                    break :r @call(.always_inline, &fast, .{ self, false }) catch continue;
                }
                t: {
                    return @call(.never_inline, &continuos, .{ self, self.lindex orelse break :t {}, self.lindex.? + @intFromEnum(optimize.range) }) catch break :t {};
                }
                return @call(.never_inline, &continuos, .{ self, null, null }) catch unreachable; // Se realmente tem memoria disponivel nunca chegara no catch
            };
        }

        fn fast(self: *Self, passthrough: bool) InternalErr!*t {
            return r: {
                const Steps: type = enum {
                    shot,
                    sync,
                    continuos,
                };
                sw: switch (Steps.shot) {
                    .shot => {
                        if (self.cindex) |cindex| {
                            break :r if (@call(.always_inline, &BitMap.read, .{ self, self.cache[cindex] orelse continue :sw .sync }) == .busy) continue :sw .sync else u: {
                                @call(.always_inline, &BitMap.set, .{ self, self.cache[cindex].?, .busy });
                                self.allocs += 1;
                                self.cindex = null;
                                self.cindex = if (cindex < self.cache.len - 1) cindex + 1 else null;
                                self.lindex = if (self.lindex) |_| i: {
                                    if (self.lindex.? != self.cache[cindex]) break :i self.lindex.?;
                                    if (self.lindex.? < self.pool.?.len - 1) break :i self.lindex.? + 1;
                                    break :i null;
                                } else null;
                                const ipool = self.cache[cindex].?;
                                self.cache[cindex] = null;
                                break :u &self.pool.?[ipool];
                            };
                        }
                        continue :sw .sync;
                    },

                    .sync => {
                        switch (comptime cache.sync) {
                            .burning => {
                                @call(.always_inline, &CacheAction.sync, .{self}) catch continue :sw .continuos;
                                continue :sw .shot;
                            },

                            .heated, .chilled => {
                                if (self.cmiss >= @intFromEnum(cache.sync)) {
                                    @call(.never_inline, &CacheAction.sync, .{self}) catch continue :sw .continuos;
                                    self.cmiss = 0;
                                    continue :sw .shot;
                                }
                                self.cmiss += 1;
                                continue :sw .continuos;
                            },
                        }
                    },

                    .continuos => {
                        break :r if (passthrough) @call(.never_inline, &continuos, .{ self, null, null }) catch unreachable else break :r InternalErr.NonOptimize;
                    },
                }
                unreachable;
            };
        }

        fn continuos(self: *Self, init: ?BitMaxIPool, end: ?BitMaxIPool) InternalErr!*t {
            return r: {
                for (init orelse 0..if (end == null or end.? > self.pool.?.len) self.pool.?.len else end.?) |i| {
                    if (@call(.always_inline, &BitMap.read, .{ self, @as(BitMaxIPool, @intCast(i)) }) == .free) {
                        @call(.always_inline, &BitMap.set, .{ self, @as(BitMaxIPool, @intCast(i)), .busy });
                        self.allocs += 1;
                        self.lindex = if (i < self.pool.?.len - 1) @as(BitMaxIPool, @intCast(i)) + 1 else null;
                        break :r &self.pool.?[i];
                    }
                }
                break :r InternalErr.Rangeless;
            };
        }

        fn poolInit(self: *Self) Err!void {
            switch (comptime config.arch.options.target) {
                .i386 => {
                    if ((@sizeOf(t) * num) > config.kernel.options.kernel_page_size) {
                        @compileError("SOA still does not support objects larger than a page");
                    }
                    _ = zero_init;
                    self.page = mm.allocPage() catch return Err.UndefinedAction;
                    self.pool = @as([*]t, @ptrCast(@alignCast(self.page.virtual.ptr)))[0 .. config.kernel.options.kernel_page_size / @sizeOf(t)];
                },
                else => @compileError("SOA does not yet support " ++ @tagName(config.arch.options.target)),
            }
        }

        fn poolDeinit(self: *Self) Err!void {
            switch (comptime config.arch.options.target) {
                .i386 => mm.freePage(&self.page) catch return Err.UndefinedAction,
                else => {},
            }
        }

        pub fn alloc(self: *Self, calling: ?Optimize.CallingAlloc) Err!*t {
            if (self.pool == null)
                try @call(.never_inline, poolInit, .{self});
            switch (optimize.type) {
                .dinamic => {
                    if (self.pool == null) return Err.NotInitialized;
                    return if (self.allocs >= num) Err.OutOfMemory else switch (calling orelse .auto) {
                        Optimize.CallingAlloc.auto => @call(.never_inline, &auto, .{self}) catch Err.UndefinedAction,
                        Optimize.CallingAlloc.continuos => @call(.never_inline, &continuos, .{ self, self.lindex, @as(u16, @intCast(self.pool.?.len)) }) catch Err.UndefinedAction,
                        Optimize.CallingAlloc.fast => @call(.never_inline, &fast, .{ self, true }) catch Err.UndefinedAction,
                    };
                },

                .linear => {
                    if (self.pool == null) return Err.NotInitialized;
                    return if (self.allocs >= num) Err.OutOfMemory else @call(.always_inline, &continuos, .{ self, self.lindex, null }) catch Err.UndefinedAction;
                },

                .optimized => {
                    if (self.pool == null) return Err.NotInitialized;
                    return if (self.allocs >= num) Err.OutOfMemory else @call(.always_inline, &auto, .{self}) catch Err.UndefinedAction;
                },
            }
        }

        pub fn free(self: *Self, obj: *t) Err!void {
            return r: {
                if (self.pool == null) return Err.NotInitialized;
                const ipool = @call(.always_inline, &BitMap.addrsToIPool, .{ self, obj });
                if (ipool == null) break :r Err.IndexOutBounds;
                if (@call(.always_inline, &BitMap.read, .{ self, ipool.? }) == .free) break :r Err.DoubleFree;
                @call(.always_inline, &BitMap.set, .{ self, ipool.?, .free });
                self.allocs -= 1;
                self.lindex = if (self.lindex) |_| self.lindex else ipool;
                if (optimize.type != .linear)
                    self.cindex = ipool;
                if (self.allocs == 0)
                    @call(.never_inline, poolDeinit, .{self}) catch {};
            };
        }
    };
}
