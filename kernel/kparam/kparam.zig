// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: kparam.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const parser: type = @import("parser.zig");
const allocator: type = @import("allocator.zig");

var sys_param: types.Params = .{};

pub inline fn paramsLoader(params: []const u8) void {
    if(params.len == 0)
        return;

    const parsed_params: []const types.Param = parser.paramsParser(params) catch {
        // KLOG()
        return;
    };

    for(0..parsed_params.len) |i| {
        sys_param.add(
            parsed_params[i].param,
            parsed_params[i].value,
            &allocator.sba.allocator
        ) catch {
            // KLOG()
        };
    }
}

pub noinline fn paramsSearch(param: []const u8) types.KParamErr!types.Value {
    return sys_param.search(param)
        catch return types.KParamErr.SysParamNotFound;
}
