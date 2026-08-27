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

pub fn fetchFusioner(comptime f_name: []const u8) ?type {
    if(!config.fusium.options.fusium_enable) {
        return if(!config.fusium.options.fetch_error_if_fusium_disable) null else
        @compileError(
            "fusioum: fetchFusioner() is not allowed since fusion is disabled"
        );
    }
    for(core.fusioners_verified) |fusioner_info| {
        if(mem.eql(f_name, fusioner_info.name, .{ .case = true })) {
            checkBlocked(&fusioner_info);
            supportedArch(&fusioner_info) catch return null;
            return fusioner_info.fusioner;
        }
    }
    @compileError("fusioum: fusioner \"" ++ f_name ++ "\" does not exist or is disable in menuconfig/overrider");
}

fn supportedArch(comptime fusioner: *const types.FusiumDescription) anyerror!void {
    for(fusioner.arch) |supported| {
        if(supported == config.arch.options.target) return;
    }
    return if(config.fusium.options.ignore_arch_not_supported) error.IgnoreThis else
        @compileError(
            ""
        );
}

fn checkBlocked(comptime fusioner: *const types.FusiumDescription) void {
    if(fusioner.flags.blocked == 1 and !config.fusium.options.ignore_blocked_flag) @compileError(
        "fusium: fusioner \"" ++ fusioner.name ++ "\" is blocked!"
    );
}
