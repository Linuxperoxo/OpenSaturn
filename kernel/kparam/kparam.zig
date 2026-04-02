// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: kparam.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const parser: type = @import("parser.zig");
const allocator: type = @import("allocator.zig");

var sys_param: types.Params_T = .{};

pub inline fn params_loader(params: []const u8) void {
    const parsed_params: []const types.Param_T = parser.params_parser(params) catch |err| {
        _ = err;
        // KLOG()
        return;
    };
    for(0..parsed_params.len) |i| {
        sys_param.add(
            parsed_params[i].param,
            parsed_params[i].value,
            &allocator.sba.allocator
        ) catch |err| {
            _ = err;
            // KLOG()
        };
    }
}

pub noinline fn params_search(param: []const u8) types.KParamErr_T!types.Value_T {
    return sys_param.search(param)
        catch return types.KParamErr_T.SysParamNotFound;
}
