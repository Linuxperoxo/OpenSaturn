// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const mm: type = @import("root").mm;
const config: type = @import("root").config;

pub const Personality_T: type = struct {
    resize: bool = true,
    resizeErr: bool = false,
};

pub const Cache_T: type = struct {
    size: CacheSize_T = .auto,

    pub const CacheSize_T: type = enum(u3) {
        small = 4,
        large = 2,
        huge = 1,
    };
};
