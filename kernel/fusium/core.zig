// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: core.zig    │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const fusioners: type = @import("root").fusioners;
const config: type = @import("root").config;
const decls: type = @import("root").decls;
const c: type = @import("root").kernel.utils.c;
const menuconfig: type = @import("menuconfig.zig");
const types: type = @import("types.zig");

pub const fusioners_verified = r: {
    const aux: type = opaque {
        pub fn check_decl(comptime container: type) void {
            if(!decls.container_decl_exist(container, .fusium)) @compileError(
                "fusium: container \"" ++ @typeName(container) ++ "\" not have decl \"" ++
                 decls.what_is_decl(.fusium) ++ "\""
            );
        }

        pub fn check_decl_type(comptime container: type) void {
            if(!decls.container_decl_type(container, .fusium)) @compileError(
                "fusium: container \"" ++ @typeName(container) ++ "\" have decl \"" ++
                decls.what_is_decl(.fusium) ++ "\" different type of \"" ++
                @typeName(decls.what_is_decl_type(.fusium)) ++ "\""
            );
        }
    };
    var fusioners_confirm: [
        fusioners.__SaturnAllFusioners__.len
    ]types.FusiumDescription_T = undefined;
    var fusioners_total: usize = 0;
    for(fusioners.__SaturnAllFusioners__) |fusioner| {
        aux.check_decl(fusioner);
        aux.check_decl_type(@TypeOf(fusioner.__SaturnFusiumDescription__));
        switch(menuconfig.fusioner_menuconf_value(fusioner.__SaturnFusiumDescription__.name) catch {
            @compileError(
                "fusium: fusioner \"" ++ fusioner.__SaturnFusiumDescription__.name ++ "\" was not included in menuconfig"
            );
        }) {
            .yes => {},
            .no => continue,
        }
        fusioners_confirm[fusioners_total] = fusioner.__SaturnFusiumDescription__;
        fusioners_total += 1;
    }
    break :r @as(
        *const [fusioners_total]types.FusiumDescription_T, @ptrCast(&fusioners_confirm)
    ).*;
};

pub fn saturn_fusium_loader() void {
    if(!config.fusium.options.FusiumEnable) return;
    inline for(fusioners_verified) |fusioner| {
        if(fusioner.init != null) fusioner.init.?() catch {
            // klog()
        };
    }
}
