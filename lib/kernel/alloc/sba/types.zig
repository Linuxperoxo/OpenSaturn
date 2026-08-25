// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const mm: type = @import("root").mm;
const config: type = @import("root").config;

pub const Personality: type = struct {
    resize: bool = true,
    resize_err: bool = false,
};

//pub const Cache: type = struct {
//    size: CacheSize = .auto,
//
//    pub const CacheSize: type = enum(u3) {
//        small = 4,
//        large = 2,
//        huge = 1,
//    };
//};
