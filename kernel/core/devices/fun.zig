// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fun.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Dev_T: type = @import("types.zig").Dev_T;
const DevErr_T: type = @import("types.zig").DevErr_T;
const MinorNum_T: type = @import("types.zig").MinorNum_T;

const add = @import("core.zig").add;
const del = @import("core.zig").del;

// Chamar essas funcoes de forma independente, faz com que crie um minor
// anonimo, ou seja, somente quem tem o minor e o major vai conseguir se
// comunicar com ele, nada de criar no vfs

pub fn create(
    D: *const Dev_T,
) DevErr_T!void {
    return @call(.always_inline, &add, .{
        D
    });
}

pub fn delete(
    M: MinorNum_T
) DevErr_T!void {
    return @call(.always_inline, &del, .{
        M
    });
}
