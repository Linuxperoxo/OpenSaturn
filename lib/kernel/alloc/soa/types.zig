// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const Optimize: type = struct {
    /// Defines which allocation strategy will be used.
    ///
    /// * dynamic: Lets you choose the allocation mode at runtime
    /// * linear: Always allocates sequentially in linear order,
    ///   designed for many consecutive allocations
    /// * optimized: Always prioritizes optimization. Use this only when
    ///   the allocator is “hot,” i.e. many allocations and frees in balance
    ///
    /// NOTE: For workloads with many consecutive allocations and almost no frees,
    /// use `linear`. For balanced allocation/free patterns, use `optimized`. If you
    /// want full control, use `dynamic`.
    ///
    /// Default: .optimized
    type: OptimizeAlloc = .optimized,

    /// Alignment of allocated objects.
    ///
    /// Default: .in8
    alignment: OptimizeAlign = .in8,

    /// Number of optimization attempts the allocator will try.
    /// Using a very large value may add overhead in `optimized` mode
    /// if it fails to optimize the allocation.
    ///
    /// * small: 2 attempts
    /// * large: 3 attempts
    /// * huge: 4 attempts
    ///
    /// Default: .large
    range: OptimizeRange = .large,

    pub const OptimizeAlloc: type = enum {
        dinamic,
        linear,
        optimized,
    };

    pub const OptimizeAlign: type = enum(u5) {
        in2 = 2,
        in4 = 4,
        in8 = 8,
        in16 = 16,
    };

    pub const OptimizeRange: type = enum(u5) {
        small = 2,
        large = 3,
        huge = 4,
    };

    pub const CallingAlloc: type = enum(u2) {
        continuos,
        fast,
        auto,
    };
};

pub const Cache: type = struct {
    /// Cache size. A larger cache can reduce misses,
    /// but cache synchronization may take longer.
    ///
    /// * auto: Automatically defines the cache size
    /// * small: Smaller cache, about 1/4 of the total number of objects
    /// * large: Default choice for most cases, about 2/4 of the total objects
    /// * huge: Full cache, space for all objects
    ///
    /// Default: .auto
    size: CacheSize = .auto,

    /// Frequency of cache synchronization. Higher frequency
    /// reduces cache errors, but may negatively impact allocation.
    ///
    /// * frozen: Never synchronizes, useful when many entries remain free
    /// * chilled: Waits for 3 cache misses before synchronizing
    /// * heated: Waits for 2 cache misses before synchronizing
    /// * burning: Always synchronizes on every allocation
    ///
    /// Default: .heated
    sync: CacheSync = .heated,

    /// How synchronization is performed. Choosing the right mode
    /// can significantly reduce synchronization cost, especially
    /// for larger caches.
    ///
    /// * prioritize_hits: Synchronizes the entire cache. Slower, but good
    ///   when syncs are infrequent (e.g., when using `sync = chilled`)
    /// * prioritize_speed: Synchronizes only half of the cache, which helps
    ///   larger caches maintain steady synchronization and avoid misses
    ///
    /// Default: .prioritize_hits
    mode: CacheMode = .prioritize_hits,

    pub const CacheMode: type = enum(u1) {
        prioritize_hits,
        prioritize_speed,
    };

    pub const CacheSize: type = enum(u3) {
        auto,
        small = 4,
        large = 2,
        huge = 1,
    };

    pub const CacheSync: type = enum(u2) {
        burning,
        chilled = 3,
        heated = 2,
    };
};
