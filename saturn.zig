// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: saturn.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Esse arquivo e responsavel por juntar todas as partes do
// kernel em um unico arquivo

pub const modules: type = @import("modules.zig");
pub const fusioners: type = @import("fusioners.zig");
pub const fusium: type = @import("kernel/fusium/core.zig");
pub const supervisor: type = @compileError("supervisor is obsolete"); // NOTE: Tmp Obsolete
pub const decls: type = @import("kernel/decls.zig");
pub const ar: type = @import("kernel/ar/ar.zig");
pub const asl: type = @import("kernel/asl/asl.zig");
pub const csl: type = @import("kernel/csl/csl.zig");
pub const kparam: type = @import("kernel/kparam/kparam.zig");
pub const codes: type = @import("codes.zig");
pub const rtests: type = @import("rtests.zig");
pub const srtr: type = @import("kernel/srtr/srtr.zig");

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
    pub const devices: type = @import("lib/saturn/interfaces/devices.zig");
    pub const fs: type = @import("lib/saturn/interfaces/fs.zig");
    pub const module: type = @import("lib/saturn/interfaces/module.zig");
    pub const arch: type = @import("lib/saturn/interfaces/arch.zig");
    pub const vfs: type = @import("lib/saturn/interfaces/vfs.zig");
    pub const events: type = @import("lib/saturn/interfaces/events.zig");
    pub const tests: type = @import("lib/saturn/interfaces/tests.zig");
};

pub const lib: type = struct {
    pub const saturn: type = struct {
        pub const memory: type = @import("lib/saturn/kernel/memory/memory.zig");
        pub const utils: type = @import("lib/saturn/kernel/utils/utils.zig");
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
        pub const test_suite: type = @import("config/kernel/test_suite.zig");
    };
};
