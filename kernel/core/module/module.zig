// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: module.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const Mod: type = @import("types.zig").Mod;
pub const ModControlFlags: type = @import("types.zig").ModControlFlags;
pub const ModType: type = @import("types.zig").ModType;
pub const ModErr: type = @import("types.zig").ModErr;
pub const ModuleDescriptionTarget: type =  @import("types.zig").ModuleDescriptionTarget;
pub const ModuleDescription: type = @import("types.zig").ModuleDescription;
pub const ModuleDescriptionLibMine: type = @import("types.zig").ModuleDescriptionLibMine;
pub const ModuleDescriptionLibOut: type = @import("types.zig").ModuleDescriptionLibOut;

pub const initmod = @import("extern.zig").initmod;
pub const killmod = @import("extern.zig").killmod;
pub const schmod = @import("extern.zig").schmod;
