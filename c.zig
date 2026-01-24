// ┌────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: c.zig      │
// │            Author: Linuxperoxo             │
// └────────────────────────────────────────────┘

const ar: type = @import("saturn.zig").ar;
const decls: type = @import("saturn.zig").decls;
const modules: type = @import("saturn.zig").modules;
const config: type = @import("saturn.zig").config;

const code: type = ar.target_code;

pub const c_sources = if(!config.compile.options.CSupport) &[_][]const[]const u8 {} else r: {
    const c_sources_decl, const c_sources_decl_type = .{
        decls.what_is_decl(.c_sources),
        decls.what_is_decl_type(.c_sources),
    };

    var sources: [modules.__SaturnAllMods__.len][]const[]const u8 = undefined;
    var sources_index: usize = 0;

    for(modules.__SaturnAllMods__) |module| {
        if(!@hasDecl(module, c_sources_decl)) continue;
        if(@TypeOf(@field(module, c_sources_decl)) != c_sources_decl_type)
            @compileError("");
        sources[sources_index] = @field(module, c_sources_decl);
        sources_index += 1;
    }
    break :r @as(*[sources][]const[]const u8, @ptrCast(&sources)).*;
};

pub const c_includes = if(!config.compile.options.CSupport) &[_][]const[]const u8 {} else r: {
    const c_includes_decl, const c_includes_decl_type = .{
        decls.what_is_decl(.c_includes),
        decls.what_is_decl_type(.c_includes),
    };

    var includes: [modules.__SaturnAllMods__.len][]const[]const u8 = undefined;
    var includes_index: usize = 0;

    for(modules.__SaturnAllMods__) |module| {
        if(!@hasDecl(module, c_includes_decl)) continue;
        if(@TypeOf(@field(module, c_includes_decl)) != c_includes_decl_type)
            @compileError("");
        includes[includes_index] = @field(module, c_includes_decl);
        includes_index += 1;
    }
    break :r @as(*[includes][]const[]const u8, @ptrCast(&includes)).*;
};
