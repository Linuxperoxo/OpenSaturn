// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: core.zig    │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const fusioners: type = @import("root").fusioners;
const interfeces: type = @import("root").interfaces;
const config: type = @import("root").config;
const decls: type = @import("root").decls;
const c: type = @import("root").kernel.utils.c;

const fusioners_verified = r: {
    const aux: type = opaque {
        pub fn check_decl(comptime container: type) void {
            if(!decls.container_decl_exist(container, .fusium)) @compileError(
                ""
            );
        }

        pub fn check_decl_type(comptime container: anytype) void {
            if(!decls.container_decl_type(@TypeOf(container), .fusium)) @compileError(
                ""
            );
        }
    };
    var fusioners_confirm: [
        fusioners.__SaturnAllFusioners__.len
    ]interfeces.fusium.FusiumDescription_T = undefined;
    for(fusioners.__SaturnAllFusioners__, 0..) |fusioner, i| {
        aux.check_decl(fusioner);
        aux.check_decl_type(fusioners.__SaturnFusiumDescription__);
        if(c.c_bool(fusioner.__SaturnFusiumDescription__.flags.blocked)) @compileError(
            ""
        );
        fusioners_confirm[i] = fusioner.__SaturnFusiumDescription__;
    }
    break :r fusioners_confirm;
};
