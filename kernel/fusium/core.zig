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
        pub fn checkDecl(comptime container: type) void {
            if(!decls.containerDeclExist(container, .fusium)) @compileError(
                "fusium: container \"" ++ @typeName(container) ++ "\" not have decl \"" ++
                 decls.whatIsDecl(.fusium) ++ "\""
            );
        }

        pub fn checkDeclType(comptime container: type) void {
            if(!decls.containerDeclType(container, .fusium)) @compileError(
                "fusium: container \"" ++ @typeName(container) ++ "\" have decl \"" ++
                decls.whatIsDecl(.fusium) ++ "\" different type of \"" ++
                @typeName(decls.whatIsDeclType(.fusium)) ++ "\""
            );
        }
    };
    var fusioners_confirm: [
        fusioners.__SaturnAllFusioners__.len
    ]types.FusiumDescription = undefined;
    var fusioners_total: usize = 0;
    for(fusioners.__SaturnAllFusioners__) |fusioner| {
        aux.checkDecl(fusioner);
        aux.checkDeclType(@TypeOf(fusioner.__SaturnFusiumDescription__));
        switch(menuconfig.fusionerMenuconfValue(fusioner.__SaturnFusiumDescription__.name) catch {
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
        *const [fusioners_total]types.FusiumDescription, @ptrCast(&fusioners_confirm)
    ).*;
};

pub fn saturnFusiumLoader(order_call: types.FusiumDescription.Order) void {
    if(!config.fusium.options.fusium_enable) return;
    inline for(fusioners_verified) |fusioner| {
        if(fusioner.order != order_call) continue;
        if(fusioner.init != null) fusioner.init.?() catch {
            // klog()
        };
    }
}
