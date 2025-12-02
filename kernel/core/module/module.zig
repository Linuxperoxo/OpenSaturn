// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const Mod_T: type = @import("types.zig").Mod_T;
pub const ModType_T: type = @import("types.zig").ModType_T;
pub const ModErr_T: type = @import("types.zig").ModErr_T;
pub const ModuleDescriptionTarget_T: type =  @import("types.zig").ModuleDescriptionTarget_T;
pub const ModuleDescription_T: type = @import("types.zig").ModuleDescription_T;

pub const srchmod = @import("main.zig").srchmod;
pub const inmod = @import("main.zig").inmod;
pub const rmmod = @import("main.zig").rmmod;
