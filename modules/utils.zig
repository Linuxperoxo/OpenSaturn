// ┌───────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: utils.zig     │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

pub fn compileError(comptime F: []const u8, comptime N: []const u8, comptime T: ?[]const u8) void {
    if(T) |_| {
        @compileError(
            N ++ " is defined in the module file " ++ F ++ ", but is not the expected type " ++ T.?
        );
    }
    @compileError(
        N ++ " is not defined in the module file " ++ F
    );
}

pub fn cmpModsNames(
    comptime @"0": []const u8,
    comptime @"1": []const u8
) bool {
    if(@"0".len != @"1".len) {
        return false;
    }
    for(0..@"0".len) |i| {
        if(@"0"[i] != @"1"[i]) {
            return false;
        }
    }
    return true;
}
