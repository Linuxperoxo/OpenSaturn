// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: management.zig │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

const Fs_T: type = @import("root").interfaces.fs.Fs_T;
const FsErr_T: type = @import("root").interfaces.fs.FsErr_T;
const alloc = @import("interfaces.zig").alloc;
const free = @import("interfaces.zig").free;

var fsRegisted: struct { fs: ?Fs_T, next: ?*@This() } = .{
    .fs = null,
    .next = null,
};

fn cmpName(
    n0: []const u8,
    n1: []const u8
) bool {
    const max: usize = if(n0.len < n1.len) n0.len else n1.len;
    var int: usize = 0;
    while(int < max) : (int += 1) {
        if(n0[int] != n1[int]) return false;
    }
    return true;
}

pub fn registerfs(
    _: *Fs_T
) FsErr_T!void {
    // TODO:
    asm volatile("movl $0xB8000, %eax\n movb $'H', (%eax)\n jmp ."); // NOTE: Apenas para debug
}

pub fn unregisterfs(
    name: []const u8
) FsErr_T!void {
    var current: ?*@TypeOf(fsRegisted) = &fsRegisted;
    var prev: ?*@TypeOf(fsRegisted) = &fsRegisted;
    while(current) |_| {
        if(current.?.fs) |_| {
            if(@call(.always_inline, &cmpName, .{
                name,
                current.?.fs.?.name
            })) {
                prev.?.next = current.?.next;
                free(current.?);
                return;
            }
        }
        prev = current;
        current = current.?.next;
    }
    return FsErr_T.NoNRegistered;
}
