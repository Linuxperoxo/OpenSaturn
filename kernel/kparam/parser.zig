// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: parser.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const mem: type = @import("root").lib.kernel.mem;

pub inline fn paramsParser(params: []const u8) types.KParamErr![]const types.Param {
    var rvalue: bool = false;
    var local_index: usize = 0;
    var parsed_index: usize = 0;
    var i: usize = 0;

    const parsed_params: []types.Param = allocator.sba.allocator.alloc(types.Param, paramsCounter(params))
        catch return types.KParamErr.AllocatorInternalError;

    for(params) |char| {
        sw: switch(char) {
            '\n' => {
                defer {
                    local_index = i + 1;
                    parsed_index += 1;
                    rvalue = false;
                }
                if(mem.eql(params[local_index..i], @tagName(types.Value.yes), .{})) {
                    parsed_params[parsed_index].value = types.Value.yes;
                    break :sw {};
                }
                if(mem.eql(params[local_index..i], @tagName(types.Value.no), .{})) {
                    parsed_params[parsed_index].value = types.Value.no;
                    break :sw {};
                }
                return types.KParamErr.ParserInvalidValue;
            },

            '=' => {
                if(rvalue) return types.KParamErr.ParserSyntaxError;
                if(local_index >= i) return types.KParamErr.ParserMissingParameter;
                if((i + 1) == params.len) return types.KParamErr.ParserMissingValue;

                switch(params[i + 1]) {
                    '\n', ' ' => return types.KParamErr.ParserMissingValue,
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

inline fn paramsCounter(params: []const u8) usize {
    var counter: usize = 0;
    for(params) |char|
        counter += @intFromBool(char == '=');
    return counter;
}
