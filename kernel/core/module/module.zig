// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const Mod_T: type = @import("types.zig").Mod;
pub const ModControlFlags_T: type = @import("types.zig").ModControlFlags_T;
pub const ModType_T: type = @import("types.zig").ModType;
pub const ModErr_T: type = @import("types.zig").ModErr_T;
pub const ModuleDescriptionTarget_T: type =  @import("types.zig").ModuleDescriptionTarget_T;
pub const ModuleDescription_T: type = @import("types.zig").ModuleDescription;
pub const ModuleDescriptionLibMine_T: type = @import("types.zig").ModuleDescriptionLibMine;
pub const ModuleDescriptionLibOut_T: type = @import("types.zig").ModuleDescriptionLibOut_T;

pub const initmod = @import("extern.zig").initmod;
pub const killmod = @import("extern.zig").killmod;
pub const schmod = @import("extern.zig").schmod;
