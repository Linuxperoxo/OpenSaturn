// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig   │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const interfaces: type = @import("root").interfaces;

pub const Vertex_T: type = struct {
    module: ?*const interfaces.module.ModuleDescription_T,
    childs: [16]?*Vertex_T,
    flags: struct {
        done: bool,
        any: bool,
    },
};
