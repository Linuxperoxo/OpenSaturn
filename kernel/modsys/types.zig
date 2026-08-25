// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig   │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;

pub const Vertex: type = struct {
    module: ?*const interfaces.module.ModuleDescription,
    childs: [16]?*Vertex,
    flags: struct {
        done: bool,
        any: bool,
    },
};
