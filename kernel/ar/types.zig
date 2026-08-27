// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("root").interfaces.arch;

pub const TargetCode: type = struct {
    target: arch.Target,
    arch: type,
    entry: type,
    init: ?type = null,
    interrupts: ?type = null,
    allocators: ?arch.ArchDescription.Allocators = null,
    config: ?type = null,
    physio: ?type = null,
    mm: ?type = null,
    lib: ?struct {
        kernel: ?type,
        userspace: ?type,
    } = null,
};
