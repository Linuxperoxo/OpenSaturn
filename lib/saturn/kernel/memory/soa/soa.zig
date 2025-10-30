// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: soa.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// === Saturn Object Allocator ===
//      A SLUB-like allocator
// === === === === === === === ===

const mm: type = if(builtin.is_test) void else @import("root").mm;
const config: type = if(builtin.is_test) void else @import("root").config;
const builtin: type = @import("builtin");

pub const Optimize_T: type = @import("types.zig").Optimize_T;
pub const Cache_T: type = @import("types.zig").Cache_T;

pub fn buildObjAllocator(
    comptime T: type,
    comptime zero_init: bool,
    comptime num: usize,
    comptime optimize: Optimize_T,
    comptime cache: Cache_T,
) type {
    comptime {
        if(@sizeOf(T) == 0) {
            @compileError(
                "SOA: type" ++
                @typeName(T) ++
                " cannot have size 0 (incomplete or invalid)."
            );
        }

        if(num == 0) {
            @compileError("SOA: obj num cannot be zero. This may cause invalid state.");
        }

        if((num % 2) != 0) {
            @compileError("SOA: obj num must be even. Provided value is odd.");
        }

        if(num <= 2) {
            @compileError("SOA: obj num must be greater than 2. Provided value is too small. Use 4 with value");
        }
    }
    return struct {
        pool: ?[]T = null,
        allocs: BitMaxIPool = 0,
        bitmap: [r: {
            break :r (num / BitMap_T.MapSize) + if((num % BitMap_T.MapSize) != 0) 1 else 0;
            // essa calculo garante que tenha a quantidade certa
            // de bitmap para objetos caso nao seja multiplo do MapSize.
        }]BitMap_T = [_]BitMap_T {
            BitMap_T {
                .map = [_]BitMap_T.Map_T {
                    .free,
                } ** BitMap_T.MapSize,
            },
        } ** ((num / BitMap_T.MapSize) + if((num % BitMap_T.MapSize) != 0) 1 else 0),
        lindex: ?BitMaxIPool = null,
        cindex: CindexType_T = if(CindexType_T == void) {} else null,
        cmiss: CmissType_T = if(CmissType_T == void) {} else 0,
        cache: CacheType_T = if(optimize.type == .linear) {} else [_]?BitMaxIPool {
            null
        } ** CacheElementSize,
        page: Page_T = if(Page_T == void) {} else undefined,

        const Self: type = @This();
        const Page_T: type = if(builtin.is_test) void else switch(config.arch.options.Target) {
            .i386 => mm.AllocPage_T,
            else => void,
        };
        const BitMap_T: type = struct {
            map: [MapSize]Map_T align(1),

            pub const MapSize: comptime_int = 8;
            pub const Map_T: type = enum(u1) {
                free,
                busy,
            };
        };
        const BitMaxIPool: type = switch(num) {
            1...255 => u8,
            256...65535 => u16,
            else => usize,
        };
        const InternalErr_T: type = error {
            NonOptimize,
            Rangeless,
        };
        const CacheType_T: type = if(optimize.type == .linear) void else [CacheElementSize]?BitMaxIPool;
        const CindexType_T: type = if(optimize.type == .linear) void else ?BitMaxIPool;
        const CmissType_T: type = r: {
            if(optimize.type == .linear) break :r void;
            switch(cache.sync) {
                .burning => break :r void,
                else => break :r u2,
            }
        };
        const CacheElementSize = r: {
            const divisor = if(cache.size != .auto and num >= @intFromEnum(cache.size)) @intFromEnum(cache.size) else t: {
                sw: switch(@sizeOf(T)) {
                    1...16 => if(num <= 16) break :t @intFromEnum(Cache_T.CacheSize_T.huge) else continue :sw 17,
                    17...32 => if(num <= 32) break :t @intFromEnum(Cache_T.CacheSize_T.large) else continue :sw 33,
                    else => break :t @intFromEnum(Cache_T.CacheSize_T.small),
                }
            };
            break :r num / divisor;
        };

        pub const err_T: type = error {
            OutOfMemory,
            DoubleFree,
            IndexOutBounds,
            UndefinedAction,
            NotInitialized,
        };

        pub const Options: type = struct {
            pub const Type: type = T;
            pub const config: struct { optimize: Optimize_T, cache: Cache_T } = .{
                .optimize = optimize,
                .cache = cache,
            };
        };

        const CacheAction: type = struct {
            pub const CacheErr_T: type = error {
                NonSync,
            };

            var midHigh: u1 = 1;
            pub fn sync(self: *Self) CacheErr_T!void {
                const init, const end = switch(cache.mode) {
                    .PrioritizeHits => .{
                        0, self.cache.len
                    },

                    .PrioritizeSpeed => .{
                        (self.cache.len / 2) * midHigh,
                        (self.cache.len / 2) + ((self.cache.len / 2) * midHigh),
                    }
                };
                var first: ?BitMaxIPool = null;
                var bindex: BitMaxIPool, var mindex: BitMaxIPool = .{ 0, 0 };
                for(init..end) |cindex| {
                    if(self.cache[cindex]) |_| continue;
                    r: {
                        while(bindex < self.bitmap.len) : (bindex += 1) {
                            while(mindex < BitMap_T.MapSize) : (mindex += 1) {
                                if(self.bitmap[bindex].map[mindex] == .free) {
                                    self.cache[cindex] = @call(.always_inline, &BitMap.bitMapIndexToIPool, .{
                                        bindex, mindex
                                    });
                                    first = if(first) |_| first else @intCast(cindex);
                                    mindex += 1;
                                    break :r {};
                                }
                            }
                            mindex = 0;
                        }
                    }
                }
                midHigh ^= 1;
                self.cindex = first orelse return CacheErr_T.NonSync;
            }

            pub fn push(_: *Self) CacheErr_T!void {

            }
        };

        const BitMap: type = struct {
            fn obtain(ipool: BitMaxIPool) struct { BitMaxIPool, u4 } {
                return .{
                    ipool / BitMap_T.MapSize,
                    @intCast(ipool % BitMap_T.MapSize),
                };
            }

            pub fn bitMapIndexToIPool(bindex: BitMaxIPool, mindex: BitMaxIPool) BitMaxIPool {
                return (bindex * BitMap_T.MapSize) + mindex;
            }

            pub fn read(self: *Self, ipool: BitMaxIPool) BitMap_T.Map_T {
                const index, const offset = @call(.always_inline, obtain, .{
                    ipool
                });
                return self.bitmap[index].map[offset];
            }

            pub fn addrsToIPool(self: *Self, obj: *T) ?BitMaxIPool {
                return if(@intFromPtr(obj) < @intFromPtr(&self.pool.?[0]) and @intFromPtr(obj) > @intFromPtr(&self.pool.?[self.pool.?.len - 1])) null else r: {
                    break :r @intCast((@intFromPtr(obj) - @intFromPtr(&self.pool.?[0])) / @sizeOf(T));
                };
            }

            pub fn set(self: *Self, ipool: BitMaxIPool, value: BitMap_T.Map_T) void {
                const index, const offset = @call(.always_inline, obtain, .{
                    ipool
                });
                self.bitmap[index].map[offset] = value;
            }
        };

        fn auto(self: *Self) InternalErr_T!*T {
            return r: {
                const init, const end = t: {
                    if(self.cindex != null and self.cindex.? + @intFromEnum(optimize.range) < self.cache.len)
                        break :t .{ self.cindex.?, self.cindex.? + @intFromEnum(optimize.range) };
                    break :t .{ 0, @intFromEnum(optimize.range) };
                };
                for(init..end) |_| {
                    break :r @call(.always_inline, &fast, .{
                        self, false
                    }) catch continue;
                }
                t: {
                    return @call(.never_inline, &continuos, .{
                        self, self.lindex orelse break :t {}, self.lindex.? + @intFromEnum(optimize.range)
                    }) catch break :t {};
                }
                return @call(.never_inline, &continuos, .{
                    self, null, null
                }) catch unreachable; // Se realmente tem memoria disponivel nunca chegara no catch
            };
        }

        fn fast(self: *Self, passthrough: bool) InternalErr_T!*T {
            return r: {
                const Steps: type = enum {
                    shot,
                    sync,
                    continuos,
                };
                sw: switch(Steps.shot) {
                    .shot => {
                        if(self.cindex) |cindex| {
                            break :r if(@call(.always_inline, &BitMap.read, .{
                                self, self.cache[cindex] orelse continue :sw .sync
                            }) == .busy) continue :sw .sync else u: {
                            @call(.always_inline, &BitMap.set, .{
                                self, self.cache[cindex].?, .busy
                            });
                            self.allocs += 1;
                            self.cindex = null;
                            self.cindex = if(cindex < self.cache.len - 1) cindex + 1 else null;
                            self.lindex = if(self.lindex) |_| i: {
                                if(self.lindex.? != self.cache[cindex]) break :i self.lindex.?;
                                if(self.lindex.? < self.pool.?.len - 1) break :i self.lindex.? + 1;
                                break :i null;
                            } else null;
                            const ipool = self.cache[cindex].?;
                            self.cache[cindex] = null;
                            break :u &self.pool.?[ipool];
                        };}
                        continue :sw .sync;
                    },

                    .sync => {
                        switch(comptime cache.sync) {
                            .burning => {
                                @call(.always_inline, &CacheAction.sync, .{
                                    self
                                }) catch continue :sw .continuos;
                                continue :sw .shot;
                            },

                            .heated, .chilled => {
                                if(self.cmiss >= @intFromEnum(cache.sync)) {
                                    @call(.never_inline, &CacheAction.sync, .{
                                        self
                                    }) catch continue :sw .continuos; self.cmiss = 0;
                                    continue :sw .shot;
                                }
                                self.cmiss += 1; continue :sw .continuos;
                            },
                        }
                    },

                    .continuos => {
                        break :r if(passthrough) @call(.never_inline, &continuos, .{
                            self, null, null
                        }) catch unreachable else break :r InternalErr_T.NonOptimize;
                    },
                }
                unreachable;
            };
        }

        fn continuos(self: *Self, init: ?BitMaxIPool, end: ?BitMaxIPool) InternalErr_T!*T {
            return r: {
                for(
                    init orelse 0
                    ..
                    if(end == null or end.? > self.pool.?.len) self.pool.?.len else end.?
                ) |i| {
                    if(@call(.always_inline, &BitMap.read, .{
                        self, @as(BitMaxIPool, @intCast(i))
                    }) == .free) {
                        @call(.always_inline, &BitMap.set, .{
                            self, @as(BitMaxIPool, @intCast(i)), .busy
                        });
                        self.allocs += 1;
                        self.lindex = if(i < self.pool.?.len - 1) @as(BitMaxIPool, @intCast(i)) + 1 else null;
                        break : r &self.pool.?[i];
                    }
                }
                break :r InternalErr_T.Rangeless;
            };
        }

        pub fn ainit(self: *Self) err_T!void {
            if(builtin.is_test) {
                const std: type = @import("std");
                var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
                var allocator = gpa.allocator();
                self.pool = allocator.alloc(T, num) catch return err_T.UndefinedAction;
                return;
            }
            switch(comptime config.arch.options.Target) {
                .i386 => {
                    if((@sizeOf(T) * num) > config.kernel.options.kernel_page_size) {
                        @compileError("SOA still does not support objects larger than a page");
                    }
                    _ = zero_init;
                    self.page = mm.alloc_page() catch return err_T.UndefinedAction;
                    self.pool = @as([*]T, @alignCast(@ptrCast(self.page.virtual.ptr)))[
                        0..config.kernel.options.kernel_page_size / @sizeOf(T)
                    ];
                },
                else => @compileError("SOA does not yet support " ++ @tagName(config.arch.options.Target)),
            }
        }

        pub fn adeinit(self: *Self) void {
            switch(comptime config.arch.options.Target) {
                .i386 => mm.page_free(&self.page) catch return err_T.UndefinedAction,
                else => {},
            }
        }

        pub const alloc = switch(optimize.type) {
            .dinamic => struct {
                pub fn dinamic(self: *Self, calling: Optimize_T.CallingAlloc_T) err_T!*T {
                    if(self.pool == null) return err_T.NotInitialized;
                    return if(self.allocs >= num) err_T.OutOfMemory else switch(calling) {
                        Optimize_T.CallingAlloc_T.auto => @call(.never_inline, &auto, .{
                            self
                        }) catch err_T.UndefinedAction,
                        Optimize_T.CallingAlloc_T.continuos => @call(.never_inline, &continuos, .{
                            self, self.lindex, @as(u16, @intCast(self.pool.?.len))
                        }) catch err_T.UndefinedAction,
                        Optimize_T.CallingAlloc_T.fast => @call(.never_inline, &fast, .{
                            self, true
                        }) catch err_T.UndefinedAction,
                    };
                }
            }.dinamic,

            .linear => struct {
                pub fn linear(self: *Self) err_T!*T {
                    if(self.pool == null) return err_T.NotInitialized;
                    return if(self.allocs >= num) err_T.OutOfMemory else @call(.always_inline, &continuos, .{
                        self, self.lindex, null
                    }) catch err_T.UndefinedAction;
                }
            }.linear,

            .optimized => struct {
                pub fn optimized(self: *Self) err_T!*T {
                    if(self.pool == null) return err_T.NotInitialized;
                    return if(self.allocs >= num) err_T.OutOfMemory else @call(.always_inline, &auto, .{
                        self
                    }) catch err_T.UndefinedAction;
                }
            }.optimized,
        };

        pub fn free(self: *Self, obj: *T) err_T!void {
            return r: {
                if(self.pool == null) return err_T.NotInitialized;
                const ipool = @call(.always_inline, &BitMap.addrsToIPool, .{
                    self, obj
                });
                if(ipool == null) break :r err_T.IndexOutBounds;
                if(@call(.always_inline, &BitMap.read, .{
                    self, ipool.?
                }) == .free) break :r err_T.DoubleFree;
                @call(.always_inline, &BitMap.set, .{
                    self, ipool.?, .free
                });
                self.allocs -= 1;
                self.lindex = if(self.lindex) |_| self.lindex else ipool;
                if(optimize.type != .linear)
                    self.cindex = ipool;
            };
        }
    };
}

// === SOA TESTS ===
const quat: comptime_int = 8192;
const TestErr_T: type = error {
    TestUnreachableCode,
    DoubleAllocInAddrs,
};
const allocators = r: {
    var allocs: [72]type = undefined;
    const optmizeAlloc: [3]Optimize_T.OptimizeRange_T = .{
        .huge, .large, .small
    };
    const cacheSync: [3]Cache_T.CacheSync_T = .{
        .burning, .chilled, .heated
    };
    const cacheSize: [4]Cache_T.CacheSize_T = .{
        .auto, .huge, .large, .small
    };
    const cacheMode: [2]Cache_T.CacheMode_T = .{
        .PrioritizeHits, .PrioritizeSpeed
    };
    var allocator_index: u32 = 0;
    for(optmizeAlloc) |alloc| {
        for(cacheSync) |sync| {
            for(cacheSize) |size| {
                for(cacheMode) |mode| {
                    allocs[allocator_index] = buildObjAllocator(
                        struct { u64, u64, u64, u64, u64, u64, u64 },
                        false,
                        quat,
                        .{
                            .type = .dinamic,
                            .range = alloc,
                        },
                        .{
                            .mode = mode,
                            .size = size,
                            .sync = sync,
                        },
                    );
                    allocator_index += 1;
                }
            }
        }
    }
    break :r allocs;
};

test "SOA Continuos Alloc" {
    inline for(0..allocators.len) |a| {
        const SOAAllocator_T: type = allocators[a];
        var allocator: SOAAllocator_T = .{};
        @import("std").debug.print("== CONTINUOS:\n* optmize: {any}\n* cache: {any}\n==\n", .{
            SOAAllocator_T.Options.config.optimize , SOAAllocator_T.Options.config.cache
        });
        try allocator.ainit();
        for(0..quat) |i| {
            const obj = try SOAAllocator_T.alloc(
                &allocator, Optimize_T.CallingAlloc_T.continuos,
            );
            for(0..i) |j|
                if(@intFromPtr(obj) == @intFromPtr(&allocator.pool.?[j])) return TestErr_T.DoubleAllocInAddrs;
            try SOAAllocator_T.free(
                &allocator, obj
            );
        }
        for(0..quat) |_| {
            _ = try SOAAllocator_T.alloc(
                &allocator, Optimize_T.CallingAlloc_T.continuos,
            );
        }
        _ = SOAAllocator_T.alloc(
            &allocator, Optimize_T.CallingAlloc_T.continuos,
        ) catch |err| switch(err) {
            SOAAllocator_T.err_T.OutOfMemory => {},
            else => return err,
        };
    }
}

test "SOA Fast Alloc" {
    inline for(0..allocators.len) |a| {
        const SOAAllocator_T: type = allocators[a];
        var allocator: SOAAllocator_T = .{};
        @import("std").debug.print("== FAST:\n* optmize: {any}\n* cache: {any}\n==\n", .{
            SOAAllocator_T.Options.config.optimize , SOAAllocator_T.Options.config.cache
        });
        try allocator.ainit();
        for(0..quat) |i| {
            const obj = try SOAAllocator_T.alloc(
                &allocator, Optimize_T.CallingAlloc_T.fast,
            );
            for(0..i) |j|
                if(@intFromPtr(obj) == @intFromPtr(&allocator.pool.?[j])) return TestErr_T.DoubleAllocInAddrs;
        }
        _ = SOAAllocator_T.alloc(
            &allocator, Optimize_T.CallingAlloc_T.fast,
        ) catch |err| switch(err) {
            SOAAllocator_T.err_T.OutOfMemory => {},
            else => return err,
        };
        for(0..quat) |i| {
            SOAAllocator_T.free(
                &allocator, @ptrFromInt(@intFromPtr(&allocator.pool.?[0]) + (@sizeOf( struct { u64, u64, u64, u64, u64, u64, u64 }) * i))
            ) catch return TestErr_T.TestUnreachableCode;
        }
    }
}

test "SOA Auto Alloc" {
    inline for(0..allocators.len) |a| {
        const SOAAllocator_T: type = allocators[a];
        var allocator: SOAAllocator_T = .{};
        @import("std").debug.print("== AUTO:\n* optmize: {any}\n* cache: {any}\n==\n", .{
            SOAAllocator_T.Options.config.optimize , SOAAllocator_T.Options.config.cache
        });
        try allocator.ainit();
        for(0..quat) |i| {
            const obj = try SOAAllocator_T.alloc(
                &allocator, Optimize_T.CallingAlloc_T.auto,
            );
            for(0..i) |j|
                if(@intFromPtr(obj) == @intFromPtr(&allocator.pool.?[j])) return TestErr_T.DoubleAllocInAddrs;
        }
        _ = SOAAllocator_T.alloc(
            &allocator, Optimize_T.CallingAlloc_T.auto,
        ) catch |err| switch(err) {
            SOAAllocator_T.err_T.OutOfMemory => {},
            else => return err,
        };
        for(0..quat) |i| {
            SOAAllocator_T.free(
                &allocator, @ptrFromInt(@intFromPtr(&allocator.pool.?[0]) + (@sizeOf( struct { u64, u64, u64, u64, u64, u64, u64 }) * i))
            ) catch return TestErr_T.TestUnreachableCode;
        }
    }
}
