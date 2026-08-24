// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: saturn.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Esse arquivo e responsavel por juntar todas as partes do
// kernel em um unico arquivo

const enable_obsolete: bool = false;

pub const modules: type = @import("modules.zig");
pub const fusioners: type = @import("fusioners.zig");
pub const fusium: type = @import("kernel/fusium/core.zig");
pub const supervisor: type = if (enable_obsolete) @import("kernel/supervisor/supervisor.zig") else @compileError("supervisor is obsolete"); // NOTE: Tmp Obsolete
pub const decls: type = @import("kernel/decls.zig");
pub const ar: type = @import("kernel/ar/ar.zig");
pub const asl: type = @import("kernel/asl/asl.zig");
pub const csl: type = @import("kernel/csl/csl.zig");
pub const kparam: type = @import("kernel/kparam/kparam.zig");
pub const codes: type = @import("codes.zig");

pub const core: type = struct {
    pub const module: type = @import("kernel/core/module/module.zig");
    pub const vfs: type = @import("kernel/core/vfs/vfs.zig");
    pub const devices: type = @import("kernel/core/devices/devices.zig");
    pub const fs: type = @import("kernel/core/fs/fs.zig");
    pub const events: type = @import("kernel/core/events/events.zig");
};

pub const modsys: type = struct {
    pub const core: type = @import("kernel/modsys/modsys.zig");
    pub const modules: type = @import("kernel/modsys/modules.zig");
    pub const smll: type = @import("kernel/modsys/smll.zig");
};

pub const interfaces: type = struct {
    pub const fusium: type = @import("kernel/fusium/fusium.zig");
    pub const devices: type = @import("lib/interfaces/devices.zig");
    pub const fs: type = @import("lib/interfaces/fs.zig");
    pub const module: type = @import("lib/interfaces/module.zig");
    pub const arch: type = @import("lib/interfaces/arch.zig");
    pub const vfs: type = @import("lib/interfaces/vfs.zig");
    pub const events: type = @import("lib/interfaces/events.zig");
};

pub const lib: type = struct {
    pub const kernel: type = struct {
        pub const alloc: type = @import("lib/kernel/alloc.zig");
        pub const fmt: type = @import("lib/kernel/fmt.zig");
        pub const mem: type = @import("lib/kernel/mem.zig");
        pub const meta: type = @import("lib/kernel/meta.zig");
        pub const c: type = @import("lib/kernel/c.zig");
        pub const linked_list: type = @import("lib/kernel/linked_list.zig");
        pub const binary_tree: type = @import("lib/kernel/binary_tree.zig");
        pub const hash_table: type = @import("lib/kernel/hash_table.zig");
        pub const writer: type = @import("lib/kernel/writer.zig");
    };
};

pub const config: type = struct {
    pub const modules: type = @import("config/modules/config.zig");
    pub const arch: type = @import("config/arch/config.zig");
    pub const compile: type = @import("config/compile/config.zig");
    pub const fusium: type = @import("config/fusium/config.zig");
    pub const kernel: type = struct {
        pub const options: type = @import("config/kernel/options.zig");
        pub const mem: type = @import("config/kernel/segments.zig");
        pub const kparam: type = @import("config/kernel/kparam.zig");
    };
};
