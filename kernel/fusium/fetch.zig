// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fetch.zig   │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const mem: type = @import("root").kernel.utils.mem;
const c: type = @import("root").kernel.utils.c;
const types: type = @import("types.zig");
const fusioners: type = @import("root").fusioners;
const decls: type = @import("root").decls;
const interfeces: type = @import("root").interfaces;
const config: type = @import("root").config;

const fusioners_verified = r: {
    var fusioners_confirm: [
        fusioners.__SaturnAllFusioners__.len
    ]interfeces.fusium.FusiumDescription_T = undefined;
    for(fusioners.__SaturnAllFusioners__, 0..) |fusioner, i| {
        if(!decls.container_decl_exist(fusioner, .fusium)) @compileError(
            ""
        );
        if(!decls.container_decl_type(@TypeOf(fusioner.__SaturnFusiumDescription__), .fusium)) @compileError(
            ""
        );
        if(c.c_bool(fusioner.__SaturnFusiumDescription__.flags.blocked)) @compileError(
            ""
        );
        fusioners_confirm[i] = fusioner.__SaturnFusiumDescription__;
    }
    break :r fusioners_confirm;
};

pub fn fetch_fusioners(comptime f_names: []const[]const u8) [f_names.len]type {
    var fusioners_arr: [f_names.len]type = undefined;
    for(f_names, 0..) |fusioner, i|
        fusioners_arr[i] = comptime fetch_fusioner(
            fusioner
        );
    return fusioners_arr;
}

pub fn fetch_fusioner(comptime f_name: []const u8) type {
    for(fusioners_verified) |fusioner_info| {
        if(mem.eql(f_name, fusioner_info.name, .{ .case = true })) {
            if(c.c_bool(fusioner_info.flags.blocked)) @compileError(
                "fusioum: fusioner \"" ++ fusioner_info.name ++ "\" " ++
                "is blocked"
            );
            return fusioner_info.fusioner;
        }
    }
    @compileError("fusioum: fusioner \"" ++ f_name ++ "\" does not exist");
}
