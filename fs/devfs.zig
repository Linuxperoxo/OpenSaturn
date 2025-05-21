// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: devfs.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const fs: type = @import("root").fs;

const devfs: fs.filesystem = .{
    .flags = .{
        .creatable = 1,
        .purgeable = 1,
        .mountable = 1,
    },
    .module = .{
        .name = "devfs",
        .desc = "Core Kernel Virtual Filesystem",
        .author = "Linuxperoxo",
        .version = "1.0-1",
        .type = .filesystem,
        .init = &init,
        .exit = &exit,
    },
    .operation = .{
        .create = &create,
        .expurg = &expurg,
    },
};

fn create() u8 {

}

fn expurg() u8 {

}

fn init() u32 {
    @call(
        .never_inline,
        &fs.registerFilesystem,
        .{
            devfs
        }
    );
}

fn exit() u32 {
    @call(
        .never_inline,
        &fs.unregisterFilesystem,
        .{
            devfs.name
        }
    );
}
