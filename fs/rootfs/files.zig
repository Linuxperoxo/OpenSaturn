// ┌────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: files.zig      │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

// kernel vfs types
const Dentry_T: type = @import("root").core.vfs.interfaces.Dentry_T;
const Inode_T: type = @import("root").core.vfs.interfaces.Inode_T;
const InodeOp_T: type = @import("root").core.vfs.interfaces.InodeOp_T;

// rootfs types
const RootfsBranch_T: type = @import("types.zig").RootfsBranch_T;

// rootfs fn
const rootfs_create = @import("management.zig").rootfs_create;
const rootfs_interator = @import("management.zig").rootfs_interator;
const rootfs_lookup = @import("management.zig").rootfs_lookup;
const rootfs_mkdir = @import("management.zig").rootfs_mkdir;
const rootfs_unlink = @import("management.zig").rootfs_unlink;

pub var @"/": RootfsBranch_T = .{
    .dentry = null,
    .brother = null,
    .child = null,
    .parent = null,
};

pub var @"usr": RootfsBranch_T = .{
    .dentry = null,
    .brother = null,
    .child = null,
    .parent = null,
};

pub var @"sys": RootfsBranch_T = .{
    .dentry = null,
    .brother = null,
    .child = null,
    .parent = null,
};

pub var @"dev": RootfsBranch_T = .{
    .dentry = null,
    .brother = null,
    .child = null,
    .parent = null,
};

pub var @"volatile": RootfsBranch_T = .{
    .dentry = null,
    .brother = null,
    .child = null,
    .parent = null,
};

comptime {
    @call(.compile_time, &createRootfsBranch, .{
        &@"/",
        "/",
        0,
    });
    @call(.compile_time, &createRootfsBranch, .{
        &@"usr",
        "usr",
        0,
    });
    @call(.compile_time, &createRootfsBranch, .{
        &@"sys",
        "sys",
        0,
    });
    @call(.compile_time, &createRootfsBranch, .{
        &@"dev",
        "dev",
        0,
    });
    @call(.compile_time, &createRootfsBranch, .{
        &@"volatile",
        "volatile",
        0,
    });

    @"/".brother = null;
    @"/".child = &@"usr";
    @"/".parent = &@"/";

    @"usr".brother = &@"sys";
    @"usr".child = null;
    @"usr".parent = &@"/";

    @"sys".brother = &@"dev";
    @"sys".child = null;
    @"sys".parent = @"/";

    @"dev".brother = &@"volatile";
    @"dev".child = null;
    @"dev".parent = @"/";

    @"volatile".brother = null;
    @"volatile".child = null;
    @"volatile".parent = &@"/";
}

fn createRootfsBranch(
    comptime ptr: *RootfsBranch_T,
    comptime name: []const u8,
    comptime ino: usize,
) void {
    ptr.dentry = @call(.compile_time, &createDefaultDentry, .{name, ino, ptr});
}

fn createDefaultInodeOp() *InodeOp_T {
    return @constCast(&InodeOp_T {
        .create = @constCast(&rootfs_create),
        .interator = @constCast(&rootfs_interator),
        .lookup = @constCast(&rootfs_lookup),
        .mkdir = @constCast(&rootfs_mkdir),
        .unlink = @constCast(&rootfs_unlink),
    });
}

fn createDefaultDentry(
    comptime name: []const u8,
    comptime ino: usize,
    comptime priv: *RootfsBranch_T,
) *Dentry_T {
    return @constCast(&Dentry_T {
        .name = name,
        .inode = @constCast(&Inode_T {
            .ino = ino,
            .type = .directory,
            .uid = 0,
            .gid = 0,
            .mode = 0b111101101,
            .nlinks = 0,
            .data_block = 0,
            .private = priv,
            .ops = @call(.compile_time, &createDefaultInodeOp, .{}),
        }),
    });
}
