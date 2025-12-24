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
const core: type = @import("core.zig");

pub fn fetch_fusioner(comptime f_name: []const u8) ?type {
    if(!config.fusium.options.FusiumEnable) {
        return if(!config.fusium.options.FetchErrorIfFusiumDisable) null else
        @compileError(
            "fusioum: fetch_fusioner() is not allowed since fusion is disabled"
        );
    }
    for(core.fusioners_verified) |fusioner_info| {
        if(mem.eql(f_name, fusioner_info.name, .{ .case = true })) {
            check_blocked(&fusioner_info);
            supported_arch(&fusioner_info) catch return null;
            return fusioner_info.fusioner;
        }
    }
    @compileError("fusioum: fusioner \"" ++ f_name ++ "\" does not exist or is disable in menuconfig/overrider");
}

fn supported_arch(comptime fusioner: *const types.FusiumDescription_T) anyerror!void {
    for(fusioner.arch) |supported| {
        if(supported == config.arch.options.Target) return;
    }
    return if(config.fusium.options.IgnoreArchNotSupported) error.IgnoreThis else
        @compileError(
            ""
        );
}

fn check_blocked(comptime fusioner: *const types.FusiumDescription_T) void {
    if(fusioner.flags.blocked == 1 and !config.fusium.options.IgnoreBlockedFlag) @compileError(
        "fusium: fusioner \"" ++ fusioner.name ++ "\" is blocked!"
    );
}
