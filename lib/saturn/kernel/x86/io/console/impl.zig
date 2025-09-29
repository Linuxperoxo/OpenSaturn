// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: impl.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const init: type = struct {
    pub fn kprint(str: []u8) void {
        @call(.never_inline, boot.kprint, .{
            str
        });
    }
};
pub const boot: type = struct {
    const ScreenContext_T: type = struct {
        fb: []u8,
        row: usize,
        col: usize,
    };

    var screenContext: ScreenContext_T = .{
        .fb = @as([*]u8, @ptrFromInt(0xB8000))[0..80 * 25],
        .row = 0,
        .col = 0,
    };

    pub fn kprint(str: []u8) void {
        
    }
};
pub const runtime: type = struct {
    pub fn kprint(str: []u8) void {
        
    }
};
