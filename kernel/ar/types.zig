// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const TargetCode_T: type = struct {
    arch: type,
    entry: type,
    init: ?type = null,
    interrupts: ?type = null,
    config: ?type = null,
    segments: ?type = null,
    physio: ?type = null,
    mm: ?type = null,
    lib: ?struct {
        kernel: ?type,
        userspace: ?type,
    } = null,
};

pub const Targets_T: type = struct {
    @"i386": TargetCode_T,
    amd64: TargetCode_T,
    arm: TargetCode_T,
    riscv64: TargetCode_T,
    avr: TargetCode_T,
    xtensa: TargetCode_T,
};
