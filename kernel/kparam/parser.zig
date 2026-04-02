// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: parser.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const mem: type = @import("root").lib.utils.mem;

pub inline fn params_parser(params: []const u8) types.KParamErr_T![]const types.Param_T {
    var rvalue: bool = false;
    var local_index: usize = 0;
    var parsed_index: usize = 0;

    const parsed_params: []types.Param_T = allocator.sba.allocator.alloc(
        types.Param_T,
        params_counter(params)
    ) catch return types.KParamErr_T.AllocatorInternalError;
    errdefer allocator.sba.allocator.free(parsed_params)
        catch {};

    var i: usize = 0;
    for(params) |char| {
        sw: switch(char) {
            ';', '\n' => {
                defer {
                    local_index = i + 1;
                    parsed_index += 1;
                    rvalue = false;
                }
                if(mem.eql(params[local_index..i], @tagName(types.Value_T.yes), .{})) {
                    parsed_params[parsed_index].value = types.Value_T.yes;
                    break :sw {};
                }
                if(mem.eql(params[local_index..i], @tagName(types.Value_T.no), .{})) {
                    parsed_params[parsed_index].value = types.Value_T.no;
                    break :sw {};
                }
                return types.KParamErr_T.ParserInvalidValue;
            },

            '=' => {
                if(rvalue) return types.KParamErr_T.ParserSyntaxError;
                if(local_index >= i) return types.KParamErr_T.ParserMissingParameter;
                if((i + 1) == params.len) return types.KParamErr_T.ParserMissingValue;

                switch(params[i + 1]) {
                    '\n', ' ' => return types.KParamErr_T.ParserMissingValue,
                    else => {},
                }

                parsed_params[parsed_index].param = params[local_index..i];
                local_index = i + 1;
                rvalue = true;
            },

            ' ' => {
                if(rvalue) continue :sw '\n';
                local_index += 1;
            },

            else => {
                if((i + 1) >= params.len) {
                    i += 1;
                    continue :sw '\n';
                }
            },
        }
        i += 1;
    }
    return parsed_params;
}

inline fn params_counter(params: []const u8) usize {
    var counter: usize = 0;
    for(params) |char|
        counter += @intFromBool(char == '=');
    return counter;
}

test "Parsing Test" {
    const std: type = @import("std");
    const kernel_param: []const u8 =
        \\sysmod_disable_devfs=yes
        \\sysmod_enable_devfs=no
    ;

    for(try params_parser(kernel_param)) |parsed_param| {
        std.debug.print("{s} = {s}\n", .{
            parsed_param.param,
            @tagName(parsed_param.value),
        });
    }
}
