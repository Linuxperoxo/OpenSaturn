// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// === Teste Info ===
//
// OS: Gentoo Linux x86_64
// Zig: 0.15.1
// Tester: Linuxperoxo
// Status: Pass

const Optimize_T: type = @import("soa.zig").Optimize_T;
const Cache_T: type = @import("soa.zig").Cache_T;

const buildObjAllocator = @import("soa.zig").buildObjAllocator;

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
        errdefer {
            @import("std").debug.print("FAILED -> FAST: optimize: {any}, cache: {any}\n", .{
                SOAAllocator_T.Options.config.optimize , SOAAllocator_T.Options.config.cache
            });
        }
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
        errdefer {
            @import("std").debug.print("FAILED -> FAST: optimize: {any}, cache: {any}\n", .{
                SOAAllocator_T.Options.config.optimize , SOAAllocator_T.Options.config.cache
            });
        }
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
        errdefer {
            @import("std").debug.print("FAILED -> AUTO: optimize: {any}, cache: {any}\n", .{
                SOAAllocator_T.Options.config.optimize , SOAAllocator_T.Options.config.cache
            });
        }
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
